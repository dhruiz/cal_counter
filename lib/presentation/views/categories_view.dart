import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../domain/entities/category.dart';
import '../../domain/errors/domain_errors.dart';
import '../providers/foods_provider.dart';
import '../providers/purchases_provider.dart';
import '../widgets/food_widgets.dart';

/// Categorías (secciones del súper) y orden de los pasillos: el general o
/// el de una tienda concreta. Arrastra para ordenar según tu recorrido.
class CategoriesView extends ConsumerStatefulWidget {
  /// Tienda cuyo orden se edita al abrir (null = orden general).
  final String? tienda;

  const CategoriesView({super.key, this.tienda});

  static Future<void> open(BuildContext context, {String? tienda}) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoriesView(tienda: tienda)),
      );

  @override
  ConsumerState<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends ConsumerState<CategoriesView> {
  String? _tienda;

  /// Orden mostrado mientras se guarda (respuesta inmediata al arrastrar).
  List<Category>? _local;

  @override
  void initState() {
    super.initState();
    _tienda = widget.tienda;
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _reorder(List<Category> cats, int oldIndex, int newIndex) async {
    // onReorderItem ya ajusta newIndex tras quitar el elemento.
    final list = [...cats];
    list.insert(newIndex, list.removeAt(oldIndex));
    setState(() => _local = list);
    await ref.read(categoryRepositoryProvider).reorder([
      for (final c in list) c.id!,
    ], tienda: _tienda);
    if (mounted) setState(() => _local = null);
  }

  Future<void> _edit([Category? c]) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryNameDialog(categoria: c),
    );
    if (res == null || !mounted) return;
    final repo = ref.read(categoryRepositoryProvider);
    if (res == '\u0000borrar') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar categoría'),
          content: Text(
            '¿Eliminar "${c!.nombre}"? Sus alimentos quedarán sin categoría.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (ok == true) await repo.deleteCategory(c!.id!);
      return;
    }
    try {
      await repo.saveCategory(
        Category(id: c?.id, nombre: res, orden: c?.orden ?? 0),
      );
    } on ValidationException catch (e) {
      _msg(e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider).valueOrNull ?? const <String>[];
    final remote =
        ref.watch(categoriesProvider(_tienda)).valueOrNull ??
        const <Category>[];
    final cats = _local ?? remote;
    final tienda = _tienda;
    final propio = tienda == null
        ? false
        : ref.watch(hasStoreOrderProvider(tienda)).valueOrNull ?? false;
    final opciones = {...stores, ?tienda}.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías y pasillos'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Nueva categoría',
            icon: const Icon(Icons.add),
            onPressed: () => _edit(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<String?>(
              initialValue: tienda,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Orden de los pasillos',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('General (todas las tiendas)'),
                ),
                for (final s in opciones)
                  DropdownMenuItem<String?>(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() {
                _tienda = v;
                _local = null;
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InfoBanner(
              color: AppStyles.semaphBlue,
              icon: Icons.drag_indicator,
              text: tienda == null
                  ? 'Arrastra las categorías según tu recorrido habitual. Las '
                        'listas de compra se ordenan así.'
                  : (propio
                        ? 'Orden propio de $tienda: se usa en el modo carrito '
                              'cuando compras allí.'
                        : '$tienda usa el orden general. Arrastra para '
                              'crear uno propio.'),
              action: tienda != null && propio
                  ? TextButton(
                      onPressed: () => ref
                          .read(categoryRepositoryProvider)
                          .resetStoreOrder(tienda),
                      child: const Text('Usar el general'),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              itemCount: cats.length,
              onReorderItem: (o, n) => _reorder(cats, o, n),
              itemBuilder: (ctx, i) {
                final c = cats[i];
                return ListTile(
                  key: ValueKey('cat_${c.id}'),
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(c.nombre),
                  trailing: const Icon(Icons.drag_handle),
                  onTap: () => _edit(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo con su propio controlador (se libera al cerrarse el diálogo,
/// no antes de que termine la animación).
class _CategoryNameDialog extends StatefulWidget {
  final Category? categoria;

  const _CategoryNameDialog({this.categoria});

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.categoria?.nombre ?? '',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.categoria;
    return AlertDialog(
      title: Text(c == null ? 'Nueva categoría' : 'Renombrar categoría'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Nombre'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        if (c != null)
          TextButton(
            onPressed: () => Navigator.pop(context, '\u0000borrar'),
            child: const Text('Eliminar'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
