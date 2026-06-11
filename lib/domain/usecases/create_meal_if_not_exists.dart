import '../repositories/meal_repository.dart';

class CreateMealIfNotExists {
  final MealRepository repository;

  CreateMealIfNotExists(this.repository);

  Future<int> call(String name, DateTime date) async {
    // Check if meal exists
    final meals = await repository.getMealsByDate(date);
    final existing = meals.where((m) => m.name == name);

    if (existing.isNotEmpty) {
      return existing.first.id!;
    } else {
      return await repository.createMeal(name, date);
    }
  }
}
