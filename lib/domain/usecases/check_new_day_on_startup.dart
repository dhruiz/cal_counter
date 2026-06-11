import '../repositories/meal_repository.dart';

class CheckNewDayOnStartup {
  final MealRepository repository;

  CheckNewDayOnStartup(this.repository);

  Future<DateTime?> call() async {
    final hasItems = await repository.hasMealItems();
    if (!hasItems) return null;

    final lastDate = await repository.getLastMealDate();
    if (lastDate == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastDate.year, lastDate.month, lastDate.day);

    if (last.isBefore(today)) {
      return last;
    }
    return null;
  }
}
