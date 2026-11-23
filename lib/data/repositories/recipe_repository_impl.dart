import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe_local_data_source.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeLocalDataSource dataSource;

  RecipeRepositoryImpl(this.dataSource);

  @override
  Future<List<Recipe>> getAllRecipes() => dataSource.getAllRecipes();

  @override
  Future<Recipe?> getRecipe(int id) => dataSource.getRecipe(id);

  @override
  Future<int> saveRecipe(Recipe recipe) => dataSource.saveRecipe(recipe);

  @override
  Future<void> deleteRecipe(int id) => dataSource.deleteRecipe(id);

  @override
  Future<void> setFavorite(int id, bool favorita) =>
      dataSource.setFavorite(id, favorita);
}
