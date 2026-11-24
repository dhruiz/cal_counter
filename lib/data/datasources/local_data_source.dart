import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food_model.dart';
import '../../domain/entities/meal_item.dart';
import '../../domain/errors.dart';
import '../../domain/services/dates.dart';
import 'module_tables.dart';

abstract class LocalDataSource {
  /// Conexión compartida (singleton). La usan también los data sources de
  /// recetas, productos y listas de compra, que viven en la misma BD.
  Future<Database> get database;
  Future<void> initDb();
  Future<List<FoodModel>> searchFoods(String query);
  Future<FoodModel?> getFoodById(int id);

  /// Alta. Lanza [DuplicateFoodNameException] si el nombre ya existe.
  Future<int> insertFood(FoodModel food);

  /// Lanza [DuplicateFoodNameException] si el nuevo nombre ya existe.
  Future<int> updateFood(FoodModel food);

  /// Crea el alimento o sobrescribe sus macros si ya hay uno con ese nombre
  /// (sin distinguir mayúsculas), conservando su id y su contador de uso.
  Future<int> saveFoodByName(FoodModel food);
  Future<int> deleteFood(int id);
  Future<void> incrementFoodUsage(int id);
  Future<void> resetFoodUsage(int id);
  Future<List<FoodModel>> getMostUsedFoods({int limit});
  Future<int> createMeal(String name, DateTime date);
  Future<List<Map<String, dynamic>>> getMealsByDate(DateTime date);
  Future<String?> getLastMealDate();
  Future<int> addItemToMeal(MealItem item);
  Future<List<Map<String, dynamic>>> getMealItems(int mealId);
  Future<void> deleteMeal(int id);
  Future<void> deleteMealItem(int id);
  Future<void> updateMealItem(int id, double newCantidad);
  Future<void> updateMealName(int id, String name);
  Future<List<FoodModel>> getAllFoods();

  /// Copia del catálogo de alimentos como archivo SQLite (bytes), para
  /// guardarla con el selector del sistema (SAF) sin permisos de almacenamiento.
  Future<Uint8List> exportDatabaseBytes();
  Future<int> importDatabase(String sourcePath);
  Future<String> exportFoodsTsv();
  Future<int> importFoodsTsvFromString(String tsvContent);
  Future<bool> hasMealItems();
  Future<void> clearMealsAndItems();
  Future<void> close();
}

class LocalDataSourceImpl implements LocalDataSource {
  static const String dbName = 'db_ctrl_calorias.db';

  static Database? _database;

  /// Apertura en curso. Las pestañas del IndexedStack piden la BD a la vez en
  /// el arranque: sin compartir este Future, varias llamadas copiaban el asset
  /// en paralelo y podían reescribir el archivo con otra conexión ya abierta.
  static Future<Database>? _opening;

  @override
  Future<Database> get database async {
    final db = _database;
    if (db != null && db.isOpen) return db;
    final pending = _opening ??= _open();
    try {
      return await pending;
    } catch (_) {
      // Permite reintentar en la próxima llamada.
      if (identical(_opening, pending)) _opening = null;
      rethrow;
    }
  }

  @override
  Future<void> initDb() async {
    await database;
  }

