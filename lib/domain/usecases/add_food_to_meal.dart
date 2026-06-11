import '../entities/food.dart';
import '../entities/meal_item.dart';
import '../repositories/meal_repository.dart';

class AddFoodToMeal {
  final MealRepository repository;

  AddFoodToMeal(this.repository);

  Future<int> call({
    required int mealId,
    required Food food,
    required double quantity, // in grams
  }) async {
    final factor = quantity / 100.0;

    final item = MealItem(
      mealId: mealId,
      alimento: food.name,
      cantidad: quantity,
      grasas: food.grasasPer100 * factor,
      carbohidratos: food.carbsPer100 * factor,
      proteinas: food.proteinsPer100 * factor,
      kcal: food.kcalPer100 * factor,
    );

    return await repository.addItemToMeal(item);
  }
}
