import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/food_model.dart';
import '../../domain/entities/meal_item.dart';

abstract class LocalDataSource {
  Future<void> initDb();
  Future<List<FoodModel>> searchFoods(String query);
  Future<int> insertFood(FoodModel food);
  Future<int> updateFood(FoodModel food);
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
  Future<List<FoodModel>> getAllFoods();
  Future<void> exportDatabase(String destinationPath);
  Future<int> importDatabase(String sourcePath);
  Future<String> exportFoodsTsv();
  Future<int> importFoodsTsvFromString(String tsvContent);
  Future<bool> hasMealItems();
  Future<void> clearMealsAndItems();
  Future<void> close();
}

class LocalDataSourceImpl implements LocalDataSource {
  static Database? _database;
  final String dbName = 'db_ctrl_calorias.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initDb();
    return _database!;
  }

  @override
  Future<void> initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, dbName);

    if (!await databaseExists(path)) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets', 'db', dbName));
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        log('Error copying DB from assets: $e');
      }
    }

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        await _createTables(db);
      },
    );
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
    await _ensureColumn(db, 'db_alimentos', 'uso_count',
        'INTEGER NOT NULL DEFAULT 0');
    await _ensureColumn(db, 'db_alimentos', 'ultimo_uso', 'TEXT');

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
  }

  /// Añade [column] a [table] solo si aún no existe (ALTER idempotente).
  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  @override
  Future<List<FoodModel>> searchFoods(String query) async {
    final db = await database;
    final res = await db.query(
      'db_alimentos',
      where: 'alimento LIKE ?',
      whereArgs: ['%$query%'],
    );
    return res.map((e) => FoodModel.fromJson(e)).toList();
  }

  @override
  Future<int> insertFood(FoodModel food) async {
    final db = await database;
    return await db.insert(
      'db_alimentos',
      food.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateFood(FoodModel food) async {
    final db = await database;
    return await db.update(
      'db_alimentos',
      food.toJson(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
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
    final dateStr = date.toIso8601String().split('T')[0];
    return await db.insert('comidas', {'nombre': name, 'fecha': dateStr});
  }

  @override
  Future<List<Map<String, dynamic>>> getMealsByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    return await db.query('comidas', where: 'fecha = ?', whereArgs: [dateStr]);
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
    await db.delete('comidas', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteMealItem(int id) async {
    final db = await database;
    await db.delete('items_comida', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateMealItem(int id, double newCantidad) async {
    final db = await database;
    // Get the current item to recalculate macros based on new quantity
    final items = await db.query(
      'items_comida',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (items.isEmpty) return;

    final item = items.first;
    final oldCantidad = item['cantidad'] as double;

    // Calculate the ratio to adjust all nutritional values
    final ratio = newCantidad / oldCantidad;

    await db.update(
      'items_comida',
      {
        'cantidad': newCantidad,
        'kCal': (item['kCal'] as double) * ratio,
        'grasas': (item['grasas'] as double) * ratio,
        'carbohidratos': (item['carbohidratos'] as double) * ratio,
        'proteinas': (item['proteinas'] as double) * ratio,
      },
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

  @override
  Future<void> exportDatabase(String destinationPath) async {
    // Get all foods from current database
    final foods = await getAllFoods();

    // Create a new database at destination
    final exportDb = await openDatabase(
      destinationPath,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );

    // Insert all foods into the export database
    for (final food in foods) {
      await exportDb.insert(
        'db_alimentos',
        food.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await exportDb.close();
  }

  @override
  Future<int> importDatabase(String sourcePath) async {
    final db = await database;

    // Open the source database
    final sourceDb = await openDatabase(sourcePath, readOnly: true);

    // Get all foods from source database
    final sourceRes = await sourceDb.query('db_alimentos');
    final sourceFoods = sourceRes.map((e) => FoodModel.fromJson(e)).toList();

    await sourceDb.close();

    // Insert foods that don't exist (using UNIQUE constraint on 'alimento' field)
    int importedCount = 0;
    for (final food in sourceFoods) {
      try {
        // Try to insert, will fail if food name already exists
        await db.insert('db_alimentos', {
          'alimento': food.name,
          'kCal': food.kcalPer100,
          'grasas': food.grasasPer100,
          'carbohidratos': food.carbsPer100,
          'proteinas': food.proteinsPer100,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        importedCount++;
      } catch (e) {
        // Silently ignore duplicates
        log('Skipping duplicate food: ${food.name}');
      }
    }

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
    final lines = tsvContent.split(RegExp(r'\r?\n'));
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

    int importedCount = 0;
    for (int i = 1; i < lines.length; i++) {
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
        final kCal = double.parse(cols[2].trim());
        final grasas = double.parse(cols[3].trim());
        final carbohidratos = double.parse(cols[4].trim());
        final proteinas = double.parse(cols[5].trim());

        final inserted = await db.insert(
          'db_alimentos',
          {
            'alimento': name,
            'kCal': kCal,
            'grasas': grasas,
            'carbohidratos': carbohidratos,
            'proteinas': proteinas,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (inserted != 0) importedCount++;
      } catch (e) {
        log('Error procesando línea TSV: $line. Error: $e');
      }
    }
    return importedCount;
  }

  @override
  Future<bool> hasMealItems() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) AS c FROM items_comida');
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
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
