import 'package:sqflite/sqflite.dart';

/// DDL de los módulos de recetas, productos/compras y listas de compra.
///
/// Se ejecuta en cada apertura desde `LocalDataSourceImpl._createTables`
/// (todo `IF NOT EXISTS`, idempotente). sqflite no activa `foreign_keys`, así
/// que los `REFERENCES` son documentales: los hijos se borran explícitamente
/// en transacción desde cada data source. Los `alimento_id` apuntan a
/// `db_alimentos` sin FK; si el alimento se borra se tratan como sin vincular.
Future<void> createModuleTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS recetas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      categoria TEXT,
      porciones INTEGER,
      tiempo_min INTEGER,
      elaboracion TEXT NOT NULL DEFAULT '',
      notas TEXT,
      favorita INTEGER NOT NULL DEFAULT 0,
      alimento_id INTEGER,
      peso_porcion_g REAL,
      creada TEXT NOT NULL,
      actualizada TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS ingredientes_receta (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      receta_id INTEGER NOT NULL REFERENCES recetas(id) ON DELETE CASCADE,
      orden INTEGER NOT NULL,
      texto TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_ingredientes_receta '
    'ON ingredientes_receta(receta_id, orden)',
  );

  await db.execute('''
    CREATE TABLE IF NOT EXISTS productos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      codigo_barras TEXT UNIQUE,
      nombre TEXT NOT NULL,
      marca TEXT,
      presentacion TEXT,
      alimento_id INTEGER,
      creado TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS compras (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      producto_id INTEGER NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
      fecha TEXT NOT NULL,
      precio REAL NOT NULL,
      establecimiento TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_compras_producto '
    'ON compras(producto_id, fecha)',
  );

  await db.execute('''
    CREATE TABLE IF NOT EXISTS listas_compra (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      creada TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS items_lista_compra (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lista_id INTEGER NOT NULL REFERENCES listas_compra(id) ON DELETE CASCADE,
      texto TEXT NOT NULL,
      cantidad TEXT,
      producto_id INTEGER,
      comprado INTEGER NOT NULL DEFAULT 0,
      orden INTEGER NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_items_lista_compra '
    'ON items_lista_compra(lista_id)',
  );
}
