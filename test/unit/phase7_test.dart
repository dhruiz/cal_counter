import 'dart:io';

import 'package:cal_counter/data/backup/foods_tsv_codec.dart';
import 'package:cal_counter/data/backup/full_backup.dart';
import 'package:cal_counter/data/backup/repertoire_codec.dart';
import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/category_repository_impl.dart';
import 'package:cal_counter/data/repositories/drift_transaction_runner.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/purchase_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/data/repositories/scale_repository_impl.dart';
import 'package:cal_counter/data/repositories/shopping_list_repository_impl.dart';
import 'package:cal_counter/domain/entities/category.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/purchase.dart';
import 'package:cal_counter/domain/entities/shopping_list.dart';
import 'package:cal_counter/domain/errors/domain_errors.dart';
import 'package:cal_counter/domain/repositories/food_repository.dart';
import 'package:cal_counter/domain/services/aisle_grouping.dart';
import 'package:cal_counter/domain/services/category_guesser.dart';
import 'package:cal_counter/domain/services/scale_barcode.dart';
import 'package:cal_counter/domain/usecases/cart.dart';
import 'package:cal_counter/domain/usecases/repertoire_exchange.dart';
import 'package:cal_counter/domain/usecases/scale_labels.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

/// EAN-13 de báscula con dígito de control correcto.
String scaleCode(String doce) {
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = doce.codeUnitAt(11 - i) - 48;
    sum += i.isEven ? d * 3 : d;
  }
  return '$doce${(10 - sum % 10) % 10}';
}

