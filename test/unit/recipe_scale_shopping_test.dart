import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/shopping_list_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/services/ingredient_text.dart';
import 'package:cal_counter/domain/services/package_suggestion.dart';
import 'package:cal_counter/domain/usecases/add_ingredients_to_shopping_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

void main() {
  group('texto de los ingredientes', () {
    test('línea generada desde el alimento', () {
      expect(
        ingredientLine(
          nombreAlimento: 'Arroz redondo',
          cantidad: 200,
          unidad: 'g',
          nota: 'lavado',
        ),
        '200 g de arroz redondo, lavado',
      );
      expect(
        ingredientLine(nombreAlimento: 'Ajo', cantidad: 2, unidad: 'diente'),
        '2 dientes de ajo',
      );
      expect(
        ingredientLine(nombreAlimento: 'Ajo', cantidad: 1, unidad: 'diente'),
        '1 diente de ajo',
      );
      expect(
        ingredientLine(
          nombreAlimento: 'AOVE',
          cantidad: 1.5,
          unidad: 'cucharada',
        ),
        '1,5 cucharadas de AOVE',
      );
      expect(
        ingredientLine(nombreAlimento: 'Sal', opcional: true),
        'Sal (opcional)',
      );
      expect(pluralize('nuez'), 'nueces');
      expect(pluralize('unidad'), 'unidades');
      expect(humanQuantity(1250, 'g'), '1,25 kg');
      expect(humanQuantity(1500, 'ml'), '1,5 L');
      expect(humanQuantity(750, 'g'), '750 g');
    });

    test('líneas escaladas', () {
      expect(
        scaledIngredientText(
          texto: '200 g de arroz redondo',
          factor: 1.5,
          nombreAlimento: 'Arroz redondo',
          cantidad: 200,
          unidad: 'g',
        ),
        '300 g de arroz redondo',
      );
      expect(scaledIngredientText(texto: '4 huevos', factor: 1.5), '6 huevos');
      expect(scaledIngredientText(texto: '½ cebolla', factor: 2), '1 cebolla');
      expect(scaledIngredientText(texto: 'Sal', factor: 2), 'Sal (×2)');
      expect(scaledIngredientText(texto: '4 huevos', factor: 1), '4 huevos');
    });
  });

  group('envase sugerido', () {
    const kilo = FoodPackage(
      alimentoId: 1,
      descripcion: '1 kg',
      contenido: 1000,
    );
    const medio = FoodPackage(
      alimentoId: 1,
      descripcion: '500 g',
      contenido: 500,
    );

    test('el que menos sobra; a igualdad, menos unidades', () {
      final a = suggestPackage(750, [medio, kilo])!;
      expect(a.presentacion, kilo);
      expect(a.unidades, 1);
      final b = suggestPackage(1200, [medio, kilo])!;
      expect(b.presentacion, medio);
      expect(b.unidades, 3);
      expect(suggestPackage(100, const [FoodPackage(alimentoId: 1)]), isNull);
    });
  });

  group('lista de compra desde recetas', () {
    late AppDatabase db;
    late FoodRepositoryImpl foods;
    late ShoppingListRepositoryImpl shopping;
    late AddIngredientsToShoppingList add;
    late int listaId;

    setUp(() async {
      db = memoryDb();
      foods = FoodRepositoryImpl(db);
      shopping = ShoppingListRepositoryImpl(db);
      add = AddIngredientsToShoppingList(shopping, foods);
      listaId = await shopping.createList('Semana');
    });

    tearDown(() => db.close());

    test('cantidades escaladas como mínimo y sumadas entre recetas', () async {
      final arroz = await foods.saveFood(
        const Food(nombre: 'Arroz', nutricion: NutritionFacts(kcal: 350)),
      );
      final ajo = await foods.saveFood(const Food(nombre: 'Ajo'));
      await foods.savePortion(
        FoodPortion(alimentoId: ajo, nombre: 'diente', gramos: 5),
      );
      final perejil = await foods.saveFood(const Food(nombre: 'Perejil'));

      var r = await add(
        listaId: listaId,
        factor: 2,
        ingredientes: [
          RecipeIngredient(
            texto: '200 g de arroz',
            alimentoId: arroz,
            cantidad: 200,
            unidad: 'g',
          ),
          RecipeIngredient(
            texto: '2 dientes de ajo',
            alimentoId: ajo,
            cantidad: 2,
            unidad: 'diente',
          ),
          RecipeIngredient(
            texto: '1 ramillete de perejil',
            alimentoId: perejil,
            cantidad: 1,
            unidad: 'ramillete',
          ),
          const RecipeIngredient(texto: '4 huevos'),
        ],
      );
      expect(r.anadidos, 4);
      var items = await shopping.getItems(listaId);
      final byName = {for (final i in items) i.texto: i};
      expect(byName['Arroz']!.cantidad, '400 g');
      expect(byName['Arroz']!.cantidadMinima, 400);
      expect(byName['Ajo']!.cantidadMinima, 20);
      // Sin el peso de la porción: solo texto.
      expect(byName['Perejil']!.cantidad, '2 ramilletes');
      expect(byName['Perejil']!.cantidadMinima, isNull);
      expect(byName['Huevos']!.cantidad, '8 unidades');

      // Otra receta con arroz: se suma al que ya estaba.
      r = await add(
        listaId: listaId,
        ingredientes: [
          RecipeIngredient(
            texto: '700 g de arroz',
            alimentoId: arroz,
            cantidad: 700,
            unidad: 'g',
          ),
        ],
      );
      expect(r.anadidos, 0);
      expect(r.actualizados, 1);
      items = await shopping.getItems(listaId);
      final a = items.singleWhere((i) => i.alimentoId == arroz);
      expect(a.cantidadMinima, 1100);
      expect(a.cantidad, '1,1 kg');
    });
  });
}
