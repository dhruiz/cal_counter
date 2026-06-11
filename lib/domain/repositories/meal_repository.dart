import '../entities/meal.dart';
import '../entities/meal_item.dart';

abstract class MealRepository {
  Future<int> createMeal(String name, DateTime date);
  Future<List<Meal>> getMealsByDate(DateTime date);
  Future<DateTime?> getLastMealDate();
  Future<int> addItemToMeal(MealItem item);
  Future<List<MealItem>> getMealItems(int mealId);
  Future<String> exportMealsByDateCSV(DateTime date);
  Future<void> deleteMeal(int id);
  Future<void> deleteMealItem(int id);
  Future<void> updateMealItem(int id, double newCantidad);
  Future<bool> hasMealItems();
  Future<void> clearMealsAndItems();
}
