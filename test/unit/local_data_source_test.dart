import 'dart:io';

import 'package:cal_counter/data/datasources/local_data_source.dart';
import 'package:cal_counter/data/models/food_model.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:path/path.dart';

void main() {
  late LocalDataSourceImpl dataSource;
  final testDir = join('.', 'test_tmp_local_data_source');

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    Directory(testDir).createSync(recursive: true);
    dataSource = LocalDataSourceImpl();
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return testDir;
        });
  });

  tearDown(() async {
    await dataSource.close();
    await databaseFactory.deleteDatabase(join(testDir, 'db_ctrl_calorias.db'));
    final dir = Directory(testDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('should insert and retrieve food', () async {
    await dataSource.initDb();

    const uniqueName = 'ZZZ_TEST_FIXTURE_FOOD_UNIQUE_001';
    final food = FoodModel(
      name: uniqueName,
      grasasPer100: 0.2,
      carbsPer100: 14,
      proteinsPer100: 0.3,
      kcalPer100: 52,
    );

    final id = await dataSource.insertFood(food);
    expect(id, isPositive);

    final results = await dataSource.searchFoods(uniqueName);
    expect(results.length, 1);
    expect(results.first.name, uniqueName);
  });

  test('should create meal and add items', () async {
    await dataSource.initDb();

    final date = DateTime(2023, 10, 25);
    final mealId = await dataSource.createMeal('Breakfast', date);
    expect(mealId, isPositive);

    final meals = await dataSource.getMealsByDate(date);
    expect(meals.length, 1);
    expect(meals.first['nombre'], 'Breakfast');

    final item = MealItem(
      mealId: mealId,
      alimento: 'Test Apple',
      cantidad: 100,
      grasas: 0.2,
      carbohidratos: 14,
      proteinas: 0.3,
      kcal: 52,
    );

    final itemId = await dataSource.addItemToMeal(item);
    expect(itemId, isPositive);

    final items = await dataSource.getMealItems(mealId);
    expect(items.length, 1);
    expect(items.first['alimento'], 'Test Apple');
  });

  test('most used foods are ranked by usage and exclude unused', () async {
    await dataSource.initDb();

    final apple = FoodModel(
      name: 'USAGE_APPLE',
      grasasPer100: 0.2,
      carbsPer100: 14,
      proteinsPer100: 0.3,
      kcalPer100: 52,
    );
    final rice = FoodModel(
      name: 'USAGE_RICE',
      grasasPer100: 0.9,
      carbsPer100: 28,
      proteinsPer100: 2.7,
      kcalPer100: 130,
    );
    // Never used → must be excluded from the most-used list.
    final unused = FoodModel(
      name: 'USAGE_UNUSED',
      grasasPer100: 1,
      carbsPer100: 1,
      proteinsPer100: 1,
      kcalPer100: 1,
    );

    final appleId = await dataSource.insertFood(apple);
    final riceId = await dataSource.insertFood(rice);
    await dataSource.insertFood(unused);

    // Rice used twice, apple once → rice ranks first.
    await dataSource.incrementFoodUsage(riceId);
    await dataSource.incrementFoodUsage(riceId);
    await dataSource.incrementFoodUsage(appleId);

    final mostUsed = await dataSource.getMostUsedFoods();
    final names = mostUsed.map((f) => f.name).toList();

    expect(names, ['USAGE_RICE', 'USAGE_APPLE']);
    expect(names, isNot(contains('USAGE_UNUSED')));
  });

  test('resetFoodUsage removes a food from the most-used list', () async {
    await dataSource.initDb();

    final apple = FoodModel(
      name: 'RESET_APPLE',
      grasasPer100: 0.2,
      carbsPer100: 14,
      proteinsPer100: 0.3,
      kcalPer100: 52,
    );
    final rice = FoodModel(
      name: 'RESET_RICE',
      grasasPer100: 0.9,
      carbsPer100: 28,
      proteinsPer100: 2.7,
      kcalPer100: 130,
    );

    final appleId = await dataSource.insertFood(apple);
    final riceId = await dataSource.insertFood(rice);

    await dataSource.incrementFoodUsage(appleId);
    await dataSource.incrementFoodUsage(riceId);

    // Reset apple → desaparece de "más usados"; el alimento sigue existiendo.
    await dataSource.resetFoodUsage(appleId);

    final mostUsed = await dataSource.getMostUsedFoods();
    final names = mostUsed.map((f) => f.name).toList();
    expect(names, isNot(contains('RESET_APPLE')));
    expect(names, contains('RESET_RICE'));

    // El alimento reseteado sigue siendo buscable en el catálogo.
    final found = await dataSource.searchFoods('RESET_APPLE');
    expect(found.map((f) => f.name), contains('RESET_APPLE'));
  });

  test(
    'deleteMeal borra también sus items (sin depender de CASCADE)',
    () async {
      await dataSource.initDb();
      final date = DateTime(2023, 10, 25);
      final keepId = await dataSource.createMeal('Comida_1', date);
      final deleteId = await dataSource.createMeal('Comida_2', date);
      MealItem item(int mealId) => MealItem(
        mealId: mealId,
        alimento: 'X',
        cantidad: 100,
        grasas: 1,
        carbohidratos: 1,
        proteinas: 1,
        kcal: 10,
      );
      await dataSource.addItemToMeal(item(keepId));
      await dataSource.addItemToMeal(item(deleteId));
      await dataSource.addItemToMeal(item(deleteId));

      await dataSource.deleteMeal(deleteId);

      final db = await dataSource.database;
      final rows = await db.query('items_comida');
      expect(rows.map((r) => r['comida_id']), [keepId]);

      await dataSource.deleteMeal(keepId);
      expect(await db.query('items_comida'), isEmpty);
      expect(await dataSource.hasMealItems(), isFalse);
    },
  );

  test(
    'items huérfanos: hasMealItems los ignora y se limpian al abrir',
    () async {
      await dataSource.initDb();
      final db = await dataSource.database;
      // Simula un huérfano dejado por versiones anteriores de deleteMeal.
      await db.insert('items_comida', {
        'comida_id': 999999,
        'cantidad': 100,
        'alimento': 'Huérfano',
        'grasas': 1,
        'carbohidratos': 1,
        'proteinas': 1,
        'kCal': 10,
      });
      expect(await dataSource.hasMealItems(), isFalse);

      await dataSource.close();
      await dataSource.initDb();
      final reopened = await dataSource.database;
      expect(await reopened.query('items_comida'), isEmpty);
    },
  );
}
