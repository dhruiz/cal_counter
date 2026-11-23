import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_item.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/usecases/check_new_day_on_startup.dart';
import '../../domain/usecases/export_day_csv.dart';
import 'core_providers.dart';

export 'core_providers.dart';

final checkNewDayOnStartupProvider = Provider<CheckNewDayOnStartup>(
  (ref) => CheckNewDayOnStartup(ref.watch(mealRepositoryProvider)),
);

final exportDayToCsvProvider = Provider<ExportDayToCsv>(
  (ref) => ExportDayToCsv(ref.watch(mealRepositoryProvider)),
);

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(ref.watch(mealRepositoryProvider)),
);

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

/// Día actual del contador. Observa la base de datos: cualquier cambio en las
/// comidas (desde cualquier pantalla) se refleja solo, sin refrescos manuales.
class HomeNotifier extends StateNotifier<HomeState> {
  final MealRepository repository;
  StreamSubscription<List<MealWithItems>>? _sub;

  HomeNotifier(this.repository)
    : super(HomeState(selectedDate: DateTime.now(), isLoading: true)) {
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    _sub = repository.watchDay(state.selectedDate).listen(_apply);
  }

  void _apply(List<MealWithItems> day) {
    if (!mounted) return;
    final items = <int, List<MealItem>>{};
    double k = 0, p = 0, f = 0, c = 0;
    for (final m in day) {
      items[m.meal.id!] = m.items;
      for (final i in m.items) {
        k += i.kcal;
        p += i.proteinas;
        f += i.grasas;
        c += i.carbohidratos;
      }
    }
    state = state.copyWith(
      meals: [for (final m in day) m.meal],
      mealItems: items,
      totalKcal: k,
      totalProteins: p,
      totalFats: f,
      totalCarbs: c,
      isLoading: false,
    );
  }

  /// Si cambió el día (la app quedó abierta pasada la medianoche), vuelve a
  /// observar el día de hoy.
  Future<void> refresh() async {
    final now = DateTime.now();
    final d = state.selectedDate;
    if (now.year != d.year || now.month != d.month || now.day != d.day) {
      state = state.copyWith(selectedDate: now);
      _listen();
    }
  }

  Future<void> deleteMeal(int id) => repository.deleteMeal(id);

  Future<void> deleteMealItem(int id) => repository.deleteMealItem(id);

  Future<void> updateMealItemQuantity(int id, double newCantidad) =>
      repository.updateMealItem(id, newCantidad);

  Future<void> renameMeal(int id, String name) =>
      repository.updateMealName(id, name);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
