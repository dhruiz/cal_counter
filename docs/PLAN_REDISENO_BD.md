# Plan de rediseño: `alimentos` como núcleo de la aplicación

> Estado: **implementado** (fases 0–7) en la rama `claude/database-tables-recipes-kyqj0h`.
> Fecha: 2026-11-23. Decisiones aprobadas: todas las recomendadas en la sección 14.
>
> Notas de la implementación:
> - Fase 0: no se pudo compilar el APK en el entorno de desarrollo (sin SDK de
>   Android); se verificaron versiones y scripts de Gradle de cada plugin.
>   `google_mlkit_text_recognition` queda anclado a 0.16.x (0.17+ exige AGP 9).
> - Fase 7: categorías con orden de pasillo (general y por tienda) y etiquetas
>   de báscula aprendidas por tienda. Esquema v2 con migración desde v1
>   (ver 4.2 y 6). El detalle de uso está en el `README.md`.
> - El catálogo base tenía dos nombres que solo se distinguían por un signo
>   ("16%" y "- 16%"); el segundo se renombró a "menos de 16%".

## 0. Resumen

- **Un solo repertorio de alimentos.** La tabla `alimentos` sustituye a la vez a `db_alimentos` y a `productos`. Todo lo demás apunta a ella con claves foráneas reales: códigos de barras, compras, listas, ingredientes de recetas y comidas.
- **La tabla nutricional puede quedar pendiente.** Los valores nutricionales admiten `NULL` ("desconocido", que no es lo mismo que 0). Así un producto escaneado en el súper existe desde el primer momento, aunque todavía no tenga sus calorías.
- **El código de barras es una forma más de buscar y de dar de alta.** Hay uno o varios códigos por alimento, en la tabla `presentaciones` (un formato concreto: "Brick 1 L", "Pack 6 × 125 g"). Se puede buscar escribiendo el código o escaneándolo, desde cualquier pantalla.
- **Alta según dónde estés.** En la tienda solo se piden los datos básicos (nombre, marca, presentación y precio), nunca la tabla nutricional. En casa se pide completar lo que falte, con ayuda de OCR sobre la etiqueta.
- **Recetas conectadas.** Cada línea de ingrediente se puede vincular a un alimento con su cantidad. La receta calcula sus calorías y avisa de qué falta para poder hacerlo.
- **Exportar e importar pensado para compartir.** Un formato JSON versionado "repertorio" para pasar alimentos (y opcionalmente recetas) entre usuarios, que fusiona sin duplicar gracias a identificadores únicos (UUID). Además, un respaldo completo para cambiar de móvil. Se siguen aceptando los formatos antiguos (TSV de 6 columnas y `.db`).
- **Base técnica sólida.** Drift sobre una SQLite incluida en la app (claves foráneas activas, migraciones versionadas y probadas, búsqueda FTS5 que ignora tildes, consultas reactivas que refrescan solas la interfaz) y precios guardados en céntimos enteros.
- **OCR preparado desde el diseño.** Desde el principio existen la estructura de la tabla nutricional, el campo de origen del dato y un parser puro y testeable. El reconocimiento de texto es ML Kit, que funciona en el móvil y sin internet, igual que el escáner actual.

---

## 1. Diagnóstico del estado actual

| # | Hallazgo | Dónde | Consecuencia |
|---|---|---|---|
| 1 | Dos catálogos paralelos: `db_alimentos` y `productos`, unidos solo por un `alimento_id` opcional que se vincula a mano | `module_tables.dart`, `Product.alimentoId` | Lo que se compra nunca entra en el repertorio. Hay datos repetidos y flujos de "vincular" por todas partes. |
| 2 | Los valores nutricionales son `NOT NULL` | `local_data_source.dart:88` | No existe el estado "pendiente". Para dar algo de alta hay que inventar valores o poner ceros. |
| 3 | El código de barras vive fuera del repertorio | `productos.codigo_barras` | El buscador de texto no encuentra códigos y el selector de alimentos de recetas no tiene escáner. |
| 4 | Los ingredientes de las recetas son solo texto | `ingredientes_receta.texto` | Las calorías no se pueden calcular. Recetas, listas y carrito solo se relacionan por coincidencia de texto aproximada (`cart_matching.dart`). |
| 5 | Las claves foráneas nunca se activan (falta `PRAGMA foreign_keys = ON`) | `initDb` | Los `ON DELETE CASCADE` no hacen nada. Por eso hay borrados manuales y limpieza de huérfanos en cada apertura. |
| 6 | No hay migraciones versionadas: siempre `version: 1`, más `_ensureColumn` y el DDL completo en cada apertura | `initDb`, `module_tables.dart` | Ningún cambio de esquema se puede probar y no hay un camino claro para evolucionar la base. |
| 7 | **Bug:** `insertFood` usa `ConflictAlgorithm.replace` y el alta desde `FoodFormView` no comprueba si el nombre ya existe | `local_data_source.dart`, `food_form_view.dart:81` | Crear un alimento con un nombre que ya existe **borra el anterior y lo reinserta con otro `id`**. Los `alimento_id` de recetas y productos quedan colgando y `uso_count` vuelve a 0. A "Guardar comida como alimento" le pasa lo mismo cuando eliges sobrescribir. |
| 8 | **Bug:** `importDatabase` incrementa el contador aunque el registro se haya ignorado por duplicado | `local_data_source.dart` (`importedCount++`) | El mensaje "N alimentos importados" cuenta también los duplicados. |
| 9 | El "respaldo" `.db` solo contiene `db_alimentos` | `exportDatabase` | No es un respaldo real: faltan recetas, productos, compras, listas y ajustes. |
| 10 | Estado duplicado en el carrito: `items_lista_compra.unidades` y `precio_pagado` repiten lo que ya está en `compras` | `AddProductToCart`, `UpdateCartItem`, `RemoveFromCart` | Hay tres caminos que deben mantener sincronizadas dos copias del mismo dato. |
| 11 | El dinero se guarda como `REAL` con redondeo manual | `compras.precio` | Riesgo de errores de redondeo al sumar totales. |
| 12 | El dominio importa clases de la capa de datos | `export_database.dart`, `import_database.dart`, `export_foods_tsv.dart`, `import_foods_tsv.dart`, `save_meal_as_food.dart` | Se rompe la Clean Architecture que declara el proyecto. |
| 13 | Inyección de dependencias dispersa: `localDataSourceProvider` vive en `home_provider.dart` y la conexión es un singleton estático; los refrescos son manuales (`refresh()`, cadenas de `invalidate`) | `home_provider.dart`, `products_provider.dart` | Es frágil: ya hay trampas documentadas en CLAUDE.md ("tras `await saveProduct` releer el notifier"). |
| 14 | La búsqueda usa `LIKE '%q%'` sin plegar tildes ni ordenar por relevancia | `searchFoods` | "platano" no encuentra "Plátano". |
| 15 | La documentación dice "~1700 alimentos precargados", pero el asset tiene **678** (parecen de una tabla latinoamericana: "Arroz Blanco, variedad Araure"…) | `assets/db/db_ctrl_calorias.db` | La documentación no coincide con los datos. |
| 16 | No hay integración continua (no existe `.github/workflows`) | — | Los tests no se ejecutan automáticamente. |

