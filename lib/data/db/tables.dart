// Patrón habitual de Drift: `check()` referencia la propia columna.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

// Esquema de la base de datos (v1 en docs/PLAN_REDISENO_BD.md, sección 4;
// v2 y v3 añaden las columnas marcadas).
// Las claves foráneas se activan en cada apertura (`PRAGMA foreign_keys`).
// Los días se guardan como TEXT 'YYYY-MM-DD'; las marcas de tiempo como
// ISO 8601. El dinero, en céntimos (INTEGER).

/// Secciones del súper. [orden] es el orden general de los pasillos (v2).
@DataClassName('CategoriaRow')
class Categorias extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()
      .withLength(min: 1)
      .customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  IntColumn get orden => integer().withDefault(const Constant(0))();
}

/// Repertorio central de alimentos. Nutrición por 100 g/ml; NULL = desconocido.
@DataClassName('AlimentoRow')
class Alimentos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get nombre =>
      text().withLength(min: 1).customConstraint('NOT NULL COLLATE NOCASE')();
  TextColumn get marca => text()
      .clientDefault(() => '')
      .customConstraint("NOT NULL DEFAULT '' COLLATE NOCASE")();
  TextColumn get tipo => text()
      .withDefault(const Constant('generico'))
      .check(tipo.isIn(['generico', 'envasado', 'preparado']))();
  TextColumn get unidad =>
      text().withDefault(const Constant('g')).check(unidad.isIn(['g', 'ml']))();
  // v2
  IntColumn get categoriaId => integer().nullable().references(
    Categorias,
    #id,
    onDelete: KeyAction.setNull,
  )();
  RealColumn get kcal =>
      real().nullable().check(kcal.isBiggerOrEqualValue(0))();
  RealColumn get proteinas =>
      real().nullable().check(proteinas.isBiggerOrEqualValue(0))();
  RealColumn get grasas =>
      real().nullable().check(grasas.isBiggerOrEqualValue(0))();
  RealColumn get grasasSaturadas =>
      real().nullable().check(grasasSaturadas.isBiggerOrEqualValue(0))();
  RealColumn get carbohidratos =>
      real().nullable().check(carbohidratos.isBiggerOrEqualValue(0))();
  RealColumn get azucares =>
      real().nullable().check(azucares.isBiggerOrEqualValue(0))();
  RealColumn get fibra =>
      real().nullable().check(fibra.isBiggerOrEqualValue(0))();
  RealColumn get sal => real().nullable().check(sal.isBiggerOrEqualValue(0))();
  TextColumn get nutricionOrigen => text().nullable().check(
    nutricionOrigen.isIn(['manual', 'etiqueta_ocr', 'importado', 'calculado']),
  )();
  TextColumn get notas => text().nullable()();
  IntColumn get usoCount => integer().withDefault(const Constant(0))();
  TextColumn get ultimoUso => text().nullable()();
  BoolColumn get archivado => boolean().withDefault(const Constant(false))();
  TextColumn get creado => text()();
  TextColumn get actualizado => text()();
  // v3: la tabla es una aproximación (receta sin peso final o con
  // ingredientes sin datos).
  BoolColumn get nutricionAproximada =>
      boolean().withDefault(const Constant(false))();
  // v3: false = artículo que no es un alimento (limpieza, higiene...): se
  // compra y se lleva su historial, pero no tiene tabla nutricional.
  BoolColumn get esAlimento => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {nombre, marca},
  ];
}

/// Equivalencias caseras: "1 diente = 5 g".
@DataClassName('PorcionRow')
class Porciones extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get alimentoId =>
      integer().references(Alimentos, #id, onDelete: KeyAction.cascade)();
  TextColumn get nombre =>
      text().withLength(min: 1).customConstraint('NOT NULL COLLATE NOCASE')();
  RealColumn get gramos => real().check(gramos.isBiggerThanValue(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {alimentoId, nombre},
  ];
}

/// Presentación comercial de un alimento; aquí viven los códigos de barras.
@DataClassName('PresentacionRow')
class Presentaciones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get alimentoId =>
      integer().references(Alimentos, #id, onDelete: KeyAction.cascade)();
  TextColumn get codigoBarras => text().nullable().unique()();
  TextColumn get descripcion => text().withDefault(const Constant(''))();
  RealColumn get contenido =>
      real().nullable().check(contenido.isBiggerThanValue(0))();
  BoolColumn get archivado => boolean().withDefault(const Constant(false))();
  TextColumn get creado => text()();
  TextColumn get actualizado => text()();
}

/// Tiendas, con el formato aprendido de sus etiquetas de báscula (v2).
@DataClassName('EstablecimientoRow')
class Establecimientos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()
      .withLength(min: 1)
      .customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  // v2: 'precio' (importe en céntimos) o 'peso' (gramos); NULL = sin aprender.
  TextColumn get formatoBascula =>
      text().nullable().check(formatoBascula.isIn(['precio', 'peso']))();
  // v2: dígitos fijos que identifican el producto (6 o 7).
  IntColumn get longitudClave => integer()
      .withDefault(const Constant(7))
      .check(longitudClave.isIn([6, 7]))();
}

