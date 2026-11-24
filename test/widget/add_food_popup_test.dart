import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/meal.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
import 'package:cal_counter/presentation/providers/home_provider.dart';
import 'package:cal_counter/presentation/providers/search_provider.dart';
import 'package:cal_counter/presentation/widgets/add_food_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Registra las comidas creadas y los items añadidos.
class _RecordingMealRepository extends FakeMealRepository {
  final List<String> created = [];
  final List<MealItem> added = [];

  @override
  Future<int> createMeal(String name, DateTime date) async {
    created.add(name);
    return 100 + created.length;
  }

  @override
  Future<int> addItemToMeal(MealItem item) async {
    added.add(item);
    return added.length;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Nueva comida no reutiliza un nombre existente y la cantidad '
      'acepta coma decimal', (tester) async {
    final meals = _RecordingMealRepository();
    final day = DateTime(2024, 1, 1);
    const food = Food(
      id: 5,
      name: 'Arroz',
      grasasPer100: 1,
      carbsPer100: 28,
      proteinsPer100: 3,
      kcalPer100: 130,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealRepositoryProvider.overrideWithValue(meals),
          foodRepositoryProvider.overrideWithValue(
            FakeFoodRepository(const []),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AddFoodPopup(
              food: food,
              selectedDate: day,
              // Comida_2 se borró: con "comidas + 1" saldría Comida_3, que ya
              // existe, y el alimento acabaría en ella.
              availableMeals: [
                Meal(id: 1, name: 'Comida_1', date: day),
                Meal(id: 3, name: 'Comida_3', date: day),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva Comida'));
    await tester.pump();
    expect(find.text('Se creará: Comida_4'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '12,5');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(meals.created, ['Comida_4']);
    expect(meals.added.single.cantidad, 12.5);
    expect(meals.added.single.kcal, closeTo(16.25, 1e-9));
  });
}
