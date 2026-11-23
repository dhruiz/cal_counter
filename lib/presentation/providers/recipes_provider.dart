import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/recipe_local_data_source.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_match.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/usecases/import_recipes.dart';
import '../../domain/usecases/search_recipes_by_ingredients.dart';
import 'home_provider.dart'; // localDataSourceProvider

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositoryImpl(
    RecipeLocalDataSourceImpl(ref.watch(localDataSourceProvider)),
  );
});

final searchRecipesByIngredientsProvider = Provider<SearchRecipesByIngredients>(
  (ref) => SearchRecipesByIngredients(),
);

final importRecipesProvider = Provider<ImportRecipes>((ref) {
  return ImportRecipes(ref.watch(recipeRepositoryProvider));
});

enum RecipeSearchMode { ingredientes, nombre }

class RecipesState {
  final List<Recipe> recipes;
  final bool isLoading;
  final RecipeSearchMode mode;
  final String query;

  /// Asumir sal, pimienta, agua y aceite como disponibles.
  final bool incluirBasicos;
  final bool soloCompletas;

  const RecipesState({
    this.recipes = const [],
    this.isLoading = false,
    this.mode = RecipeSearchMode.ingredientes,
    this.query = '',
    this.incluirBasicos = true,
    this.soloCompletas = false,
  });

  /// Ingredientes escritos por el usuario (solo en modo ingredientes).
  List<String> get terminos =>
      mode == RecipeSearchMode.ingredientes ? splitUserTerms(query) : const [];

  RecipesState copyWith({
    List<Recipe>? recipes,
    bool? isLoading,
    RecipeSearchMode? mode,
    String? query,
    bool? incluirBasicos,
    bool? soloCompletas,
  }) {
    return RecipesState(
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      mode: mode ?? this.mode,
      query: query ?? this.query,
      incluirBasicos: incluirBasicos ?? this.incluirBasicos,
      soloCompletas: soloCompletas ?? this.soloCompletas,
    );
  }
}

class RecipesNotifier extends StateNotifier<RecipesState> {
  final Ref _ref;
  RecipeRepository get _repo => _ref.read(recipeRepositoryProvider);

  RecipesNotifier(this._ref) : super(const RecipesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final recipes = await _repo.getAllRecipes();
    state = state.copyWith(recipes: recipes, isLoading: false);
  }

  void setQuery(String q) => state = state.copyWith(query: q);
  void setMode(RecipeSearchMode m) => state = state.copyWith(mode: m);
  void setIncluirBasicos(bool v) => state = state.copyWith(incluirBasicos: v);
  void setSoloCompletas(bool v) => state = state.copyWith(soloCompletas: v);

  /// Quita un término de la búsqueda por ingredientes.
  void removeTermino(String termino) {
    final rest = state.terminos.where((t) => t != termino).join(', ');
    state = state.copyWith(query: rest);
  }

  Future<int> save(Recipe recipe) async {
    final id = await _repo.saveRecipe(recipe);
    _ref.invalidate(recipeDetailProvider(id));
    await load();
    return id;
  }

  Future<void> delete(int id) async {
    await _repo.deleteRecipe(id);
    await load();
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    if (recipe.id == null) return;
    await _repo.setFavorite(recipe.id!, !recipe.favorita);
    _ref.invalidate(recipeDetailProvider(recipe.id!));
    await load();
  }

  Future<int> importRecipes(List<Recipe> recipes) async {
    final saved = await _ref.read(importRecipesProvider)(recipes);
    await load();
    return saved;
  }
}

final recipesProvider = StateNotifierProvider<RecipesNotifier, RecipesState>(
  (ref) => RecipesNotifier(ref),
);

/// Recetas ordenadas por coincidencia con los ingredientes escritos.
final recipeMatchesProvider = Provider<List<RecipeMatch>>((ref) {
  final s = ref.watch(recipesProvider);
  if (s.mode != RecipeSearchMode.ingredientes) return const [];
  return ref.watch(searchRecipesByIngredientsProvider)(
    s.recipes,
    s.terminos,
    incluirBasicos: s.incluirBasicos,
    soloCompletas: s.soloCompletas,
  );
});

/// Recetas filtradas por nombre o categoría (sin tildes ni mayúsculas).
final recipesByNameProvider = Provider<List<Recipe>>((ref) {
  final s = ref.watch(recipesProvider);
  final q = normalizeText(s.query);
  if (s.mode != RecipeSearchMode.nombre || q.isEmpty) return s.recipes;
  return s.recipes
      .where(
        (r) =>
            normalizeText(r.nombre).contains(q) ||
            normalizeText(r.categoria ?? '').contains(q),
      )
      .toList();
});

final recipeDetailProvider = FutureProvider.autoDispose.family<Recipe?, int>((
  ref,
  id,
) {
  return ref.watch(recipeRepositoryProvider).getRecipe(id);
});
