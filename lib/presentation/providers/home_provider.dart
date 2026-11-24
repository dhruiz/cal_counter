import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_item.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/services/dates.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../data/datasources/local_data_source.dart';
import '../../domain/usecases/check_new_day_on_startup.dart';
import '../../domain/usecases/export_day_csv.dart';

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

  /// Mensaje si la última carga falló (null si fue bien).
  final String? error;

  HomeState({
    required this.selectedDate,
    this.meals = const [],
    this.mealItems = const {},
    this.totalKcal = 0,
    this.totalProteins = 0,
    this.totalFats = 0,
    this.totalCarbs = 0,
    this.isLoading = false,
    this.error,
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
    String? error,
    bool clearError = false,
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
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Notifier
class HomeNotifier extends StateNotifier<HomeState> {
  final MealRepository repository;

  /// Reloj inyectable (tests de cambio de día).
  final DateTime Function() _now;

  bool _loadedOnce = false;

  /// Número de la última carga lanzada: una carga más antigua que termine
  /// después no pisa el estado (p. ej. tras cambiar de día).
  int _loadSeq = 0;

  HomeNotifier(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(HomeState(selectedDate: dateOnly((now ?? DateTime.now)()))) {
    loadDailyData();
  }

  Future<void> loadDailyData() async {
    final seq = ++_loadSeq;
    // El indicador a pantalla completa solo en la primera carga: en cada
    // vuelta de otra pantalla se refresca sin parpadeo.
    if (!_loadedOnce) state = state.copyWith(isLoading: true);
    final date = state.selectedDate;
    try {
      final meals = await repository.getMealsByDate(date);

      final itemsMap = <int, List<MealItem>>{};
      double k = 0, p = 0, f = 0, c = 0;

      for (final meal in meals) {
        final items = await repository.getMealItems(meal.id!);
        itemsMap[meal.id!] = items;
        for (final item in items) {
          k += item.kcal;
          p += item.proteinas;
          f += item.grasas;
          c += item.carbohidratos;
        }
      }

      if (!mounted || seq != _loadSeq) return;
      _loadedOnce = true;
      state = state.copyWith(
        meals: meals,
        mealItems: itemsMap,
        totalKcal: k,
        totalProteins: p,
        totalFats: f,
        totalCarbs: c,
        isLoading: false,
        clearError: true,
      );
    } catch (e, st) {
      // Sin esto el indicador de carga quedaba girando para siempre.
      log('Error cargando el día', error: e, stackTrace: st);
      if (!mounted || seq != _loadSeq) return;
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudieron cargar las comidas: $e',
      );
    }
  }

  /// Si cambió el día desde la última carga (la app siguió abierta pasada la
  /// medianoche), pasa al día actual y recarga. Devuelve true si cambió.
  ///
  /// Antes `selectedDate` se fijaba al crear el notifier y no cambiaba nunca:
  /// lo registrado al día siguiente se guardaba con la fecha anterior.
  Future<bool> syncToday() async {
    final today = dateOnly(_now());
    if (dateOnly(state.selectedDate) == today) return false;
    state = state.copyWith(selectedDate: today);
    await loadDailyData();
    return true;
  }

  Future<void> deleteMeal(int id) async {
    await repository.deleteMeal(id);
    await loadDailyData();
  }

  /// Borra varias comidas con una sola recarga (antes, una por comida).
  Future<void> deleteMeals(Iterable<int> ids) async {
    for (final id in ids) {
      await repository.deleteMeal(id);
    }
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

  Future<void> renameMeal(int id, String name) async {
    await repository.updateMealName(id, name);
    await loadDailyData();
  }

  Future<void> refresh() async {
    await loadDailyData();
  }
}
