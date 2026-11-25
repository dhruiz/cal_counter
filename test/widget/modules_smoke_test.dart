import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/parsers/recipe_text_codec.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/purchase_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/data/repositories/shopping_list_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/purchase.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/entities/shopping_list.dart';
import 'package:cal_counter/domain/repositories/food_repository.dart';
import 'package:cal_counter/presentation/providers/data_provider.dart';
import 'package:cal_counter/presentation/views/cart_mode_view.dart';
import 'package:cal_counter/presentation/views/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

NutritionFacts _n(double kcal, double p, double g, double c) =>
    NutritionFacts.basica(
      kcal: kcal,
      proteinas: p,
      grasas: g,
      carbohidratos: c,
    );

/// Recorre las pantallas con una base de datos real en memoria (mismo
/// esquema que en el móvil) para detectar errores de layout o de flujo. No
/// usa cámara ni archivos.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  late AppDatabase db;
  late FoodRepositoryImpl foods;
  late PurchaseRepositoryImpl purchases;
  late ShoppingListRepositoryImpl shopping;
  late RecipeRepositoryImpl recipes;
  late int lecheId, panId, huevoId, listaId;

  setUp(() async {
    // La lista de frutas y verduras ya incorporada: no se importa sola.
    SharedPreferences.setMockInitialValues({
      kProduceCatalogVersionKey: kProduceCatalogVersion,
    });
    db = memoryDb();
    foods = FoodRepositoryImpl(db);
    purchases = PurchaseRepositoryImpl(db);
    shopping = ShoppingListRepositoryImpl(db);
    recipes = RecipeRepositoryImpl(db);
    final now = DateTime.now();

    await foods.saveFood(
      Food(nombre: 'Plátano', nutricion: _n(94, 1.2, 0.3, 20)),
    );
    huevoId = await foods.saveFood(
      Food(nombre: 'Huevo', nutricion: _n(143, 12.6, 9.5, 0.7)),
    );
    await foods.savePortion(
      FoodPortion(alimentoId: huevoId, nombre: 'unidad', gramos: 60),
    );
    await foods.saveFood(Food(nombre: 'Patata', nutricion: _n(77, 2, 0.1, 17)));
    await foods.saveFood(
      Food(nombre: 'Aceite de oliva', nutricion: _n(884, 0, 100, 0)),
    );
    lecheId = await foods.saveFood(
      Food(
        nombre: 'Leche entera',
        marca: 'Vaca',
        tipo: FoodType.envasado,
        unidad: FoodUnit.ml,
        nutricion: _n(64, 3.2, 3.6, 4.7),
      ),
    );
    final lechePack = await foods.savePackage(
      FoodPackage(
        alimentoId: lecheId,
        codigoBarras: '8410000000001',
        descripcion: 'Brick 1 L',
        contenido: 1000,
      ),
    );
    final cafeId = await foods.saveFood(
      Food(
        nombre: 'Café molido',
        tipo: FoodType.envasado,
        nutricion: _n(2, 0.1, 0, 0),
      ),
    );
    await foods.savePackage(
      FoodPackage(alimentoId: cafeId, codigoBarras: '5550001'),
    );
    panId = await foods.saveFood(
      Food(nombre: 'Pan de barra', nutricion: _n(270, 9, 1.5, 55)),
    );
    await foods.saveFood(const Food(nombre: 'Tomate triturado'));

    await purchases.addPurchase(
      Purchase(
        presentacionId: lechePack,
        fecha: now.subtract(const Duration(days: 20)),
        precioCent: 95,
        establecimiento: 'Mercado',
      ),
    );
    await purchases.addPurchase(
      Purchase(
        presentacionId: lechePack,
        fecha: now.subtract(const Duration(days: 2)),
        precioCent: 105,
        establecimiento: 'Súper Centro',
      ),
    );

    await recipes.save(
      Recipe.desdeLineas(
        nombre: 'Tortilla de patatas',
        categoria: 'Plato principal',
        porciones: 4,
        tiempoMin: 40,
        lineas: [
          '4 huevos',
          '500 g de patatas',
          '1 cebolla (opcional)',
          '50 ml de aceite de oliva',
          'Sal',
        ],
        elaboracion:
            'Pelar y cortar las patatas.\nFreír.\nCuajar con el huevo.',
        notas: 'Mejor jugosa.',
      ),
    );
    await recipes.save(
      Recipe.desdeLineas(
        nombre: 'Flan',
        lineas: ['4 huevos', '500 ml de leche', '150 g de azúcar'],
        elaboracion: 'Mezclar\nHornear al baño maría',
      ),
    );
    await recipes.save(
      Recipe.desdeLineas(nombre: 'Ensalada', lineas: ['2 tomates', '1 pepino']),
    );

    listaId = await shopping.createList('Súper');
    await shopping.addItem(
      ShoppingItem(
        listaId: listaId,
        texto: 'Leche entera',
        alimentoId: lecheId,
      ),
    );
    await shopping.addItem(
      ShoppingItem(listaId: listaId, texto: 'Pan', cantidad: '2'),
    );
    await shopping.addItem(
      ShoppingItem(listaId: listaId, texto: 'Huevos', comprado: true),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Widget home = const MainShell(),
  }) async {
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

  /// Desmonta la app para que se cancelen las consultas observadas.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('alimentos: buscar sin tildes, pendientes y completar', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Alimentos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 alimento pendiente'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'platano');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Plátano'), findsOneWidget);
    expect(find.text('Patata'), findsNothing);

    // Por código de barras.
    await tester.enterText(find.byType(TextField).first, '8410000000001');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Leche entera'), findsOneWidget);
    await tester.tap(find.text('Leche entera'));
    await tester.pumpAndSettle();
    expect(find.text('Tabla nutricional'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Brick 1 L'), 200);
    expect(find.text('Brick 1 L'), findsWidgets);
    expect(find.textContaining('1,05 €/L'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Precios'), 200);
    expect(
      find.textContaining('Último: 1,05 € en Súper Centro'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Pendientes: completar la tabla.
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomate triturado'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pendiente: faltan'), findsOneWidget);
    await tester.tap(find.text('Completar'));
    await tester.pumpAndSettle();
    expect(find.text('Completar tabla nutricional'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor energético *'),
      '30',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Grasas *'),
      '0,2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hidratos de carbono *'),
      '5',
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Proteínas *'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Proteínas *'),
      '1,3',
    );
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    final tomate = (await tester.runAsync(
      () => foods.search('tomate triturado'),
    ))!;
    expect(tomate.single.pendiente, isFalse);
    expect(tomate.single.nutricion.grasas, 0.2);
    await unmount(tester);
  });

  testWidgets('calorías: agregar ingesta y pedir completar un pendiente', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Agregar Ingesta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'huevo');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huevo'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar Huevo'), findsOneWidget);
    await tester.tap(find.text('1 unidad (60 g)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    // Vuelve a Calorías con el día actualizado solo.
    expect(find.text('Agregar Ingesta'), findsOneWidget);
    expect(find.textContaining('86'), findsWidgets); // 143 × 0,6 ≈ 86 kcal

    await tester.tap(find.text('Agregar Ingesta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'tomate');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomate triturado'));
    await tester.pumpAndSettle();
    expect(find.text('Falta la tabla nutricional'), findsOneWidget);
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    await unmount(tester);
  });

  testWidgets('recetas: buscar, vincular, calcular y lista de compra', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Recetas'));
    await tester.pumpAndSettle();
    expect(find.text('Tortilla de patatas'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'huevos, papas');
    await tester.pumpAndSettle();
    expect(find.text('¡Puedes hacerla!'), findsOneWidget);
    expect(find.textContaining('Te falta: leche, azúcar'), findsOneWidget);
    expect(find.text('Ensalada'), findsNothing);

    await tester.tap(find.text('Tortilla de patatas'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredientes (5)'), findsOneWidget);
    expect(find.text('Para calcular las calorías faltan:'), findsOneWidget);
    await tester.tap(find.text('Vincular automáticamente'));
    await tester.pumpAndSettle();
    expect(find.text('Vincular ingredientes'), findsOneWidget);
    expect(find.textContaining('→ Huevo · 4 unidad'), findsOneWidget);
    expect(find.textContaining('→ Patata · 500 g'), findsOneWidget);
    await tester.tap(find.text('Vincular 3 ingredientes'));
    await tester.pumpAndSettle();
    expect(find.text('Para calcular las calorías faltan:'), findsNothing);
    // Sin peso final la tabla es aproximada, pero ya es un alimento más.
    expect(find.text('Nutrición (aproximada)'), findsOneWidget);
    expect(find.textContaining('falta el peso final'), findsOneWidget);
    expect(
      find.text('En tus alimentos como «Tortilla de patatas · Receta»'),
      findsOneWidget,
    );
    expect(find.text('Registrar en el día'), findsOneWidget);
    expect(find.textContaining('Por porción'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Añadir lo que me falta a la lista'),
      200,
    );
    await tester.tap(find.text('Añadir lo que me falta a la lista'));
    await tester.pumpAndSettle();
    expect(find.text('Añadir a la lista de compra'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Añadir'));
    await tester.pumpAndSettle();
    expect(find.text('2 artículos añadidos a "Súper"'), findsOneWidget);
    final items = (await tester.runAsync(() => shopping.getItems(listaId)))!;
    expect(items.map((i) => i.texto), containsAll(['Leche', 'Azúcar']));
    await unmount(tester);
  });

  testWidgets('recetas: nueva receta y pegar texto', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Recetas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nueva receta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre de la receta *'),
      'Batido',
    );
    // Ingrediente desde el buscador, como en el contador.
    await tester.tap(find.byKey(const Key('anadir_ingrediente')));
    await tester.pumpAndSettle();
    expect(find.text('Añadir ingrediente'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'platano');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plátano'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('cantidad_ingrediente')),
      '120',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('guardar_ingrediente')));
    await tester.pumpAndSettle();
    expect(find.text('120 g de plátano'), findsOneWidget);

    // Lista pegada: entra por vincular y se propone el alimento.
    await tester.tap(find.text('Pegar lista'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '250 ml de leche');
    await tester.tap(find.widgetWithText(FilledButton, 'Añadir'));
    await tester.pumpAndSettle();
    expect(find.text('Vincular ingredientes'), findsOneWidget);
    await tester.tap(find.text('Vincular 1 ingrediente'));
    await tester.pumpAndSettle();
    expect(find.text('→ Leche entera · Vaca'), findsOneWidget);

    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    var all = (await tester.runAsync(recipes.getAll))!;
    final batido = all.singleWhere((r) => r.nombre == 'Batido');
    expect(
      batido.ingredientes.map((i) => i.alimentoId),
      everyElement(isNotNull),
    );
    expect(batido.ingredientes.first.cantidad, 120);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pegar texto de una receta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), RecipeTextCodec.plantilla);
    await tester.tap(find.text('Revisar recetas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Se encontraron 2 recetas'), findsOneWidget);
    expect(
      find.textContaining('Ya existe una receta con este nombre'),
      findsOneWidget,
    );
    await tester.tap(find.text('Guardar 1 receta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 receta importada'), findsOneWidget);
    // Se pasa directamente a vincular sus ingredientes.
    expect(find.text('Vincular ingredientes'), findsOneWidget);
    all = (await tester.runAsync(recipes.getAll))!;
    expect(all.length, 5);
    await unmount(tester);
  });

  testWidgets('compras: lista, marcar, precio y total', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Compras'));
    await tester.pumpAndSettle();
    expect(find.text('1 de 3 comprados'), findsOneWidget);

    await tester.tap(find.text('Súper'));
    await tester.pumpAndSettle();
    expect(
      find.text('Falta por comprar (estimado) · 1 sin precio'),
      findsOneWidget,
    );
    expect(find.textContaining('Ref: 1,05 € (Súper Centro)'), findsOneWidget);
    expect(find.text('Comprados (1)'), findsOneWidget);

    // Marcar a mano un artículo vinculado → «Añadir precio» → se registra.
    await tester.tap(find.text('Leche entera'));
    await tester.pumpAndSettle();
    expect(find.text('Comprados (2)'), findsOneWidget);
    await tester.tap(find.text('Añadir precio'));
    await tester.pumpAndSettle();
    expect(find.text('Establecimiento'), findsOneWidget);
    await tester.tap(find.text('Añadir al carrito'));
    await tester.pumpAndSettle();
    final compras = (await tester.runAsync(
      () => purchases.getPurchasesForFood(lecheId),
    ))!;
    expect(compras.length, 3);
    expect(find.textContaining('1 × 1,05 € = 1,05 €'), findsOneWidget);
    expect(find.text('En el carrito (2) · 1 sin precio'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Tomates 1 kg');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Tomates'), findsOneWidget);
    expect(find.text('1 kg'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('modo carrito: escanear, alta mínima, total y terminar', (
    tester,
  ) async {
    await pumpApp(
      tester,
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => CartModeView(
                    listaId: listaId,
                    scannerBuilder: (_, onCode) => _FakeScanner(onCode: onCode),
                  ),
                ),
              ),
              child: const Text('Abrir carrito'),
            ),
          ),
        ),
      ),
    );

    Future<void> scan(String code) async {
      await tester.tap(find.text('escanear $code'));
      await tester.pumpAndSettle();
    }

    Future<void> settleToast() async {
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    Future<ShoppingItem> item(String texto) async => (await tester.runAsync(
      () => shopping.getItems(listaId),
    ))!.firstWhere((i) => i.texto == texto);

    // 1. Tienda al entrar.
    await tester.tap(find.text('Abrir carrito'));
    await tester.pumpAndSettle();
    expect(find.text('¿En qué tienda estás?'), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    expect(find.text('Súper Centro'), findsOneWidget); // chip de la AppBar

    // 2. Producto con precio guardado: confirmar con un toque.
    await scan('8410000000001');
    expect(
      find.textContaining('Último: 1,05 € en Súper Centro'),
      findsOneWidget,
    );
    await tester.tap(find.text('Añadir al carrito'));
    await tester.pumpAndSettle();
    var leche = await item('Leche entera');
    expect(leche.comprado, isTrue);
    expect(leche.precioCent, 105);
    await settleToast();

    // 3. Mismo código otra vez = una unidad más, sin otra compra.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2600)),
    );
    await scan('8410000000001');
    expect(find.textContaining('Ya llevas 1 en el carrito'), findsOneWidget);
    await tester.tap(find.text('Añadir al carrito'));
    await tester.pumpAndSettle();
    leche = await item('Leche entera');
    expect(leche.unidades, 2);
    expect(find.text('2,10 €'), findsWidgets);
    await settleToast();

    // 4. Producto conocido sin precio y fuera de la lista.
    await scan('5550001');
    expect(
      find.text('Este producto no está en tu lista de compra.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Añadir aunque no está en la lista'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un precio válido'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Precio por unidad'),
      '3,20',
    );
    await tester.tap(find.text('Añadir aunque no está en la lista'));
    await tester.pumpAndSettle();
    expect((await item('Café molido')).precioCent, 320);
    await settleToast();

    // 5. Código desconocido: aviso y alta mínima (sin tabla nutricional).
    await scan('7770001');
    expect(find.text('Producto no registrado'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre *'),
      'Galletas',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Marca'), 'Dora');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Presentación'),
      'Paquete 500 g',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Precio por unidad *'),
      '2,40',
    );
    await tester.tap(find.text('Guardar y añadir al carrito'));
    await tester.pumpAndSettle();
    final galletas = (await tester.runAsync(
      () => foods.findByBarcode('7770001'),
    ))!;
    expect(galletas.food.nombre, 'Galletas');
    expect(galletas.food.pendiente, isTrue);
    expect(galletas.package.descripcion, 'Paquete 500 g');
    expect((await item('Galletas')).comprado, isTrue);
    expect(find.text('7,70 €'), findsWidgets);
    await settleToast();

    // 6. Pendiente sin vincular (Pan): se elige su alimento y se añade.
    await tester.tap(find.text('Te falta (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pan'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué es «Pan»?'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pan de barra'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Precio por unidad'),
      '1,10',
    );
    await tester.tap(find.byTooltip('Una más'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir al carrito'));
    await tester.pumpAndSettle();
    final pan = await item('Pan');
    expect(pan.unidades, 2);
    expect(pan.alimentoId, panId);
    expect(find.text('9,90 €'), findsWidgets);
    await settleToast();

    // 7. Quitar del carrito borra su compra del historial.
    await tester.tap(find.text('Leche entera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar del carrito'));
    await tester.pumpAndSettle();
    expect((await item('Leche entera')).comprado, isFalse);
    final compras = (await tester.runAsync(
      () => purchases.getPurchasesForFood(lecheId),
    ))!;
    expect(compras.length, 2);
    expect(find.text('7,80 €'), findsWidgets);
    await settleToast();

    // 8. Terminar: avisa del producto nuevo pendiente y quita comprados.
    await tester.tap(find.text('Terminar compra'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 producto nuevo sin tabla'), findsOneWidget);
    await tester.tap(find.text('Quitar comprados'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir carrito'), findsOneWidget);
    final restantes = (await tester.runAsync(
      () => shopping.getItems(listaId),
    ))!;
    expect(restantes.map((i) => i.texto), ['Leche entera']);
    final pendientes = (await tester.runAsync(
      () => foods.search('', filter: FoodFilter.pendientes),
    ))!;
    expect(pendientes.map((f) => f.nombre), contains('Galletas'));
    await unmount(tester);
  });
}

/// Sustituye a la cámara: un botón por código.
class _FakeScanner extends StatelessWidget {
  final ValueChanged<String> onCode;

  const _FakeScanner({required this.onCode});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (final code in ['8410000000001', '5550001', '7770001'])
          TextButton(
            onPressed: () => onCode(code),
            child: Text('escanear $code'),
          ),
      ],
    );
  }
}
