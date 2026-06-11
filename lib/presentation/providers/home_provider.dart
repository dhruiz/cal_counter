import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_item.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../data/datasources/local_data_source.dart';
import '../../domain/usecases/check_new_day_on_startup.dart';
import '../../domain/usecases/export_day_csv.dart';
import '../../domain/usecases/export_foods_tsv.dart';
import '../../domain/usecases/import_foods_tsv.dart';

// Providers
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSourceImpl();
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepositoryImpl(ref.watch(localDataSourceProvider));
});

final checkNewDayOnStartupProvider = Provider<CheckNewDayOnStartup>((ref) {
  return CheckNewDayOnStartup(ref.watch(mealRepositoryProvider));
});

final exportDayToCsvProvider = Provider<ExportDayToCsv>((ref) {
  return ExportDayToCsv(ref.watch(mealRepositoryProvider));
});

final exportFoodsTsvProvider = Provider<ExportFoodsTsv>((ref) {
  return ExportFoodsTsv(ref.watch(localDataSourceProvider));
});

final importFoodsTsvProvider = Provider<ImportFoodsTsv>((ref) {
  return ImportFoodsTsv(ref.watch(localDataSourceProvider));
});

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(mealRepositoryProvider);
  return HomeNotifier(repository);
});

// State
class HomeState {
  final DateTime selectedDate;
  final List<Meal> meals;
  final Map<int, List<MealItem>> mealItems;
  final double totalKcal;
  final double totalProteins;
  final double totalFats;
  final double totalCarbs;
  final bool isLoading;

  HomeState({
    required this.selectedDate,
    this.meals = const [],
    this.mealItems = const {},
    this.totalKcal = 0,
    this.totalProteins = 0,
    this.totalFats = 0,
    this.totalCarbs = 0,
    this.isLoading = false,
  });

  HomeState copyWith({
    DateTime? selectedDate,
    List<Meal>? meals,
    Map<int, List<MealItem>>? mealItems,
    double? totalKcal,
    double? totalProteins,
    double? totalFats,
    double? totalCarbs,
    bool? isLoading,
  }) {
    return HomeState(
      selectedDate: selectedDate ?? this.selectedDate,
      meals: meals ?? this.meals,
      mealItems: mealItems ?? this.mealItems,
      totalKcal: totalKcal ?? this.totalKcal,
      totalProteins: totalProteins ?? this.totalProteins,
      totalFats: totalFats ?? this.totalFats,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Notifier
class HomeNotifier extends StateNotifier<HomeState> {
  final MealRepository repository;

  HomeNotifier(this.repository)
    : super(HomeState(selectedDate: DateTime.now())) {
    loadDailyData();
  }

  Future<void> loadDailyData() async {
    state = state.copyWith(isLoading: true);
    final date = state.selectedDate;
    final meals = await repository.getMealsByDate(date);

    Map<int, List<MealItem>> itemsMap = {};
    double k = 0, p = 0, f = 0, c = 0;

    for (var meal in meals) {
      final items = await repository.getMealItems(meal.id!);
      itemsMap[meal.id!] = items;
      for (var item in items) {
        k += item.kcal;
        p += item.proteinas;
        f += item.grasas;
        c += item.carbohidratos;
      }
    }

    state = state.copyWith(
      meals: meals,
      mealItems: itemsMap,
      totalKcal: k,
      totalProteins: p,
      totalFats: f,
      totalCarbs: c,
      isLoading: false,
    );
  }

  Future<void> deleteMeal(int id) async {
    await repository.deleteMeal(id);
    await loadDailyData();
  }

  Future<void> deleteMealItem(int id) async {
    await repository.deleteMealItem(id);
    await loadDailyData();
  }

  Future<void> updateMealItemQuantity(int id, double newCantidad) async {
    await repository.updateMealItem(id, newCantidad);
    await loadDailyData();
  }

  Future<void> refresh() async {
    await loadDailyData();
  }
}
