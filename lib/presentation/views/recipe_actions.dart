import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/services/money.dart';
import '../../domain/services/nutrition_calculator.dart';
import '../../domain/services/quantity_parser.dart';
import '../providers/foods_provider.dart';
import '../providers/recipes_provider.dart';
import '../widgets/dialog_controllers.dart';
import 'food_form_view.dart';
import 'food_picker_view.dart';

/// Acciones sobre ingredientes de una receta: vincular, cantidad, porciones y
/// resolver lo que falta para calcular la nutrición.
class RecipeActions {
  RecipeActions._();

  static Future<void> _saveIngredient(
    WidgetRef ref,
    Recipe receta,
    int indice,
    RecipeIngredient ing,
  ) async {
    final list = [...receta.ingredientes];
    list[indice] = ing;
    await ref
        .read(recipeRepositoryProvider)
        .save(receta.copyWith(ingredientes: list));
  }

  /// Vincula la línea [indice] a un alimento elegido (o creado), proponiendo
  /// la cantidad escrita en la línea.
  static Future<void> link(
    BuildContext context,
    WidgetRef ref,
    Recipe receta,
    int indice,
  ) async {
    final ing = receta.ingredientes[indice];
    final nombre = parseIngredientLine(ing.texto).nombre;
    final food = await FoodPickerView.pick(
      context,
      initialQuery: nombre,
      title: 'Vincular «${ing.texto}»',
    );
    if (food == null) return;
    final q = parseQuantity(ing.texto);
    await _saveIngredient(
      ref,
      receta,
      indice,
      ing.copyWith(
        alimentoId: food.id,
        cantidad: ing.cantidad ?? q?.cantidad,
        unidad:
            ing.unidad ??
            (q == null
                ? null
                : (q.esMasa || q.esVolumen ? food.unidad.clave : q.unidad)),
      ),
    );
  }

  /// Editor completo de una línea: alimento, cantidad, unidad y opcional.
  static Future<void> edit(
    BuildContext context,
    WidgetRef ref,
    Recipe receta,
    int indice, {
    Food? alimento,
    List<FoodPortion> porciones = const [],
  }) async {
    final res = await showModalBottomSheet<RecipeIngredient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _IngredientEditor(
        ingrediente: receta.ingredientes[indice],
        alimento: alimento,
        porciones: porciones,
      ),
    );
    if (res != null) await _saveIngredient(ref, receta, indice, res);
  }

  /// Resuelve un problema concreto del cálculo nutricional.
  static Future<void> resolve(
    BuildContext context,
    WidgetRef ref,
    RecipeAnalysis a,
    IngredientIssue issue,
  ) async {
    final receta = a.receta;
    final food = issue.alimento;
    switch (issue.tipo) {
      case IngredientIssueKind.sinVincular:
      case IngredientIssueKind.alimentoNoEncontrado:
        await link(context, ref, receta, issue.indice);
      case IngredientIssueKind.alimentoPendiente:
        if (food != null) {
          await FoodFormView.open(context, food: food, completar: true);
        }
      case IngredientIssueKind.sinCantidad:
        await edit(
          context,
          ref,
          receta,
          issue.indice,
          alimento: food,
          porciones: food == null ? const [] : a.porciones[food.id] ?? const [],
        );
      case IngredientIssueKind.unidadSinEquivalencia:
        if (food == null) return;
        await addPortion(context, ref, food, issue.ingrediente.unidad ?? '');
    }
  }

  /// Pide cuántos g/ml pesa 1 [nombre] del alimento y lo guarda.
  static Future<void> addPortion(
    BuildContext context,
    WidgetRef ref,
    Food food,
    String nombre,
  ) async {
    final gramos = await showDialog<double>(
      context: context,
      builder: (_) => DialogControllers(
        iniciales: const [''],
        builder: (ctx, c) => _portionDialog(ctx, c.first, food, nombre),
      ),
    );
    if (gramos == null || gramos <= 0) return;
    try {
      await ref
          .read(foodRepositoryProvider)
          .savePortion(
            FoodPortion(alimentoId: food.id, nombre: nombre, gramos: gramos),
          );
    } on ValidationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    }
  }

  static Widget _portionDialog(
    BuildContext ctx,
    TextEditingController ctrl,
    Food food,
    String nombre,
  ) => AlertDialog(
    title: Text('¿Cuánto pesa 1 $nombre?'),
    content: TextField(
      controller: ctrl,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '1 $nombre de ${food.nombre}',
        suffixText: food.u,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(ctx, parseDecimal(ctrl.text)),
        child: const Text('Guardar'),
      ),
    ],
  );
}

