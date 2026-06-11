import '../entities/food.dart';
import '../../data/models/food_model.dart';

abstract class FoodRepository {
  Future<List<Food>> searchFoods(String query);
  Future<int> insertFood(FoodModel food);
  Future<int> updateFood(FoodModel food);
  Future<int> deleteFood(int id);
}