  Future<Database> _open() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, dbName);

    if (!await databaseExists(path)) {
      await _copyBundledDatabase(path);
    }

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        await _createTables(db);
      },
    );
    _database = db;
    _opening = null;
    return db;
  }

  /// Copia la BD precargada de assets. Se escribe en un temporal y se renombra
  /// para que una copia interrumpida no deje un archivo corrupto que se
  /// abriría en cada arranque. Si falla, se abre una BD vacía.
  Future<void> _copyBundledDatabase(String path) async {
    final tmp = File('$path.tmp');
    try {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load('assets/db/$dbName');
      await tmp.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await tmp.rename(path);
    } catch (e) {
      log('Error copiando la BD de assets: $e');
      if (await tmp.exists()) await tmp.delete();
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS db_alimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        alimento TEXT NOT NULL UNIQUE,
        kCal REAL NOT NULL,
        grasas REAL NOT NULL,
        carbohidratos REAL NOT NULL,
        proteinas REAL NOT NULL,
        uso_count INTEGER NOT NULL DEFAULT 0,
        ultimo_uso TEXT
      )
    ''');

    // Migración idempotente: la BD precargada de assets existe sin estas columnas.
    await ensureColumn(
      db,
      'db_alimentos',
      'uso_count',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await ensureColumn(db, 'db_alimentos', 'ultimo_uso', 'TEXT');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS comidas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        fecha TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS items_comida (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comida_id INTEGER NOT NULL REFERENCES comidas(id) ON DELETE CASCADE,
        cantidad REAL NOT NULL,
        alimento TEXT NOT NULL,
        grasas REAL NOT NULL,
        carbohidratos REAL NOT NULL,
        proteinas REAL NOT NULL,
        kCal REAL NOT NULL
      )
    ''');

    // sqflite no activa `PRAGMA foreign_keys`, así que el ON DELETE CASCADE de
    // items_comida nunca actuó y versiones anteriores de deleteMeal dejaban
    // items huérfanos. Limpieza idempotente en cada apertura.
    await db.execute(
      'DELETE FROM items_comida WHERE comida_id NOT IN (SELECT id FROM comidas)',
    );

    // Recetas, productos/compras y listas de compra (module_tables.dart).
    await createModuleTables(db);
  }

  /// Escapa los comodines de LIKE para buscar el texto literal
  /// ("50%" o "_" no deben coincidir con todo).
  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  /// Macros por 100 g aceptables al importar: números finitos y no negativos.
  static bool _validMacros(double kcal, double g, double c, double p) =>
      [kcal, g, c, p].every((v) => v.isFinite && v >= 0);

  @override
  Future<List<FoodModel>> searchFoods(String query) async {
    final db = await database;
    final res = await db.query(
      'db_alimentos',
      where: r"alimento LIKE ? ESCAPE '\'",
      whereArgs: ['%${_escapeLike(query)}%'],
    );
    return res.map((e) => FoodModel.fromJson(e)).toList();
  }

  @override
  Future<FoodModel?> getFoodById(int id) async {
    final db = await database;
    final res = await db.query(
      'db_alimentos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return res.isEmpty ? null : FoodModel.fromJson(res.first);
  }

  /// Antes era `ConflictAlgorithm.replace`: un alta con un nombre existente
  /// borraba la fila original (nuevo id: se rompían los vínculos de recetas y
  /// productos y se perdía el contador de uso) sin avisar.
  @override
  Future<int> insertFood(FoodModel food) async {
    final db = await database;
    try {
      return await db.insert(
        'db_alimentos',
        food.toJson()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw DuplicateFoodNameException(food.name);
      }
      rethrow;
    }
  }

  @override
  Future<int> updateFood(FoodModel food) async {
    final db = await database;
    try {
      return await db.update(
        'db_alimentos',
        food.toJson()..remove('id'),
        where: 'id = ?',
        whereArgs: [food.id],
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw DuplicateFoodNameException(food.name);
      }
      rethrow;
    }
  }

  @override
  Future<int> saveFoodByName(FoodModel food) async {
    final db = await database;
    return db.transaction((txn) async {
      // Coincidencia exacta primero; si no, sin distinguir mayúsculas (la UI
      // pregunta "¿sobrescribir?" con esa misma comparación).
      var rows = await txn.query(
        'db_alimentos',
        columns: ['id'],
        where: 'alimento = ?',
        whereArgs: [food.name],
        limit: 1,
      );
      if (rows.isEmpty) {
        rows = await txn.query(
          'db_alimentos',
          columns: ['id'],
          where: 'alimento = ? COLLATE NOCASE',
          whereArgs: [food.name],
          limit: 1,
        );
      }
      final values = food.toJson()..remove('id');
      if (rows.isEmpty) return txn.insert('db_alimentos', values);
      final id = rows.first['id'] as int;
      await txn.update(
        'db_alimentos',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    });
  }

  @override
  Future<int> deleteFood(int id) async {
    final db = await database;
    return await db.delete('db_alimentos', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> incrementFoodUsage(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE db_alimentos SET uso_count = uso_count + 1, ultimo_uso = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  @override
  Future<void> resetFoodUsage(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE db_alimentos SET uso_count = 0, ultimo_uso = NULL WHERE id = ?',
      [id],
    );
  }

  @override
  Future<List<FoodModel>> getMostUsedFoods({int limit = 20}) async {
    final db = await database;
    final res = await db.query(
      'db_alimentos',
      where: 'uso_count > 0',
      orderBy: 'uso_count DESC, ultimo_uso DESC',
      limit: limit,
    );
    return res.map((e) => FoodModel.fromJson(e)).toList();
  }

  @override
  Future<int> createMeal(String name, DateTime date) async {
    final db = await database;
    return await db.insert('comidas', {'nombre': name, 'fecha': dateKey(date)});
  }

  @override
  Future<List<Map<String, dynamic>>> getMealsByDate(DateTime date) async {
    final db = await database;
    return await db.query(
      'comidas',
      where: 'fecha = ?',
      whereArgs: [dateKey(date)],
      orderBy: 'id ASC',
    );
  }

  @override
  Future<String?> getLastMealDate() async {
    final db = await database;
    final res = await db.query('comidas', orderBy: 'fecha DESC', limit: 1);
    if (res.isNotEmpty) {
      return res.first['fecha'] as String;
    }
    return null;
  }

  @override
  Future<int> addItemToMeal(MealItem item) async {
    final db = await database;
    return await db.insert('items_comida', {
      'comida_id': item.mealId,
      'cantidad': item.cantidad,
      'alimento': item.alimento,
      'grasas': item.grasas,
      'carbohidratos': item.carbohidratos,
      'proteinas': item.proteinas,
      'kCal': item.kcal,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getMealItems(int mealId) async {
    final db = await database;
    return await db.query(
      'items_comida',
      where: 'comida_id = ?',
      whereArgs: [mealId],
    );
  }

  @override
  Future<void> deleteMeal(int id) async {
    final db = await database;
    // Sin foreign keys activas el CASCADE no actúa: se borran los items de la
    // comida explícitamente en la misma transacción.
    await db.transaction((txn) async {
      await txn.delete('items_comida', where: 'comida_id = ?', whereArgs: [id]);
      await txn.delete('comidas', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> deleteMealItem(int id) async {
    final db = await database;
    await db.delete('items_comida', where: 'id = ?', whereArgs: [id]);
  }

  /// Reescala los macros ya guardados con `nueva/anterior` (no se vuelve a
  /// consultar el alimento base, que puede haber cambiado o no existir).
  @override
  Future<void> updateMealItem(int id, double newCantidad) async {
    if (!newCantidad.isFinite || newCantidad <= 0) {
      throw ArgumentError('La cantidad debe ser mayor que 0.');
    }
    final db = await database;
    await db.transaction((txn) async {
      final items = await txn.query(
        'items_comida',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (items.isEmpty) return;

      final item = items.first;
      double value(String col) => (item[col] as num).toDouble();
      final oldCantidad = value('cantidad');
      // Con cantidad 0 el factor sería infinito y corrompería los macros.
      if (oldCantidad <= 0) {
        throw StateError('El item $id tiene una cantidad guardada inválida.');
      }
      final ratio = newCantidad / oldCantidad;

      await txn.update(
        'items_comida',
        {
          'cantidad': newCantidad,
          'kCal': value('kCal') * ratio,
          'grasas': value('grasas') * ratio,
          'carbohidratos': value('carbohidratos') * ratio,
          'proteinas': value('proteinas') * ratio,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<void> updateMealName(int id, String name) async {
    final db = await database;
    await db.update(
      'comidas',
      {'nombre': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<FoodModel>> getAllFoods() async {
    final db = await database;
    final res = await db.query('db_alimentos');
    return res.map((e) => FoodModel.fromJson(e)).toList();
  }

  /// Antes se escribía directamente en una carpeta elegida con
  /// `getDirectoryPath`: en Android 7-10 fallaba (el permiso de escritura nunca
  /// se pedía en tiempo de ejecución) y en 11+ solo funcionaba en algunas
  /// carpetas. Ahora se genera en la caché y la UI lo guarda vía SAF.
  @override
  Future<Uint8List> exportDatabaseBytes() async {
    final foods = await getAllFoods();
    final tmpDir = await getTemporaryDirectory();
    final path = join(
      tmpDir.path,
      'export_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final exportDb = await openDatabase(
      path,
      version: 1,
      singleInstance: false,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
    try {
      await exportDb.transaction((txn) async {
        final batch = txn.batch();
        for (final food in foods) {
          batch.insert(
            'db_alimentos',
            food.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } finally {
      await exportDb.close();
    }
    try {
      return await File(path).readAsBytes();
    } finally {
      await deleteDatabase(path);
    }
  }

  @override
  Future<int> importDatabase(String sourcePath) async {
    final db = await database;

    final List<FoodModel> sourceFoods;
    final sourceDb = await openDatabase(
      sourcePath,
      readOnly: true,
      singleInstance: false,
    );
    try {
      final sourceRes = await sourceDb.query('db_alimentos');
      sourceFoods = sourceRes.map((e) => FoodModel.fromJson(e)).toList();
    } finally {
      await sourceDb.close();
    }

    // Solo los que no existen (UNIQUE en `alimento`). En Android un insert
    // ignorado devuelve -1 (en FFI, 0): solo cuentan los ids positivos.
    var importedCount = 0;
    await db.transaction((txn) async {
      for (final food in sourceFoods) {
        final name = food.name.trim();
        if (name.isEmpty ||
            !_validMacros(
              food.kcalPer100,
              food.grasasPer100,
              food.carbsPer100,
              food.proteinsPer100,
            )) {
          log('Alimento importado ignorado (datos inválidos): ${food.name}');
          continue;
        }
        final id = await txn.insert('db_alimentos', {
          'alimento': name,
          'kCal': food.kcalPer100,
          'grasas': food.grasasPer100,
          'carbohidratos': food.carbsPer100,
          'proteinas': food.proteinsPer100,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        if (id > 0) importedCount++;
      }
    });
    return importedCount;
  }

  @override
  Future<String> exportFoodsTsv() async {
    final foods = await getAllFoods();
    final buffer = StringBuffer();
    buffer.writeln('id\talimento\tkCal\tgrasas\tcarbohidratos\tproteinas');
    for (final food in foods) {
      final safeName = food.name
          .replaceAll('\t', ' ')
          .replaceAll('\n', ' ')
          .replaceAll('\r', ' ');
      buffer.writeln(
        '${food.id ?? ''}\t$safeName\t${food.kcalPer100}\t${food.grasasPer100}\t${food.carbsPer100}\t${food.proteinsPer100}',
      );
    }
    return buffer.toString();
  }

  @override
  Future<int> importFoodsTsvFromString(String tsvContent) async {
    final db = await database;
    // Excel y otros editores añaden BOM al guardar en UTF-8.
    final content = tsvContent.startsWith('﻿')
        ? tsvContent.substring(1)
        : tsvContent;
    final lines = content.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return 0;

    final headerLine = lines.first.trim();
    if (headerLine.isEmpty) {
      throw const FormatException('Archivo TSV vacío.');
    }
    final headerCols = headerLine.split('\t');
    if (headerCols.length != 6 ||
        headerCols[0] != 'id' ||
        headerCols[1] != 'alimento' ||
        headerCols[2] != 'kCal' ||
        headerCols[3] != 'grasas' ||
        headerCols[4] != 'carbohidratos' ||
        headerCols[5] != 'proteinas') {
      throw const FormatException(
        'Cabecera TSV inválida. Esperado: id\\talimento\\tkCal\\tgrasas\\tcarbohidratos\\tproteinas',
      );
    }

    // Coma decimal aceptada: es lo que escribe una hoja de cálculo en español.
    double parseNum(String s) => double.parse(s.trim().replaceAll(',', '.'));

    var importedCount = 0;
    // Una sola transacción: con cientos de líneas, un commit por fila tardaba
    // segundos.
    await db.transaction((txn) async {
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;
        final cols = line.split('\t');
        if (cols.length != 6) {
          log('Línea TSV ignorada (columnas inválidas): $line');
          continue;
        }
        try {
          final name = cols[1].trim();
          if (name.isEmpty) continue;
          final kCal = parseNum(cols[2]);
          final grasas = parseNum(cols[3]);
          final carbohidratos = parseNum(cols[4]);
          final proteinas = parseNum(cols[5]);
          if (!_validMacros(kCal, grasas, carbohidratos, proteinas)) {
            log('Línea TSV ignorada (valores inválidos): $line');
            continue;
          }

          final inserted = await txn.insert('db_alimentos', {
            'alimento': name,
            'kCal': kCal,
            'grasas': grasas,
            'carbohidratos': carbohidratos,
            'proteinas': proteinas,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          // Android devuelve -1 si el nombre ya existía (FFI devuelve 0).
          if (inserted > 0) importedCount++;
        } on FormatException catch (e) {
          log('Error procesando línea TSV: $line. Error: $e');
        }
      }
    });
    return importedCount;
  }

  @override
  Future<bool> hasMealItems() async {
    final db = await database;
    // Solo cuentan items de comidas existentes (defensa ante huérfanos).
    final res = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM items_comida i '
      'JOIN comidas c ON c.id = i.comida_id',
    );
    final count = Sqflite.firstIntValue(res) ?? 0;
    return count > 0;
  }

  @override
  Future<void> clearMealsAndItems() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('items_comida');
      await txn.delete('comidas');
    });
  }

  @override
  Future<void> close() async {
    var db = _database;
    final pending = _opening;
    if (db == null && pending != null) {
      try {
        db = await pending;
      } catch (_) {
        // Nada que cerrar.
      }
    }
    _database = null;
    _opening = null;
    if (db != null && db.isOpen) await db.close();
  }
}
