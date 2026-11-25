-- Esquema v2 tal como lo creaba la app (para tests de migración).
-- Sentencias separadas por líneas '--'. Las categorías se siembran
-- aparte (ver el test).
--
CREATE TABLE "categorias" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "nombre" TEXT NOT NULL UNIQUE COLLATE NOCASE, "orden" INTEGER NOT NULL DEFAULT 0);
--
CREATE TABLE "alimentos" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "uuid" TEXT NOT NULL UNIQUE, "nombre" TEXT NOT NULL COLLATE NOCASE, "marca" TEXT NOT NULL DEFAULT '' COLLATE NOCASE, "tipo" TEXT NOT NULL DEFAULT 'generico' CHECK("tipo" IN ('generico', 'envasado', 'preparado')), "unidad" TEXT NOT NULL DEFAULT 'g' CHECK("unidad" IN ('g', 'ml')), "categoria_id" INTEGER NULL REFERENCES categorias (id) ON DELETE SET NULL, "kcal" REAL NULL CHECK("kcal" >= 0.0), "proteinas" REAL NULL CHECK("proteinas" >= 0.0), "grasas" REAL NULL CHECK("grasas" >= 0.0), "grasas_saturadas" REAL NULL CHECK("grasas_saturadas" >= 0.0), "carbohidratos" REAL NULL CHECK("carbohidratos" >= 0.0), "azucares" REAL NULL CHECK("azucares" >= 0.0), "fibra" REAL NULL CHECK("fibra" >= 0.0), "sal" REAL NULL CHECK("sal" >= 0.0), "nutricion_origen" TEXT NULL CHECK("nutricion_origen" IN ('manual', 'etiqueta_ocr', 'importado', 'calculado')), "notas" TEXT NULL, "uso_count" INTEGER NOT NULL DEFAULT 0, "ultimo_uso" TEXT NULL, "archivado" INTEGER NOT NULL DEFAULT 0 CHECK ("archivado" IN (0, 1)), "creado" TEXT NOT NULL, "actualizado" TEXT NOT NULL, UNIQUE ("nombre", "marca"));
--
CREATE TABLE "porciones" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "alimento_id" INTEGER NOT NULL REFERENCES alimentos (id) ON DELETE CASCADE, "nombre" TEXT NOT NULL COLLATE NOCASE, "gramos" REAL NOT NULL CHECK("gramos" > 0.0), UNIQUE ("alimento_id", "nombre"));
--
CREATE TABLE "presentaciones" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "uuid" TEXT NOT NULL UNIQUE, "alimento_id" INTEGER NOT NULL REFERENCES alimentos (id) ON DELETE CASCADE, "codigo_barras" TEXT NULL UNIQUE, "descripcion" TEXT NOT NULL DEFAULT '', "contenido" REAL NULL CHECK("contenido" > 0.0), "archivado" INTEGER NOT NULL DEFAULT 0 CHECK ("archivado" IN (0, 1)), "creado" TEXT NOT NULL, "actualizado" TEXT NOT NULL);
--
CREATE TABLE "establecimientos" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "nombre" TEXT NOT NULL UNIQUE COLLATE NOCASE, "formato_bascula" TEXT NULL CHECK("formato_bascula" IN ('precio', 'peso')), "longitud_clave" INTEGER NOT NULL DEFAULT 7 CHECK("longitud_clave" IN (6, 7)));
--
CREATE TABLE "orden_pasillos" ("establecimiento_id" INTEGER NOT NULL REFERENCES establecimientos (id) ON DELETE CASCADE, "categoria_id" INTEGER NOT NULL REFERENCES categorias (id) ON DELETE CASCADE, "orden" INTEGER NOT NULL, PRIMARY KEY ("establecimiento_id", "categoria_id"));
--
CREATE TABLE "codigos_bascula" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "establecimiento_id" INTEGER NOT NULL REFERENCES establecimientos (id) ON DELETE CASCADE, "clave" TEXT NOT NULL, "presentacion_id" INTEGER NOT NULL REFERENCES presentaciones (id) ON DELETE CASCADE, UNIQUE ("establecimiento_id", "clave"));
--
CREATE TABLE "compras" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "presentacion_id" INTEGER NOT NULL REFERENCES presentaciones (id) ON DELETE RESTRICT, "establecimiento_id" INTEGER NOT NULL REFERENCES establecimientos (id) ON DELETE RESTRICT, "fecha" TEXT NOT NULL, "precio_cent" INTEGER NOT NULL CHECK("precio_cent" > 0), "unidades" INTEGER NOT NULL DEFAULT 1 CHECK("unidades" >= 1), "peso_g" REAL NULL CHECK("peso_g" > 0.0));
--
CREATE TABLE "listas_compra" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "nombre" TEXT NOT NULL, "creada" TEXT NOT NULL);
--
CREATE TABLE "items_lista" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "lista_id" INTEGER NOT NULL REFERENCES listas_compra (id) ON DELETE CASCADE, "alimento_id" INTEGER NULL REFERENCES alimentos (id) ON DELETE SET NULL, "texto" TEXT NOT NULL, "cantidad" TEXT NULL, "orden" INTEGER NOT NULL, "comprado" INTEGER NOT NULL DEFAULT 0 CHECK ("comprado" IN (0, 1)), "compra_id" INTEGER NULL UNIQUE REFERENCES compras (id) ON DELETE SET NULL);
--
CREATE TABLE "recetas" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "uuid" TEXT NOT NULL UNIQUE, "nombre" TEXT NOT NULL, "categoria" TEXT NULL, "porciones" INTEGER NULL CHECK("porciones" > 0), "tiempo_min" INTEGER NULL, "elaboracion" TEXT NOT NULL DEFAULT '', "notas" TEXT NULL, "favorita" INTEGER NOT NULL DEFAULT 0 CHECK ("favorita" IN (0, 1)), "peso_final_g" REAL NULL CHECK("peso_final_g" > 0.0), "alimento_id" INTEGER NULL REFERENCES alimentos (id) ON DELETE SET NULL, "creada" TEXT NOT NULL, "actualizada" TEXT NOT NULL);
--
CREATE TABLE "ingredientes_receta" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "receta_id" INTEGER NOT NULL REFERENCES recetas (id) ON DELETE CASCADE, "orden" INTEGER NOT NULL, "texto" TEXT NOT NULL, "alimento_id" INTEGER NULL REFERENCES alimentos (id) ON DELETE SET NULL, "cantidad" REAL NULL CHECK("cantidad" > 0.0), "unidad" TEXT NULL, "opcional" INTEGER NOT NULL DEFAULT 0 CHECK ("opcional" IN (0, 1)));
--
CREATE TABLE "comidas" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "nombre" TEXT NOT NULL, "fecha" TEXT NOT NULL);
--
CREATE TABLE "items_comida" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "comida_id" INTEGER NOT NULL REFERENCES comidas (id) ON DELETE CASCADE, "alimento_id" INTEGER NULL REFERENCES alimentos (id) ON DELETE SET NULL, "nombre" TEXT NOT NULL, "cantidad" REAL NOT NULL CHECK("cantidad" > 0.0), "kcal" REAL NOT NULL, "proteinas" REAL NOT NULL, "grasas" REAL NOT NULL, "carbohidratos" REAL NOT NULL);
--
CREATE VIRTUAL TABLE alimentos_fts USING fts5(
    nombre, marca,
    content = 'alimentos', content_rowid = 'id',
    tokenize = 'unicode61 remove_diacritics 2'
  );
