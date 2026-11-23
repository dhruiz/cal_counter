import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/drift_transaction_runner.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/meal_repository_impl.dart';
import 'package:cal_counter/data/repositories/purchase_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/data/repositories/shopping_list_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/purchase.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/entities/shopping_list.dart';
import 'package:cal_counter/domain/errors/domain_errors.dart';
import 'package:cal_counter/domain/repositories/food_repository.dart';
import 'package:cal_counter/domain/usecases/add_ingredients_to_shopping_list.dart';
import 'package:cal_counter/domain/usecases/cart.dart';
import 'package:cal_counter/domain/usecases/food_registration.dart';
import 'package:cal_counter/domain/usecases/purge_old_purchases.dart';
import 'package:cal_counter/domain/usecases/register_purchase.dart';
import 'package:cal_counter/domain/usecases/save_meal_as_food.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

const _completa = NutritionFacts.basica(
  kcal: 100,
  proteinas: 10,
  grasas: 2,
  carbohidratos: 11,
);

void main() {
  late AppDatabase db;
  late FoodRepositoryImpl foods;
  late PurchaseRepositoryImpl purchases;
  late ShoppingListRepositoryImpl shopping;
  late RecipeRepositoryImpl recipes;
  late MealRepositoryImpl meals;
  late DriftTransactionRunner tx;

  setUp(() {
    db = memoryDb();
    foods = FoodRepositoryImpl(db);
    purchases = PurchaseRepositoryImpl(db);
    shopping = ShoppingListRepositoryImpl(db);
    recipes = RecipeRepositoryImpl(db);
    meals = MealRepositoryImpl(db);
    tx = DriftTransactionRunner(db);
  });

  tearDown(() => db.close());

  Future<int> food(
    String nombre, {
    String marca = '',
    NutritionFacts n = _completa,
    FoodType tipo = FoodType.generico,
  }) => foods.saveFood(
    Food(nombre: nombre, marca: marca, nutricion: n, tipo: tipo),
  );

  group('esquema', () {
    test('claves foráneas activas', () async {
      final r = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(r.data.values.first, 1);
    });

    test('borrar una comida borra sus items en cascada', () async {
      final mealId = await meals.createMeal('Comida_1', DateTime(2026, 1, 1));
      await meals.addItemToMeal(
        MealItem(
          mealId: mealId,
          alimento: 'X',
          cantidad: 100,
          grasas: 1,
          carbohidratos: 1,
          proteinas: 1,
          kcal: 10,
        ),
      );
      expect(await meals.hasMealItems(), isTrue);
      await meals.deleteMeal(mealId);
      expect(await meals.hasMealItems(), isFalse);
    });
  });

  group('alimentos', () {
    test('búsqueda sin tildes, por prefijo, plurales y sinónimos', () async {
      await food('Plátano de Canarias');
      await food('Patata cocida');
      await food('Leche semidesnatada', marca: 'Hacendado');

      final r1 = await foods.search('platano');
      expect(r1.map((f) => f.nombre), ['Plátano de Canarias']);
      final r2 = await foods.search('plat can');
      expect(r2.single.nombre, 'Plátano de Canarias');
      final r3 = await foods.search('papas'); // sinónimo regional
      expect(r3.single.nombre, 'Patata cocida');
      final r4 = await foods.search('hacendado'); // por marca
      expect(r4.single.nombre, 'Leche semidesnatada');
    });

    test(
      'búsqueda por código de barras normalizado (UPC-A → EAN-13)',
      () async {
        final id = await food('Galletas', marca: 'X', tipo: FoodType.envasado);
        await foods.savePackage(
          FoodPackage(alimentoId: id, codigoBarras: '012345678905'),
        );
        final r = await foods.search('0012345678905');
        expect(r.single.id, id);
        final m = await foods.findByBarcode('012345678905');
        expect(m!.food.id, id);
        expect(m.package.codigoBarras, '0012345678905');
      },
    );

    test('duplicados por nombre y marca (sin tildes ni mayúsculas)', () async {
      await food('Plátano');
      expect(() => food('platano'), throwsA(isA<DuplicateFoodException>()));
      // Misma palabra con otra marca sí se permite.
      await food('Plátano', marca: 'Canarias');
    });

    test('editar conserva id, uso y vínculos (sin REPLACE)', () async {
      final id = await food('Arroz');
      await foods.incrementUsage(id);
      final f = (await foods.getFood(id))!;
      await foods.saveFood(f.copyWith(nombre: 'Arroz blanco'));
      final g = (await foods.getFood(id))!;
      expect(g.nombre, 'Arroz blanco');
      expect(g.usoCount, 1);
      expect(g.uuid, f.uuid);
    });

    test(
      'pendientes: sin tabla, con prioridad a los usados en recetas',
      () async {
        final a = await food('Tomate triturado', n: NutritionFacts.vacia);
        final b = await food('Yogur', n: const NutritionFacts(kcal: 60));
        await food('Completo');
        await recipes.save(
          const Recipe(
            nombre: 'Salsa',
            ingredientes: [RecipeIngredient(texto: 'Yogur')],
          ).copyWith(
            ingredientes: [RecipeIngredient(texto: 'Yogur', alimentoId: b)],
          ),
        );
        final pend = await foods.watchPending().first;
        expect(pend.map((f) => f.id), [b, a]);
        expect(await foods.watchPendingCount().first, 2);
        final filtrados = await foods.search('', filter: FoodFilter.pendientes);
        expect(filtrados.length, 2);
      },
    );

    test('borrar sin compras borra; con compras archiva', () async {
      final a = await food('Sin historial');
      final b = await food('Con historial');
      final pid = await foods.defaultPackageId(b);
      await purchases.addPurchase(
        Purchase(
          presentacionId: pid,
          fecha: DateTime(2026, 11, 1),
          precioCent: 120,
          establecimiento: 'Súper',
        ),
      );
      expect(await foods.deleteFood(a), FoodDeletion.borrado);
      expect(await foods.getFood(a), isNull);
      expect(await foods.deleteFood(b), FoodDeletion.archivado);
      expect((await foods.getFood(b))!.archivado, isTrue);
      expect(await foods.search('historial'), isEmpty);
      expect(
        (await foods.search('historial', filter: FoodFilter.archivados)).length,
        1,
      );
    });

    test('código duplicado en otra presentación', () async {
      final a = await food('A', tipo: FoodType.envasado);
      final b = await food('B', tipo: FoodType.envasado);
      await foods.savePackage(
        FoodPackage(alimentoId: a, codigoBarras: '8410000000001'),
      );
      expect(
        () => foods.savePackage(
          FoodPackage(alimentoId: b, codigoBarras: '8410000000001'),
        ),
        throwsA(isA<DuplicateBarcodeException>()),
      );
    });

    test('porciones: alta, duplicado y borrado en cascada', () async {
      final id = await food('Ajo');
      await foods.savePortion(
        FoodPortion(alimentoId: id, nombre: 'diente', gramos: 5),
      );
      expect(
        () => foods.savePortion(
          FoodPortion(alimentoId: id, nombre: 'Diente', gramos: 6),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect((await foods.getPortionsFor([id]))[id]!.single.gramos, 5);
      await foods.deleteFood(id);
      expect(await foods.getPortionsFor([id]), isEmpty);
    });

    test('borrar un alimento desvincula ingredientes y comidas', () async {
      final id = await food('Cebolla');
      final rid = await recipes.save(
        Recipe(
          nombre: 'Sofrito',
          ingredientes: [
            RecipeIngredient(
              texto: '1 cebolla',
              alimentoId: id,
              cantidad: 1,
              unidad: 'unidad',
            ),
          ],
        ),
      );
      await foods.deleteFood(id);
      final r = await recipes.get(rid);
      expect(r!.ingredientes.single.alimentoId, isNull);
      expect(r.ingredientes.single.texto, '1 cebolla');
    });
  });

  group('compras', () {
    test(
      'establecimientos sin duplicar por mayúsculas, recientes primero',
      () async {
        final id = await food('Pan');
        final pid = await foods.defaultPackageId(id);
        Future<void> compra(String tienda, DateTime f) => purchases.addPurchase(
          Purchase(
            presentacionId: pid,
            fecha: f,
            precioCent: 100,
            establecimiento: tienda,
          ),
        );
        await compra('Mercado', DateTime(2026, 10, 1));
        await compra('  súper  ', DateTime(2026, 11, 1));
        await compra('mercado', DateTime(2026, 9, 1));
        expect(await purchases.getStoreNames(), ['súper', 'Mercado']);
      },
    );

    test('purga: 3 meses + la última de cada presentación', () async {
      final id = await food('Aceite');
      final p1 = await foods.defaultPackageId(id);
      final p2 = await foods.savePackage(
        FoodPackage(alimentoId: id, descripcion: '5 L'),
      );
      Future<int> compra(int pid, DateTime f) => purchases.addPurchase(
        Purchase(
          presentacionId: pid,
          fecha: f,
          precioCent: 500,
          establecimiento: 'S',
        ),
      );
      await compra(p1, DateTime(2026, 1, 1));
      await compra(p1, DateTime(2026, 11, 1));
      await compra(p2, DateTime(2026, 2, 1)); // vieja pero la última de p2
      final borradas = await PurgeOldPurchases(purchases)(
        now: DateTime(2026, 11, 23),
      );
      expect(borradas, 1);
      final restantes = await purchases.getPurchasesForFood(id);
      expect(restantes.length, 2);
    });

    test('RegisterPurchase sin presentación usa la de por defecto', () async {
      final id = await food('Plátanos');
      await RegisterPurchase(foods, purchases)(
        alimentoId: id,
        precioCent: 199,
        establecimiento: 'Frutería',
      );
      final last = await purchases.lastPurchaseForFood(id);
      expect(last!.compra.precioCent, 199);
      expect(last.presentacion.codigoBarras, isNull);
    });
  });

  group('alta en tienda', () {
    test('crea alimento pendiente + presentación con código', () async {
      final m = await RegisterFoodInStore(foods, tx)(
        nombre: 'Yogur griego',
        marca: 'Hacendado',
        presentacion: const PackageDraft(
          codigoBarras: '8480000123456',
          descripcion: 'Pack 4 × 125 g',
          contenido: 500,
        ),
      );
      expect(m.food.pendiente, isTrue);
      expect(m.food.tipo, FoodType.envasado);
      expect(m.package.codigoBarras, '8480000123456');
      expect(m.package.contenido, 500);
      expect(await foods.watchPendingCount().first, 1);
    });

    test('otro código para un alimento existente', () async {
      final id = await food('Leche', marca: 'Vaca', tipo: FoodType.envasado);
      final m = await RegisterFoodInStore(foods, tx)(
        nombre: '',
        alimentoExistenteId: id,
        presentacion: const PackageDraft(codigoBarras: '8410000000002'),
      );
      expect(m.food.id, id);
      expect((await foods.getPackages(id)).length, 1);
    });

    test('si falla el código no deja el alimento a medias', () async {
      final a = await food('A', tipo: FoodType.envasado);
      await foods.savePackage(
        FoodPackage(alimentoId: a, codigoBarras: '8410000000001'),
      );
      await expectLater(
        RegisterFoodInStore(foods, tx)(
          nombre: 'Nuevo',
          presentacion: const PackageDraft(codigoBarras: '8410000000001'),
        ),
        throwsA(isA<DuplicateBarcodeException>()),
      );
      expect(await foods.search('nuevo'), isEmpty);
    });
  });

  group('carrito', () {
    late int listaId;
    late Food leche;
    late AddToCart addToCart;

    setUp(() async {
      listaId = await shopping.createList('Semana');
      final id = await food('Leche entera', tipo: FoodType.envasado);
      leche = (await foods.getFood(id))!;
      addToCart = AddToCart(shopping, purchases, foods, tx);
    });

    test('marca el pendiente que coincide y registra la compra', () async {
      await shopping.addItem(ShoppingItem(listaId: listaId, texto: 'leches'));
      await addToCart(
        listaId: listaId,
        alimento: leche,
        precioCent: 95,
        unidades: 2,
        establecimiento: 'Súper',
      );
      final items = await shopping.getItems(listaId);
      final it = items.single;
      expect(it.comprado, isTrue);
      expect(it.alimentoId, leche.id);
      expect(it.unidades, 2);
      expect(it.precioCent, 95);
      expect(it.subtotalCent, 190);
      expect((await purchases.getPurchasesForFood(leche.id!)).length, 1);
    });

    test('repetir suma unidades sobre la misma compra', () async {
      await addToCart(
        listaId: listaId,
        alimento: leche,
        precioCent: 95,
        establecimiento: 'Súper',
      );
      await addToCart(
        listaId: listaId,
        alimento: leche,
        precioCent: 99,
        establecimiento: 'Súper',
      );
      final it = (await shopping.getItems(listaId)).single;
      expect(it.unidades, 2);
      expect(it.precioCent, 99);
      expect((await purchases.getPurchasesForFood(leche.id!)).length, 1);
    });

    test('desmarcar conserva la compra; quitar del carrito la borra', () async {
      await addToCart(
        listaId: listaId,
        alimento: leche,
        precioCent: 95,
        establecimiento: 'Súper',
      );
      var it = (await shopping.getItems(listaId)).single;
      await shopping.setItemBought(it.id!, false);
      it = (await shopping.getItems(listaId)).single;
      expect(it.compraId, isNull);
      expect((await purchases.getPurchasesForFood(leche.id!)).length, 1);

      await addToCart(
        listaId: listaId,
        alimento: leche,
        precioCent: 97,
        establecimiento: 'Súper',
      );
      it = (await shopping.getItems(listaId)).single;
      await RemoveFromCart(shopping, purchases, tx)(it);
      it = (await shopping.getItems(listaId)).single;
      expect(it.comprado, isFalse);
      expect((await purchases.getPurchasesForFood(leche.id!)).length, 1);
    });

    test('UpdateCartItem corrige precio y unidades', () async {
      await addToCart(
        listaId: listaId,
        alimento: leche,
        precioCent: 95,
        establecimiento: 'Súper',
      );
      var it = (await shopping.getItems(listaId)).single;
      await UpdateCartItem(shopping, purchases, tx)(
        item: it,
        precioCent: 120,
        unidades: 3,
      );
      it = (await shopping.getItems(listaId)).single;
      expect(it.subtotalCent, 360);
    });

    test('precio de referencia: última compra del alimento', () async {
      final otra = await shopping.createList('Otra');
      await addToCart(
        listaId: otra,
        alimento: leche,
        precioCent: 89,
        establecimiento: 'Mercado',
      );
      await shopping.addItem(
        ShoppingItem(listaId: listaId, texto: 'Leche', alimentoId: leche.id),
      );
      final it = (await shopping.getItems(listaId)).single;
      expect(it.precioReferenciaCent, 89);
      expect(it.establecimientoReferencia, 'Mercado');
    });

    test('ingredientes de receta heredan el vínculo y no se repiten', () async {
      final add = AddIngredientsToShoppingList(shopping);
      final n = await add(
        listaId: listaId,
        ingredientes: [
          RecipeIngredient(texto: '1 L de leche', alimentoId: leche.id),
          const RecipeIngredient(texto: '200 g de harina'),
          const RecipeIngredient(texto: 'Harina'),
        ],
      );
      expect(n, 2);
      final items = await shopping.getItems(listaId);
      expect(items.first.alimentoId, leche.id);
      expect(items.first.cantidad, '1 L');
    });

    test('borrar la lista conserva las compras', () async {
      await addToCart(
        listaId: listaId,
        alimento: leche,
        precioCent: 95,
        establecimiento: 'Súper',
      );
      await shopping.deleteList(listaId);
      expect((await purchases.getPurchasesForFood(leche.id!)).length, 1);
    });
  });

  group('recetas', () {
    test('guarda ingredientes vinculados con cantidad y unidad', () async {
      final ajo = await food('Ajo');
      final id = await recipes.save(
        Recipe(
          nombre: 'Ajoblanco',
          porciones: 4,
          ingredientes: [
            RecipeIngredient(
              texto: '2 dientes de ajo',
              alimentoId: ajo,
              cantidad: 2,
              unidad: 'diente',
            ),
            const RecipeIngredient(texto: 'Sal'),
          ],
        ),
      );
      final r = (await recipes.get(id))!;
      expect(r.uuid, isNotNull);
      expect(r.ingredientes.first.unidad, 'diente');
      expect(r.ingredientes.last.alimentoId, isNull);
      final usando = await recipes.watchUsingFood(ajo).first;
      expect(usando.single.id, id);
    });
  });

  group('comidas', () {
    test(
      'watchDay agrupa items y updateMealItem escala por proporción',
      () async {
        final day = DateTime(2026, 11, 23);
        final mealId = await meals.createMeal('Comida_1', day);
        final itemId = await meals.addItemToMeal(
          MealItem(
            mealId: mealId,
            alimento: 'Arroz',
            cantidad: 100,
            grasas: 1,
            carbohidratos: 78,
            proteinas: 7,
            kcal: 350,
          ),
        );
        await meals.updateMealItem(itemId, 50);
        final dia = await meals.watchDay(day).first;
        final item = dia.single.items.single;
        expect(item.cantidad, 50);
        expect(item.kcal, 175);
        expect(item.carbohidratos, 39);
      },
    );

    test('CSV diario: TAB, cabecera fija y total', () async {
      final day = DateTime(2023, 12, 1);
      final mealId = await meals.createMeal('Comida_Test', day);
      await meals.addItemToMeal(
        MealItem(
          mealId: mealId,
          alimento: 'Test Food',
          cantidad: 100,
          grasas: 5,
          carbohidratos: 10,
          proteinas: 15,
          kcal: 150,
        ),
      );
      final csv = await meals.buildDayCsv(day);
      expect(
        csv,
        contains(
          'nombre_comida\tcantidad\talimento\tgrasas\tcarbos\tproteinas\tkcal',
        ),
      );
      expect(csv, contains('Comida_Test\t100.0\tTest Food'));
      expect(csv, contains('\tTotal\t5.0\t10.0\t15.0\t150.0'));
    });

    test('guardar comida como alimento: actualiza sin cambiar el id', () async {
      final save = SaveMealAsFood(foods);
      final items = [
        const MealItem(
          mealId: 1,
          alimento: 'A',
          cantidad: 200,
          grasas: 10,
          carbohidratos: 40,
          proteinas: 20,
          kcal: 330,
        ),
      ];
      final id = await save(name: 'Mi guiso', items: items);
      final f = (await foods.getFood(id))!;
      expect(f.tipo, FoodType.preparado);
      expect(f.nutricion.kcal, 165);
      final id2 = await save(
        name: 'Mi guiso',
        items: items,
        totalGrams: 400,
        sobrescribir: f,
      );
      expect(id2, id);
      expect((await foods.getFood(id))!.nutricion.kcal, 82.5);
    });
  });
}
