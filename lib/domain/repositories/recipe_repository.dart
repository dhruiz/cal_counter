import '../entities/recipe.dart';

abstract class RecipeRepository {
  /// Todas las recetas con sus ingredientes (favoritas primero, luego A-Z).
  Stream<List<Recipe>> watchAll();
  Future<List<Recipe>> getAll();
  Future<Recipe?> get(int id);
  Stream<Recipe?> watch(int id);

  /// Inserta (id null) o actualiza la receta y reemplaza sus ingredientes.
  /// Devuelve el id.
  Future<int> save(Recipe recipe);
  Future<void> delete(int id);
  Future<void> setFavorite(int id, bool favorita);

  /// Recetas que usan el alimento en algún ingrediente (o que lo tienen como
  /// su alimento "preparado").
  Stream<List<Recipe>> watchUsingFood(int alimentoId);

  /// Receta cuyo alimento "preparado" es [alimentoId], si la hay.
  Stream<Recipe?> watchByFood(int alimentoId);

  /// Vincula la receta con su alimento "preparado" (null = sin alimento) sin
  /// tocar los ingredientes.
  Future<void> setFoodLink(int recipeId, int? alimentoId);

  /// Guarda el peso final de la preparación (null = sin peso) y, si se
  /// indica, el día en que se preparó.
  Future<void> setFinalWeight(
    int recipeId,
    double? pesoFinalG, {
    DateTime? preparadaEl,
  });

  /// Marca el día en que se preparó por última vez.
  Future<void> setLastPrepared(int recipeId, DateTime fecha);

  /// Emite al empezar y cada vez que cambian recetas, ingredientes, alimentos
  /// o porciones: lo que puede alterar la nutrición calculada de una receta.
  Stream<void> watchNutritionInputs();
}
