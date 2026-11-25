import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/presentation/providers/data_provider.dart';
import 'package:cal_counter/presentation/views/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

/// Artículos que no son alimentos: filtro en Alimentos, fuera del contador
/// y alta sin tabla nutricional.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      kProduceCatalogVersionKey: kProduceCatalogVersion,
    });
    db = memoryDb();
    final foods = FoodRepositoryImpl(db);
    await foods.saveFood(
      const Food(nombre: 'Detergente líquido', esAlimento: false),
    );
    await foods.saveFood(
      const Food(
        nombre: 'Leche',
        nutricion: NutritionFacts(
          kcal: 64,
          proteinas: 3,
          grasas: 3.6,
          carbohidratos: 4.7,
        ),
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, {double ancho = 393}) async {
    tester.view.physicalSize = Size(ancho * 3, 851 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: MainShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('filtro «No alimentarios» en Alimentos', (tester) async {
    await pumpApp(tester, ancho: 1400);
    await tester.tap(find.text('Alimentos'));
    await tester.pumpAndSettle();
    // No cuenta como pendiente aunque no tenga tabla.
    expect(find.textContaining('pendiente'), findsNothing);
    // Pantalla ancha: la fila de filtros (horizontal) se ve entera.
    await tester.tap(find.text('No alimentarios'));
    await tester.pumpAndSettle();
    expect(find.text('Detergente líquido'), findsOneWidget);
    expect(find.text('No alimentario'), findsOneWidget);
    expect(find.text('Leche'), findsNothing);
    await unmount(tester);
  });

  testWidgets('el contador no ofrece artículos que no son alimentos', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'detergente');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Detergente líquido'), findsNothing);
    await unmount(tester);
  });

  testWidgets('alta de un artículo sin tabla nutricional', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Alimentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alimento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre *'),
      'Papel higiénico',
    );
    await tester.pump();
    expect(find.text('Nuevo artículo'), findsOneWidget);
    expect(find.text('Tabla nutricional'), findsNothing);
    expect(find.text('Se mide en'), findsOneWidget);
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    final papel = (await tester.runAsync(
      () => FoodRepositoryImpl(db).findByNameAndBrand('Papel higiénico', ''),
    ))!;
    expect(papel.esAlimento, isFalse);
    expect(papel.pendiente, isFalse);
    await unmount(tester);
  });
}
