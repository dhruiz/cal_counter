import '../entities/meal_item.dart';
import '../repositories/food_repository.dart';
import '../../data/models/food_model.dart';

/// Guarda una comida completa como un alimento en `db_alimentos`.
///
/// Toma los valores nutricionales totales de los items (ya escalados a la
/// cantidad consumida) y el peso total en gramos, y los proratea a "por 100g":
/// `valorPor100 = total / gramosTotales * 100`.
///
/// `insertFood` usa `ConflictAlgorithm.replace`, así que un alimento con el
/// mismo nombre (columna UNIQUE) se sobrescribe. La confirmación de
/// sobrescritura se decide en la UI antes de llamar aquí.
class SaveMealAsFood {
  final FoodRepository repository;

  SaveMealAsFood(this.repository);

  Future<int> call({
    required String name,
    required List<MealItem> items,
  }) async {
    double totalGrams = 0;
    double kcal = 0;
    double fats = 0;
    double carbs = 0;
    double proteins = 0;

    for (final item in items) {
      totalGrams += item.cantidad;
      kcal += item.kcal;
      fats += item.grasas;
      carbs += item.carbohidratos;
      proteins += item.proteinas;
    }

    if (totalGrams <= 0) {
      throw Exception('La comida no tiene ingredientes con peso.');
    }

    final factor = 100.0 / totalGrams;
    final food = FoodModel(
      name: name,
      kcalPer100: kcal * factor,
      grasasPer100: fats * factor,
      carbsPer100: carbs * factor,
      proteinsPer100: proteins * factor,
    );

    return await repository.insertFood(food);
  }
}