---

## 2. Principios de diseño

1. **Una sola fuente de verdad por dato.** La nutrición vive en el alimento, el precio en la compra y el código en la presentación. Nada se copia, salvo los históricos que deben ser inmutables: los `items_comida` guardan una foto de los valores en el momento de comer.
2. **"Desconocido" no es cero.** `NULL` significa que falta el dato y la interfaz lo trata como pendiente.
3. **Integridad dentro de la base de datos.** Claves foráneas activas, `CHECK`, `UNIQUE` y transacciones en cada caso de uso que escriba en varias tablas.
4. **El historial no se rompe.** Un alimento con compras o en uso no se borra: se archiva.
5. **Pedir lo justo en el momento justo.** En la tienda, lo mínimo; en casa, completar.
6. **Todo en local.** Sin servicios online (decisión ya tomada). El OCR y el escáner funcionan en el propio móvil.
7. **Formatos de intercambio estables.** JSON versionado, tolerante a campos desconocidos e independiente del esquema interno.

---

## 3. Decisiones técnicas

### 3.1 Motor de base de datos: Drift sobre una SQLite incluida (recomendado)

| | Drift + SQLite incluida | Seguir con sqflite |
|---|---|---|
| Versión de SQLite | Moderna, la misma en todos los dispositivos | La del sistema Android: con `minSdk 24` puede ser **3.9**, sin FTS5, sin `UPSERT`, sin funciones de ventana y sin `RETURNING` |
| Búsqueda sin tildes | FTS5 con `remove_diacritics` | Hay que hacerla en Dart o con columnas derivadas |
| Migraciones | `schemaVersion` + `MigrationStrategy` + tests de migración generados | Escritas a mano y sin tests |
| Consultas | Comprobadas al compilar | Strings sin comprobar |
| Reactividad | `watch()` devuelve un `Stream`: la interfaz se actualiza sola | Llamadas manuales a `refresh()` e `invalidate` |
| Tests | Base en memoria (`NativeDatabase.memory()`), sin rutas FFI ni limpieza de ficheros | FFI con limpieza de rutas |
| Coste | Generación de código (`build_runner`) y una dependencia nativa más | Ninguno |

**Alternativa mínima** si Drift no compilara con la toolchain anclada (AGP 8.13.1): seguir con sqflite, pero con `onConfigure: PRAGMA foreign_keys = ON`, `version` y `onUpgrade` reales, y búsqueda sin tildes en Dart (unos pocos miles de filas en memoria se buscan sin coste apreciable). La Fase 0 lo decide con una prueba de compilación.

### 3.2 Otras decisiones

- **Riverpod:** el código nuevo usa `StreamProvider`, `Notifier` y `AsyncNotifier` (ya disponibles en la 2.6). `StateNotifier` está en modo legado; migrar a Riverpod 3 queda fuera de este plan.
- **Identidad global:** `uuid TEXT UNIQUE` en `alimentos`, `presentaciones` y `recetas`. El `id` entero sigue siendo la clave interna; el `uuid` permite fusionar repertorios de distintos usuarios sin duplicar.
- **Dinero:** `INTEGER` en céntimos (`precio_cent`). Se sigue mostrando con `AppUtils.formatPrecio` y se lee lo escrito con `RegisterPurchase.parsePrecio`.
- **Fechas:** los días como `TEXT 'YYYY-MM-DD'` (como ahora); las marcas de tiempo como ISO 8601.
- **Códigos de barras (GTIN):** se normalizan antes de guardar o buscar. Solo dígitos; validación del dígito de control para EAN-8, UPC-A, EAN-13 y GTIN-14; los UPC-A (12 dígitos) se convierten a EAN-13 añadiendo un `0` delante, para que el mismo producto no quede duplicado según el lector. Si se escribe a mano un código con el dígito de control mal, se avisa pero se permite guardarlo (códigos internos de tienda).
- **Nombres en el código:** se mantiene el estilo actual: clases en inglés y columnas, campos de la interfaz y comentarios en español.

---

## 4. Modelo de datos nuevo

### 4.1 Mapa de relaciones

```
categorias ─┐ (opcional)
            ▼
         alimentos ◄──────────────┬───────────────┬──────────────────┐
          │    │                  │               │                  │
          │    └─► porciones      │               │                  │
          ▼                       │               │                  │
   presentaciones (código)  ingredientes_receta  items_lista    items_comida (copia
          │                       │               │   │          + vínculo opcional)
          ▼                       ▼               │   │                 ▲
       compras ◄── establecimientos  recetas      │   │              comidas
          ▲                                       │   ▼
          └───────────── compra_id (carrito) ─────┘ listas_compra
```

