import 'dart:typed_data';

import '../entities/food.dart';

abstract class FoodRepository {
  Future<List<Food>> searchFoods(String query);
  Future<Food?> getFoodById(int id);

  /// Alta. Lanza `DuplicateFoodNameException` si el nombre ya existe.
  Future<int> insertFood(Food food);

  /// Lanza `DuplicateFoodNameException` si el nuevo nombre ya existe.
  Future<int> updateFood(Food food);

  /// Crea el alimento o, si ya existe uno con ese nombre (sin distinguir
  /// mayúsculas), sobrescribe sus macros conservando id y contador de uso
  /// (los vínculos de recetas y productos siguen apuntando a él).
  Future<int> saveFoodByName(Food food);

  Future<int> deleteFood(int id);
  Future<void> incrementUsage(int foodId);
  Future<void> resetUsage(int foodId);
  Future<List<Food>> getMostUsedFoods({int limit});

  /// Catálogo como TSV (cabecera fija `id\talimento\tkCal\t...`).
  Future<String> exportFoodsTsv();

  /// Importa un TSV; omite nombres existentes. Devuelve cuántos se añadieron.
  Future<int> importFoodsTsv(String content);

  /// Catálogo como archivo SQLite listo para guardar.
  Future<Uint8List> exportDatabase();

  /// Importa los alimentos de otra BD; omite nombres existentes.
  Future<int> importDatabase(String sourcePath);
}
