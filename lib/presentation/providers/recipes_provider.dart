import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_match.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/services/nutrition_calculator.dart';
import '../../domain/services/recipe_ideas.dart';
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

final syncRecipeFoodsProvider = Provider<SyncRecipeFoods>(
  (ref) => SyncRecipeFoods(
    ref.watch(recipeRepositoryProvider),
    ref.watch(foodRepositoryProvider),
    ref.watch(transactionRunnerProvider),
  ),
);

final saveRecipeProvider = Provider<SaveRecipe>(
  (ref) => SaveRecipe(
    ref.watch(recipeRepositoryProvider),
    ref.watch(syncRecipeFoodsProvider),
    ref.watch(transactionRunnerProvider),
  ),
);

final setRecipeFinalWeightProvider = Provider<SetRecipeFinalWeight>(
  (ref) => SetRecipeFinalWeight(
    ref.watch(recipeRepositoryProvider),
    ref.watch(syncRecipeFoodsProvider),
  ),
);

/// Vigilante (escuchado en `MainShell`): cada vez que cambian recetas,
/// ingredientes, alimentos o porciones pone al día los alimentos de las
/// recetas. Cubre cualquier camino: completar la tabla de un ingrediente,
/// añadir el peso de una porción, importar o restaurar. Solo escribe lo que
/// cambia, así que la escritura que provoca no vuelve a escribir nada.
final recipeFoodSyncProvider = Provider<void>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  final sync = ref.watch(syncRecipeFoodsProvider);
  var enCurso = false;
  var pendiente = false;
  var activo = true;
  Future<void> run() async {
    if (enCurso) {
      pendiente = true;
      return;
    }
    enCurso = true;
    try {
      do {
        pendiente = false;
        if (!activo) return;
        await sync();
      } while (pendiente);
    } catch (e, st) {
      log(
        'Error al poner al día los alimentos de las recetas',
        error: e,
        stackTrace: st,
      );
    } finally {
      enCurso = false;
    }
  }

  final sub = repo.watchNutritionInputs().listen((_) => run());
  ref.onDispose(() {
    activo = false;
    sub.cancel();
  });
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

  /// Orden de la lista (modo por nombre).
  final RecipeOrder orden;

  /// Solo las recetas de esta categoría (null = todas).
  final String? categoria;

  const RecipesState({
    this.recipes = const [],
    this.isLoading = false,
    this.mode = RecipeSearchMode.ingredientes,
    this.query = '',
    this.incluirBasicos = true,
    this.soloCompletas = false,
    this.orden = RecipeOrder.favoritas,
    this.categoria,
  });

  /// Recetas de la categoría elegida (todas si no hay ninguna).
  List<Recipe> get deLaCategoria {
    final c = categoria;
    if (c == null) return recipes;
    return [
      for (final r in recipes)
        if (isInCategory(r, c)) r,
    ];
  }

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
    RecipeOrder? orden,
    String? categoria,
    bool clearCategoria = false,
  }) {
    return RecipesState(
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      mode: mode ?? this.mode,
      query: query ?? this.query,
      incluirBasicos: incluirBasicos ?? this.incluirBasicos,
      soloCompletas: soloCompletas ?? this.soloCompletas,
      orden: orden ?? this.orden,
      categoria: clearCategoria ? null : (categoria ?? this.categoria),
    );
  }
}

/// Recetas (observa la base de datos) y estado de la búsqueda.
class RecipesNotifier extends StateNotifier<RecipesState> {
  final Ref _ref;
  StreamSubscription<List<Recipe>>? _sub;

  RecipesNotifier(this._ref) : super(const RecipesState(isLoading: true)) {
    _sub = _repo.watchAll().listen(
      (recipes) {
        if (mounted) {
          state = state.copyWith(recipes: recipes, isLoading: false);
        }
      },
      onError: (Object e, StackTrace st) {
        // Sin esto el indicador de carga quedaba girando para siempre.
        log('Error cargando recetas', error: e, stackTrace: st);
        if (mounted) state = state.copyWith(isLoading: false);
      },
    );
  }