12 tablas, más la tabla virtual de búsqueda `alimentos_fts`. `categorias` es opcional (Fase 7).

**Implementado (esquema v2, Fase 7):** 14 tablas. `categorias` pasa a ser obligatoria (se siembra con 13 categorías por defecto) y se añaden `orden_pasillos` (orden propio de cada tienda) y `codigos_bascula` (etiquetas de báscula aprendidas por tienda). Ver el final de 4.2.

### 4.2 Definición de las tablas (SQL equivalente al que generará Drift)

```sql
PRAGMA foreign_keys = ON;            -- en cada apertura (beforeOpen)

-- Repertorio central -------------------------------------------------------
CREATE TABLE alimentos (
  id                INTEGER PRIMARY KEY,
  uuid              TEXT    NOT NULL UNIQUE,
  nombre            TEXT    NOT NULL COLLATE NOCASE,
  marca             TEXT    NOT NULL DEFAULT '' COLLATE NOCASE,  -- '' = genérico
  tipo              TEXT    NOT NULL DEFAULT 'generico'
                    CHECK (tipo IN ('generico','envasado','preparado')),
  categoria_id      INTEGER REFERENCES categorias(id) ON DELETE SET NULL,
  unidad            TEXT    NOT NULL DEFAULT 'g' CHECK (unidad IN ('g','ml')),
  -- Tabla nutricional por 100 g/ml. NULL = desconocido (≠ 0).
  kcal              REAL CHECK (kcal >= 0),
  proteinas         REAL CHECK (proteinas >= 0),
  grasas            REAL CHECK (grasas >= 0),
  grasas_saturadas  REAL CHECK (grasas_saturadas >= 0),
  carbohidratos     REAL CHECK (carbohidratos >= 0),
  azucares          REAL CHECK (azucares >= 0),
  fibra             REAL CHECK (fibra >= 0),
  sal               REAL CHECK (sal >= 0),
  nutricion_origen  TEXT CHECK (nutricion_origen IN
                    ('manual','etiqueta_ocr','importado','calculado')),
  notas             TEXT,
  uso_count         INTEGER NOT NULL DEFAULT 0,
  ultimo_uso        TEXT,
  archivado         INTEGER NOT NULL DEFAULT 0,
  creado            TEXT    NOT NULL,
  actualizado       TEXT    NOT NULL,
  UNIQUE (nombre, marca)
);

-- Equivalencias caseras: "1 huevo = 60 g", "1 diente = 5 g", "1 taza = 240 ml"
CREATE TABLE porciones (
  id           INTEGER PRIMARY KEY,
  alimento_id  INTEGER NOT NULL REFERENCES alimentos(id) ON DELETE CASCADE,
  nombre       TEXT    NOT NULL COLLATE NOCASE,
  gramos       REAL    NOT NULL CHECK (gramos > 0),
  UNIQUE (alimento_id, nombre)
);

-- Formato comercial de un alimento; aquí viven los códigos de barras.
CREATE TABLE presentaciones (
  id             INTEGER PRIMARY KEY,
  uuid           TEXT    NOT NULL UNIQUE,
  alimento_id    INTEGER NOT NULL REFERENCES alimentos(id) ON DELETE CASCADE,
  codigo_barras  TEXT    UNIQUE,            -- GTIN normalizado; NULL = granel
  descripcion    TEXT    NOT NULL DEFAULT '',  -- "Brick 1 L", "Pack 6 × 125 g"
  contenido      REAL    CHECK (contenido > 0), -- neto total en la unidad del alimento
  archivado      INTEGER NOT NULL DEFAULT 0,
  creado         TEXT    NOT NULL,
  actualizado    TEXT    NOT NULL
);

-- Compras ------------------------------------------------------------------
CREATE TABLE establecimientos (
  id      INTEGER PRIMARY KEY,
  nombre  TEXT NOT NULL UNIQUE COLLATE NOCASE
);

CREATE TABLE compras (
  id                  INTEGER PRIMARY KEY,
  presentacion_id     INTEGER NOT NULL REFERENCES presentaciones(id) ON DELETE RESTRICT,
  establecimiento_id  INTEGER NOT NULL REFERENCES establecimientos(id) ON DELETE RESTRICT,
  fecha               TEXT    NOT NULL,                       -- YYYY-MM-DD
  precio_cent         INTEGER NOT NULL CHECK (precio_cent > 0),   -- precio unitario
  unidades            INTEGER NOT NULL DEFAULT 1 CHECK (unidades >= 1)
);
CREATE INDEX ix_compras_presentacion_fecha ON compras(presentacion_id, fecha);

CREATE TABLE listas_compra (
  id      INTEGER PRIMARY KEY,
  nombre  TEXT NOT NULL,
  creada  TEXT NOT NULL
);

CREATE TABLE items_lista (
  id           INTEGER PRIMARY KEY,
  lista_id     INTEGER NOT NULL REFERENCES listas_compra(id) ON DELETE CASCADE,
  alimento_id  INTEGER REFERENCES alimentos(id) ON DELETE SET NULL,  -- NULL = texto libre
  texto        TEXT    NOT NULL,
  cantidad     TEXT,                          -- "500 g", "2 bricks"
  orden        INTEGER NOT NULL,
  comprado     INTEGER NOT NULL DEFAULT 0,
  compra_id    INTEGER UNIQUE REFERENCES compras(id) ON DELETE SET NULL  -- carrito
);
CREATE INDEX ix_items_lista ON items_lista(lista_id, orden);

-- Recetas ------------------------------------------------------------------
CREATE TABLE recetas (
  id            INTEGER PRIMARY KEY,
  uuid          TEXT    NOT NULL UNIQUE,
  nombre        TEXT    NOT NULL,
  categoria     TEXT,
  porciones     INTEGER CHECK (porciones > 0),
  tiempo_min    INTEGER,
  elaboracion   TEXT    NOT NULL DEFAULT '',
  notas         TEXT,
  favorita      INTEGER NOT NULL DEFAULT 0,
  peso_final_g  REAL CHECK (peso_final_g > 0),   -- peso ya cocinado (opcional)
  alimento_id   INTEGER REFERENCES alimentos(id) ON DELETE SET NULL,  -- su alimento "preparado"
  creada        TEXT    NOT NULL,
  actualizada   TEXT    NOT NULL
);

CREATE TABLE ingredientes_receta (
  id           INTEGER PRIMARY KEY,
  receta_id    INTEGER NOT NULL REFERENCES recetas(id) ON DELETE CASCADE,
  orden        INTEGER NOT NULL,
  texto        TEXT    NOT NULL,              -- línea original, siempre se conserva
  alimento_id  INTEGER REFERENCES alimentos(id) ON DELETE SET NULL,
  cantidad     REAL CHECK (cantidad > 0),
  unidad       TEXT,                          -- 'g' | 'ml' | nombre de porción ("diente")
  opcional     INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX ix_ingredientes_receta ON ingredientes_receta(receta_id, orden);
CREATE INDEX ix_ingredientes_alimento ON ingredientes_receta(alimento_id);

-- Registro diario ----------------------------------------------------------
CREATE TABLE comidas (
  id      INTEGER PRIMARY KEY,
  nombre  TEXT NOT NULL,
  fecha   TEXT NOT NULL                       -- YYYY-MM-DD
);
CREATE INDEX ix_comidas_fecha ON comidas(fecha);

CREATE TABLE items_comida (
  id             INTEGER PRIMARY KEY,
  comida_id      INTEGER NOT NULL REFERENCES comidas(id) ON DELETE CASCADE,
  alimento_id    INTEGER REFERENCES alimentos(id) ON DELETE SET NULL,
  nombre         TEXT NOT NULL,               -- copia (histórico inmutable)
  cantidad       REAL NOT NULL CHECK (cantidad > 0),
  kcal           REAL NOT NULL,               -- ya escalados a la cantidad
  proteinas      REAL NOT NULL,
  grasas         REAL NOT NULL,
  carbohidratos  REAL NOT NULL
);

-- Búsqueda -----------------------------------------------------------------
CREATE VIRTUAL TABLE alimentos_fts USING fts5(
  nombre, marca,
  content = 'alimentos', content_rowid = 'id',
  tokenize = 'unicode61 remove_diacritics 2'
);
-- + triggers AFTER INSERT / UPDATE / DELETE en alimentos para mantenerla al día.

-- Opcional (Fase 7): orden de pasillo en las listas.
CREATE TABLE categorias (
  id      INTEGER PRIMARY KEY,
  nombre  TEXT    NOT NULL UNIQUE COLLATE NOCASE,
  orden   INTEGER NOT NULL DEFAULT 0
);
```

