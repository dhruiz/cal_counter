import '../entities/food.dart';
import '../entities/meal_item.dart';
import '../errors/domain_errors.dart';
import '../repositories/meal_repository.dart';

/// Registra [quantity] (g o ml) de un alimento en una comida. Los valores se
/// guardan YA escalados: `factor = cantidad / 100`.
///
/// Un alimento pendiente (sin tabla nutricional completa) no se registra:
/// sería contar ceros. La UI pide completarlo antes.
class AddFoodToMeal {
  final MealRepository repository;

  AddFoodToMeal(this.repository);

  Future<int> call({
    required int mealId,
    required Food food,
    required double quantity,
  }) async {
    if (quantity <= 0) {
      throw const ValidationException('La cantidad debe ser mayor que 0.');
    }
    final n = food.nutricion;
    if (!n.estaCompleta) {
      throw ValidationException(
        '"${food.nombreCompleto}" no tiene la tabla nutricional completa.',
      );
    }
    final factor = quantity / 100.0;
    return repository.addItemToMeal(
      MealItem(
        mealId: mealId,
        alimentoId: food.id,
        alimento: food.nombreCompleto,
        cantidad: quantity,
        grasas: n.grasas! * factor,
        carbohidratos: n.carbohidratos! * factor,
        proteinas: n.proteinas! * factor,
        kcal: n.kcal! * factor,
      ),
    );
  }
}
