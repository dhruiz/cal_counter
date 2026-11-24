import 'package:cal_counter/data/backup/full_backup.dart';
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
    // rootBundle guarda los assets leídos; un Future de un test anterior queda
    // ligado a su reloj simulado y no se completaría en este.
    rootBundle.clear();
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

  testWidgets('primera vez: frutas y verduras y luego la app', (tester) async {
    await pump(tester);
    expect(find.text('Tus alimentos, en el centro de todo'), findsOneWidget);
    expect(
      find.text('Importar mis datos de la versión anterior'),
      findsNothing,
    );
    await tester.tap(find.text('Empezar con frutas y verduras'));
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
    expect(foods.length, 229);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kOnboardingDone), isTrue);
    // Ya incorporada: al abrir la app no se vuelve a importar.
    expect(prefs.getInt(kProduceCatalogVersionKey), kProduceCatalogVersion);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  /// Deja correr la app en tiempo real (el asset se decodifica en otro
  /// isolate) hasta que aparezca [finder] o pasen [vueltas] × 100 ms.
  Future<void> esperar(
    WidgetTester tester, {
    Finder? finder,
    int vueltas = 150,
  }) async {
    for (var i = 0; i < vueltas; i++) {
      if (finder != null && finder.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<List<Food>> alimentos(WidgetTester tester) async => (await tester
      .runAsync(() => FoodRepositoryImpl(db).search('', limit: 2000)))!;

  testWidgets(
    'con alimentos ya guardados no se muestra y se añaden solas las frutas',
    (tester) async {
      await tester.runAsync(
        () => FoodRepositoryImpl(db).saveFood(const Food(nombre: 'Pan')),
      );
      await pump(tester);
      expect(find.text('Tus alimentos, en el centro de todo'), findsNothing);
      expect(find.text('Agregar Ingesta'), findsOneWidget);

      final aviso = find.text(
        'Se añadieron 229 frutas, verduras y hortalizas a tus alimentos.',
      );
      await esperar(tester, finder: aviso);
      expect(aviso, findsOneWidget);
      expect((await alimentos(tester)).length, 1 + 229);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(kProduceCatalogVersionKey), kProduceCatalogVersion);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('al restaurar un respaldo la lista se repone si hace falta', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      kOnboardingDone: true,
      kProduceCatalogVersionKey: kProduceCatalogVersion,
    });
    await tester.runAsync(
      () => FoodRepositoryImpl(db).saveFood(const Food(nombre: 'Pan')),
    );
    await pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.text('Agregar Ingesta')),
    );
    final aviso = find.text(
      'Se añadieron 229 frutas, verduras y hortalizas a tus alimentos.',
    );

    // Respaldo anterior a la lista (sin la marca), hecho con otra base.
    final prefs = await SharedPreferences.getInstance();
    final viejo = memoryDb();
    final json = (await tester.runAsync(() async {
      await FoodRepositoryImpl(viejo).saveFood(const Food(nombre: 'Arroz'));
      await prefs.remove(kProduceCatalogVersionKey);
      final j = await FullBackupService(viejo).export();
      await prefs.setInt(kProduceCatalogVersionKey, kProduceCatalogVersion);
      await viejo.close();
      return j;
    }))!;

    // Como hace Datos y respaldos: restaurar e invalidar el provider.
    await tester.runAsync(
      () => FullBackupService(
        db,
      ).restore(json, ajustesDeLosDatos: kAjustesDeLosDatos),
    );
    expect(prefs.containsKey(kProduceCatalogVersionKey), isFalse);
    container.invalidate(autoImportProduceProvider);
    await esperar(tester, finder: aviso);
    expect(aviso, findsOneWidget);
    expect((await alimentos(tester)).length, 1 + 229); // Arroz + la lista

    // Recargarlo otra vez (la lista ya está) no repite el aviso: el estado de
    // carga conserva el 229 anterior y no debe contar.
    ScaffoldMessenger.of(
      tester.element(find.text('Agregar Ingesta')),
    ).removeCurrentSnackBar();
    await tester.pump();
    expect(aviso, findsNothing);
    container.invalidate(autoImportProduceProvider);
    await esperar(tester, vueltas: 20);
    expect(aviso, findsNothing);
    expect((await alimentos(tester)).length, 1 + 229);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('la lista se añade una sola vez por versión', (tester) async {
    // Ya incorporada (por ejemplo, y luego se borraron alimentos): no vuelve.
    SharedPreferences.setMockInitialValues({
      kOnboardingDone: true,
      kProduceCatalogVersionKey: kProduceCatalogVersion,
    });
    await tester.runAsync(
      () => FoodRepositoryImpl(db).saveFood(const Food(nombre: 'Pan')),
    );
    await pump(tester);
    expect(find.text('Agregar Ingesta'), findsOneWidget);
    await esperar(tester, vueltas: 20);
    expect((await alimentos(tester)).map((f) => f.nombre), ['Pan']);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('empezar vacío', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Empezar vacío'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar Ingesta'), findsOneWidget);
    // Se respeta la elección: tampoco se añade sola la lista de frutas.
    await esperar(tester, vueltas: 20);
    expect(await alimentos(tester), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(kProduceCatalogVersionKey), kProduceCatalogVersion);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