**Implementado en el esquema v2 (Fase 7)**, además de `categorias`:

```sql
ALTER TABLE alimentos        ADD COLUMN categoria_id INTEGER
  REFERENCES categorias(id) ON DELETE SET NULL;
ALTER TABLE establecimientos ADD COLUMN formato_bascula TEXT
  CHECK (formato_bascula IN ('precio','peso'));      -- NULL = sin aprender
ALTER TABLE establecimientos ADD COLUMN longitud_clave INTEGER NOT NULL DEFAULT 7
  CHECK (longitud_clave IN (6,7));
ALTER TABLE compras          ADD COLUMN peso_g REAL CHECK (peso_g > 0);  -- frescos al peso

-- Orden de los pasillos de una tienda; sin filas se usa categorias.orden.
CREATE TABLE orden_pasillos (
  establecimiento_id INTEGER NOT NULL REFERENCES establecimientos(id) ON DELETE CASCADE,
  categoria_id       INTEGER NOT NULL REFERENCES categorias(id)       ON DELETE CASCADE,
  orden              INTEGER NOT NULL,
  PRIMARY KEY (establecimiento_id, categoria_id)
);

-- Etiquetas de báscula: la parte fija del código identifica una
-- presentación "Al peso" en cada tienda.
CREATE TABLE codigos_bascula (
  id                 INTEGER PRIMARY KEY,
  establecimiento_id INTEGER NOT NULL REFERENCES establecimientos(id) ON DELETE CASCADE,
  clave              TEXT    NOT NULL,
  presentacion_id    INTEGER NOT NULL REFERENCES presentaciones(id)   ON DELETE CASCADE,
  UNIQUE (establecimiento_id, clave)
);
```

La migración v1 → v2 crea las tablas y columnas, siembra las categorías por defecto y clasifica los alimentos existentes por su nombre.

Los ajustes del usuario siguen en SharedPreferences y entran en el respaldo completo.

### 4.3 Por qué separar `alimentos` y `presentaciones`

- La **nutrición** es del producto: la leche X tiene la misma tabla por 100 ml en 1 L que en 1,5 L.
- El **código y el precio** son del envase: cada tamaño tiene su EAN y su precio.
- Así se pueden comparar precios **por kg o por litro** entre envases y tiendas: `precio_cent / contenido`.
- Los productos a granel (fruta, pescado) tienen una presentación sin código: "Granel, €/kg", con `contenido = 1000`.
- En la interfaz casi no se nota: escaneas un código nuevo, escribes "1 L" en *Presentación* y listo. Solo si escaneas otro tamaño del mismo producto se te ofrece "¿Es otra presentación de *Leche semidesnatada Hacendado*?".

---

## 5. Reglas de negocio

