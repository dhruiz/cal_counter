import 'package:cal_counter/data/parsers/recipe_text_codec.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/product.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/entities/shopping_list.dart';
import 'package:cal_counter/presentation/providers/home_provider.dart';
import 'package:cal_counter/presentation/providers/products_provider.dart';
import 'package:cal_counter/presentation/providers/recipes_provider.dart';
import 'package:cal_counter/presentation/providers/search_provider.dart';
import 'package:cal_counter/presentation/providers/shopping_provider.dart';
import 'package:cal_counter/presentation/views/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Recorre las pantallas nuevas con repositorios en memoria para detectar
/// errores de layout o de flujo (no toca SQLite, cámara ni archivos).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  late FakeRecipeRepository recipes;
  late FakeProductRepository products;
  late FakeShoppingListRepository shopping;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    recipes = FakeRecipeRepository(const [
      Recipe(
        nombre: 'Tortilla de patatas',
        categoria: 'Plato principal',
        porciones: 4,
        tiempoMin: 40,
        ingredientes: [
          '4 huevos',
          '500 g de patatas',
          '1 cebolla (opcional)',
          'Aceite de oliva',
          'Sal',
        ],
        elaboracion:
            'Pelar y cortar las patatas.\nFreír.\nCuajar con el huevo.',
        notas: 'Mejor jugosa.',
        alimentoId: 1,
        pesoPorcionG: 150,
      ),
      Recipe(
        nombre: 'Flan',
        ingredientes: ['4 huevos', '500 ml de leche', '150 g de azúcar'],
        elaboracion: 'Mezclar\nHornear al baño maría',
      ),
      Recipe(nombre: 'Ensalada', ingredientes: ['2 tomates', '1 pepino']),
    ]);
    products = FakeProductRepository();
    final leche = await products.saveProduct(
      const Product(
        codigoBarras: '8410000000001',
        nombre: 'Leche entera',
        marca: 'Vaca',
        presentacion: '1 L',
      ),
    );
    await products.saveProduct(const Product(nombre: 'Pan de barra'));
    await products.addPurchase(
      Purchase(
        productoId: leche,
        fecha: now.subtract(const Duration(days: 20)),
        precio: 0.95,
        establecimiento: 'Mercado',
      ),
    );
    await products.addPurchase(
      Purchase(
        productoId: leche,
        fecha: now.subtract(const Duration(days: 2)),
        precio: 1.05,
        establecimiento: 'Súper Centro',
      ),
    );
    shopping = FakeShoppingListRepository(productRepo: products);
    final lista = await shopping.createList('Súper');
    await shopping.addItem(
      ShoppingItem(listaId: lista, texto: 'Leche entera', productoId: leche),
    );
    await shopping.addItem(
      ShoppingItem(listaId: lista, texto: 'Pan', cantidad: '2'),
    );
    await shopping.addItem(
      ShoppingItem(listaId: lista, texto: 'Huevos', comprado: true),
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393 * 3, 851 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mealRepositoryProvider.overrideWithValue(FakeMealRepository()),
          recipeRepositoryProvider.overrideWithValue(recipes),
          productRepositoryProvider.overrideWithValue(products),
          shoppingListRepositoryProvider.overrideWithValue(shopping),
          foodRepositoryProvider.overrideWithValue(
            FakeFoodRepository(const [
              Food(
                id: 1,
                name: 'Tortilla de patatas casera',
                grasasPer100: 11,
                carbsPer100: 12,
                proteinsPer100: 6,
                kcalPer100: 170,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('recetas: buscar por ingredientes, detalle y lista de compra', (
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
    expect(find.text('Registrar porción'), findsOneWidget);
    expect(find.textContaining('por porción (150 g)'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir lo que me falta a la lista'));
    await tester.pumpAndSettle();
    expect(find.text('Añadir a la lista de compra'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Añadir'));
    await tester.pumpAndSettle();
    expect(find.text('2 artículos añadidos a "Súper"'), findsOneWidget);
    expect(
      shopping.items.map((i) => i.texto),
      containsAll(['Leche', 'Azúcar']),
    );
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
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ingredientes * (uno por línea)'),
      '1 plátano\n250 ml de leche',
    );
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();
    expect(recipes.data.values.any((r) => r.nombre == 'Batido'), isTrue);
    // Deja que se oculte el SnackBar "Receta guardada".
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
    // "Tortilla de patatas" ya existe: aparece avisada y desmarcada.
    expect(
      find.textContaining('Ya existe una receta con este nombre'),
      findsOneWidget,
    );
    await tester.tap(find.text('Guardar 1 receta'));
    await tester.pumpAndSettle();
    expect(find.text('1 receta importada'), findsOneWidget);
    expect(recipes.data.length, 5);
  });

  testWidgets('productos: listado, detalle y registrar compra', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Productos'));
    await tester.pumpAndSettle();
    expect(find.text('Leche entera'), findsOneWidget);
    expect(find.textContaining('Último: 1,05\u00A0€'), findsOneWidget);

    await tester.tap(find.text('Leche entera'));
    await tester.pumpAndSettle();
    expect(find.text('Último precio'), findsOneWidget);
    expect(find.text('Último precio en cada establecimiento'), findsOneWidget);
    expect(find.text('Vincular al contador de calorías'), findsOneWidget);

    await tester.tap(find.text('Registrar compra'));
    await tester.pumpAndSettle();
    expect(find.text('Compra de Leche entera'), findsOneWidget);
    expect(find.text('€'), findsOneWidget); // sufijo del campo de precio
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Precio por unidad'),
      '1,10',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Compra registrada'), findsOneWidget);
    expect(products.purchases.last.precio, 1.10);
    expect(products.purchases.last.establecimiento, 'Súper Centro');
  });

  testWidgets('productos: formulario sin código', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Productos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Añadir producto sin código'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del producto *'),
      'Manzanas',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Precio por unidad'),
      '2,40',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Establecimiento'),
      'Frutería',
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(ElevatedButton, 'Guardar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(products.products.values.any((p) => p.nombre == 'Manzanas'), isTrue);
    expect(products.purchases.last.establecimiento, 'Frutería');
  });

  testWidgets('compras: lista, marcar, añadir y total', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Compras'));
    await tester.pumpAndSettle();
    expect(find.text('1 de 3 comprados'), findsOneWidget);

    await tester.tap(find.text('Súper'));
    await tester.pumpAndSettle();
    expect(find.text('Total estimado (2 sin precio)'), findsOneWidget);
    expect(find.text('1,05\u00A0€'), findsOneWidget);
    expect(
      find.textContaining('Ref: 1,05\u00A0€ (Súper Centro)'),
      findsOneWidget,
    );
    expect(find.text('Comprados (1)'), findsOneWidget);

    await tester.tap(find.text('Leche entera'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar precio'), findsWidgets);
    expect(find.text('Comprados (2)'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Tomates 1 kg');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Tomates'), findsOneWidget);
    expect(find.text('1 kg'), findsOneWidget);
  });
}