class _IngredientEditor extends ConsumerStatefulWidget {
  final RecipeIngredient ingrediente;
  final Food? alimento;
  final List<FoodPortion> porciones;

  const _IngredientEditor({
    required this.ingrediente,
    required this.alimento,
    required this.porciones,
  });

  @override
  ConsumerState<_IngredientEditor> createState() => _IngredientEditorState();
}

class _IngredientEditorState extends ConsumerState<_IngredientEditor> {
  late final TextEditingController _textCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;
  Food? _food;
  late bool _opcional;

  @override
  void initState() {
    super.initState();
    final ing = widget.ingrediente;
    final q = parseQuantity(ing.texto);
    _textCtrl = TextEditingController(text: ing.texto);
    _qtyCtrl = TextEditingController(
      text: AppUtils.formatNumero(
        ing.cantidad ?? q?.cantidad ?? 0,
      ).replaceAll(RegExp(r'^0$'), ''),
    );
    _food = widget.alimento;
    _unitCtrl = TextEditingController(
      text: ing.unidad ?? _defaultUnit(q, widget.alimento),
    );
    _opcional = ing.opcional;
  }

  static String _defaultUnit(ParsedQuantity? q, Food? f) {
    if (q == null) return f?.unidad.clave ?? 'g';
    if (q.esMasa || q.esVolumen) return f?.unidad.clave ?? q.unidad;
    return q.unidad;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await FoodPickerView.pick(context, initialQuery: _textCtrl.text);
    if (f != null) setState(() => _food = f);
  }

  void _save() {
    final cantidad = parseDecimal(_qtyCtrl.text);
    final unidad = _unitCtrl.text.trim();
    Navigator.pop(
      context,
      _food == null
          ? RecipeIngredient(
              id: widget.ingrediente.id,
              texto: _textCtrl.text.trim(),
              opcional: _opcional,
            )
          : RecipeIngredient(
              id: widget.ingrediente.id,
              texto: _textCtrl.text.trim(),
              alimentoId: _food!.id,
              cantidad: (cantidad ?? 0) > 0 ? cantidad : null,
              unidad: unidad.isEmpty ? _food!.unidad.clave : unidad,
              opcional: _opcional,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = _food;
    final porciones = food == null
        ? const <FoodPortion>[]
        : (ref.watch(foodPortionsProvider(food.id!)).valueOrNull ??
              widget.porciones);
    final unidades = <String>{
      if (food != null) food.unidad.clave,
      for (final p in porciones) p.nombre,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ingrediente', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _textCtrl,
              decoration: const InputDecoration(
                labelText: 'Línea de la receta',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.kitchen_outlined),
              title: Text(food?.nombreCompleto ?? 'Sin vincular'),
              subtitle: food == null
                  ? const Text('Vincúlalo para calcular las calorías')
                  : (food.pendiente
                        ? const Text('Alimento pendiente de completar')
                        : null),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _pick,
                    child: Text(food == null ? 'Vincular' : 'Cambiar'),
                  ),
                  if (food != null)
                    IconButton(
                      tooltip: 'Desvincular',
                      icon: const Icon(Icons.link_off),
                      onPressed: () => setState(() => _food = null),
                    ),
                ],
              ),
            ),
            if (food != null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _unitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        hintText: 'g, ml, diente, taza...',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final u in unidades)
                    ChoiceChip(
                      label: Text(u),
                      selected: _unitCtrl.text.trim() == u,
                      onSelected: (_) => setState(() => _unitCtrl.text = u),
                    ),
                ],
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Opcional'),
              subtitle: const Text('No cuenta para calorías ni faltantes'),
              value: _opcional,
              onChanged: (v) => setState(() => _opcional = v),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
          ],
        ),
      ),
    );
  }
}
