import '../entities/food.dart';
import '../../data/models/food_model.dart';

abstract class FoodRepository {
  Future<List<Food>> searchFoods(String query);
  Future<Food?> getFoodById(int id);
  Future<int> insertFood(FoodModel food);
  Future<int> updateFood(FoodModel food);
  Future<int> deleteFood(int id);
  Future<void> incrementUsage(int foodId);
  Future<void> resetUsage(int foodId);
  Future<List<Food>> getMostUsedFoods({int limit});
}
