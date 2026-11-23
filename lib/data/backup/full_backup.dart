import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/errors/domain_errors.dart';
import '../db/app_database.dart';

/// Respaldo completo (personal): todas las tablas y los ajustes, para
/// cambiar de móvil o guardar una copia de seguridad.
///
/// ```json
/// {"formato": "cal_counter/respaldo", "version": 1, "esquema": 1,
///  "exportado": "...", "tablas": {"alimentos": [{...fila...}], ...},
///  "ajustes": {"clave": {"t": "double", "v": 70.0}}}
/// ```
///
/// Las filas van tal cual están en SQLite (columnas snake_case). Restaurar
/// REEMPLAZA todo el contenido, en una transacción.
class FullBackupService {
  final AppDatabase db;

  FullBackupService(this.db);

  static const String formato = 'cal_counter/respaldo';
  static const int version = 1;

  /// Orden de inserción (padres antes que hijos por las claves foráneas).
  static const List<String> tablas = [
    'alimentos',
    'porciones',
    'presentaciones',
    'establecimientos',
    'compras',
    'listas_compra',
    'items_lista',
    'recetas',
    'ingredientes_receta',
    'comidas',
    'items_comida',
  ];

  /// Ajustes internos que no se restauran (dependen de la instalación).
  static const Set<String> _ajustesLocales = {
    'onboarding_completado',
    'migracion_legado_hecha',
  };

  Future<String> export() async {
    final data = <String, Object?>{};
    for (final t in tablas) {
      final rows = await db.customSelect('SELECT * FROM $t ORDER BY id').get();
      data[t] = [for (final r in rows) r.data];
    }
    final prefs = await SharedPreferences.getInstance();
    final ajustes = <String, Object?>{};
    for (final k in prefs.getKeys()) {
      if (_ajustesLocales.contains(k)) continue;
      final v = prefs.get(k);
      final tipo = switch (v) {
        bool() => 'bool',
        int() => 'int',
        double() => 'double',
        String() => 'string',
        List() => 'list',
        _ => null,
      };
      if (tipo != null) ajustes[k] = {'t': tipo, 'v': v};
    }
    return const JsonEncoder.withIndent(' ').convert({
      'formato': formato,
      'version': version,
      'esquema': db.schemaVersion,
      'exportado': DateTime.now().toUtc().toIso8601String(),
      'tablas': data,
      'ajustes': ajustes,
    });
  }

  /// Comprueba que [content] es un respaldo restaurable y devuelve cuántas
  /// filas tiene cada tabla.
  static Map<String, int> inspect(String content) {
    final json = _parse(content);
    final t = json['tablas'] as Map;
    return {for (final name in tablas) name: ((t[name] as List?) ?? []).length};
  }

  static Map<String, Object?> _parse(String content) {
    final Object? json;
    try {
      json = jsonDecode(content);
    } on FormatException {
      throw const ValidationException('El archivo no es un JSON válido.');
    }
    if (json is! Map || json['formato'] != formato) {
      throw const ValidationException(
        'El archivo no es un respaldo completo de esta app.',
      );
    }
    final v = json['version'];
    if (v is int && v > version) {
      throw const ValidationException(
        'El respaldo es de una versión más nueva de la app. Actualízala.',
      );
    }
    if (json['tablas'] is! Map) {
      throw const ValidationException('El respaldo no contiene datos.');
    }
    return json.cast<String, Object?>();
  }

  /// Reemplaza todo el contenido por el del respaldo (transacción).
  Future<void> restore(String content) async {
    final json = _parse(content);
    final datos = json['tablas'] as Map;
    final columnas = <String, Set<String>>{
      for (final t in db.allTables)
        t.actualTableName: {for (final c in t.$columns) c.name},
    };
    await db.transaction(() async {
      for (final t in tablas.reversed) {
        await db.customStatement('DELETE FROM $t');
      }
      for (final t in tablas) {
        final permitidas = columnas[t] ?? const <String>{};
        for (final row in (datos[t] as List?) ?? const []) {
          if (row is! Map) continue;
          final cols = [
            for (final k in row.keys)
              if (permitidas.contains(k)) k as String,
          ];
          if (cols.isEmpty) continue;
          await db.customInsert(
            'INSERT INTO $t (${cols.join(', ')}) '
            'VALUES (${List.filled(cols.length, '?').join(', ')})',
            variables: [for (final c in cols) _variable(row[c])],
          );
        }
      }
      await db.reconstruirBusqueda();
    });
    db.notifyUpdates({for (final t in db.allTables) TableUpdate.onTable(t)});

    final ajustes = json['ajustes'];
    if (ajustes is Map) {
      final prefs = await SharedPreferences.getInstance();
      for (final e in ajustes.entries) {
        final k = e.key as String;
        final w = e.value;
        if (w is! Map || _ajustesLocales.contains(k)) continue;
        final v = w['v'];
        switch (w['t']) {
          case 'bool':
            if (v is bool) await prefs.setBool(k, v);
          case 'int':
            if (v is num) await prefs.setInt(k, v.toInt());
          case 'double':
            if (v is num) await prefs.setDouble(k, v.toDouble());
          case 'string':
            if (v is String) await prefs.setString(k, v);
          case 'list':
            if (v is List) {
              await prefs.setStringList(k, [for (final s in v) '$s']);
            }
        }
      }
    }
  }

  static Variable _variable(Object? v) => switch (v) {
    null => const Variable(null),
    int() => Variable.withInt(v),
    double() => Variable.withReal(v),
    bool() => Variable.withBool(v),
    String() => Variable.withString(v),
    _ => Variable.withString('$v'),
  };
}
