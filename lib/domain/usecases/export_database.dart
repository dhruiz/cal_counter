import 'dart:typed_data';

import '../repositories/food_repository.dart';

/// Copia del catálogo de alimentos como archivo SQLite (bytes).
class ExportDatabase {
  final FoodRepository repository;

  ExportDatabase(this.repository);

  Future<Uint8List> call() => repository.exportDatabase();
}
