import 'dart:io';

import 'package:cal_counter/data/datasources/local_data_source.dart';
import 'package:cal_counter/data/datasources/module_tables.dart';
import 'package:cal_counter/data/datasources/product_local_data_source.dart';
import 'package:cal_counter/data/datasources/recipe_local_data_source.dart';
import 'package:cal_counter/data/datasources/shopping_local_data_source.dart';
import 'package:cal_counter/data/repositories/product_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/data/repositories/shopping_list_repository_impl.dart';
import 'package:cal_counter/domain/entities/product.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/entities/shopping_list.dart';
import 'package:cal_counter/domain/usecases/add_ingredients_to_shopping_list.dart';
import 'package:cal_counter/domain/usecases/add_product_to_cart.dart';
import 'package:cal_counter/domain/usecases/remove_from_cart.dart';
import 'package:cal_counter/domain/usecases/update_cart_item.dart';
import 'package:cal_counter/domain/usecases/export_price_history_csv.dart';
import 'package:cal_counter/domain/usecases/import_recipes.dart';
import 'package:cal_counter/domain/usecases/purge_old_purchases.dart';
import 'package:cal_counter/domain/usecases/register_purchase.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final testDir = join('.', 'test_tmp_modules_data_source');
  late LocalDataSourceImpl core;
  late RecipeRepositoryImpl recipes;
  late ProductRepositoryImpl products;
  late ShoppingListRepositoryImpl shopping;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    Directory(testDir).createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => testDir,
        );
    core = LocalDataSourceImpl();
    await core.initDb();
    recipes = RecipeRepositoryImpl(RecipeLocalDataSourceImpl(core));
    products = ProductRepositoryImpl(ProductLocalDataSourceImpl(core));
    shopping = ShoppingListRepositoryImpl(ShoppingLocalDataSourceImpl(core));
  });

  tearDown(() async {
    await core.close();
    await databaseFactory.deleteDatabase(join(testDir, 'db_ctrl_calorias.db'));
    final dir = Directory(testDir);
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('recetas', () {
    test('guardar, leer, actualizar ingredientes y borrar', () async {
      final id = await recipes.saveRecipe(
        const Recipe(
          nombre: 'Tortilla',
          porciones: 4,
          ingredientes: ['4 huevos', ' ', '500 g de patatas'],
          elaboracion: 'Freír\nCuajar',
        ),
      );
      var r = await recipes.getRecipe(id);
      expect(r!.ingredientes, ['4 huevos', '500 g de patatas']);
      expect(r.pasos, ['Freír', 'Cuajar']);

      await recipes.saveRecipe(
        r.copyWith(
          ingredientes: ['3 huevos'],
          alimentoId: 7,
          pesoPorcionG: 150,
        ),
      );
      r = await recipes.getRecipe(id);
      expect(r!.ingredientes, ['3 huevos']);
      expect(r.alimentoId, 7);
      expect(r.pesoPorcionG, 150);

      await recipes.setFavorite(id, true);
      expect((await recipes.getAllRecipes()).single.favorita, isTrue);

      await recipes.deleteRecipe(id);
      expect(await recipes.getAllRecipes(), isEmpty);
      final db = await core.database;
      final orphans = await db.query('ingredientes_receta');
      expect(orphans, isEmpty);
    });

    test('favoritas primero, luego alfabético', () async {
      await recipes.saveRecipe(const Recipe(nombre: 'banana split'));
      await recipes.saveRecipe(const Recipe(nombre: 'Zumo', favorita: true));
      await recipes.saveRecipe(const Recipe(nombre: 'Arroz'));
      final names = (await recipes.getAllRecipes()).map((r) => r.nombre);
      expect(names, ['Zumo', 'Arroz', 'banana split']);
    });

    test('ImportRecipes omite duplicados por nombre', () async {
      await recipes.saveRecipe(const Recipe(nombre: 'Gazpacho'));
      final saved = await ImportRecipes(recipes)([
        const Recipe(nombre: 'gazpacho'),
        const Recipe(nombre: 'Salmorejo'),
        const Recipe(nombre: 'SALMOREJO'),
      ]);
      expect(saved, 1);
      expect((await recipes.getAllRecipes()).length, 2);
    });
  });

  group('productos y compras', () {
    test('código de barras único y búsqueda por código', () async {
      final id = await products.saveProduct(
        const Product(codigoBarras: '8410001', nombre: 'Leche', marca: 'X'),
      );
      expect((await products.getProductByBarcode('8410001'))!.id, id);
      expect(await products.getProductByBarcode('000'), isNull);
      expect(
        () => products.saveProduct(
          const Product(codigoBarras: '8410001', nombre: 'Otra'),
        ),
        throwsStateError,
      );
      // Varios productos sin código (NULL) no chocan con el UNIQUE.
      await products.saveProduct(
        const Product(codigoBarras: '', nombre: 'Pan'),
      );
      await products.saveProduct(const Product(nombre: 'Fruta'));
      expect((await products.getProducts()).length, 3);
    });

    test('última compra, tiendas y purga que conserva la última', () async {
      final leche = await products.saveProduct(const Product(nombre: 'Leche'));
      final pan = await products.saveProduct(const Product(nombre: 'Pan'));
      final register = RegisterPurchase(products);
      await register(
        productoId: leche,
        precio: 0.8,
        establecimiento: 'A',
        fecha: DateTime(2026, 1, 10),
      );
      await register(
        productoId: leche,
        precio: 0.9,
        establecimiento: 'B ',
        fecha: DateTime(2026, 6, 1),
      );
      await register(
        productoId: leche,
        precio: 1.0,
        establecimiento: 'A',
        fecha: DateTime(2026, 11, 1),
      );
      await register(
        productoId: pan,
        precio: 1.2,
        establecimiento: 'C',
        fecha: DateTime(2026, 2, 1),
      );

      expect(
        () => register(productoId: pan, precio: 0, establecimiento: 'C'),
        throwsArgumentError,
      );

      final all = await products.getProducts();
      expect(all.firstWhere((p) => p.id == leche).ultimaCompra!.precio, 1.0);
      expect(await products.getStores(), ['A', 'B', 'C']); // por fecha reciente

      final deleted = await PurgeOldPurchases(products)(
        now: DateTime(2026, 11, 23),
      );
      expect(
        deleted,
        2,
      ); // leche 10/01 y 01/06; el pan conserva su única compra
      expect((await products.getPurchases(leche)).map((c) => c.precio), [1.0]);
      expect((await products.getPurchases(pan)).length, 1);

      final tsv = await ExportPriceHistoryCsv(products)(
        now: DateTime(2026, 11, 23),
      );
      final lines = tsv.trim().split('\n');
      expect(lines.length, 2); // cabecera + compra de leche de noviembre
      expect(lines[1], startsWith('2026-11-01\t\tLeche'));
    });

    test('borrar producto elimina compras y desvincula listas', () async {
      final id = await products.saveProduct(const Product(nombre: 'Café'));
      await products.addPurchase(
        Purchase(
          productoId: id,
          fecha: DateTime(2026, 11, 1),
          precio: 3,
          establecimiento: 'A',
        ),
      );
      final lista = await shopping.createList('Semana');
      await shopping.addItem(
        ShoppingItem(listaId: lista, texto: 'Café', productoId: id),
      );

      var items = await shopping.getItems(lista);
      expect(items.single.precioReferencia, 3);
      expect(items.single.establecimientoReferencia, 'A');

      await products.deleteProduct(id);
      expect(await products.getPurchases(id), isEmpty);
      items = await shopping.getItems(lista);
      expect(items.single.productoId, isNull);
      expect(items.single.precioReferencia, isNull);
    });
  });

  group('listas de compra', () {
    test('contadores, orden, marcar y limpiar', () async {
      final id = await shopping.createList('Súper');
      final a = await shopping.addItem(
        ShoppingItem(listaId: id, texto: 'Leche', cantidad: '2 L'),
      );
      await shopping.addItem(
        ShoppingItem(listaId: id, texto: 'Pan', cantidad: ' '),
      );
      await shopping.addItem(ShoppingItem(listaId: id, texto: 'Huevos'));

      await shopping.setItemBought(a, true);
      var items = await shopping.getItems(id);
      expect(items.map((i) => i.texto), ['Pan', 'Huevos', 'Leche']);
      expect(items[0].cantidad, isNull);

      var lists = await shopping.getLists();
      expect(lists.single.totalItems, 3);
      expect(lists.single.comprados, 1);

      await shopping.deleteBoughtItems(id);
      expect((await shopping.getItems(id)).length, 2);

      await shopping.setAllBought(id, true);
      lists = await shopping.getLists();
      expect(lists.single.comprados, 2);

      final item = (await shopping.getItems(id)).first;
      await shopping.updateItem(
        ShoppingItem(
          id: item.id,
          listaId: id,
          texto: 'Pan integral',
          comprado: false,
        ),
      );
      items = await shopping.getItems(id);
      expect(items.first.texto, 'Pan integral');
      expect(items.first.comprado, isFalse);

      await shopping.renameList(id, 'Mercado');
      expect((await shopping.getLists()).single.nombre, 'Mercado');

      await shopping.deleteList(id);
      expect(await shopping.getLists(), isEmpty);
      final db = await core.database;
      expect(await db.query('items_lista_compra'), isEmpty);
    });

    test(
      'AddIngredientsToShoppingList separa cantidad y evita repetidos',
      () async {
        final id = await shopping.createList('Receta');
        final add = AddIngredientsToShoppingList(shopping);
        final n = await add(
          listaId: id,
          lineas: ['500 g de patatas', '4 huevos', 'Patatas'],
        );
        expect(n, 2);
        final items = await shopping.getItems(id);
        expect(items.map((i) => (i.texto, i.cantidad)), [
          ('Patatas', '500 g'),
          ('Huevos', '4'),
        ]);
      },
    );
  });

  group('modo carrito', () {
    test(
      'migración añade las columnas del carrito a una tabla antigua',
      () async {
        final db = await core.database;
        await db.execute('DROP TABLE items_lista_compra');
        await db.execute('''
        CREATE TABLE items_lista_compra (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          lista_id INTEGER NOT NULL,
          texto TEXT NOT NULL,
          cantidad TEXT,
          producto_id INTEGER,
          comprado INTEGER NOT NULL DEFAULT 0,
          orden INTEGER NOT NULL
        )
      ''');
        await db.insert('items_lista_compra', {
          'lista_id': 1,
          'texto': 'Antiguo',
          'orden': 1,
        });
        await createModuleTables(db);
        final cols = (await db.rawQuery(
          'PRAGMA table_info(items_lista_compra)',
        )).map((r) => r['name']).toSet();
        expect(cols, containsAll(['unidades', 'precio_pagado', 'compra_id']));
        final item = (await shopping.getItems(1)).single;
        expect(item.unidades, 1);
        expect(item.precioPagado, isNull);
      },
    );

    test('AddProductToCart: marca, registra, suma unidades y crea', () async {
      final leche = await products.saveProduct(
        const Product(codigoBarras: '111', nombre: 'Leche entera'),
      );
      final cafe = await products.saveProduct(
        const Product(codigoBarras: '222', nombre: 'Café'),
      );
      final lista = await shopping.createList('Súper');
      // Texto sin vincular que coincide por tokens con el producto.
      await shopping.addItem(ShoppingItem(listaId: lista, texto: 'Leche'));
      final add = AddProductToCart(shopping, products);
      final lecheP = (await products.getProduct(leche))!;
      final cafeP = (await products.getProduct(cafe))!;

      var item = await add(
        listaId: lista,
        producto: lecheP,
        precio: 1.049,
        establecimiento: ' Súper  Centro ',
      );
      expect(item.texto, 'Leche'); // marcó el artículo existente
      expect(item.productoId, leche);
      expect(item.comprado, isTrue);
      expect(item.precioPagado, 1.05);
      var compras = await products.getPurchases(leche);
      expect(compras.single.establecimiento, 'Súper Centro');
      expect(item.compraId, compras.single.id);

      // Segundo escaneo: más unidades, sin nueva compra; precio corregido.
      item = await add(
        listaId: lista,
        producto: lecheP,
        precio: 1.10,
        unidades: 2,
        establecimiento: 'Súper Centro',
      );
      expect(item.unidades, 3);
      compras = await products.getPurchases(leche);
      expect(compras.length, 1);
      expect(compras.single.precio, 1.10);

      // No estaba en la lista: se añade ya comprado.
      item = await add(
        listaId: lista,
        producto: cafeP,
        precio: 3.2,
        establecimiento: 'Súper Centro',
      );
      final items = await shopping.getItems(lista);
      expect(items.length, 2);
      expect(items.every((i) => i.comprado), isTrue);
      expect(items.firstWhere((i) => i.texto == 'Café').subtotal, 3.2);

      expect(
        () => add(
          listaId: lista,
          producto: cafeP,
          precio: 0,
          establecimiento: 'X',
        ),
        throwsArgumentError,
      );
    });

    test(
      'marcado a mano sin precio: fija las unidades en vez de sumar',
      () async {
        final pan = await products.saveProduct(const Product(nombre: 'Pan'));
        final lista = await shopping.createList('Súper');
        final id = await shopping.addItem(
          ShoppingItem(listaId: lista, texto: 'Pan', productoId: pan),
        );
        await shopping.setItemBought(id, true);
        final item = await AddProductToCart(shopping, products)(
          listaId: lista,
          producto: (await products.getProduct(pan))!,
          precio: 1,
          unidades: 2,
          establecimiento: 'Panadería',
        );
        expect(item.unidades, 2);
      },
    );

    test('UpdateCartItem corrige la compra; RemoveFromCart la borra', () async {
      final leche = await products.saveProduct(const Product(nombre: 'Leche'));
      final lista = await shopping.createList('Súper');
      final add = AddProductToCart(shopping, products);
      final item = await add(
        listaId: lista,
        producto: (await products.getProduct(leche))!,
        precio: 1,
        establecimiento: 'A',
        fecha: DateTime(2026, 11, 20),
      );

      final updated = await UpdateCartItem(shopping, products)(
        item: item,
        precio: 1.25,
        unidades: 4,
      );
      expect(updated.subtotal, 5.0);
      final compra = (await products.getPurchases(leche)).single;
      expect(compra.precio, 1.25);
      expect(compra.fecha, DateTime(2026, 11, 20)); // conserva fecha y tienda
      expect(compra.establecimiento, 'A');

      await RemoveFromCart(shopping, products)(updated);
      expect(await products.getPurchases(leche), isEmpty);
      final back = (await shopping.getItems(lista)).single;
      expect(back.comprado, isFalse);
      expect(back.precioPagado, isNull);
      expect(back.unidades, 1);
    });

    test(
      'desmarcar todo saca del carrito pero conserva el historial',
      () async {
        final leche = await products.saveProduct(
          const Product(nombre: 'Leche'),
        );
        final lista = await shopping.createList('Semana');
        await AddProductToCart(shopping, products)(
          listaId: lista,
          producto: (await products.getProduct(leche))!,
          precio: 1,
          unidades: 2,
          establecimiento: 'A',
        );
        await shopping.setAllBought(lista, false);
        final item = (await shopping.getItems(lista)).single;
        expect(item.comprado, isFalse);
        expect(item.precioPagado, isNull);
        expect(item.compraId, isNull);
        expect(item.unidades, 1);
        expect((await products.getPurchases(leche)).length, 1);
      },
    );

    test(
      'artículo sin producto: el precio cuenta pero no va al historial',
      () async {
        final lista = await shopping.createList('Mercado');
        final id = await shopping.addItem(
          ShoppingItem(listaId: lista, texto: 'Manzanas'),
        );
        final item = (await shopping.getItems(
          lista,
        )).firstWhere((i) => i.id == id);
        final updated = await UpdateCartItem(shopping, products)(
          item: item,
          precio: 2.4,
          unidades: 1,
        );
        expect(updated.comprado, isTrue);
        expect(updated.subtotal, 2.4);
        final db = await core.database;
        expect(await db.query('compras'), isEmpty);
      },
    );
  });
}
