import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/food_model.dart';

class FoodRepositoryImpl implements FoodRepository {
  final LocalDataSource localDataSource;

  FoodRepositoryImpl(this.localDataSource);

  @override
  Future<List<Food>> searchFoods(String query) async {
    return await localDataSource.searchFoods(query);
  }

  @override
  Future<int> insertFood(FoodModel food) async {
    return await localDataSource.insertFood(food);
  }

  @override
  Future<int> updateFood(FoodModel food) async {
    return await localDataSource.updateFood(food);
  }

  @override
  Future<int> deleteFood(int id) async {
    return await localDataSource.deleteFood(id);
  }
}