### 5.1 Completitud nutricional
- **Completa** = `kcal`, `proteinas`, `grasas` y `carbohidratos` no son `NULL`. El resto (saturadas, azúcares, fibra, sal) es opcional.
- Se calcula al vuelo; no se guarda ninguna columna derivada.
- La entidad `NutritionFacts` (valores nulables) expone `estaCompleta` y `faltantes`. La rellenan igual el formulario manual, el OCR, el importador y el cálculo de recetas.
- Comprobación de coherencia: si `kcal` se aleja más de un ±15 % de `4·P + 4·C + 9·G (+ 2·fibra)`, se avisa al guardar, pero no se bloquea.

### 5.2 Alta según el contexto
| Contexto | Qué se pide | Resultado |
|---|---|---|
| **Tienda** (lista, carrito, historial de precios) | Nombre\*, marca, presentación ("1 L"), contenido opcional y precio\* | Alimento `envasado` con la tabla pendiente, presentación con el código y compra, todo en **una transacción**. Nunca se pide la tabla nutricional. |
| **Casa** (Calorías, Alimentos, Recetas) | Datos básicos + tabla nutricional, con el botón **"Leer etiqueta"** (OCR) | Alimento completo. Si se deja a medias, queda pendiente. |

### 5.3 Calorías con un alimento pendiente
Un alimento sin tabla completa **no se registra con ceros**. Al elegirlo se abre "Completar tabla nutricional" (formulario + OCR). Si se cancela, no se añade nada.

### 5.4 Borrar y archivar
- Si un alimento no tiene compras ni aparece en recetas o listas → se borra de verdad (sus porciones y presentaciones caen en cascada).
- Si tiene compras → `ON DELETE RESTRICT` lo impide y la app lo **archiva**: desaparece del buscador y del selector, pero el historial sigue intacto. Los vínculos desde recetas, listas y comidas usan `SET NULL`, así que el texto se conserva.
- Se termina con el `REPLACE` actual (bug 7). Los duplicados se detectan antes de guardar: exactos por `UNIQUE (nombre, marca)` y parecidos con `normalizeText`, mostrando "Ya existe *Plátano* — ¿es este?".

### 5.5 Nutrición de las recetas
- Gramos de cada ingrediente: si la unidad es `g` o `ml`, la propia cantidad; si es una porción, `cantidad × porciones.gramos` ("2 dientes" × 5 g).
- `total = Σ gramos/100 × valor por 100`; `peso = peso_final_g ?? Σ gramos`; `por porción = total / porciones`.
- Estado de la receta:
  - **Completa**: todos los ingredientes no opcionales están vinculados, con cantidad convertible a gramos y con la tabla completa.
  - **Parcial**: se muestra el valor como mínimo ("≥ 420 kcal") junto con la lista de lo que falta.
- Los ingredientes "al gusto" sin cantidad (sal, pimienta) no bloquean el cálculo.
- **"Registrar porción"** añade a Calorías una foto de los valores calculados (`items_comida` con `alimento_id` del preparado, si existe).
- **"Añadir al repertorio"** crea o actualiza un alimento `preparado` (`nutricion_origen = 'calculado'`) vinculado con `recetas.alimento_id`. Se recalcula al editar la receta. Sustituye al "vincular receta a alimento" actual.
- **Vinculación asistida:** al guardar o importar una receta, `parseIngredientLine` y `ingredient_matcher` proponen alimento, cantidad y unidad para cada línea. Una pantalla "Vincular ingredientes" permite confirmarlos todos de golpe. El texto original nunca se pierde.

### 5.6 Compras y carrito
- El carrito ya no copia nada: `items_lista.compra_id` apunta a la compra, y las unidades y el precio salen de ahí. **Total = Σ unidades × precio de las compras enlazadas.**
- Al escanear: código → presentación → alimento → el artículo de la lista con ese `alimento_id`. La coincidencia por texto (`cart_matching`) queda solo como último recurso.
- Repetir un producto suma unidades a la misma compra. Desmarcar quita `compra_id` y **conserva** la compra en el historial. Quitar del carrito borra la compra.
- Precio de referencia en las listas: la última compra de cualquier presentación del alimento, con preferencia por la tienda elegida.
- Purga: se conservan **3 meses + la última compra de cada presentación** (la misma regla que hoy, aplicada por presentación).
- Lista desde una receta: los artículos heredan el `alimento_id` del ingrediente, así que luego coinciden exactamente en el carrito.

### 5.7 Lo que se mantiene igual
- `ExportDayToCsv` exporta y **vacía** el día (efecto deliberado). Mismo formato TAB y extensión `.csv`.
- Las fórmulas de TDEE, objetivos y carbohidratos residuales no cambian.
- Las ediciones de cantidad en `items_comida` siguen escalando por proporción sobre los valores guardados.

---

## 6. Flujos del código de barras

| Dónde se escanea | Código conocido | Código desconocido |
|---|---|---|
| **Carrito / lista** (tienda) | Ficha de precio (como ahora) | Aviso "Código no registrado" → alta mínima (5.2) + "¿Es otra presentación de…?" |
| **Historial de precios** (tienda) | Ficha del alimento → registrar compra | Alta mínima |
| **Buscador de alimentos / registrar comida** (casa) | Añadir a la comida; si está pendiente, completar primero | Alta completa con OCR |
| **Vincular ingrediente de receta** (casa) | Vincula | Alta completa con OCR |
| **Pestaña Alimentos** (casa) | Abre la ficha | Alta completa con OCR |

- **Búsqueda por texto:** si lo escrito son solo dígitos con longitud de GTIN (8, 12, 13 o 14), se busca primero el código exacto y después por texto.
- Siempre se puede escribir el código a mano (como ahora).
- **Más adelante (Fase 7):** los códigos de peso variable de la sección de frescos (EAN-13 que empiezan por `2`, con el precio o el peso incrustado). Se identifican por los primeros dígitos y se lee el precio del propio código.
  - **Implementado:** la clave son los 7 primeros dígitos (6 si la tienda usa dígito de control del precio en la posición 7) y el valor, las cifras 8 a 12. Como el formato cambia de un supermercado a otro, se aprende **por tienda**: si el valor es importe o peso (primera etiqueta), qué producto es cada clave y si la clave es de 6 dígitos. Con formato peso, el importe se calcula con el último €/kg de ese producto en la tienda. Varios paquetes del mismo producto se suman en una compra. En casa, la etiqueta se reconoce y precarga los gramos. Un código de báscula nunca se guarda como código de barras de una presentación.

