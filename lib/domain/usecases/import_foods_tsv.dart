import '../repositories/food_repository.dart';

class ImportFoodsTsv {
  final FoodRepository repository;

  ImportFoodsTsv(this.repository);

  Future<int> call(String tsvContent) => repository.importFoodsTsv(tsvContent);
}
