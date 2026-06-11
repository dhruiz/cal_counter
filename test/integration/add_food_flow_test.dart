import 'dart:io';

import 'package:cal_counter/data/datasources/local_data_source.dart';
import 'package:cal_counter/data/models/food_model.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/meal_repository_impl.dart';
import 'package:cal_counter/domain/usecases/add_food_to_meal.dart';
import 'package:cal_counter/domain/usecases/create_meal_if_not_exists.dart';
import 'package:cal_counter/domain/usecases/search_foods.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late LocalDataSourceImpl dataSource;
  late FoodRepositoryImpl foodRepo;
  late MealRepositoryImpl mealRepo;
  late SearchFoods searchFoods;
  late AddFoodToMeal addFoodToMeal;
  late CreateMealIfNotExists createMealIfNotExists;
  final testDir = join('.', 'test_tmp_add_food_flow');

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  setUp(() async {
    Directory(testDir).createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return testDir;
        });

    dataSource = LocalDataSourceImpl();
    foodRepo = FoodRepositoryImpl(dataSource);
    mealRepo = MealRepositoryImpl(dataSource);
    searchFoods = SearchFoods(foodRepo);
    addFoodToMeal = AddFoodToMeal(mealRepo);
    createMealIfNotExists = CreateMealIfNotExists(mealRepo);

    // Initialize and clear DB
    await dataSource.initDb();
    final db = await dataSource.database;
    await db.delete('db_alimentos');
    await db.delete('comidas');
    await db.delete('items_comida');
  });

  tearDown(() async {
    await dataSource.close();
    await databaseFactory.deleteDatabase(join(testDir, 'db_ctrl_calorias.db'));
    final dir = Directory(testDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('Integration: Search, Create Meal, Add Food', () async {
    await dataSource.initDb();

    // 1. Insert test food
    final foodModel = FoodModel(
      name: 'Integration Apple',
      grasasPer100: 0.5,
      carbsPer100: 15,
      proteinsPer100: 0.4,
      kcalPer100: 60,
    );
    await dataSource.insertFood(foodModel);

    // 2. Search
    final results = await searchFoods('Integration');
    expect(results.length, 1);
    final food = results.first;
    expect(food.name, 'Integration Apple');

    // 3. Create Meal
    final date = DateTime(2023, 11, 1);
    final mealId = await createMealIfNotExists('Comida_1', date);
    expect(mealId, isPositive);

    // 4. Add Food to Meal
    await addFoodToMeal(
      mealId: mealId,
      food: food,
      quantity: 200, // 200g
    );

    // 5. Verify Item in DB
    final items = await mealRepo.getMealItems(mealId);
    expect(items.length, 1);
    final item = items.first;
    expect(item.cantidad, 200);
    expect(item.kcal, 120); // 60 * 2
    expect(item.carbohidratos, 30); // 15 * 2
  });
}
