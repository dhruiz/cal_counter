import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/meal.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
import 'package:cal_counter/domain/repositories/meal_repository.dart';
import 'package:cal_counter/domain/usecases/add_food_to_meal.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple Mock for MealRepository
class MockMealRepository implements MealRepository {
  final List<MealItem> items = [];

  @override
  Future<int> addItemToMeal(MealItem item) async {
    items.add(item);
    return items.length;
  }

  @override
  Future<int> createMeal(String name, DateTime date) async => 1;

  @override
  Future<void> deleteMeal(int id) async {}

  @override
  Future<void> deleteMealItem(int id) async {}

  @override
  Future<void> updateMealItem(int id, double newCantidad) async {}

  @override
  Future<void> updateMealName(int id, String name) async {}

  @override
  Future<String> exportMealsByDateCSV(DateTime date) async => 'path/to/csv';

  @override
  Future<List<MealItem>> getMealItems(int mealId) async => items;

  @override
  Future<List<Meal>> getMealsByDate(DateTime date) async => [];

  @override
  Future<DateTime?> getLastMealDate() async => null;

  @override
  Future<bool> hasMealItems() async => items.isNotEmpty;

  @override
  Future<void> clearMealsAndItems() async {
    items.clear();
  }
}

void main() {
  late MockMealRepository mockRepository;
  late AddFoodToMeal addFoodToMeal;

  setUp(() {
    mockRepository = MockMealRepository();
    addFoodToMeal = AddFoodToMeal(mockRepository);
  });

  test('AddFoodToMeal calculates nutrients correctly', () async {
    final food = Food(
      id: 1,
      name: 'Test Food',
      grasasPer100: 10,
      carbsPer100: 20,
      proteinsPer100: 30,
      kcalPer100: 100,
    );

    await addFoodToMeal(
      mealId: 1,
      food: food,
      quantity: 150, // 1.5 times per 100g
    );

    expect(mockRepository.items.length, 1);
    final item = mockRepository.items.first;

    expect(item.cantidad, 150);
    expect(item.grasas, 15.0); // 10 * 1.5
    expect(item.carbohidratos, 30.0); // 20 * 1.5
    expect(item.proteinas, 45.0); // 30 * 1.5
    expect(item.kcal, 150.0); // 100 * 1.5
  });
}
