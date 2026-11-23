import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../providers/shopping_provider.dart';

/// Diálogo para llevar ingredientes de una receta a una lista de compra
/// (existente o nueva). [preseleccionados] indica qué líneas van marcadas;
/// si es null se marcan todas salvo los básicos (sal, aceite...).
class AddToShoppingListDialog extends ConsumerStatefulWidget {
  final List<String> lineas;
  final Set<String>? preseleccionados;

  const AddToShoppingListDialog({
    super.key,
    required this.lineas,
    this.preseleccionados,
  });

  /// Muestra el diálogo y un SnackBar con el resultado.
  static Future<void> show(
    BuildContext context, {
    required List<String> lineas,
    Set<String>? preseleccionados,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final msg = await showDialog<String>(
      context: context,
      builder: (_) => AddToShoppingListDialog(
        lineas: lineas,
        preseleccionados: preseleccionados,
      ),
    );
    if (msg != null) messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  ConsumerState<AddToShoppingListDialog> createState() =>
      _AddToShoppingListDialogState();
}

class _AddToShoppingListDialogState
    extends ConsumerState<AddToShoppingListDialog> {
  static const int _nuevaLista = -1;
  late final Set<int> _checked;
  int? _listaId;
  final _nameCtrl = TextEditingController(
    text: 'Compra ${AppUtils.formatFechaCorta(DateTime.now())}',
  );
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checked = {
      for (var i = 0; i < widget.lineas.length; i++)
        if (widget.preseleccionados?.contains(widget.lineas[i]) ??
            !IngredientAvailability.isBasic(widget.lineas[i]))
          i,
    };
    final lists = ref.read(shoppingListsProvider).lists;
    _listaId = lists.isEmpty ? _nuevaLista : lists.first.id;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final notifier = ref.read(shoppingListsProvider.notifier);
    setState(() => _saving = true);
    var listaId = _listaId!;
    var nombre = '';
    if (listaId == _nuevaLista) {
      nombre = _nameCtrl.text.trim().isEmpty
          ? 'Lista de compra'
          : _nameCtrl.text.trim();
      listaId = await notifier.create(nombre);
    } else {
      nombre = ref
          .read(shoppingListsProvider)
          .lists
          .firstWhere((l) => l.id == listaId)
          .nombre;
    }
    final lineas = [
      for (var i = 0; i < widget.lineas.length; i++)
        if (_checked.contains(i)) widget.lineas[i],
    ];
    final n = await notifier.addIngredients(listaId, lineas);
    if (!mounted) return;
    Navigator.pop(
      context,
      n == 0
          ? 'Esos ingredientes ya estaban en "$nombre"'
          : '$n ${n == 1 ? 'artículo añadido' : 'artículos añadidos'} a "$nombre"',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(shoppingListsProvider).lists;
    return AlertDialog(
      title: const Text('Añadir a la lista de compra'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _listaId,
              decoration: const InputDecoration(labelText: 'Lista'),
              items: [
                ...lists.map(
                  (l) => DropdownMenuItem(value: l.id, child: Text(l.nombre)),
                ),
                const DropdownMenuItem(
                  value: _nuevaLista,
                  child: Text('➕ Nueva lista'),
                ),
              ],
              onChanged: (v) => setState(() => _listaId = v),
            ),
            if (_listaId == _nuevaLista)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la nueva lista',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text('Marca lo que necesitas comprar:'),
            ...List.generate(widget.lineas.length, (i) {
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _checked.contains(i),
                title: Text(widget.lineas[i]),
                onChanged: (v) => setState(
                  () => v == true ? _checked.add(i) : _checked.remove(i),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving || _checked.isEmpty || _listaId == null
              ? null
              : _add,
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}
