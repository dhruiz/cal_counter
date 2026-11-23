import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_match.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/services/nutrition_calculator.dart';
import '../../domain/usecases/import_recipes.dart';
import '../../domain/usecases/recipe_food.dart';
import '../../domain/usecases/search_recipes_by_ingredients.dart';
import 'core_providers.dart';

export 'core_providers.dart';

final searchRecipesByIngredientsProvider = Provider<SearchRecipesByIngredients>(
  (ref) => SearchRecipesByIngredients(),
);

final importRecipesProvider = Provider<ImportRecipes>(
  (ref) => ImportRecipes(ref.watch(recipeRepositoryProvider)),
);

final suggestIngredientLinksProvider = Provider<SuggestIngredientLinks>(
  (ref) => SuggestIngredientLinks(ref.watch(foodRepositoryProvider)),
);

final saveRecipeAsFoodProvider = Provider<SaveRecipeAsFood>(
  (ref) => SaveRecipeAsFood(
    ref.watch(foodRepositoryProvider),
    ref.watch(recipeRepositoryProvider),
    ref.watch(transactionRunnerProvider),
  ),
);

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

/// Recetas (observa la base de datos) y estado de la búsqueda.
class RecipesNotifier extends StateNotifier<RecipesState> {
  final Ref _ref;
  StreamSubscription<List<Recipe>>? _sub;

  RecipesNotifier(this._ref) : super(const RecipesState(isLoading: true)) {
    _sub = _repo.watchAll().listen((recipes) {
      if (mounted) {
        state = state.copyWith(recipes: recipes, isLoading: false);
      }
    });
  }

  RecipeRepository get _repo => _ref.read(recipeRepositoryProvider);

  void setQuery(String q) => state = state.copyWith(query: q);
  void setMode(RecipeSearchMode m) => state = state.copyWith(mode: m);
  void setIncluirBasicos(bool v) => state = state.copyWith(incluirBasicos: v);
  void setSoloCompletas(bool v) => state = state.copyWith(soloCompletas: v);

  /// Quita un término de la búsqueda por ingredientes.
  void removeTermino(String termino) {
    final rest = state.terminos.where((t) => t != termino).join(', ');
    state = state.copyWith(query: rest);
  }

  Future<int> save(Recipe recipe) => _repo.save(recipe);

  Future<void> delete(int id) => _repo.delete(id);

  Future<void> toggleFavorite(Recipe recipe) async {
    if (recipe.id == null) return;
    await _repo.setFavorite(recipe.id!, !recipe.favorita);
  }

  Future<int> importRecipes(List<Recipe> recipes) =>
      _ref.read(importRecipesProvider)(recipes);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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

final recipeDetailProvider = StreamProvider.autoDispose.family<Recipe?, int>(
  (ref, id) => ref.watch(recipeRepositoryProvider).watch(id),
);

/// Receta + alimentos de sus ingredientes + nutrición calculada. Se recalcula
/// solo al editar la receta o completar cualquiera de sus alimentos.
class RecipeAnalysis {
  final Recipe receta;
  final Map<int, Food> alimentos;
  final Map<int, List<FoodPortion>> porciones;
  final RecipeNutrition nutricion;

  const RecipeAnalysis({
    required this.receta,
    required this.alimentos,
    required this.porciones,
    required this.nutricion,
  });

  /// Comida virtual con la nutrición por 100 g, para registrar una porción
  /// en el contador.
  Food? get comoAlimento {
    final p100 = nutricion.por100;
    if (p100 == null || !nutricion.completa) return null;
    return Food(
      id: receta.alimentoId,
      nombre: receta.nombre,
      tipo: FoodType.preparado,
      nutricion: p100,
      origenNutricion: NutritionSource.calculado,
    );
  }
}

final recipeAnalysisProvider = StreamProvider.autoDispose
    .family<RecipeAnalysis?, int>((ref, id) {
      final recipe = ref.watch(recipeDetailProvider(id)).valueOrNull;
      if (recipe == null) return Stream.value(null);
      final ids = {
        for (final i in recipe.ingredientes)
          if (i.alimentoId != null) i.alimentoId!,
      };
      return ref
          .watch(foodRepositoryProvider)
          .watchFoodsWithPortions(ids)
          .map(
            (d) => RecipeAnalysis(
              receta: recipe,
              alimentos: d.alimentos,
              porciones: d.porciones,
              nutricion: calculateRecipeNutrition(
                recipe,
                alimentos: d.alimentos,
                porciones: d.porciones,
              ),
            ),
          );
    });
