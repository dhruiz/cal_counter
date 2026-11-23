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

  /// Recetas que usan el alimento en algún ingrediente.
  Stream<List<Recipe>> watchUsingFood(int alimentoId);
}
