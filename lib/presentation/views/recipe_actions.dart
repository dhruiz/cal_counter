import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/services/money.dart';
import '../../domain/services/nutrition_calculator.dart';
import '../providers/recipes_provider.dart';
import '../widgets/dialog_controllers.dart';
import '../widgets/ingredient_sheet.dart';
import 'food_form_view.dart';

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
    await ref.read(saveRecipeProvider)(receta.copyWith(ingredientes: list));
  }

  static Set<int> _excluir(Recipe receta) => {?receta.alimentoId};

  static Future<void> _apply(
    WidgetRef ref,
    Recipe receta,
    int indice,
    IngredientEdit? res,
  ) async {
    if (res == null) return;
    if (res.quitar) {
      final list = [...receta.ingredientes]..removeAt(indice);
      await ref.read(saveRecipeProvider)(receta.copyWith(ingredientes: list));
      return;
    }
    await _saveIngredient(ref, receta, indice, res.ingrediente!);
  }

  /// Vincula la línea [indice] a un alimento elegido en el buscador (o
  /// creado), proponiendo la cantidad escrita en la línea.
  static Future<void> link(
    BuildContext context,
    WidgetRef ref,
    Recipe receta,
    int indice,
  ) async {
    final res = await IngredientSheet.pickAndEdit(
      context,
      ingrediente: receta.ingredientes[indice],
      excluir: _excluir(receta),
    );
    await _apply(ref, receta, indice, res);
  }

  /// Editor de una línea: alimento, cantidad, unidad, nota y opcional. Una
  /// línea sin vincular se busca primero en tus alimentos.
  static Future<void> edit(
    BuildContext context,
    WidgetRef ref,
    Recipe receta,
    int indice, {
    Food? alimento,
    List<FoodPortion> porciones = const [],
  }) async {
    final ing = receta.ingredientes[indice];
    if (alimento == null) {
      await link(context, ref, receta, indice);
      return;
    }
    final res = await IngredientSheet.show(
      context,
      alimento: alimento,
      ingrediente: ing,
      excluir: _excluir(receta),
    );
    await _apply(ref, receta, indice, res);
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
      case IngredientIssueKind.circular:
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