### 6.1 Avisos de datos pendientes en casa
- **Contador** en la pestaña Alimentos ("3 pendientes") y filtro **"Pendientes de completar"**, ordenado por prioridad: usados en recetas, después comprados recientemente, después el resto.
- **En la receta:** tarjeta "Para calcular las calorías faltan:", con una fila por problema y su acción directa:
  - *Tomate triturado Hacendado* — sin tabla nutricional → **Leer etiqueta** / Completar
  - *Ajo* — falta el peso de 1 "diente" → Añadir porción
  - "una pizca de comino" — sin vincular → Vincular
- **Modo cocina** (paso a paso, con la pantalla siempre encendida): el mismo aviso al empezar, sin bloquear. Es el momento ideal, porque el envase está en la mano.
- **Al cerrar el carrito:** resumen "Has añadido 3 productos nuevos sin tabla nutricional; te los recordaremos en casa". Informativo, no bloquea.

---

## 7. Navegación e interfaz

Pestañas: **Calorías · Alimentos · Recetas · Compras**. La pestaña Productos desaparece y se integra en Alimentos.

- **Alimentos (repertorio):** buscador por texto o código con botón de escanear. Filtros: todos, pendientes, envasados, genéricos, preparados y archivados. Crear nuevo.
- **Ficha del alimento:** nombre, marca y distintivos (pendiente, preparado), tabla nutricional (con *Completar* y *Leer etiqueta*), porciones, presentaciones y códigos (con *añadir código escaneando*), precios (último, mínimo, por tienda, €/kg) y "Usado en recetas".
- **`FoodPicker` único**, el mismo en todas partes: búsqueda, escanear, más usados y "Crear «lo que escribiste»".
- **Compras:** listas, modo carrito e historial de precios (exportable).
- **Recetas:** como ahora, más nutrición calculada, la tarjeta de pendientes, "Vincular ingredientes" y el modo cocina.
- **Ajustes → Datos:** exportar e importar repertorio, respaldo completo, TSV y formatos antiguos.

---

## 8. Exportar, importar y compartir

### 8.1 Formatos
| Formato | Contenido | Uso | Al importar |
|---|---|---|---|
| **Repertorio** `.json` | Alimentos + porciones + presentaciones (códigos); recetas si se marca la casilla | Compartir con otros usuarios | **Fusiona** (8.2) |
| **Respaldo completo** `.json` | Todo: tablas + ajustes | Cambio de móvil o copia de seguridad | **Reemplaza**, previa confirmación y con un respaldo automático del estado actual antes |
| **TSV de alimentos** | Cabecera ampliada: `uuid, nombre, marca, codigos, unidad, kcal, …` | Hoja de cálculo | Fusiona; **también acepta la cabecera antigua** de 6 columnas |
| **`.db` antiguo** | La tabla `db_alimentos` de versiones anteriores | Repertorios que ya circulan | Fusiona |
| Recetas `.txt` / JSON / CSV | `RecipeTextCodec` (sin cambios) | Compartir recetas sueltas | Igual que ahora |
| CSV diario / historial de precios | Sin cambios | — | — |

El repertorio **nunca** incluye datos personales: ni comidas, ni compras, ni precios, ni contadores de uso, ni ajustes.

Estructura del archivo:

```json
{
  "formato": "cal_counter/repertorio",
  "version": 1,
  "exportado": "2026-11-23T18:00:00Z",
  "alimentos": [
    {
      "uuid": "6f1c…", "nombre": "Leche semidesnatada", "marca": "Hacendado",
      "tipo": "envasado", "unidad": "ml",
      "nutricion": { "kcal": 46, "proteinas": 3.1, "grasas": 1.6,
                     "grasas_saturadas": 1.0, "carbohidratos": 4.7,
                     "azucares": 4.7, "sal": 0.13, "origen": "etiqueta_ocr" },
      "porciones": [{ "nombre": "vaso", "gramos": 250 }],
      "presentaciones": [{ "uuid": "a93e…", "codigo_barras": "8480000123456",
                           "descripcion": "Brick 1 L", "contenido": 1000 }]
    }
  ],
  "recetas": []
}
```

- Las versiones mayores más nuevas se rechazan con un mensaje claro. Los campos desconocidos se ignoran.
- Se exporta y se importa con SAF, como ahora (`FilePicker.saveFile(bytes:)` y `pickFiles(withData: true)`).

### 8.2 Fusión al importar un repertorio
1. Para cada alimento importado se busca su pareja local, en este orden: **mismo `uuid`** → **mismo código de barras** en alguna presentación → **mismo nombre y marca normalizados**.
2. Si **no hay pareja**, se inserta conservando el `uuid`.
3. Si **hay pareja**:
   - Se **rellenan los huecos** (los campos `NULL` locales toman el valor importado).
   - Si los dos tienen valores distintos, se aplica la política elegida en la vista previa: *Conservar los míos* (por defecto), *Usar los importados* o *Revisar uno a uno*.
4. **Conflicto de código** (el mismo código apunta a otro alimento local): se informa y se conserva el local.
5. **Vista previa** antes de aplicar: "120 nuevos · 35 completados · 4 conflictos". Todo se aplica en **una transacción**: o se importa todo o nada.
6. El resultado muestra contadores **reales** (corrige el bug 8).

