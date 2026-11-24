import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/add_ingredients_to_shopping_list.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../providers/shopping_provider.dart';

/// Diálogo para llevar ingredientes de una receta a una lista de compra
/// (existente o nueva). [preseleccionados] indica qué líneas van marcadas;
/// si es null se marcan todas salvo los básicos (sal, aceite...). Los
/// ingredientes vinculados a un alimento conservan el vínculo en la lista.
/// Con [factor] (escala de la receta) las cantidades se multiplican y se
/// guardan como mínimo a comprar.
class AddToShoppingListDialog extends ConsumerStatefulWidget {
  final List<RecipeIngredient> ingredientes;
  final Set<String>? preseleccionados;
  final double factor;

  /// Texto de cada línea (escalada) para mostrar.
  final List<String>? textos;

  const AddToShoppingListDialog({
    super.key,
    required this.ingredientes,
    this.preseleccionados,
    this.factor = 1,
    this.textos,
  });

  List<String> get lineas => [for (final i in ingredientes) i.texto];

  /// Muestra el diálogo y un SnackBar con el resultado.
  static Future<void> show(
    BuildContext context, {
    required List<RecipeIngredient> ingredientes,
    Set<String>? preseleccionados,
    double factor = 1,
    List<String>? textos,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final msg = await showDialog<String>(
      context: context,
      builder: (_) => AddToShoppingListDialog(
        ingredientes: ingredientes,
        preseleccionados: preseleccionados,
        factor: factor,
        textos: textos,
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
    final lists = ref.read(shoppingListsProvider).valueOrNull ?? const [];
    _listaId = lists.isEmpty ? _nuevaLista : lists.first.id;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final notifier = ref.read(shoppingListsActionsProvider);
    setState(() => _saving = true);
    var listaId = _listaId!;
    var nombre = '';
    final ShoppingAddResult n;
    try {
      if (listaId == _nuevaLista) {
        nombre = _nameCtrl.text.trim().isEmpty
            ? 'Lista de compra'
            : _nameCtrl.text.trim();
        listaId = await notifier.create(nombre);
      } else {
        nombre = (ref.read(shoppingListsProvider).valueOrNull ?? const [])
            .firstWhere((l) => l.id == listaId)
            .nombre;
      }
      final elegidos = [
        for (var i = 0; i < widget.ingredientes.length; i++)
          if (_checked.contains(i)) widget.ingredientes[i],
      ];
      n = await notifier.addIngredients(
        listaId,
        elegidos,
        factor: widget.factor,
      );
    } catch (e) {
      // Sin esto el diálogo quedaba con los botones deshabilitados.
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo añadir: $e')));
      return;
    }
    if (!mounted) return;
    final partes = [
      if (n.anadidos > 0)
        '${n.anadidos} ${n.anadidos == 1 ? 'artículo añadido' : 'artículos añadidos'}',
      if (n.actualizados > 0)
        '${n.actualizados} ${n.actualizados == 1 ? 'actualizado' : 'actualizados'} '
            '(se suma la cantidad)',
    ];
    Navigator.pop(
      context,
      n.total == 0
          ? 'Esos ingredientes ya estaban en "$nombre"'
          : '${partes.join(' y ')} a "$nombre"',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(shoppingListsProvider).valueOrNull ?? const [];
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
            Text(
              widget.factor == 1
                  ? 'Marca lo que necesitas comprar:'
                  : 'Marca lo que necesitas comprar (cantidades a '
                        '×${AppUtils.formatNumero(widget.factor)}):',
            ),
            ...List.generate(widget.lineas.length, (i) {
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _checked.contains(i),
                title: Text(widget.textos?[i] ?? widget.lineas[i]),
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

/// Añade un alimento del repertorio a una lista de compra (vinculado).
class AddFoodToShoppingListDialog {
  AddFoodToShoppingListDialog._();

  static Future<void> show(BuildContext context, Food food) =>
      AddToShoppingListDialog.show(
        context,
        ingredientes: [
          RecipeIngredient(texto: food.nombre, alimentoId: food.id),
        ],
        preseleccionados: {food.nombre},
      );
}
