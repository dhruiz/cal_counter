import 'dart:async';

import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/meal_repository_impl.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
import 'package:cal_counter/domain/repositories/meal_repository.dart';
import 'package:cal_counter/presentation/providers/home_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

/// Repositorio cuyo día falla al observarlo mientras [fail] sea true.
class _FailingRepo implements MealRepository {
  bool fail = true;

  @override
  Stream<List<MealWithItems>> watchDay(DateTime date) => fail
      ? Stream.error(StateError('BD no disponible'))
      : Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Deja correr las consultas de Drift (en memoria, pero asíncronas).
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late AppDatabase db;
  late MealRepositoryImpl repo;

  setUp(() {
    db = memoryDb();
    repo = MealRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('syncToday cambia al día actual si la app siguió abierta pasada la '
      'medianoche (antes la fecha quedaba fija)', () async {
    final mealId = await repo.createMeal('Comida_1', DateTime(2024, 3, 11));
    await repo.addItemToMeal(
      MealItem(
        mealId: mealId,
        alimento: 'Pan',
        cantidad: 50,
        grasas: 1,
        carbohidratos: 25,
        proteinas: 4,
        kcal: 130,
      ),
    );

    var now = DateTime(2024, 3, 10, 23, 50);
    final notifier = HomeNotifier(repo, now: () => now);
    addTearDown(notifier.dispose);
    await settle();
    expect(notifier.state.selectedDate, DateTime(2024, 3, 10));
    expect(notifier.state.meals, isEmpty);

    expect(await notifier.syncToday(), isFalse); // mismo día: nada

    now = DateTime(2024, 3, 11, 8, 0);
    expect(await notifier.syncToday(), isTrue);
    await settle();
    expect(notifier.state.selectedDate, DateTime(2024, 3, 11));
    expect(notifier.state.meals.single.id, mealId);
    expect(notifier.state.totalKcal, 130);
  });

  test('un error de carga no deja el indicador girando para siempre', () async {
    final failing = _FailingRepo();
    final notifier = HomeNotifier(failing);
    addTearDown(notifier.dispose);
    await settle();
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.error, isNotNull);

    failing.fail = false;
    await notifier.refresh(); // "Reintentar"
    await settle();
    expect(notifier.state.error, isNull);
    expect(notifier.state.isLoading, isFalse);
  });

  test('deleteMeals borra todas las comidas del día y el estado se '
      'actualiza solo', () async {
    final today = DateTime(2024, 5, 1);
    final a = await repo.createMeal('Comida_1', today);
    final b = await repo.createMeal('Comida_2', today);
    final notifier = HomeNotifier(repo, now: () => today);
    addTearDown(notifier.dispose);
    await settle();
    expect(notifier.state.meals, hasLength(2));

    await notifier.deleteMeals([a, b]);
    await settle();
    expect(notifier.state.meals, isEmpty);
    expect(await repo.getMealsByDate(today), isEmpty);
  });
}
