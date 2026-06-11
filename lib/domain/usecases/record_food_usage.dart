import '../repositories/food_repository.dart';

class RecordFoodUsage {
  final FoodRepository repository;

  RecordFoodUsage(this.repository);

  Future<void> call(int foodId) async {
    return await repository.incrementUsage(foodId);
  }
}