  RecipeRepository get _repo => _ref.read(recipeRepositoryProvider);

  void setQuery(String q) => state = state.copyWith(query: q);
  void setMode(RecipeSearchMode m) => state = state.copyWith(mode: m);
  void setIncluirBasicos(bool v) => state = state.copyWith(incluirBasicos: v);
  void setSoloCompletas(bool v) => state = state.copyWith(soloCompletas: v);
  void setOrden(RecipeOrder o) => state = state.copyWith(orden: o);

  /// Filtra por categoría (null = todas).
  void setCategoria(String? c) => state = c == null
      ? state.copyWith(clearCategoria: true)
      : state.copyWith(categoria: c);

  /// Quita un término de la búsqueda por ingredientes.
  void removeTermino(String termino) {
    final rest = state.terminos.where((t) => t != termino).join(', ');
    state = state.copyWith(query: rest);
  }

  /// Guarda la receta (nombre único) y pone al día su alimento.
  Future<int> save(Recipe recipe) => _ref.read(saveRecipeProvider)(recipe);

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

/// Recetas filtradas por nombre o categoría (sin tildes ni mayúsculas), de
/// la categoría elegida y en el orden elegido.
final recipesByNameProvider = Provider<List<Recipe>>((ref) {
  final s = ref.watch(recipesProvider);
  if (s.mode != RecipeSearchMode.nombre) return s.recipes;
  final q = normalizeText(s.query);
  final base = s.deLaCategoria;
  final filtradas = q.isEmpty
      ? base
      : base
            .where(
              (r) =>
                  normalizeText(r.nombre).contains(q) ||
                  normalizeText(r.categoria ?? '').contains(q),
            )
            .toList();
  return sortRecipes(filtradas, s.orden);
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

  /// Alimento "preparado" de la receta (el que se registra en el contador).
  final Food? alimentoReceta;

  /// Otro alimento que ya tiene el nombre que le tocaría al de la receta,
  /// por lo que no se pudo crear.
  final Food? conflicto;

  const RecipeAnalysis({
    required this.receta,
    required this.alimentos,
    required this.porciones,
    required this.nutricion,
    this.alimentoReceta,
    this.conflicto,
  });
}

final recipeAnalysisProvider = StreamProvider.autoDispose
    .family<RecipeAnalysis?, int>((ref, id) {
      final recipe = ref.watch(recipeDetailProvider(id)).valueOrNull;
      if (recipe == null) return Stream.value(null);
      final propio = recipe.alimentoId;
      final ids = {
        for (final i in recipe.ingredientes)
          if (i.alimentoId != null) i.alimentoId!,
        ?propio,
      };
      final foods = ref.watch(foodRepositoryProvider);
      return foods.watchFoodsWithPortions(ids).asyncMap((d) async {
        final nutricion = calculateRecipeNutrition(
          recipe,
          alimentos: d.alimentos,
          porciones: d.porciones,
          excluidos: {?propio},
        );
        final alimentoReceta = propio == null ? null : d.alimentos[propio];
        Food? conflicto;
        if (alimentoReceta == null && nutricion.tieneDatos) {
          final f = await foods.findByNameAndBrand(recipe.nombre, kMarcaReceta);
          if (f != null && f.tipo != FoodType.preparado) conflicto = f;
        }
        return RecipeAnalysis(
          receta: recipe,
          alimentos: d.alimentos,
          porciones: d.porciones,
          nutricion: nutricion,
          alimentoReceta: alimentoReceta,
          conflicto: conflicto,
        );
      });
    });

/// Escala con la que se ve una receta (×2 = el doble de todo). Se usa en el
/// detalle, el modo cocina, la lista de compra y el peso final.
final recipeScaleProvider = StateProvider.autoDispose.family<double, int>(
  (ref, id) => 1,
);

/// Receta cuyo alimento "preparado" es este (para avisar en el contador de
/// por qué su tabla es aproximada).
final recipeByFoodProvider = StreamProvider.autoDispose.family<Recipe?, int>(
  (ref, alimentoId) =>
      ref.watch(recipeRepositoryProvider).watchByFood(alimentoId),
);
