import '../entities/food.dart';
import '../entities/meal_item.dart';
import '../entities/nutrition_facts.dart';
import '../errors/domain_errors.dart';
import '../repositories/food_repository.dart';

/// Guarda una comida completa como un alimento "preparado" del repertorio.
///
/// Toma los valores totales de los items (ya escalados a la cantidad
/// consumida) y el peso total, y los proratea a "por 100 g":
/// `valorPor100 = total / gramosTotales * 100`, redondeado a 2 decimales.
///
/// `totalGrams` permite indicar el peso real de la preparación (p. ej. ya
/// cocinada). Si es `null` se usa la suma de los pesos de los items.
///
/// Con [sobrescribir] = un alimento existente, se ACTUALIZA ese alimento
/// (conserva su id, sus vínculos y su uso); nunca se borra y reinserta.
class SaveMealAsFood {
  final FoodRepository repository;

  SaveMealAsFood(this.repository);

  Future<int> call({
    required String name,
    required List<MealItem> items,
    double? totalGrams,
    Food? sobrescribir,
  }) async {
    double summedGrams = 0, kcal = 0, fats = 0, carbs = 0, proteins = 0;
    for (final item in items) {
      summedGrams += item.cantidad;
      kcal += item.kcal;
      fats += item.grasas;
      carbs += item.carbohidratos;
      proteins += item.proteinas;
    }

    final grams = totalGrams ?? summedGrams;
    if (grams <= 0) {
      throw const ValidationException(
        'La comida no tiene ingredientes con peso.',
      );
    }

    final nutricion = NutritionFacts.basica(
      kcal: kcal,
      proteinas: proteins,
      grasas: fats,
      carbohidratos: carbs,
    ).escalada(100.0 / grams).redondeada();

    final base =
        sobrescribir ?? Food(nombre: name.trim(), tipo: FoodType.preparado);
    return repository.saveFood(
      base.copyWith(
        nombre: name.trim(),
        nutricion: nutricion,
        origenNutricion: NutritionSource.calculado,
      ),
    );
  }
}
