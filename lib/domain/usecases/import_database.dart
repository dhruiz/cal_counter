import '../repositories/food_repository.dart';

class ImportDatabase {
  final FoodRepository repository;

  ImportDatabase(this.repository);

  Future<int> call(String sourcePath) => repository.importDatabase(sourcePath);
}
