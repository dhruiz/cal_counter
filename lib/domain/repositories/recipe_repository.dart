import '../entities/recipe.dart';

abstract class RecipeRepository {
  /// Todas las recetas con sus ingredientes (favoritas primero, luego A-Z).
  Future<List<Recipe>> getAllRecipes();
  Future<Recipe?> getRecipe(int id);

  /// Inserta (id null) o actualiza la receta y reemplaza sus ingredientes.
  /// Devuelve el id.
  Future<int> saveRecipe(Recipe recipe);
  Future<void> deleteRecipe(int id);
  Future<void> setFavorite(int id, bool favorita);
}
