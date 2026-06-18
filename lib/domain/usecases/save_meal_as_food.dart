import '../entities/meal_item.dart';
import '../repositories/food_repository.dart';
import '../../data/models/food_model.dart';

/// Guarda una comida completa como un alimento en `db_alimentos`.
///
/// Toma los valores nutricionales totales de los items (ya escalados a la
/// cantidad consumida) y el peso total en gramos, y los proratea a "por 100g":
/// `valorPor100 = total / gramosTotales * 100`. Los valores resultantes se
/// redondean a 2 decimales.
///
/// `totalGrams` permite indicar el peso real de la preparación (p. ej. el peso
/// ya cocinado, que difiere de la suma de los ingredientes crudos). Si es
/// `null` se usa la suma de los pesos de los items.
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
    double? totalGrams,
  }) async {
    double summedGrams = 0;
    double kcal = 0;
    double fats = 0;
    double carbs = 0;
    double proteins = 0;

    for (final item in items) {
      summedGrams += item.cantidad;
      kcal += item.kcal;
      fats += item.grasas;
      carbs += item.carbohidratos;
      proteins += item.proteinas;
    }

    final grams = totalGrams ?? summedGrams;
    if (grams <= 0) {
      throw Exception('La comida no tiene ingredientes con peso.');
    }

    final factor = 100.0 / grams;
    final food = FoodModel(
      name: name,
      kcalPer100: _round2(kcal * factor),
      grasasPer100: _round2(fats * factor),
      carbsPer100: _round2(carbs * factor),
      proteinsPer100: _round2(proteins * factor),
    );

    return await repository.insertFood(food);
  }

  /// Redondea a 2 decimales para no almacenar precisión irreal.
  double _round2(double v) => (v * 100).roundToDouble() / 100;
}
