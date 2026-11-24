import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/food.dart';
import '../../domain/usecases/search_foods.dart';
import '../../domain/usecases/export_database.dart';
import '../../domain/usecases/import_database.dart';
import '../../domain/usecases/record_food_usage.dart';
import '../../domain/usecases/reset_food_usage.dart';
import '../../domain/usecases/get_most_used_foods.dart';
import '../../domain/usecases/save_meal_as_food.dart';
import '../../domain/usecases/export_foods_tsv.dart';
import '../../domain/usecases/import_foods_tsv.dart';
import '../../domain/repositories/food_repository.dart';
import '../../data/repositories/food_repository_impl.dart';
import 'home_provider.dart'; // for localDataSourceProvider

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepositoryImpl(ref.watch(localDataSourceProvider));
});

final searchFoodsProvider = Provider<SearchFoods>((ref) {
  return SearchFoods(ref.watch(foodRepositoryProvider));
});

final recordFoodUsageProvider = Provider<RecordFoodUsage>((ref) {
  return RecordFoodUsage(ref.watch(foodRepositoryProvider));
});

final resetFoodUsageProvider = Provider<ResetFoodUsage>((ref) {
  return ResetFoodUsage(ref.watch(foodRepositoryProvider));
});

final getMostUsedFoodsProvider = Provider<GetMostUsedFoods>((ref) {
  return GetMostUsedFoods(ref.watch(foodRepositoryProvider));
});

final saveMealAsFoodProvider = Provider<SaveMealAsFood>((ref) {
  return SaveMealAsFood(ref.watch(foodRepositoryProvider));
});

/// Alimento por id (vínculos desde recetas y productos). null si se borró.
final foodByIdProvider = FutureProvider.autoDispose.family<Food?, int>((
  ref,
  id,
) {
  return ref.watch(foodRepositoryProvider).getFoodById(id);
});

/// Lista de alimentos más usados (frecuencia desc). autoDispose → se recarga
/// cada vez que se vuelve a entrar en SearchView, recogiendo los usos nuevos.
final mostUsedFoodsProvider = FutureProvider.autoDispose<List<Food>>((ref) {
  return ref.watch(getMostUsedFoodsProvider).call();
});

final exportDatabaseProvider = Provider<ExportDatabase>((ref) {
  return ExportDatabase(ref.watch(foodRepositoryProvider));
});

final importDatabaseProvider = Provider<ImportDatabase>((ref) {
  return ImportDatabase(ref.watch(foodRepositoryProvider));
});

final exportFoodsTsvProvider = Provider<ExportFoodsTsv>((ref) {
  return ExportFoodsTsv(ref.watch(foodRepositoryProvider));
});

final importFoodsTsvProvider = Provider<ImportFoodsTsv>((ref) {
  return ImportFoodsTsv(ref.watch(foodRepositoryProvider));
});

final searchResultsProvider = StateNotifierProvider<SearchNotifier, List<Food>>(
  (ref) {
    final searchFoods = ref.watch(searchFoodsProvider);
    return SearchNotifier(searchFoods);
  },
);

class SearchNotifier extends StateNotifier<List<Food>> {
  final SearchFoods _searchFoods;
  Timer? _debounce;

  /// Búsqueda vigente: un resultado en vuelo de una consulta anterior (o
  /// tras vaciar el campo) se descarta en vez de pisar la lista.
  int _generation = 0;

  SearchNotifier(this._searchFoods) : super([]);

  void search(String query) {
    _debounce?.cancel();
    final generation = ++_generation;

    if (query.trim().isEmpty) {
      state = [];
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final results = await _searchFoods(query);
        if (mounted && generation == _generation) state = results;
      } catch (e, st) {
        log('Error buscando alimentos', error: e, stackTrace: st);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
