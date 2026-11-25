import 'dart:io';

import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/data/repositories/shopping_list_repository_impl.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

/// Ejecuta un archivo de esquema con sentencias separadas por líneas '--'.
void _ejecutarEsquema(dynamic raw, String sql) {
  for (final stmt in sql.split(RegExp(r'^--\s*$', multiLine: true))) {
    final s = stmt
        .split('\n')
        .where((l) => !l.startsWith('--'))
        .join('\n')
        .trim();
    if (s.isNotEmpty) raw.execute(s);
  }
}

/// Tablas, índices y triggers, y las columnas de cada tabla.
Future<Map<String, Object>> _esquema(AppDatabase d) async {
  final out = <String, Object>{};
  final objetos = await d
      .customSelect(
        "SELECT type, name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'",
      )
      .get();
  for (final r in objetos) {
    final type = r.read<String>('type');
    final name = r.read<String>('name');
    if (type == 'table' && !name.startsWith('alimentos_fts')) {
      final cols = await d.customSelect("PRAGMA table_info('$name')").get();
      out['$type:$name'] = {
        for (final c in cols)
          '${c.read<String>('name')} ${c.read<String>('type')} '
              'notnull=${c.read<int>('notnull')} '
              'def=${c.readNullable<String>('dflt_value')}',
      };
    } else {
      out['$type:$name'] = true;
    }
  }
  return out;
}

void main() {
  test('migración v2 → v3 conserva los datos y añade las columnas', () async {
    final sql = File('test/fixtures/schema_v2.sql').readAsStringSync();
    final executor = NativeDatabase.memory(
      setup: (raw) {
        _ejecutarEsquema(raw, sql);
        raw.execute(
          "INSERT INTO categorias (nombre, orden) VALUES ('Despensa', 0)",
        );
        raw.execute(
          "INSERT INTO alimentos (uuid, nombre, marca, tipo, unidad, kcal, "
          "proteinas, grasas, carbohidratos, creado, actualizado) VALUES "
          "('u1', 'Arroz', '', 'generico', 'g', 350, 7, 1, 78, 'x', 'x')",
        );
        raw.execute(
          "INSERT INTO recetas (uuid, nombre, porciones, alimento_id, creada, "
          "actualizada) VALUES ('r1', 'Arroz blanco', 2, NULL, 'x', 'x')",
        );
        raw.execute(
          "INSERT INTO ingredientes_receta (receta_id, orden, texto, "
          "alimento_id, cantidad, unidad) VALUES (1, 1, '200 g de arroz', 1, "
          "200, 'g')",
        );
        raw.execute(
          "INSERT INTO listas_compra (nombre, creada) VALUES ('Semana', 'x')",
        );
        raw.execute(
          "INSERT INTO items_lista (lista_id, alimento_id, texto, cantidad, "
          "orden) VALUES (1, 1, 'Arroz', '1 kg', 1)",
        );
        raw.execute('PRAGMA user_version = 2');
      },
    );
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(executor);

    final arroz = (await FoodRepositoryImpl(db).getFood(1))!;
    expect(arroz.nombre, 'Arroz');
    expect(arroz.aproximado, isFalse);
    expect(arroz.esAlimento, isTrue);
    expect(arroz.pendiente, isFalse);

    final receta = (await RecipeRepositoryImpl(db).get(1))!;
    expect(receta.ultimaPreparacion, isNull);
    expect(receta.ingredientes.single.nota, isNull);
    expect(receta.ingredientes.single.cantidad, 200);

    final item = (await ShoppingListRepositoryImpl(db).getItems(1)).single;
    expect(item.cantidad, '1 kg');
    expect(item.cantidadMinima, isNull);

    // Las columnas nuevas se pueden escribir y leer.
    await RecipeRepositoryImpl(db).save(
      receta.copyWith(
        ultimaPreparacion: DateTime(2026, 11, 24),
        ingredientes: [receta.ingredientes.single.copyWith(nota: 'lavado')],
      ),
    );
    final guardada = (await RecipeRepositoryImpl(db).get(1))!;
    expect(guardada.ultimaPreparacion, DateTime(2026, 11, 24));
    expect(guardada.ingredientes.single.nota, 'lavado');

    // Mismo esquema (tablas, columnas, índices y triggers) que una
    // instalación nueva.
    final nueva = memoryDb();
    expect(await _esquema(db), await _esquema(nueva));
    await nueva.close();
    await db.close();
  });
}
