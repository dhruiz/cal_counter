import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/meal_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/meal.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/presentation/providers/core_providers.dart';
import 'package:cal_counter/presentation/widgets/add_food_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => initializeDateFormatting('es'));
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = memoryDb();
  });
  tearDown(() => db.close());

  testWidgets('Nueva comida no reutiliza un nombre existente y la cantidad '
      'acepta coma decimal', (tester) async {
    final day = DateTime(2024, 1, 1);
    final meals = MealRepositoryImpl(db);
    late Food food;
    late List<Meal> existentes;
    await tester.runAsync(() async {
      final foods = FoodRepositoryImpl(db);
      final id = await foods.saveFood(
        const Food(
          nombre: 'Arroz',
          nutricion: NutritionFacts.basica(
            kcal: 130,
            proteinas: 3,
            grasas: 1,
            carbohidratos: 28,
          ),
        ),
      );
      food = (await foods.getFood(id))!;
      // Comida_2 se borró: con "comidas + 1" saldría Comida_3, que ya existe,
      // y el alimento acabaría en ella.
      await meals.createMeal('Comida_1', day);
      await meals.createMeal('Comida_3', day);
      existentes = await meals.getMealsByDate(day);
    });

    tester.view.physicalSize = const Size(393 * 3, 851 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: AddFoodPopup(
              food: food,
              selectedDate: day,
              availableMeals: existentes,
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
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    final dia = await tester.runAsync(() => meals.getMealsByDate(day));
    final nueva = dia!.singleWhere((m) => m.name == 'Comida_4');
    final items = await tester.runAsync(() => meals.getMealItems(nueva.id!));
    expect(items!.single.cantidad, 12.5);
    expect(items.single.kcal, closeTo(16.25, 1e-9));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
