import 'dart:typed_data';

import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/food_model.dart';

class FoodRepositoryImpl implements FoodRepository {
  final LocalDataSource localDataSource;

  FoodRepositoryImpl(this.localDataSource);

  @override
  Future<List<Food>> searchFoods(String query) =>
      localDataSource.searchFoods(query);

  @override
  Future<Food?> getFoodById(int id) => localDataSource.getFoodById(id);

  @override
  Future<int> insertFood(Food food) =>
      localDataSource.insertFood(FoodModel.fromEntity(food));

  @override
  Future<int> updateFood(Food food) =>
      localDataSource.updateFood(FoodModel.fromEntity(food));

  @override
  Future<int> saveFoodByName(Food food) =>
      localDataSource.saveFoodByName(FoodModel.fromEntity(food));

  @override
  Future<int> deleteFood(int id) => localDataSource.deleteFood(id);

  @override
  Future<void> incrementUsage(int foodId) =>
      localDataSource.incrementFoodUsage(foodId);

  @override
  Future<void> resetUsage(int foodId) => localDataSource.resetFoodUsage(foodId);

  @override
  Future<List<Food>> getMostUsedFoods({int limit = 20}) =>
      localDataSource.getMostUsedFoods(limit: limit);

  @override
  Future<String> exportFoodsTsv() => localDataSource.exportFoodsTsv();

  @override
  Future<int> importFoodsTsv(String content) =>
      localDataSource.importFoodsTsvFromString(content);

  @override
  Future<Uint8List> exportDatabase() => localDataSource.exportDatabaseBytes();

  @override
  Future<int> importDatabase(String sourcePath) =>
      localDataSource.importDatabase(sourcePath);
}