### 8.3 Catálogo base y primer arranque
- El `.db` precargado se convierte en `assets/semilla/alimentos_base.json` con formato de repertorio.
- **Primera pantalla:** *Empezar con el catálogo base (678 alimentos)* · *Empezar vacío* · *Restaurar un respaldo* · *Importar un repertorio*.
- **Migración de la instalación actual:** si existe `db_ctrl_calorias.db`, se ofrece "Importar tus datos de la versión anterior" (ver Apéndice A). El archivo antiguo **no se toca**: se lee, se copia al esquema nuevo y queda guardado como respaldo hasta que lo borres. Se puede empezar vacío, pero no hace falta perder nada.

---

## 9. OCR de la etiqueta nutricional

### 9.1 Componentes
| Pieza | Capa | Detalle |
|---|---|---|
| Captura | Presentación | Foto fija con `image_picker` (cámara) y recorte opcional. El escáner de códigos sigue con `mobile_scanner`. |
| `TextRecognizer` (interfaz) | Dominio | Devuelve líneas con sus cajas (posición en la imagen). |
| `MlKitTextRecognizer` | Datos | `google_mlkit_text_recognition`, modelo latino **incluido en la app**: sin internet ni Google Play Services. |
| `NutritionLabelParser` | Dominio (Dart puro) | Texto → `NutritionFacts` + confianza por campo. 100 % testeable con textos de prueba. |
| Pantalla de revisión | Presentación | Formulario prerrellenado, campos dudosos resaltados y miniatura de la foto. **Nunca se guarda sin que confirmes.** |

### 9.2 Qué tiene que resolver el parser
- **Etiqueta UE** (Reglamento 1169/2011), en este orden: valor energético (kJ/kcal), grasas, *de las cuales saturadas*, hidratos de carbono, *de los cuales azúcares*, fibra, proteínas y sal. Por eso el esquema guarda esos 8 campos.
- **Varios idiomas** en el mismo envase (ES/PT/FR/EN/IT): diccionario de etiquetas por idioma ("lípidos", "matières grasses", "fat"…).
- **Columna correcta:** "por 100 g / 100 ml" frente a "por ración". Si solo aparece por ración y se lee su peso, se convierte a 100 g.
- **Energía:** "1046 kJ / 250 kcal" → se toma kcal. Si solo aparece kJ → `kJ / 4,184`.
- **Números:** coma decimal, "<0,5 g", "trazas" → 0, y confusiones típicas del OCR (`O`→`0`, `l`→`1`, "g" pegado al número).
- **Geometría:** agrupar por filas usando la coordenada vertical de cada caja para emparejar la etiqueta con su valor en tablas de dos columnas.
- **Validación:** saturadas ≤ grasas, azúcares ≤ carbohidratos, suma de macros ≤ 100 g y coherencia de kcal (5.1). Lo que no cuadra se marca para revisar.
- **Extra:** leer el contenido neto ("500 g", "1 L") para proponer la presentación. El nombre y la marca no se leen por OCR: es poco fiable en el frontal del envase.

### 9.3 Qué queda preparado desde la Fase 1
Los 8 campos nutricionales, `nutricion_origen = 'etiqueta_ocr'`, el formulario con el orden de la etiqueta UE, la entidad `NutritionFacts` compartida y un hueco para el botón "Leer etiqueta". El OCR se puede añadir en la Fase 6 sin tocar el esquema.

---

## 10. Arquitectura del código

```
lib/
  core/                     estilos, utilidades, formato de precio
  domain/
    entities/               Food, NutritionFacts, FoodPortion, FoodPackage, Purchase,
                            Store, ShoppingList, ShoppingItem, Recipe, RecipeIngredient,
                            Meal, MealItem, UserSettings
    repositories/           interfaces (las listas devuelven Stream)
    services/               barcode.dart (GTIN), nutrition_calculator.dart,
                            nutrition_label_parser.dart, ingredient_matcher.dart,
                            repertoire_merge.dart, cart_matching.dart
    usecases/               un caso de uso por acción; varias escrituras = una transacción
  data/
    db/                     app_database.dart (Drift), tables/, daos/, migrations/
    backup/                 repertoire_codec.dart, full_backup_codec.dart,
                            foods_tsv_codec.dart, legacy_db_importer.dart
    ocr/                    mlkit_text_recognizer.dart
    parsers/                recipe_text_codec.dart (se mantiene)
    repositories/           implementaciones
  presentation/
    providers/core_providers.dart   base de datos (con onDispose → close) y repositorios
    providers/…                     uno por módulo
    views/, widgets/
```

Reglas:
- `domain/` no importa nada de `data/` (corrige el hallazgo 12).
- La conexión se crea en un solo provider; no hay singleton estático.
- Las listas se observan con `watch()` y desaparecen los `refresh()` y las cadenas de `invalidate` manuales.

---

## 11. Calidad y pruebas

- **Tests de DAO** con la base en memoria de Drift: restricciones, cascadas, `RESTRICT` y archivado, FTS y purga.
- **Tests de migración** con los esquemas versionados de `drift_dev`, y prueba del importador desde la versión antigua con un `.db` real de ejemplo.
- **Servicios puros:**
  - GTIN (dígito de control, UPC-A → EAN-13).
  - Cálculo de nutrición de recetas (completo, parcial, porciones).
  - Fusión de repertorios (los cuatro casos de 8.2).
  - Carrito.
  - Parser OCR con **unos 20 textos reales de etiquetas** (marcas blancas y de fabricante, de una y dos columnas, multilingües).
- **Tests de widgets** con la base en memoria en lugar de los repositorios falsos escritos a mano (`fakes.dart`, 334 líneas).
- **Integración continua (GitHub Actions):** `flutter analyze` y `flutter test` en cada push.
- **Documentación:** README y CLAUDE.md se reescriben al final de cada fase. Este plan queda como registro de decisiones.

---

## 12. Fases de implementación

Cada fase deja la app compilando y usable, con sus tests.

