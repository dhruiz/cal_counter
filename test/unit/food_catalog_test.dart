import 'dart:io';

import 'package:cal_counter/data/datasources/local_data_source.dart';
import 'package:cal_counter/data/models/food_model.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
import 'package:cal_counter/domain/errors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Regresiones de la auditoría en la capa de datos (SQLite real vía FFI).
void main() {
  late LocalDataSourceImpl dataSource;
  // Ruta absoluta: con FFI una ruta relativa se resuelve dentro de
  // .dart_tool/ para SQLite pero desde el directorio actual para `File`, y la
  // copia del asset y la exportación (que usan ambos) no coincidirían. En
  // Android path_provider siempre devuelve rutas absolutas.
  final testDir = join(Directory.current.path, 'test_tmp_food_catalog');
  final dbPath = join(testDir, LocalDataSourceImpl.dbName);

  TestWidgetsFlutterBinding.ensureInitialized();

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
    dataSource = LocalDataSourceImpl();
  });

  tearDown(() async {
    await dataSource.close();
    await databaseFactory.deleteDatabase(dbPath);
    final dir = Directory(testDir);
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  FoodModel food(String name, {double kcal = 100}) => FoodModel(
    name: name,
    kcalPer100: kcal,
    grasasPer100: 1,
    carbsPer100: 2,
    proteinsPer100: 3,
  );

  Future<Map<String, Object?>> row(String name) async {
    final db = await dataSource.database;
    final rows = await db.query(
      'db_alimentos',
      where: 'alimento = ?',
      whereArgs: [name],
    );
    expect(rows, hasLength(1), reason: 'una sola fila para "$name"');
    return rows.first;
  }

  group('apertura de la BD', () {
    test('aperturas simultáneas en el primer arranque comparten conexión '
        'y la BD precargada queda íntegra', () async {
      final results = await Future.wait([
        dataSource.database,
        dataSource.database,
        LocalDataSourceImpl().database,
      ]);
      expect(identical(results[0], results[1]), isTrue);
      expect(identical(results[0], results[2]), isTrue);

      final count =
          (await results[0].rawQuery(
                'SELECT COUNT(*) AS n FROM db_alimentos',
              )).first['n']
              as int;
      expect(count, greaterThan(600)); // asset precargado (678 alimentos)
      final cols = await results[0].rawQuery('PRAGMA table_info(db_alimentos)');
      expect(cols.map((c) => c['name']), contains('uso_count'));
      expect(File('$dbPath.tmp').existsSync(), isFalse);
    });

    test('close() y reapertura funcionan', () async {
      final first = await dataSource.database;
      await dataSource.close();
      expect(first.isOpen, isFalse);
      final second = await dataSource.database;
      expect(second.isOpen, isTrue);
    });
  });

  group('alta y sobrescritura de alimentos', () {
    test(
      'alta con nombre existente lanza DuplicateFoodNameException y no '
      'toca el original (antes REPLACE lo sobrescribía en silencio)',
      () async {
        final id = await dataSource.insertFood(
          food('ZZ Arroz test', kcal: 130),
        );
        await dataSource.incrementFoodUsage(id);

        await expectLater(
          dataSource.insertFood(food('ZZ Arroz test', kcal: 999)),
          throwsA(isA<DuplicateFoodNameException>()),
        );

        final r = await row('ZZ Arroz test');
        expect(r['id'], id);
        expect(r['kCal'], 130);
        expect(r['uso_count'], 1);
      },
    );

    test(
      'renombrar a un nombre existente lanza DuplicateFoodNameException',
      () async {
        await dataSource.insertFood(food('ZZ Uno'));
        final id2 = await dataSource.insertFood(food('ZZ Dos'));
        await expectLater(
          dataSource.updateFood(
            FoodModel(
              id: id2,
              name: 'ZZ Uno',
              kcalPer100: 1,
              grasasPer100: 1,
              carbsPer100: 1,
              proteinsPer100: 1,
            ),
          ),
          throwsA(isA<DuplicateFoodNameException>()),
        );
      },
    );

    test('saveFoodByName sobrescribe en su sitio: mismo id (vínculos de '
        'recetas/productos intactos) y conserva el contador de uso', () async {
      final id = await dataSource.insertFood(food('ZZ Guiso', kcal: 80));
      await dataSource.incrementFoodUsage(id);
      await dataSource.incrementFoodUsage(id);

      final savedId = await dataSource.saveFoodByName(
        food('zz guiso', kcal: 95), // otra capitalización, como en la UI
      );

      expect(savedId, id);
      final r = await row('zz guiso');
      expect(r['id'], id);
      expect(r['kCal'], 95);
      expect(r['uso_count'], 2);
    });

    test('saveFoodByName crea el alimento si no existe', () async {
      final id = await dataSource.saveFoodByName(food('ZZ Nuevo plato'));
      expect(id, greaterThan(0));
      expect((await row('ZZ Nuevo plato'))['id'], id);
    });
  });

  test(
    'buscar "%" o "_" busca el carácter literal, no todo el catálogo',
    () async {
      await dataSource.insertFood(food('ZZ Leche 0%'));
      final all = await dataSource.getAllFoods();
      final percent = await dataSource.searchFoods('%');
      expect(percent.map((f) => f.name), contains('ZZ Leche 0%'));
      expect(percent.every((f) => f.name.contains('%')), isTrue);
      expect(percent.length, lessThan(all.length));
      // Ningún alimento lleva "_": sin escape, "_" coincidía con todos.
      expect(await dataSource.searchFoods('_'), isEmpty);
    },
  );

  group('importar TSV', () {
    const header = 'id\talimento\tkCal\tgrasas\tcarbohidratos\tproteinas';

    test('cuenta solo los nuevos, acepta BOM y coma decimal, ignora valores '
        'inválidos', () async {
      await dataSource.insertFood(food('ZZ Existente'));
      final tsv = [
        '﻿$header',
        '1\tZZ Existente\t1\t1\t1\t1', // duplicado
        '2\tZZ Coma\t12,5\t0,3\t2\t1', // coma decimal
        '3\tZZ NaN\tNaN\t1\t1\t1', // inválido
        '4\tZZ Negativo\t-5\t1\t1\t1', // inválido
        '5\tZZ Bien\t50\t1\t2\t3',
      ].join('\n');

      final imported = await dataSource.importFoodsTsvFromString(tsv);

      expect(imported, 2);
      expect((await row('ZZ Coma'))['kCal'], 12.5);
      final names = (await dataSource.searchFoods('ZZ ')).map((f) => f.name);
      expect(names, isNot(contains('ZZ NaN')));
      expect(names, isNot(contains('ZZ Negativo')));
    });
  });

  group('exportar e importar BD', () {
    test('la copia exportada es una BD válida que se reimporta contando solo '
        'los alimentos nuevos', () async {
      await dataSource.insertFood(food('ZZ Exportado'));
      final bytes = await dataSource.exportDatabaseBytes();
      expect(bytes.length, greaterThan(0));
      // Cabecera de SQLite.
      expect(String.fromCharCodes(bytes.take(15)), 'SQLite format 3');

      final file = File(join(testDir, 'copia.db'))..writeAsBytesSync(bytes);

      // Misma BD: todo duplicado → 0 importados (antes contaba todos).
      expect(await dataSource.importDatabase(file.path), 0);

      final db = await dataSource.database;
      await db.delete(
        'db_alimentos',
        where: 'alimento = ?',
        whereArgs: ['ZZ Exportado'],
      );
      expect(await dataSource.importDatabase(file.path), 1);
      expect((await row('ZZ Exportado'))['kCal'], 100);
    });

    test('importar un archivo que no es una BD lanza error', () async {
      final file = File(join(testDir, 'no_es_bd.db'))
        ..writeAsStringSync('hola, no soy SQLite');
      await expectLater(
        dataSource.importDatabase(file.path),
        throwsA(anything),
      );
    });
  });

  group('editar cantidad de un item', () {
    Future<int> addItem(double cantidad) async {
      final mealId = await dataSource.createMeal(
        'Comida_1',
        DateTime(2024, 1, 1),
      );
      return dataSource.addItemToMeal(
        MealItem(
          mealId: mealId,
          alimento: 'X',
          cantidad: cantidad,
          grasas: 10,
          carbohidratos: 20,
          proteinas: 30,
          kcal: 200,
        ),
      );
    }

    test('reescala los macros guardados', () async {
      final id = await addItem(100);
      await dataSource.updateMealItem(id, 150);
      final db = await dataSource.database;
      final r = (await db.query(
        'items_comida',
        where: 'id = ?',
        whereArgs: [id],
      )).first;
      expect(r['cantidad'], 150);
      expect(r['kCal'], 300);
      expect(r['proteinas'], 45);
    });

    test('cantidad nueva <= 0 se rechaza (antes podía dejar macros a 0 y '
        'luego dividir entre 0)', () async {
      final id = await addItem(100);
      expect(() => dataSource.updateMealItem(id, 0), throwsArgumentError);
    });

    test('cantidad guardada 0 no produce macros infinitos', () async {
      final id = await addItem(0);
      await expectLater(
        dataSource.updateMealItem(id, 50),
        throwsA(isA<StateError>()),
      );
    });
  });
}
