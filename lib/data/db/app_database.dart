import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/services/category_guesser.dart';
import '../../domain/services/ingredient_matcher.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Nombre del archivo de la base de datos (en el directorio de documentos).
const String kDatabaseName = 'cal_counter';

/// Base de datos de la app (Drift sobre una SQLite moderna incluida en la
/// app: FTS5, claves foráneas y la misma versión en todos los dispositivos).
@DriftDatabase(
  tables: [
    Categorias,
    Alimentos,
    Porciones,
    Presentaciones,
    Establecimientos,
    OrdenPasillos,
    CodigosBascula,
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

  /// v1: esquema inicial. v2: categorías y orden de pasillos, etiquetas de
  /// báscula por tienda y peso real de las compras. v3: recetas como
  /// alimentos (tabla aproximada, nota de ingrediente, última preparación),
  /// artículos que no son alimentos y cantidad mínima en las listas.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _crearIndices(_indices);
      await _crearIndices(_indicesV2);
      await _crearBusqueda();
      await sembrarCategorias();
    },
    onUpgrade: (m, from, to) async {
      // Las claves foráneas se desactivan durante la migración (se vuelven
      // a activar en beforeOpen).
      await customStatement('PRAGMA foreign_keys = OFF');
      if (from < 2) {
        await m.createTable(categorias);
        await m.createTable(ordenPasillos);
        await m.createTable(codigosBascula);
        await m.addColumn(alimentos, alimentos.categoriaId);
        await m.addColumn(establecimientos, establecimientos.formatoBascula);
        await m.addColumn(establecimientos, establecimientos.longitudClave);
        await m.addColumn(compras, compras.pesoG);
        await _crearIndices(_indicesV2);
        await sembrarCategorias();
        await clasificarAlimentos();
      }
      if (from < 3) {
        await m.addColumn(alimentos, alimentos.nutricionAproximada);
        await m.addColumn(alimentos, alimentos.esAlimento);
        await m.addColumn(recetas, recetas.ultimaPreparacion);
        await m.addColumn(ingredientesReceta, ingredientesReceta.nota);
        await m.addColumn(itemsLista, itemsLista.cantidadMinima);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _crearIndices(List<String> sentencias) async {
    for (final sql in sentencias) {
      await customStatement(sql);
    }
  }

  /// Crea las categorías por defecto si no hay ninguna.
  Future<void> sembrarCategorias() async {
    final hay = await customSelect(
      'SELECT COUNT(*) AS n FROM categorias',
    ).getSingle();
    if (hay.read<int>('n') > 0) return;
    for (var i = 0; i < defaultCategories.length; i++) {
      await into(categorias).insert(
        CategoriasCompanion.insert(
          nombre: defaultCategories[i].nombre,
          orden: Value(i),
        ),
      );
    }
  }

  /// Asigna categoría (por su nombre) a los alimentos que no tienen.
  Future<int> clasificarAlimentos() async {
    final cats = await select(categorias).get();
    final porNombre = {for (final c in cats) normalizeText(c.nombre): c.id};
    final sin = await customSelect(
      'SELECT id, nombre FROM alimentos WHERE categoria_id IS NULL',
    ).get();
    var n = 0;
    for (final r in sin) {
      final guess = guessCategoryName(r.read<String>('nombre'));
      final id = guess == null ? null : porNombre[normalizeText(guess)];
      if (id == null) continue;
      await customUpdate(
        'UPDATE alimentos SET categoria_id = ? WHERE id = ?',
        variables: [Variable.withInt(id), Variable.withInt(r.read<int>('id'))],
        updates: {alimentos},
      );
      n++;
    }
    return n;
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

const List<String> _indicesV2 = [
  'CREATE INDEX ix_alimentos_categoria ON alimentos(categoria_id)',
  'CREATE INDEX ix_codigos_bascula_presentacion '
      'ON codigos_bascula(presentacion_id)',
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