| Fase | Contenido | Criterio de aceptación |
|---|---|---|
| **0. Prueba técnica** | Fijar versiones exactas. Compilar un APK con Drift + SQLite incluida + `google_mlkit_text_recognition` + `image_picker` sobre la toolchain actual (AGP 8.13.1). Medir el tamaño del APK. | El APK de release compila y arranca. Decidimos Drift o el plan B (3.1). |
| **1. Núcleo de datos** | Esquema v1, DAOs, claves foráneas, `core_providers`, entidades e interfaces nuevas, `NutritionFacts`, servicio GTIN. | Tests de DAO y de servicios en verde. |
| **2. Repertorio** | Pestaña Alimentos, `FoodPicker` único, búsqueda FTS + código, alta y edición con tabla nutricional parcial, porciones, presentaciones, archivado, pendientes. Calorías adaptada (5.3). | Buscar "platano" encuentra "Plátano"; escanear abre el alimento; un pendiente no se registra con ceros. |
| **3. Compras** | Listas, carrito e historial sobre presentaciones; alta mínima en tienda; precios en céntimos; establecimientos; €/kg. Desaparece la pestaña Productos. | Un código desconocido en el carrito crea alimento pendiente + presentación + compra en una transacción, sin pedir la tabla. |
| **4. Recetas** | Ingredientes vinculados con cantidad, vinculación asistida, cálculo de nutrición, tarjeta de pendientes, modo cocina, registrar porción y alimento preparado. | Una receta con todos sus ingredientes completos muestra kcal por porción; si falta algo, lo lista con su acción. |
| **5. Datos** | Repertorio JSON con fusión y vista previa, respaldo completo, TSV ampliado + legado, importador de `.db` antiguo, catálogo base, primer arranque y migración de la instalación actual. | Exportar → importar en una base vacía da los mismos datos; importar dos veces no duplica nada. |
| **6. OCR** | Captura, ML Kit, parser con textos reales, pantalla de revisión. | Al menos el 80 % de las etiquetas de prueba sin corrección manual en los 4 macros. |
| **7. Pulido (opcional)** | Categorías y orden de pasillo, códigos de peso variable, rendimiento, accesibilidad, limpieza del código antiguo, documentación final. **Implementado:** categorías y pasillos (general y por tienda), etiquetas de báscula, esquema v2 con migración probada, documentación. | Migrar una base v1 con datos da el mismo esquema que una instalación nueva; una etiqueta de báscula aprendida en una tienda se reconoce en el carrito y en casa. |

---

## 13. Riesgos y cómo mitigarlos

| Riesgo | Mitigación |
|---|---|
| La toolchain Android es frágil (AGP/KGP anclados) y los plugins nuevos podrían no compilar | Fase 0 antes de escribir código. Plan B: sqflite con claves foráneas y búsqueda en Dart. |
| Tamaño del APK (modelo OCR incluido, unos +4–8 MB por arquitectura) | `flutter build apk --split-per-abi`. Medirlo en la Fase 0. |
| El OCR falla con envases curvos o con brillos | La revisión es obligatoria y se puede editar a mano; el parser tiene tests; se puede recortar la foto. |
| Errores al migrar los datos actuales | El archivo antiguo no se modifica nunca; la migración se puede repetir; hay tests con un `.db` real. |
| Alcance grande | Fases entregables por separado; se puede parar tras la 5 y dejar el OCR para después. |
| En este contenedor no está instalado Flutter | Intentaré instalarlo aquí para `analyze` y los tests. Compilar el APK y probar en el móvil se hace en tu máquina. |

---

## 14. Decisiones que necesito de ti

Cada una tiene mi recomendación. Si no dices nada, aplico la recomendada.

1. **Motor:** Drift + SQLite incluida *(recomendado)* o seguir con sqflite.
2. **Datos actuales:** migrarlos al esquema nuevo conservando el archivo antiguo *(recomendado)* o empezar vacío.
3. **Catálogo base:** ofrecer los 678 alimentos genéricos al primer arranque *(recomendado)* o no incluir catálogo.
4. **Nutrientes ampliados** (saturadas, azúcares, fibra, sal): guardarlos y mostrarlos, con los objetivos diarios en kcal/P/G/C como ahora *(recomendado)*, o guardar solo los 4 macros.
5. **Alimento pendiente en Calorías:** pedir que se complete en ese momento *(recomendado)* o permitir registrarlo marcado como incompleto.
6. **Recetas en el repertorio compartido:** casilla opcional al exportar *(recomendado)*, siempre o nunca.
7. **Categorías y orden de pasillo:** en la Fase 7 *(recomendado)* o desde la Fase 3.

---

## Apéndice A. Correspondencia entre tablas antiguas y nuevas (migración)

| Antiguo | Nuevo |
|---|---|
| `db_alimentos` | `alimentos`: `alimento`→`nombre`, `kCal`→`kcal`, `marca=''`, `tipo='generico'`, `nutricion_origen='importado'`; se conservan `uso_count` y `ultimo_uso` |
| `productos` | Un alimento `envasado` por producto (nombre y marca). Si estaba vinculado a un alimento, **se copia su tabla nutricional**; si no, queda pendiente. Más una `presentacion` (`codigo_barras` normalizado, `presentacion`→`descripcion`). |
| `compras` | `compras`: presentación del producto; `establecimiento`→`establecimientos` (sin duplicados por mayúsculas); `precio`→`precio_cent` |
| `listas_compra` / `items_lista_compra` | `listas_compra` / `items_lista`: `producto_id`→`alimento_id` del alimento creado. Carrito: `unidades` y `precio_pagado` pasan a la compra enlazada. |
| `recetas` / `ingredientes_receta` | Las mismas tablas; `alimento_id` se traduce; los ingredientes quedan sin vincular, a la espera de la vinculación asistida |
| `comidas` / `items_comida` | Las mismas tablas; `alimento`→`nombre`; `alimento_id` por coincidencia exacta de nombre |
