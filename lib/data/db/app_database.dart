import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Nombre del archivo de la base de datos (en el directorio de documentos).
const String kDatabaseName = 'cal_counter';

/// Base de datos de la app (Drift sobre una SQLite moderna incluida en la
/// app: FTS5, claves foráneas y la misma versión en todos los dispositivos).
@DriftDatabase(
  tables: [
    Alimentos,
    Porciones,
    Presentaciones,
    Establecimientos,
    Compras,
    ListasCompra,
    ItemsLista,
    Recetas,
    IngredientesReceta,
    Comidas,
    ItemsComida,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Base de datos en el dispositivo.
  factory AppDatabase.dispositivo() =>
      AppDatabase(driftDatabase(name: kDatabaseName));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _crearIndices();
      await _crearBusqueda();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _crearIndices() async {
    for (final sql in _indices) {
      await customStatement(sql);
    }
  }

  /// Índice de búsqueda FTS5 sobre nombre y marca, sin tildes, sincronizado
  /// con `alimentos` mediante triggers.
  Future<void> _crearBusqueda() async {
    for (final sql in _fts) {
      await customStatement(sql);
    }
  }

  /// Reconstruye el índice de búsqueda (tras importaciones masivas).
  Future<void> reconstruirBusqueda() => customStatement(
    "INSERT INTO alimentos_fts(alimentos_fts) VALUES('rebuild')",
  );
}

const List<String> _indices = [
  'CREATE INDEX ix_porciones_alimento ON porciones(alimento_id)',
  'CREATE INDEX ix_presentaciones_alimento ON presentaciones(alimento_id)',
  'CREATE INDEX ix_compras_presentacion_fecha '
      'ON compras(presentacion_id, fecha)',
  'CREATE INDEX ix_compras_establecimiento ON compras(establecimiento_id)',
  'CREATE INDEX ix_items_lista ON items_lista(lista_id, orden)',
  'CREATE INDEX ix_items_lista_alimento ON items_lista(alimento_id)',
  'CREATE INDEX ix_ingredientes_receta ON ingredientes_receta(receta_id, orden)',
  'CREATE INDEX ix_ingredientes_alimento ON ingredientes_receta(alimento_id)',
  'CREATE INDEX ix_recetas_alimento ON recetas(alimento_id)',
  'CREATE INDEX ix_comidas_fecha ON comidas(fecha)',
  'CREATE INDEX ix_items_comida ON items_comida(comida_id)',
  'CREATE INDEX ix_items_comida_alimento ON items_comida(alimento_id)',
];

const List<String> _fts = [
  '''
  CREATE VIRTUAL TABLE alimentos_fts USING fts5(
    nombre, marca,
    content = 'alimentos', content_rowid = 'id',
    tokenize = 'unicode61 remove_diacritics 2'
  )''',
  '''
  CREATE TRIGGER alimentos_fts_ai AFTER INSERT ON alimentos BEGIN
    INSERT INTO alimentos_fts(rowid, nombre, marca)
    VALUES (new.id, new.nombre, new.marca);
  END''',
  '''
  CREATE TRIGGER alimentos_fts_ad AFTER DELETE ON alimentos BEGIN
    INSERT INTO alimentos_fts(alimentos_fts, rowid, nombre, marca)
    VALUES ('delete', old.id, old.nombre, old.marca);
  END''',
  '''
  CREATE TRIGGER alimentos_fts_au AFTER UPDATE OF nombre, marca ON alimentos
  BEGIN
    INSERT INTO alimentos_fts(alimentos_fts, rowid, nombre, marca)
    VALUES ('delete', old.id, old.nombre, old.marca);
    INSERT INTO alimentos_fts(rowid, nombre, marca)
    VALUES (new.id, new.nombre, new.marca);
  END''',
];
