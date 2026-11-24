import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/presentation/providers/data_provider.dart';
import 'package:cal_counter/presentation/views/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    await initializeDateFormatting('es');
    // path_provider: sin directorio de documentos → no hay datos antiguos.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => '/no/existe',
        );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = memoryDb();
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393 * 3, 851 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: StartupGate()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('primera vez: catálogo base y luego la app', (tester) async {
    await pump(tester);
    expect(find.text('Tus alimentos, en el centro de todo'), findsOneWidget);
    expect(
      find.text('Importar mis datos de la versión anterior'),
      findsNothing,
    );
    await tester.tap(find.text('Empezar con el catálogo base'));
    // La carga del asset (grande) decodifica en otro isolate: tiempo real.
    for (var i = 0; i < 100; i++) {
      if (find.text('Agregar Ingesta').evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(find.text('Agregar Ingesta'), findsOneWidget);
    final foods = (await tester.runAsync(
      () => FoodRepositoryImpl(db).search('', limit: 1000),
    ))!;
    expect(foods.length, 678 + 222); // catálogo base + frutas y verduras
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kOnboardingDone), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('con alimentos ya guardados no se muestra', (tester) async {
    await tester.runAsync(
      () => FoodRepositoryImpl(db).saveFood(const Food(nombre: 'Pan')),
    );
    await pump(tester);
    expect(find.text('Tus alimentos, en el centro de todo'), findsNothing);
    expect(find.text('Agregar Ingesta'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('empezar vacío', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Empezar vacío'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar Ingesta'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