--
CREATE INDEX ix_porciones_alimento ON porciones(alimento_id);
--
CREATE INDEX ix_presentaciones_alimento ON presentaciones(alimento_id);
--
CREATE INDEX ix_compras_presentacion_fecha ON compras(presentacion_id, fecha);
--
CREATE INDEX ix_compras_establecimiento ON compras(establecimiento_id);
--
CREATE INDEX ix_items_lista ON items_lista(lista_id, orden);
--
CREATE INDEX ix_items_lista_alimento ON items_lista(alimento_id);
--
CREATE INDEX ix_ingredientes_receta ON ingredientes_receta(receta_id, orden);
--
CREATE INDEX ix_ingredientes_alimento ON ingredientes_receta(alimento_id);
--
CREATE INDEX ix_recetas_alimento ON recetas(alimento_id);
--
CREATE INDEX ix_comidas_fecha ON comidas(fecha);
--
CREATE INDEX ix_items_comida ON items_comida(comida_id);
--
CREATE INDEX ix_items_comida_alimento ON items_comida(alimento_id);
--
CREATE INDEX ix_alimentos_categoria ON alimentos(categoria_id);
--
CREATE INDEX ix_codigos_bascula_presentacion ON codigos_bascula(presentacion_id);
--
CREATE TRIGGER alimentos_fts_ai AFTER INSERT ON alimentos BEGIN
    INSERT INTO alimentos_fts(rowid, nombre, marca)
    VALUES (new.id, new.nombre, new.marca);
  END;
--
CREATE TRIGGER alimentos_fts_ad AFTER DELETE ON alimentos BEGIN
    INSERT INTO alimentos_fts(alimentos_fts, rowid, nombre, marca)
    VALUES ('delete', old.id, old.nombre, old.marca);
  END;
--
CREATE TRIGGER alimentos_fts_au AFTER UPDATE OF nombre, marca ON alimentos
  BEGIN
    INSERT INTO alimentos_fts(alimentos_fts, rowid, nombre, marca)
    VALUES ('delete', old.id, old.nombre, old.marca);
    INSERT INTO alimentos_fts(rowid, nombre, marca)
    VALUES (new.id, new.nombre, new.marca);
  END;
--
