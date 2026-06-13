import '../repositories/food_repository.dart';

/// Quita un alimento de la lista de "más usados" reseteando su contador de uso
/// (uso_count = 0, ultimo_uso = null). El alimento permanece en el catálogo.
class ResetFoodUsage {
  final FoodRepository repository;

  ResetFoodUsage(this.repository);

  Future<void> call(int foodId) async {
    return await repository.resetUsage(foodId);
  }
}
