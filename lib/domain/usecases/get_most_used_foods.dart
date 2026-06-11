import '../entities/food.dart';
import '../repositories/food_repository.dart';

class GetMostUsedFoods {
  final FoodRepository repository;

  GetMostUsedFoods(this.repository);

  Future<List<Food>> call({int limit = 20}) async {
    return await repository.getMostUsedFoods(limit: limit);
  }
}
