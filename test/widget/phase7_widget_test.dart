import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/purchase_repository_impl.dart';
import 'package:cal_counter/data/repositories/scale_repository_impl.dart';
import 'package:cal_counter/data/repositories/shopping_list_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/shopping_list.dart';
import 'package:cal_counter/domain/services/scale_barcode.dart';
import 'package:cal_counter/presentation/providers/data_provider.dart';
import 'package:cal_counter/data/repositories/category_repository_impl.dart';
import 'package:cal_counter/presentation/views/cart_mode_view.dart';
import 'package:cal_counter/presentation/views/categories_view.dart';
import 'package:cal_counter/presentation/views/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

/// EAN-13 con dígito de control correcto.
String _ean(String doce) {
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = doce.codeUnitAt(11 - i) - 48;
    sum += i.isEven ? d * 3 : d;
  }
  return '$doce${(10 - sum % 10) % 10}';
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  late AppDatabase db;
  late FoodRepositoryImpl foods;
  late ShoppingListRepositoryImpl shopping;
  late int listaId, polloId;

  setUp(() async {
    // La lista de frutas y verduras ya incorporada: no se importa sola.
    SharedPreferences.setMockInitialValues({
      kProduceCatalogVersionKey: kProduceCatalogVersion,
    });
    db = memoryDb();
    foods = FoodRepositoryImpl(db);
    shopping = ShoppingListRepositoryImpl(db);
    polloId = await foods.saveFood(
      const Food(
        nombre: 'Pechuga de pollo',
        nutricion: NutritionFacts.basica(
          kcal: 120,
          proteinas: 23,
          grasas: 2,
          carbohidratos: 0,
        ),
      ),
    );
    await foods.saveFood(const Food(nombre: 'Detergente'));
    listaId = await shopping.createList('Semana');
    await shopping.addItem(ShoppingItem(listaId: listaId, texto: 'Detergente'));
    await shopping.addItem(ShoppingItem(listaId: listaId, texto: 'Manzanas'));
    await shopping.addItem(
      ShoppingItem(listaId: listaId, texto: 'Pollo', alimentoId: polloId),
    );
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(393 * 3, 851 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('lista agrupada por pasillos y categoría en el alta', (
    tester,
  ) async {
    await pump(tester, const MainShell());
    await tester.tap(find.text('Compras'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();
    // Orden general: frutas, carnicería, …, limpieza.
    final frutas = tester.getTopLeft(find.text('Frutas y verduras (1)')).dy;
    final carne = tester.getTopLeft(find.text('Carnicería (1)')).dy;
    final limpieza = tester.getTopLeft(find.text('Limpieza (1)')).dy;
    expect(frutas < carne && carne < limpieza, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Alta de un alimento: la categoría se sugiere por el nombre.
    await tester.tap(find.text('Alimentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alimento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre *'),
      'Merluza',
    );
    await tester.pumpAndSettle();
    expect(find.text('Pescadería'), findsOneWidget);
    expect(find.text('Sugerida por el nombre'), findsOneWidget);
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    final merluza = (await tester.runAsync(() => foods.search('merluza')))!;
    expect(merluza.single.categoriaId, isNotNull);

    // Filtro por categoría en la pestaña Alimentos.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carnicería').last);
    await tester.pumpAndSettle();
    expect(find.text('Pechuga de pollo'), findsOneWidget);
    expect(find.text('Detergente'), findsNothing);
    await unmount(tester);
  });

  testWidgets('modo carrito: etiquetas de báscula aprendidas por tienda', (
    tester,
  ) async {
    final bandeja1 = _ean('211234500850'); // 850 g
    final bandeja2 = _ean('211234500920'); // 920 g
    await pump(
      tester,
      Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => CartModeView(
                    listaId: listaId,
                    scannerBuilder: (_, onCode) => Wrap(
                      children: [
                        for (final c in [bandeja1, bandeja2])
                          TextButton(
                            onPressed: () => onCode(c),
                            child: Text('escanear $c'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              child: const Text('Abrir carrito'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir carrito'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Establecimiento'),
      'Mercado',
    );
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    // "Te falta" agrupado por pasillos.
    expect(find.text('Frutas y verduras'), findsOneWidget);
    expect(find.text('Carnicería'), findsOneWidget);

    // 1ª etiqueta de la tienda: se aprende el formato (peso).
    await tester.tap(find.text('escanear $bandeja1'));
    await tester.pumpAndSettle();
    expect(find.text('Etiqueta de báscula'), findsOneWidget);
    expect(find.text('Peso: 0,850 kg'), findsOneWidget);
    await tester.tap(find.text('Peso: 0,850 kg'));
    await tester.pumpAndSettle();
    // Producto desconocido: se elige el alimento.
    expect(find.text('¿Qué producto es esta etiqueta?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'pechuga');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pechuga de pollo'));
    await tester.pumpAndSettle();
    // Sin €/kg conocido: se pide el importe de la etiqueta.
    expect(find.text('Importe del paquete'), findsOneWidget);
    expect(find.textContaining('0,850 kg'), findsWidgets);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Importe del paquete'),
      '12,67',
    );
    await tester.tap(find.text('Añadir al carrito'));
    await tester.pumpAndSettle();
    expect(find.textContaining('14,91 €/kg'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 2ª bandeja (otro peso): reconocida y con el importe calculado.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2600)),
    );
    await tester.tap(find.text('escanear $bandeja2'));
    await tester.pumpAndSettle();
    expect(find.text('Etiqueta de báscula'), findsNothing);
    expect(find.text('Pechuga de pollo'), findsWidgets);
    expect(find.textContaining('se sumará este paquete'), findsOneWidget);
    await tester.tap(find.text('Añadir al carrito'));
    await tester.pumpAndSettle();

    final item = (await tester.runAsync(() => shopping.getItems(listaId)))!
        .firstWhere((i) => i.texto == 'Pollo');
    expect(item.comprado, isTrue);
    expect(item.pesoG, 1770);
    expect(item.subtotalCent, 1267 + 1372); // 0,92 kg × 14,91 €/kg
    final tienda = (await tester.runAsync(
      () => ScaleRepositoryImpl(db).getStore('mercado'),
    ))!;
    expect(tienda.formatoBascula, ScaleFormat.peso);
    final compras = (await tester.runAsync(
      () => PurchaseRepositoryImpl(db).getPurchasesForFood(polloId),
    ))!;
    expect(compras.single.compra.pesoG, 1770);
    await unmount(tester);
  });

  testWidgets('categorías: crear y orden propio de una tienda', (tester) async {
    final cats = CategoryRepositoryImpl(db);
    await tester.runAsync(() async {
      final general = await cats.getCategories();
      await cats.reorder([
        for (final c in general.reversed) c.id!,
      ], tienda: 'Mercado');
    });
    await pump(tester, const CategoriesView(tienda: 'Mercado'));
    expect(find.textContaining('Orden propio de Mercado'), findsOneWidget);
    await tester.tap(find.text('Usar el general'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mercado usa el orden general'), findsOneWidget);

    await tester.tap(find.byTooltip('Nueva categoría'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Mascotas');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mascotas'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Mascotas'), findsOneWidget);
    final nombres = (await tester.runAsync(cats.getCategories))!
        .map((c) => c.nombre);
    expect(nombres.last, 'Mascotas');
    await unmount(tester);
  });
}
