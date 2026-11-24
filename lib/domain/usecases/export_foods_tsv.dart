import '../repositories/food_repository.dart';

class ExportFoodsTsv {
  final FoodRepository repository;

  ExportFoodsTsv(this.repository);

  Future<String> call() => repository.exportFoodsTsv();
}
