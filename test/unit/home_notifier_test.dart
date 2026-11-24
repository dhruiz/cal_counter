import 'package:cal_counter/domain/entities/meal.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
import 'package:cal_counter/domain/repositories/meal_repository.dart';
import 'package:cal_counter/presentation/providers/home_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio con comidas por fecha (`YYYY-MM-DD`) y fallos opcionales.
class _Repo implements MealRepository {
  final Map<String, List<Meal>> byDate = {};
  final Map<int, List<MealItem>> items = {};
  bool fail = false;
  final List<DateTime> requested = [];

  static String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<List<Meal>> getMealsByDate(DateTime date) async {
    requested.add(date);
    if (fail) throw StateError('BD no disponible');
    return byDate[key(date)] ?? const [];
  }

  @override
  Future<List<MealItem>> getMealItems(int mealId) async =>
      items[mealId] ?? const [];

  @override
  Future<void> deleteMeal(int id) async {
    for (final list in byDate.values) {
      list.removeWhere((m) => m.id == id);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('syncToday cambia al día actual si la app siguió abierta pasada la '
      'medianoche (antes la fecha quedaba fija)', () async {
    final repo = _Repo();
    var now = DateTime(2024, 3, 10, 23, 50);
    repo.byDate['2024-03-11'] = [
      Meal(id: 7, name: 'Comida_1', date: DateTime(2024, 3, 11)),
    ];
    repo.items[7] = const [
      MealItem(
        id: 1,
        mealId: 7,
        alimento: 'Pan',
        cantidad: 50,
        grasas: 1,
        carbohidratos: 25,
        proteinas: 4,
        kcal: 130,
      ),
    ];
    final notifier = HomeNotifier(repo, now: () => now);
    await settle();
    expect(notifier.state.selectedDate, DateTime(2024, 3, 10));
    expect(notifier.state.meals, isEmpty);

    expect(await notifier.syncToday(), isFalse); // mismo día: nada

    now = DateTime(2024, 3, 11, 8, 0);
    expect(await notifier.syncToday(), isTrue);
    expect(notifier.state.selectedDate, DateTime(2024, 3, 11));
    expect(notifier.state.meals.single.id, 7);
    expect(notifier.state.totalKcal, 130);
  });

  test('un error de carga no deja el indicador girando para siempre', () async {
    final repo = _Repo()..fail = true;
    final notifier = HomeNotifier(repo);
    await settle();
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, isNotNull);

    repo.fail = false;
    await notifier.refresh();
    expect(notifier.state.error, isNull);
  });

  test('deleteMeals borra varias comidas con una sola recarga', () async {
    final repo = _Repo();
    final today = DateTime(2024, 5, 1);
    repo.byDate['2024-05-01'] = [
      Meal(id: 1, name: 'Comida_1', date: today),
      Meal(id: 2, name: 'Comida_2', date: today),
    ];
    final notifier = HomeNotifier(repo, now: () => today);
    await settle();
    final before = repo.requested.length;
    await notifier.deleteMeals([1, 2]);
    expect(repo.requested.length - before, 1);
    expect(notifier.state.meals, isEmpty);
  });
}