void main() {
  group('adivinar categoría', () {
    test('por palabra, frase y posición', () {
      expect(guessCategoryName('Pechuga de pollo'), 'Carnicería');
      expect(guessCategoryName('Plátanos de Canarias'), 'Frutas y verduras');
      expect(guessCategoryName('Leche semidesnatada'), 'Lácteos y huevos');
      expect(guessCategoryName('Tomate frito'), 'Despensa');
      expect(guessCategoryName('Atún claro en aceite'), 'Despensa');
      expect(guessCategoryName('Zumo de naranja'), 'Bebidas');
      expect(guessCategoryName('Yogur de fresa'), 'Lácteos y huevos');
      expect(guessCategoryName('Queso curado'), 'Charcutería y quesos');
      expect(guessCategoryName('Queso fresco'), 'Lácteos y huevos');
      expect(guessCategoryName('Pasta de dientes'), 'Higiene y cuidado personal');
      expect(guessCategoryName('Helado de chocolate'), 'Congelados');
      expect(guessCategoryName('Detergente líquido'), 'Limpieza');
      expect(guessCategoryName('Cosa rara'), isNull);
    });
  });

  group('esquema v2', () {
    test('instalación nueva: categorías por defecto en orden', () async {
      final db = memoryDb();
      final cats = await CategoryRepositoryImpl(db).getCategories();
      expect(cats.map((c) => c.nombre), [
        for (final c in defaultCategories) c.nombre,
      ]);
      await db.close();
    });

    test('migración v1 → v2 conserva los datos y clasifica', () async {
      final sql = File('test/fixtures/schema_v1.sql').readAsStringSync();
      final executor = NativeDatabase.memory(
        setup: (raw) {
          for (final stmt in sql.split(RegExp(r'^--\s*$', multiLine: true))) {
            final s = stmt
                .split('\n')
                .where((l) => !l.startsWith('--'))
                .join('\n')
                .trim();
            if (s.isNotEmpty) raw.execute(s);
          }
          raw.execute(
            "INSERT INTO alimentos (uuid, nombre, marca, tipo, unidad, kcal, "
            "creado, actualizado) VALUES "
            "('u1', 'Pechuga de pollo', '', 'generico', 'g', 120, 'x', 'x'), "
            "('u2', 'Cosa rara', '', 'generico', 'g', NULL, 'x', 'x')",
          );
          raw.execute(
            "INSERT INTO presentaciones (uuid, alimento_id, codigo_barras, "
            "creado, actualizado) VALUES ('p1', 1, '8410000000001', 'x', 'x')",
          );
          raw.execute(
            "INSERT INTO establecimientos (nombre) VALUES ('Súper')",
          );
          raw.execute(
            "INSERT INTO compras (presentacion_id, establecimiento_id, fecha, "
            "precio_cent) VALUES (1, 1, '2026-11-01', 450)",
          );
          raw.execute('PRAGMA user_version = 1');
        },
      );
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(executor);
      final foods = FoodRepositoryImpl(db);
      final cats = CategoryRepositoryImpl(db);

      final pollo = (await foods.findByNameAndBrand('Pechuga de pollo', ''))!;
      final carne = (await cats.getCategories()).firstWhere(
        (c) => c.nombre == 'Carnicería',
      );
      expect(pollo.categoriaId, carne.id);
      expect((await foods.findByNameAndBrand('Cosa rara', ''))!.categoriaId,
          isNull);
      // FTS, compras y claves foráneas siguen funcionando.
      expect((await foods.search('pollo')).single.id, pollo.id);
      final compras = await PurchaseRepositoryImpl(db).getPurchasesForFood(
        pollo.id!,
      );
      expect(compras.single.compra.precioCent, 450);
      expect(compras.single.compra.pesoG, isNull);
      final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(fk.data.values.first, 1);
      final store = await ScaleRepositoryImpl(db).getStore('súper');
      expect(store!.longitudClave, 7);
      expect(store.formatoBascula, isNull);

      // Mismas tablas e índices que una instalación nueva.
      Future<Set<String>> esquema(AppDatabase d) async => {
        for (final r in await d
            .customSelect(
              "SELECT type || ':' || name AS n FROM sqlite_master "
              "WHERE name NOT LIKE 'sqlite_%'",
            )
            .get())
          r.read<String>('n'),
      };
      final nueva = memoryDb();
      expect(await esquema(db), await esquema(nueva));
      await nueva.close();
      await db.close();
    });
  });

  group('categorías y pasillos', () {
    late AppDatabase db;
    late CategoryRepositoryImpl cats;
    late FoodRepositoryImpl foods;
    late ShoppingListRepositoryImpl shopping;

    setUp(() {
      db = memoryDb();
      cats = CategoryRepositoryImpl(db);
      foods = FoodRepositoryImpl(db);
      shopping = ShoppingListRepositoryImpl(db);
    });

    tearDown(() => db.close());

    test('al crear un alimento se le asigna la categoría sugerida', () async {
      final id = await foods.saveFood(const Food(nombre: 'Merluza'));
      final pescado = (await cats.suggestFor('merluza'))!;
      expect((await foods.getFood(id))!.categoriaId, pescado.id);
      final sin = await foods.saveFood(
        const Food(nombre: 'Lubina'),
        adivinarCategoria: false,
      );
      expect((await foods.getFood(sin))!.categoriaId, isNull);
      expect(
        (await foods.search('', categoriaId: kSinCategoria)).single.id,
        sin,
      );
      expect((await foods.search('', categoriaId: pescado.id)).single.id, id);
    });

    test('orden por tienda y vuelta al general', () async {
      final general = await cats.getCategories();
      final invertido = [for (final c in general.reversed) c.id!];
      await cats.reorder(invertido, tienda: 'Mercado');
      final mercado = await cats.getCategories(tienda: 'Mercado');
      expect(mercado.first.nombre, general.last.nombre);
      expect(await cats.watchHasStoreOrder('mercado').first, isTrue);
      // Otra tienda sigue con el general.
      expect((await cats.getCategories(tienda: 'Otra')).first, general.first);
      await cats.resetStoreOrder('Mercado');
      expect((await cats.getCategories(tienda: 'Mercado')).first, general.first);
    });

    test('reordenar el general, crear, renombrar y borrar', () async {
      final general = await cats.getCategories();
      await cats.reorder([general[1].id!, general[0].id!]);
      expect((await cats.getCategories()).first.id, general[1].id);
      final id = await cats.saveCategory(const Category(nombre: 'Mascotas'));
      expect((await cats.getCategories()).last.id, id);
      expect(
        () => cats.saveCategory(const Category(nombre: 'mascotas')),
        throwsA(isA<ValidationException>()),
      );
      final pienso = await foods.saveFood(
        Food(nombre: 'Pienso', categoriaId: id),
      );
      await cats.deleteCategory(id);
      expect((await foods.getFood(pienso))!.categoriaId, isNull);
    });

    test('lista agrupada por pasillos (vinculados y texto libre)', () async {
      final pollo = await foods.saveFood(const Food(nombre: 'Pollo entero'));
      final lista = await shopping.createList('Semana');
      await shopping.addItem(
        ShoppingItem(listaId: lista, texto: 'Detergente'),
      );
      await shopping.addItem(
        ShoppingItem(listaId: lista, texto: 'Pollo', alimentoId: pollo),
      );
      await shopping.addItem(ShoppingItem(listaId: lista, texto: 'Manzanas'));
      await shopping.addItem(ShoppingItem(listaId: lista, texto: 'Chisme'));
      final items = await shopping.getItems(lista);
      final grupos = groupByAisle(items, await cats.getCategories());
      expect(grupos.map((g) => g.titulo), [
        'Frutas y verduras',
        'Carnicería',
        'Limpieza',
        'Otros',
      ]);
      expect(grupos[1].items.single.alimentoId, pollo);
    });

    test('gasto por categoría', () async {
      final purchases = PurchaseRepositoryImpl(db);
      final pollo = await foods.saveFood(const Food(nombre: 'Pollo'));
      final leche = await foods.saveFood(const Food(nombre: 'Leche'));
      Future<void> compra(int alimento, int cent, int uds) async =>
          purchases.addPurchase(
            Purchase(
              presentacionId: await foods.defaultPackageId(alimento),
              fecha: DateTime(2026, 11, 10),
              precioCent: cent,
              unidades: uds,
              establecimiento: 'S',
            ),
          );
      await compra(pollo, 500, 1);
      await compra(leche, 90, 6);
      await compra(pollo, 300, 1);
      final gasto = await purchases.spendingByCategory(DateTime(2026, 11, 1));
      expect(gasto.first.categoria!.nombre, 'Carnicería');
      expect(gasto.first.totalCent, 800);
      expect(gasto.last.totalCent, 540);
      expect(gasto.last.compras, 1);
    });

    test('repertorio, TSV y respaldo llevan la categoría', () async {
      final b = memoryDb();
      try {
        final mascotas = await cats.saveCategory(
          const Category(nombre: 'Mascotas'),
        );
        await foods.saveFood(Food(nombre: 'Pienso gato', categoriaId: mascotas));
        final rep = await ExportRepertoire(
          foods,
          RecipeRepositoryImpl(db),
          cats,
        )();
        final json = RepertoireCodec.encode(rep);
        expect(json, contains('"categoria": "Mascotas"'));
        final bFoods = FoodRepositoryImpl(b);
        final bCats = CategoryRepositoryImpl(b);
        await ImportRepertoire(
          bFoods,
          RecipeRepositoryImpl(b),
          DriftTransactionRunner(b),
          bCats,
        )(RepertoireCodec.decode(json));
        final pienso = (await bFoods.search('pienso')).single;
        final cat = (await bCats.getCategories()).firstWhere(
          (c) => c.id == pienso.categoriaId,
        );
        expect(cat.nombre, 'Mascotas'); // se creó en el otro móvil

        final tsv = FoodsTsvCodec.encode(rep);
        expect(tsv.split('\n').first.endsWith('\tcategoria'), isTrue);
        expect(
          FoodsTsvCodec.decode(tsv).alimentos.single.categoria,
          'Mascotas',
        );

        SharedPreferences.setMockInitialValues({});
        final backup = await FullBackupService(db).export();
        await FullBackupService(b).restore(backup);
        final restaurado = (await bFoods.search('pienso')).single;
        expect(
          (await bCats.getCategories())
              .firstWhere((c) => c.id == restaurado.categoriaId)
              .nombre,
          'Mascotas',
        );
      } finally {
        await b.close();
      }
    });
  });

  group('etiquetas de báscula', () {
    test('interpreta clave y valor; rechaza códigos normales', () {
      final code = scaleCode('211234501250');
      final l = ScaleLabel.parse(code)!;
      expect(l.clave, '2112345');
      expect(l.valor, 1250);
      expect(l.comoPrecioCent, 1250);
      expect(l.comoPesoG, 1250);
      expect(ScaleLabel.parse(code, longitudClave: 6)!.clave, '211234');
      expect(ScaleLabel.parse('8410000000001'), isNull);
      expect(ScaleLabel.parse('2112345012500'), isNull); // control erróneo
    });

    test('lectura con formato precio o peso', () {
      final l = ScaleLabel.parse(scaleCode('211234500850'))!;
      final precio = readScaleLabel(l, ScaleFormat.precio);
      expect(precio.precioCent, 850);
      expect(precio.pesoG, isNull);
      final peso = readScaleLabel(l, ScaleFormat.peso, precioKiloCent: 1490);
      expect(peso.pesoG, 850);
      expect(peso.precioCent, 1267); // 0,85 kg × 14,90 €/kg
      expect(readScaleLabel(l, ScaleFormat.peso).precioCent, isNull);
    });

    test('aprender producto por tienda y sumar paquetes en el carrito', () async {
      final db = memoryDb();
      final foods = FoodRepositoryImpl(db);
      final scale = ScaleRepositoryImpl(db);
      final purchases = PurchaseRepositoryImpl(db);
      final shopping = ShoppingListRepositoryImpl(db);
      final tx = DriftTransactionRunner(db);

      final tienda = await scale.ensureStore('Mercado');
      await scale.setScaleFormat(tienda.id!, ScaleFormat.peso);
      final polloId = await foods.saveFood(const Food(nombre: 'Pechuga de pollo'));
      final pollo = (await foods.getFood(polloId))!;
      final l1 = ScaleLabel.parse(scaleCode('211234500850'))!;
      final m = await LinkScaleCode(foods, scale, tx)(
        tienda: (await scale.getStore('mercado'))!,
        clave: l1.clave,
        alimento: pollo,
      );
      expect(m.presentacion.descripcion, kPresentacionAlPeso);

      // Otra bandeja: misma clave, otro valor → mismo producto.
      final l2 = ScaleLabel.parse(scaleCode('211234500920'))!;
      expect((await scale.findCode(tienda.id!, l2.clave))!.alimento.id, polloId);
      // En otra tienda la misma clave no significa nada.
      final otra = await scale.ensureStore('Otra');
      expect(await scale.findCode(otra.id!, l2.clave), isNull);
      // En casa se encuentra buscando en todas las tiendas.
      expect((await scale.findAnyStore(l2.codigo)).single.tienda.nombre,
          'Mercado');

      final lista = await shopping.createList('Hoy');
      final add = AddToCart(shopping, purchases, foods, tx);
      await add(
        listaId: lista,
        alimento: pollo,
        presentacionId: m.presentacion.id,
        precioCent: 1267,
        alPeso: true,
        pesoG: 850,
        establecimiento: 'Mercado',
      );
      await add(
        listaId: lista,
        alimento: pollo,
        presentacionId: m.presentacion.id,
        precioCent: 1371,
        alPeso: true,
        pesoG: 920,
        establecimiento: 'Mercado',
      );
      final item = (await shopping.getItems(lista)).single;
      expect(item.unidades, 1);
      expect(item.subtotalCent, 2638);
      expect(item.pesoG, 1770);
      final rec = (await purchases.getPurchasesForFood(polloId)).single;
      expect(rec.precioPorKiloCent, 1490);
      expect(
        await scale.lastPricePerKiloCent(m.presentacion.id!, storeId: tienda.id),
        1490,
      );

      // Tiendas con dígito de control del precio: clave de 6.
      expect(
        (await scale.findByShortKey(tienda.id!, l1.claveCorta)).single
            .alimento
            .id,
        polloId,
      );
      await db.close();
    });
  });
}
