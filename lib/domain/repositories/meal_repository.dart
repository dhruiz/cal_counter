import '../entities/meal.dart';
import '../entities/meal_item.dart';

/// Comida con sus alimentos.
class MealWithItems {
  final Meal meal;
  final List<MealItem> items;

  const MealWithItems(this.meal, this.items);
}

abstract class MealRepository {
  Future<int> createMeal(String name, DateTime date);
  Future<List<Meal>> getMealsByDate(DateTime date);

  /// Comidas del día con sus alimentos; emite de nuevo en cada cambio.
  Stream<List<MealWithItems>> watchDay(DateTime date);
  Future<DateTime?> getLastMealDate();
  Future<int> addItemToMeal(MealItem item);
  Future<List<MealItem>> getMealItems(int mealId);
  Future<String> exportMealsByDateCSV(DateTime date);
  Future<void> deleteMeal(int id);
  Future<void> deleteMealItem(int id);

  /// Cambia la cantidad escalando por proporción los valores guardados (no
  /// se vuelve a consultar el alimento).
  Future<void> updateMealItem(int id, double newCantidad);
  Future<void> updateMealName(int id, String name);
  Future<bool> hasMealItems();
  Future<void> clearMealsAndItems();
}
