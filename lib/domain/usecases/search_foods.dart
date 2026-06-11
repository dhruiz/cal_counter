import '../entities/food.dart';
import '../repositories/food_repository.dart';

class SearchFoods {
  final FoodRepository repository;

  SearchFoods(this.repository);

  Future<List<Food>> call(String query) async {
    return await repository.searchFoods(query);
  }
}
