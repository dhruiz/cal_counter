import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/cooking_pot_repository_impl.dart';
import 'package:cal_counter/data/repositories/drift_transaction_runner.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/data/repositories/shopping_list_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/usecases/recipe_food.dart';
import 'package:cal_counter/presentation/providers/data_provider.dart';
import 'package:cal_counter/presentation/views/main_shell.dart';
import 'package:cal_counter/presentation/views/recipe_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

NutritionFacts _n(double kcal, double p, double g, double c) =>
    NutritionFacts(kcal: kcal, proteinas: p, grasas: g, carbohidratos: c);

/// Recetas como alimentos: peso final, aviso de aproximado en el contador,
/// ingredientes desde el buscador, escala y lista de compra.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  late AppDatabase db;
  late FoodRepositoryImpl foods;
  late RecipeRepositoryImpl recipes;
  late ShoppingListRepositoryImpl shopping;
  late int arrozId, aceiteId, recetaId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      kProduceCatalogVersionKey: kProduceCatalogVersion,
    });
    db = memoryDb();
    foods = FoodRepositoryImpl(db);
    recipes = RecipeRepositoryImpl(db);
    shopping = ShoppingListRepositoryImpl(db);
    arrozId = await foods.saveFood(
      Food(nombre: 'Arroz redondo', nutricion: _n(350, 7, 1, 78)),
    );
    aceiteId = await foods.saveFood(
      Food(
        nombre: 'Aceite de oliva',
        unidad: FoodUnit.ml,
        nutricion: _n(900, 0, 100, 0),
      ),
    );
    await foods.savePortion(
      FoodPortion(alimentoId: aceiteId, nombre: 'cucharada', gramos: 10),
    );
    final tx = DriftTransactionRunner(db);
    recetaId =
        await SaveRecipe(recipes, SyncRecipeFoods(recipes, foods, tx), tx)(
          Recipe(
            nombre: 'Arroz blanco',
            porciones: 2,
            ingredientes: [
              RecipeIngredient(
                texto: '200 g de arroz redondo',
                alimentoId: arrozId,
                cantidad: 200,
                unidad: 'g',
              ),
            ],
          ),
        );
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, Widget home) async {
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

  testWidgets('peso final con la olla descontada', (tester) async {
    await pumpApp(tester, RecipeDetailView(recipeId: recetaId));
    expect(find.text('Nutrición (aproximada)'), findsOneWidget);
    expect(find.textContaining('falta el peso final'), findsOneWidget);
    expect(
      find.text('En tus alimentos como «Arroz blanco · Receta»'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Introducir'));
    await tester.pumpAndSettle();
    expect(find.text('Peso final'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('peso_total')), '1500');
    await tester.pump();
    // Guarda la olla con su peso.
    await tester.enterText(find.byKey(const Key('peso_olla')), '1000');
    await tester.pump();
    await tester.tap(find.text('Guardar olla'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Olla grande',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar').last);
    await tester.pumpAndSettle();
    expect(find.text('Olla grande · 1000 g'), findsOneWidget);
    expect(find.text('Peso de la preparación: 500 g'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Nutrición'), findsOneWidget);
    expect(find.textContaining('Peso final: 500 g'), findsOneWidget);
    final r = (await tester.runAsync(() => recipes.get(recetaId)))!;
    expect(r.pesoFinalG, 500);
    final f = (await tester.runAsync(() => foods.getFood(r.alimentoId!)))!;
    expect(f.aproximado, isFalse);
    expect(f.nutricion.kcal, 140);
    final pots = (await tester.runAsync(CookingPotRepositoryImpl().getAll))!;
    expect(pots.single.gramos, 1000);
    await unmount(tester);
  });

  testWidgets('el contador avisa de que la tabla es aproximada', (
    tester,
  ) async {
    await pumpApp(tester, const MainShell());
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'arroz blanco');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Arroz blanco'), findsOneWidget);
    expect(find.text('Aproximado'), findsOneWidget);
    await tester.tap(find.text('Arroz blanco'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('no se ha introducido el peso total final'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('escalar la receta y llevarla a la lista como mínimo', (
    tester,
  ) async {
    await pumpApp(tester, RecipeDetailView(recipeId: recetaId));
    await tester.scrollUntilVisible(find.text('200 g de arroz redondo'), 200);
    expect(find.text('2 raciones'), findsOneWidget);
    expect(find.text('200 g de arroz redondo'), findsOneWidget);
    await tester.tap(find.byTooltip('Más'));
    await tester.pumpAndSettle();
    expect(find.text('3 raciones'), findsOneWidget);
    expect(find.text('300 g de arroz redondo'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Añadir a la lista de compra'),
      200,
    );
    await tester.tap(find.text('Añadir a la lista de compra'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cantidades a ×1,5'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Añadir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 artículo añadido'), findsOneWidget);

    final listas = (await tester.runAsync(() => shopping.watchLists().first))!;
    final items = (await tester.runAsync(
      () => shopping.getItems(listas.single.id!),
    ))!;
    expect(items.single.texto, 'Arroz redondo');
    expect(items.single.cantidad, '300 g');
    expect(items.single.cantidadMinima, 300);
    await unmount(tester);
  });

  testWidgets('ideas: sugerir una receta y ordenar', (tester) async {
    await pumpApp(tester, const MainShell());
    await tester.tap(find.text('Recetas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sugiéreme algo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué tal esta?'), findsOneWidget);
    expect(find.text('Arroz blanco'), findsWidgets);
    expect(find.text('Aún no la has marcado como preparada.'), findsOneWidget);
    await tester.tap(find.text('Ver receta'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeDetailView), findsOneWidget);

    // «La he preparado hoy» y la lista lo muestra.
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('La he preparado hoy'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Por nombre'));
    await tester.pumpAndSettle();
    expect(find.text('Favoritas primero'), findsOneWidget);
    expect(find.text('hoy'), findsOneWidget);
    await tester.tap(find.text('Favoritas primero'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hace más tiempo que no la preparas').last);
    await tester.pumpAndSettle();
    expect(find.text('Hace más tiempo que no la preparas'), findsOneWidget);
    await unmount(tester);
  });
}