/// Orden de los pasillos de una tienda concreta (v2). Sin filas, la tienda
/// usa el orden general de `categorias`.
@DataClassName('OrdenPasilloRow')
class OrdenPasillos extends Table {
  IntColumn get establecimientoId => integer().references(
    Establecimientos,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get categoriaId =>
      integer().references(Categorias, #id, onDelete: KeyAction.cascade)();
  IntColumn get orden => integer()();

  @override
  Set<Column> get primaryKey => {establecimientoId, categoriaId};
}

/// Etiquetas de báscula aprendidas (v2): en cada tienda, la parte fija del
/// código identifica una presentación "al peso" de un alimento.
@DataClassName('CodigoBasculaRow')
class CodigosBascula extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get establecimientoId => integer().references(
    Establecimientos,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get clave => text()();
  IntColumn get presentacionId =>
      integer().references(Presentaciones, #id, onDelete: KeyAction.cascade)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {establecimientoId, clave},
  ];
}

/// Historial de precios. RESTRICT: una presentación con compras no se borra
/// (se archiva), así el historial nunca se rompe.
@DataClassName('CompraRow')
class Compras extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get presentacionId =>
      integer().references(Presentaciones, #id, onDelete: KeyAction.restrict)();
  IntColumn get establecimientoId => integer().references(
    Establecimientos,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get fecha => text()();
  IntColumn get precioCent =>
      integer().check(precioCent.isBiggerThanValue(0))();
  IntColumn get unidades => integer()
      .withDefault(const Constant(1))
      .check(unidades.isBiggerOrEqualValue(1))();
  // v2: peso neto real de la compra (frescos al peso), para el €/kg.
  RealColumn get pesoG => real().nullable().check(pesoG.isBiggerThanValue(0))();
}

@DataClassName('ListaCompraRow')
class ListasCompra extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get creada => text()();
}

/// Artículos de las listas. En el carrito, [compraId] apunta a la compra y de
/// ella salen unidades y precio (nada se copia).
@DataClassName('ItemListaRow')
class ItemsLista extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listaId =>
      integer().references(ListasCompra, #id, onDelete: KeyAction.cascade)();
  IntColumn get alimentoId => integer().nullable().references(
    Alimentos,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get texto => text()();
  TextColumn get cantidad => text().nullable()();
  IntColumn get orden => integer()();
  BoolColumn get comprado => boolean().withDefault(const Constant(false))();
  IntColumn get compraId => integer().nullable().unique().references(
    Compras,
    #id,
    onDelete: KeyAction.setNull,
  )();
  // v3: cantidad mínima que hace falta (g o ml del alimento), p. ej. la suma
  // de lo que piden las recetas. [cantidad] es el texto que se muestra.
  RealColumn get cantidadMinima =>
      real().nullable().check(cantidadMinima.isBiggerThanValue(0))();
}

@DataClassName('RecetaRow')
class Recetas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get nombre => text()();
  TextColumn get categoria => text().nullable()();
  IntColumn get porciones =>
      integer().nullable().check(porciones.isBiggerThanValue(0))();
  IntColumn get tiempoMin => integer().nullable()();
  TextColumn get elaboracion => text().withDefault(const Constant(''))();
  TextColumn get notas => text().nullable()();
  BoolColumn get favorita => boolean().withDefault(const Constant(false))();
  RealColumn get pesoFinalG =>
      real().nullable().check(pesoFinalG.isBiggerThanValue(0))();
  IntColumn get alimentoId => integer().nullable().references(
    Alimentos,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get creada => text()();
  TextColumn get actualizada => text()();
  // v3: último día en que se preparó ('YYYY-MM-DD').
  TextColumn get ultimaPreparacion => text().nullable()();
}

@DataClassName('IngredienteRecetaRow')
class IngredientesReceta extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recetaId =>
      integer().references(Recetas, #id, onDelete: KeyAction.cascade)();
  IntColumn get orden => integer()();
  TextColumn get texto => text()();
  IntColumn get alimentoId => integer().nullable().references(
    Alimentos,
    #id,
    onDelete: KeyAction.setNull,
  )();
  RealColumn get cantidad =>
      real().nullable().check(cantidad.isBiggerThanValue(0))();
  TextColumn get unidad => text().nullable()();
  BoolColumn get opcional => boolean().withDefault(const Constant(false))();
  // v3: nota de la línea ("picada", "en dados").
  TextColumn get nota => text().nullable()();
}

@DataClassName('ComidaRow')
class Comidas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get fecha => text()();
}

/// Alimentos consumidos: valores YA escalados y nombre copiado (histórico).
@DataClassName('ItemComidaRow')
class ItemsComida extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get comidaId =>
      integer().references(Comidas, #id, onDelete: KeyAction.cascade)();
  IntColumn get alimentoId => integer().nullable().references(
    Alimentos,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get nombre => text()();
  RealColumn get cantidad => real().check(cantidad.isBiggerThanValue(0))();
  RealColumn get kcal => real()();
  RealColumn get proteinas => real()();
  RealColumn get grasas => real()();
  RealColumn get carbohidratos => real()();
}
