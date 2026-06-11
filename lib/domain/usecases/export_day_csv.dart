import '../repositories/meal_repository.dart';

class ExportDayToCsv {
  final MealRepository repository;

  ExportDayToCsv(this.repository);

  Future<String> call(DateTime date) async {
    final path = await repository.exportMealsByDateCSV(date);
    if (path.isNotEmpty) {
      await repository.clearMealsAndItems();
    }
    return path;
  }
}
