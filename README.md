# cal_counter — alimentos, calorías, recetas y compras

Aplicación Flutter (Android primario) para llevar las calorías y macros del día, guardar recetas y hacer la compra, todo alrededor de **un único repertorio de alimentos**. Interfaz y datos en **español**. Todo funciona en local, sin servicios online: el escáner de códigos y el OCR de etiquetas se ejecutan en el móvil.

> El diseño y las decisiones de este modelo están en [`docs/PLAN_REDISENO_BD.md`](docs/PLAN_REDISENO_BD.md).

---

## Índice

1. [Qué hace](#qué-hace)
2. [Entorno y comandos](#entorno-y-comandos)
3. [Arquitectura](#arquitectura)
4. [Modelo de datos](#modelo-de-datos)
5. [Flujos principales](#flujos-principales)
6. [Exportar, importar y compartir](#exportar-importar-y-compartir)
7. [OCR de etiquetas](#ocr-de-etiquetas)
8. [Calorías: objetivos, TDEE y día](#calorías-objetivos-tdee-y-día)
9. [Configuración Android](#configuración-android)
10. [Dependencias](#dependencias)
11. [Pruebas](#pruebas)
12. [Reglas que no deben romperse](#reglas-que-no-deben-romperse)

---

## Qué hace

Cuatro pestañas (`MainShell`, `NavigationBar` + `IndexedStack`):

| Pestaña | Contenido |
|---|---|
| **Calorías** | Anillos de kcal, grasas, carbohidratos y proteínas frente a los objetivos; *Agregar ingesta* (buscar por texto o escanear) y *Gestionar día* (editar cantidades, renombrar, guardar una comida como alimento, exportar el día). |
| **Alimentos** | El repertorio: búsqueda sin tildes o por código de barras, filtros (pendientes, envasados, genéricos, preparados, archivados) y **filtro por categoría**, insignia con los **pendientes de completar** y ficha de cada alimento (tabla nutricional, categoría, porciones caseras, presentaciones y códigos, precios por tienda y €/kg, recetas que lo usan). |
| **Recetas** | Búsqueda por los ingredientes que tienes; ingredientes vinculados a alimentos con cantidad → **nutrición calculada** por porción y por 100 g, con la lista de lo que falta para calcularla y una acción directa para cada cosa; modo cocina; importar desde texto/plantilla/JSON/CSV. |
| **Compras** | Listas de compra con precio de referencia y **agrupadas por pasillos** (orden general o el de una tienda), **modo carrito** (escanear lo que metes en el carrito con total en vivo, incluidas las **etiquetas de báscula** de los frescos al peso) e historial de precios exportable con el **gasto por categoría**. |

**Ajustes**:

- **Datos y respaldos**: compartir el repertorio, respaldo completo, TSV, importar `.db` antiguos y añadir el catálogo base.
- **Categorías y pasillos**: crear, renombrar, borrar y ordenar las categorías arrastrando; orden general u orden propio de cada tienda.

---

## Entorno y comandos

| Componente | Versión |
|---|---|
| Flutter | 3.47 (Dart 3.13) |
| Base de datos | Drift 2.35 sobre SQLite 3.5x **incluida en la app** (paquete `sqlite3`, con FTS5) |
| Android | AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, `android.builtInKotlin=false`, `android.newDsl=false` (ver [Configuración Android](#configuración-android)) |

```bash
flutter pub get
dart run build_runner build          # regenera lib/data/db/app_database.g.dart tras tocar tables.dart
flutter analyze
flutter test                         # todos los tests
flutter test test/unit/backup_test.dart
flutter test --name "modo carrito"
flutter build apk --release          # build/app/outputs/flutter-apk/app-release.apk
```

Si el build falla por caché: `flutter clean && flutter pub get && flutter build apk --release`.

El archivo generado `app_database.g.dart` se versiona en el repositorio: solo hay que regenerarlo al cambiar el esquema.

---

## Arquitectura

Clean Architecture en tres capas; las dependencias apuntan al dominio.

```
lib/
  core/            estilos (AppStyles), utilidades (formato de precios y números), constantes
  domain/          Dart puro (solo equatable)
    entities/      Food, FoodPortion, FoodPackage, NutritionFacts, Purchase, Store,
                   Category, ShoppingList/Item, Recipe/RecipeIngredient, Meal/MealItem,
                   Repertoire, UserSettings…
    repositories/  interfaces (las listas devuelven Stream) + TransactionRunner
                   (incluye CategoryRepository y ScaleRepository)
    services/      barcode (GTIN), money (céntimos), quantity_parser, nutrition_calculator,
                   nutrition_label_parser (OCR), ingredient_matcher, cart_matching,
                   category_guesser, aisle_grouping, scale_barcode, dates
    usecases/      una clase con un único call(...) por acción
  data/
    db/            tables.dart (esquema Drift), app_database.dart (+ .g.dart), mappers.dart
    repositories/  implementaciones Drift
    backup/        repertoire_codec (JSON), foods_tsv_codec, full_backup, legacy_db
    ocr/           mlkit_text_recognizer
    parsers/       recipe_text_codec (importar recetas desde texto)
  presentation/
    providers/     core_providers.dart (BD, repositorios, casos de uso) y uno por módulo
    views/, widgets/  (dialog_controllers: controladores de texto de los diálogos)
```

- **Un solo punto de creación de la base de datos**: `appDatabaseProvider` (en `core_providers.dart`), que la cierra al desecharse. En tests se sustituye por una en memoria con `ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(db)])`.
- **Reactividad**: los repositorios exponen `watch…()` (streams de Drift). Las pantallas se actualizan solas después de cualquier escritura, sin `refresh()` ni `invalidate` manuales. `HomeNotifier`, `ShoppingItemsNotifier` y `RecipesNotifier` se suscriben a esos streams.
- **Transacciones**: los casos de uso que escriben en varias tablas reciben un `TransactionRunner` (Drift `transaction`). Ejemplos: alta en tienda, carrito, importación, migración.
- **Riverpod 2.6**: el código nuevo usa `StreamProvider`, `Provider` y `StateNotifier` cuando hace falta estado de pantalla.
- **Navegación imperativa** (`Navigator.push`/`pop` + `MaterialPageRoute`). La raíz es `StartupGate`, que muestra la bienvenida la primera vez o `MainShell`.

---

## Modelo de datos

Esquema **v2** (`lib/data/db/tables.dart`, `schemaVersion = 2`). Las **claves foráneas están activas** (`PRAGMA foreign_keys = ON` en cada apertura). Los días se guardan como `TEXT 'YYYY-MM-DD'`, las marcas de tiempo en ISO 8601 y el dinero en **céntimos** (`INTEGER`).

```
categorias ──< orden_pasillos >── establecimientos ──< codigos_bascula >── presentaciones
    │
    │ categoria_id (SET NULL)
    ▼
alimentos ──< porciones
    │  └────< presentaciones (código de barras) ──< compras >── establecimientos
    │                                                 ▲
    ├──< ingredientes_receta >── recetas              │ compra_id (carrito)
    ├──< items_lista >── listas_compra ───────────────┘
    └──< items_comida (copia + vínculo) >── comidas
```

| Tabla | Qué guarda |
|---|---|
| `categorias` | Secciones del súper (v2): `nombre` único sin distinguir mayúsculas y `orden` general de los pasillos. Al instalar (y al migrar desde v1) se crean 13 por defecto: Frutas y verduras, Panadería, Carnicería, Pescadería, Charcutería y quesos, Lácteos y huevos, Despensa, Desayuno y dulces, Bebidas, Congelados, Platos preparados, Limpieza, Higiene y cuidado personal. |
| `alimentos` | El repertorio. `uuid` único (identidad para compartir), `nombre` + `marca` (únicos juntos, sin distinguir mayúsculas; marca `''` = genérico), `tipo` (`generico`/`envasado`/`preparado`), `unidad` (`g`/`ml`), `categoria_id` (v2, opcional, `SET NULL` al borrar la categoría). Tabla nutricional **por 100 g/ml** con 8 nutrientes (`kcal`, `proteinas`, `grasas`, `grasas_saturadas`, `carbohidratos`, `azucares`, `fibra`, `sal`); **`NULL` = desconocido** (no es lo mismo que 0). `nutricion_origen` (`manual`, `etiqueta_ocr`, `importado`, `calculado`), `uso_count`/`ultimo_uso` (lista de "más usados"), `archivado`. |
| `porciones` | Equivalencias caseras: "1 diente = 5 g", "1 vaso = 250 ml". Sirven para registrar rápido y para calcular recetas con "2 dientes de ajo". |
| `presentaciones` | Formato comercial de un alimento: `codigo_barras` (GTIN normalizado, único, `NULL` = granel), `descripcion` ("Brick 1 L"), `contenido` neto (para el precio por kg o litro). Un alimento puede tener varias. Los frescos de báscula usan una presentación **"Al peso"** sin código. |
| `establecimientos` | Tiendas, sin duplicados por mayúsculas. v2: `formato_bascula` (`'precio'`, `'peso'` o `NULL` = aún sin aprender) y `longitud_clave` (6 o 7, por defecto 7) de sus etiquetas de báscula. |
| `orden_pasillos` | Orden propio de los pasillos de una tienda (v2). PK `establecimiento_id + categoria_id`, `orden`. Sin filas, la tienda usa el orden general de `categorias`. |
| `codigos_bascula` | Etiquetas de báscula aprendidas (v2): en cada tienda, la `clave` (parte fija del código) apunta a una `presentacion_id`. Única por tienda + clave. |
| `compras` | Historial de precios: presentación, tienda, fecha, `precio_cent` unitario y `unidades`. v2: `peso_g` (peso real de la compra, para el €/kg de los frescos al peso). `ON DELETE RESTRICT`: una presentación con compras no se borra, se archiva. |
| `listas_compra` / `items_lista` | Listas y artículos (`alimento_id` opcional, `texto`, `cantidad`, `comprado`). En el carrito, `compra_id` apunta a la compra: unidades y precio se leen de ella, **no se copian**. |
| `recetas` / `ingredientes_receta` | Receta (`uuid`, porciones, `peso_final_g` cocinado, `alimento_id` del alimento "preparado" que la representa) e ingredientes: `texto` original siempre, más `alimento_id`, `cantidad` y `unidad` (`g`, `ml` o nombre de una porción) opcionales. |
| `comidas` / `items_comida` | Registro del día. Los items guardan el nombre y los macros **ya escalados** (histórico inmutable) y un `alimento_id` informativo. |
| `alimentos_fts` | Índice FTS5 (`unicode61 remove_diacritics 2`) sobre nombre y marca, mantenido por triggers. |

### Reglas del modelo

- **Completo** = tiene `kcal`, `proteinas`, `grasas` y `carbohidratos`. Si no, está **pendiente**: aparece en Alimentos → Pendientes (con insignia), ordenado por prioridad (usado en recetas → comprado recientemente → resto).
- **Un alimento pendiente no se registra en Calorías con ceros**: al elegirlo se ofrece completarlo (formulario + lectura de etiqueta).
- **Borrar** un alimento sin compras lo borra, y sus porciones y presentaciones caen en cascada. Con compras se **archiva**. Recetas, listas y comidas que lo usaban quedan desvinculadas (`SET NULL`) pero conservan su texto.
- **Duplicados**: no puede haber dos alimentos con el mismo nombre y marca (sin tildes ni mayúsculas). Editar nunca borra y reinserta: se conservan el id, los vínculos y el uso.
- **Códigos de barras**: se normalizan antes de guardar o buscar (solo dígitos; UPC-A de 12 → EAN-13 con un 0 delante). Se valida el dígito de control, pero se permite guardar un código que no cuadre (códigos internos de tienda).
- **Búsqueda**: FTS5 por prefijo de palabra, sin tildes, con singular y sinónimos regionales (`papas` → patata). Si lo escrito son 8–14 dígitos, se busca por código.
- **Purga del historial**: al abrir la app (y antes de exportarlo) se borran las compras de más de 3 meses, **salvo la última de cada presentación**.
- **Categoría automática**: al insertar un alimento sin categoría, `FoodRepositoryImpl.saveFood` le asigna la que sugiere su nombre (`guessCategoryName`). El formulario pasa `adivinarCategoria: false` porque ya muestra la sugerencia en vivo y el usuario decide. Borrar una categoría deja sus alimentos sin categoría.
- **Códigos de báscula**: un EAN-13 que empieza por `2` (`isVariableMeasure`) **nunca** se guarda como `codigo_barras` de una presentación; se guarda su clave en `codigos_bascula`, ligada a la tienda.

### Migraciones

- **v1 → v2** (`onUpgrade`, `from < 2`): crea `categorias`, `orden_pasillos` y `codigos_bascula`; añade `alimentos.categoria_id`, `establecimientos.formato_bascula`, `establecimientos.longitud_clave` y `compras.peso_g`; crea los índices nuevos; siembra las categorías por defecto (`sembrarCategorias`) y clasifica los alimentos existentes por su nombre (`clasificarAlimentos`). `onCreate` siembra las categorías igual. Las claves foráneas se desactivan durante la migración y se reactivan en `beforeOpen`.
- El test de migración parte de un volcado del esquema v1 con datos (`test/fixtures/schema_v1.sql`) y compara el resultado con una instalación nueva.

---

## Flujos principales

### Código de barras según el contexto

| Dónde | Código conocido | Código desconocido |
|---|---|---|
| Modo carrito / lista (**tienda**) | Ficha de precio | Aviso **"Producto no registrado"** y alta mínima: nombre, marca, presentación, contenido y precio. Crea un alimento **pendiente**, su presentación y la compra en una transacción (`RegisterFoodInStore`). **Nunca pide la tabla nutricional.** También permite "Es otra presentación de uno que ya tengo". |
| Agregar ingesta, Alimentos, vincular ingrediente (**casa**) | Abre o usa el alimento; si está pendiente, ofrece completarlo | Alta completa con tabla nutricional (y lectura de etiqueta) u "otra presentación de…" (`FoodFlows.foodForBarcode`) |
| Etiqueta de báscula en el **modo carrito** | Importe leído o calculado con el €/kg (ver [Etiquetas de báscula](#etiquetas-de-báscula-frescos-al-peso)) | Se elige o crea el alimento y la tienda aprende la etiqueta |
| Etiqueta de báscula en **casa** (`FoodFlows.scanAtHome`) | Se reconoce en cualquier tienda (`findAnyStore`); si la tienda usa formato peso, "Agregar ingesta" precarga los gramos | Aviso "aún sin aprender: escanéala una vez en el modo carrito" y se elige el alimento a mano. No se da de alta ningún código |

Siempre se puede escribir el código a mano.

### Carrito (`AddToCart`, `UpdateCartItem`, `RemoveFromCart`)

- El artículo de la lista se elige así: si está en el carrito, ese; si no, un pendiente vinculado al alimento; si no, un pendiente sin vincular cuyo texto coincida (`findItemForFood`).
- Repetir un producto suma unidades a la misma compra.
- Desmarcar quita `compra_id` y conserva la compra. "Quitar del carrito" borra la compra.
- Total del carrito = Σ unidades × precio de las compras enlazadas.
- Un pendiente sin vincular ("Fruta") se mete en el carrito eligiendo o creando su alimento: todo lo que se compra entra en el repertorio.
- **Al peso** (`AddToCart(alPeso: true, pesoG:)`): varios paquetes del mismo producto se acumulan en **una sola compra** (importe y peso sumados, 1 unidad). `PurchaseRecord.precioPorKiloCent` usa `compras.peso_g` si existe y, si no, el contenido de la presentación.
- La sección "Te falta" se agrupa por pasillos con el orden de la tienda actual.
- Al terminar se avisa de los productos nuevos que quedaron sin tabla nutricional.

### Categorías y orden de pasillos

- **Sugerencia por nombre** (`category_guesser.dart`): cada categoría por defecto tiene palabras clave y frases. Las frases tienen prioridad sobre las palabras sueltas; entre palabras gana la categoría con más coincidencias y, a igualdad, la de la palabra que aparece antes en el nombre ("Leche de coco" → Lácteos y huevos).
- **Agrupar por pasillos** (`groupByAisle`, en `aisle_grouping.dart`): un artículo vinculado usa la categoría de su alimento; uno de texto libre se clasifica por su nombre; lo que no encaja va a "Otros", al final. Dentro de cada grupo se respeta el orden de la lista.
- **Orden general y por tienda** (`CategoryRepository`): `reorder` guarda el orden general o el de una tienda; `resetStoreOrder` vuelve al general.
- **Dónde se ve**:
  - **Categorías y pasillos** (`CategoriesView`): reordenar arrastrando, selector "General / tienda", crear, renombrar, borrar y "Usar el general". Se abre desde Ajustes y desde el menú de la lista.
  - Formulario de alimento: categoría sugerida en vivo. Ficha: chip para cambiarla (`pickCategory`, `CategoryDropdown` en `widgets/category_widgets.dart`).
  - Pestaña Alimentos: chip de filtro por categoría (`kSinCategoria = 0` muestra los que no tienen).
  - Lista de compra: "Agrupar por pasillos" y "Ordenar por los pasillos de…" una tienda.
  - Historial de precios: tarjeta **"Gasto por categoría"** de los últimos 30 días o 3 meses (`PurchaseRepository.spendingByCategory`).

### Etiquetas de báscula (frescos al peso)

Una etiqueta de báscula es un EAN-13 que empieza por `2` (`ScaleLabel.parse`, en `scale_barcode.dart`):

- **Clave** (identifica el producto en la tienda): los primeros 7 dígitos, o 6 si la tienda usa un dígito de control del precio en la posición 7.
- **Valor**: siempre las cifras 8 a 12. Según la tienda es el **importe** en céntimos o el **peso** en gramos.

El mismo código significa cosas distintas en tiendas distintas, así que formato y productos se **aprenden por tienda** (`ScaleRepository`). En el modo carrito (`CartModeView._onScaleLabel`):

1. Primera etiqueta de una tienda: pregunta "¿importe X € o peso Y kg?" y guarda el formato (`setScaleFormat`).
2. Producto desconocido: se elige o crea con `FoodPickerView` y `LinkScaleCode` lo asocia a su presentación "Al peso" (creada si no existe).
3. Si otra bandeja difiere solo en la cifra 7, pregunta si es el mismo producto. Con un "sí", la tienda pasa a claves de 6 dígitos (`useShortKeys`, que recorta las claves ya aprendidas).
4. Formato peso: importe = peso × último €/kg de esa presentación en la tienda (`lastPricePerKiloCent`, `priceForWeight`). La primera vez se pide el importe.
5. `CartPriceSheet(alPeso: true)` pide el "Importe del paquete" sin unidades, y la compra se registra con su `peso_g`.

### Recetas conectadas (`nutrition_calculator.dart`, `recipe_food.dart`)

- **Gramos de un ingrediente**: si la unidad es `g`/`ml`, la cantidad; si es una porción, `cantidad × gramos de la porción` ("dientes" ↔ "diente").
- **Cálculos**: `total = Σ gramos/100 × valor por 100`. `peso = peso_final_g ?? Σ gramos`. **Por porción** = total / porciones.
- **Completa** cuando todos los ingredientes no opcionales están vinculados, con cantidad convertible a gramos y con su tabla completa. Si no, se muestra el mínimo ("≥ X kcal") y una lista con el motivo de cada ingrediente:
  - sin vincular → **Vincular**
  - sin cantidad → **Cantidad**
  - porción sin peso → **Añadir peso**
  - alimento pendiente → **Completar**, con lectura de etiqueta
- "Sal/pimienta/agua al gusto" no bloquean el cálculo.
- **Vincular automáticamente** (`SuggestIngredientLinks`): propone para cada línea el alimento que mejor encaja y la cantidad leída ("200 g de arroz" → Arroz, 200 g). Se revisa antes de guardar.
- **Registrar porción** añade la receta al día. **Añadir a mis alimentos** crea o actualiza un alimento `preparado` con la nutrición calculada y la porción de la receta (`SaveRecipeAsFood`).
- **Editar la receta** conserva los vínculos de las líneas cuyo texto no cambia.
- **Modo cocina**: ingredientes y pasos en grande. Al empezar recuerda los datos que faltan, porque el envase está en la mano para leer la etiqueta.

---

## Exportar, importar y compartir

Todo se guarda y se abre con el selector del sistema (SAF en Android, sin permisos de almacenamiento). "Importar" detecta el tipo de archivo por su contenido.

| Formato | Contenido | Al importar |
|---|---|---|
| **Repertorio** `.json` (`RepertoireCodec`) | Alimentos con porciones, presentaciones y categoría (por nombre); recetas opcionales (con los ingredientes vinculados por `uuid`). **Sin datos personales**: ni comidas, ni compras, ni precios, ni uso, ni ajustes. | **Fusiona** (`ImportRepertoire`) |
| **Respaldo completo** `.json` (`FullBackupService`) | Todas las tablas tal cual (incluidas `categorias`, `orden_pasillos` y `codigos_bascula`) + ajustes (SharedPreferences) | **Reemplaza** todo, en una transacción, después de guardar una copia automática del estado actual (`respaldo_automatico_*.json` en documentos). Un respaldo anterior a v2 se restaura y después se siembran las categorías y se clasifican los alimentos |
| **TSV** (`FoodsTsvCodec`) | `uuid nombre marca tipo unidad codigos kcal grasas grasas_saturadas carbohidratos azucares fibra proteinas sal categoria` (TAB; celdas vacías = desconocido) | Fusiona. Acepta archivos sin la columna `categoria` y **también la cabecera antigua** `id alimento kCal grasas carbohidratos proteinas` |
| **`.db` antiguo** (`LegacyData`) | `db_alimentos` de versiones anteriores | Fusiona los alimentos |
| Recetas `.txt`/JSON/CSV (`RecipeTextCodec`) | Recetas sueltas | Omite las que ya existen por nombre |
| CSV diario / historial de precios | Exportación (TAB, extensión `.csv`) | — |

Estructura del repertorio: `{"formato": "cal_counter/repertorio", "version": 1, "exportado", "alimentos": [{"uuid", "nombre", "marca", "tipo", "unidad", "categoria", "nutricion": {..., "origen"}, "porciones": [...], "presentaciones": [...]}], "recetas": [...]}`. Los campos desconocidos se ignoran y las versiones mayores más nuevas se rechazan con un mensaje claro.

**Categorías en el intercambio**: viajan siempre **por nombre**, nunca por id. `categoria` es un campo opcional (añadido sin cambiar la versión del formato); si la categoría no existe en el destino, se crea. Al fusionar, un alimento local conserva su categoría y solo toma la importada si no tenía ninguna.

**Fusión** (`ImportRepertoire`, todo en una transacción y con vista previa):

1. **Emparejado**: cada alimento importado busca su pareja local por **uuid**, luego por **código de barras** y luego por **nombre y marca** (sin tildes ni mayúsculas).
2. **Sin pareja**: se crea conservando su uuid.
3. **Con pareja**:
   - Se rellenan los huecos de la tabla nutricional.
   - Si ambos tienen valores distintos, se aplica la política: *Conservar los míos* (por defecto) o *Usar los importados*.
   - Se añaden las porciones y presentaciones que falten. Un código que ya es de otro alimento se ignora y se informa.
4. **Recetas**: se emparejan por uuid o nombre; las que ya existen se omiten.
5. **Resultado**: importar dos veces el mismo archivo no duplica nada.

**Primer arranque** (`OnboardingView`, solo con el repertorio vacío):

- **Importar mis datos de la versión anterior**: aparece si existe `db_ctrl_calorias.db` y migra todo con `MigrateLegacyData`, según el Apéndice A del plan:
  - Cada producto pasa a ser un alimento envasado, con la tabla de su alimento vinculado.
  - Las compras pasan a céntimos.
  - Se migran las listas con el carrito, las recetas y las comidas.
  - El archivo antiguo **no se modifica**.
- **Catálogo base**: 678 alimentos genéricos en `assets/semilla/alimentos_base.json`, con uuid determinista para que el mismo catálogo coincida entre usuarios.
- **Frutas, verduras y hortalizas**: 229 alimentos en `assets/semilla/frutas_verduras.json` con el nombre en español y en alemán («Manzana con piel, cruda / Apfel mit Schale, roh»). La tabla sale de CIQUAL 2025 (ANSES; carbohidratos sin fibra y proteína bruta, como las etiquetas de la UE) cuando publica cifra para kcal, proteínas, grasas y carbohidratos, y si no, del alimento entero en USDA SR Legacy (FoodData Central; carbohidratos con fibra). Ningún valor está estimado: lo que la fuente no publica queda vacío. Lleva porciones caseras de USDA y una nota con la fuente y su código. Se carga junto al catálogo base en la bienvenida; en una instalación que ya tenía datos se incorpora sola, una vez, la primera vez que se abre la app tras actualizar (y no vuelve aunque se borren alimentos). También se puede añadir desde *Datos y respaldos → Catálogos incluidos*. Lo genera `tool/semilla/generar_frutas_verduras.py`; criterios y lista completa en `docs/FRUTAS_VERDURAS.md`.
- **Restaurar o importar** un archivo.
- **Empezar vacío.**

---

## OCR de etiquetas

Desde el formulario de alimento, *Leer la etiqueta con la cámara* sigue estos pasos:

1. Foto con `image_picker` (cámara o galería).
2. Reconocimiento de texto con **ML Kit** en el dispositivo (`MlKitLabelRecognizer`, modelo latino incluido: sin internet).
3. Interpretación con `NutritionLabelParser`, que es Dart puro y está probado con textos reales:
   - Agrupa en filas las líneas que están a la misma altura, porque el OCR devuelve las columnas por separado.
   - Reconoce las etiquetas UE en español, portugués, francés, inglés, italiano y alemán (incluidos "Brennwert" y "Eiweiß", también leído como "Eiweiss" o "EiweiB").
   - Toma la columna "por 100 g/ml" e ignora los % de ingesta de referencia.
   - Energía: usa las kcal; si solo hay kJ, divide entre 4,184.
   - Corrige errores típicos del OCR (`O`→`0`, `l`→`1`, comas sueltas).
   - "<0,5 g" (también "≤", "menos de" y "weniger als", con o sin espacio), "trazas" y "Spuren" cuentan como 0. Con ">6 g" (también "≥", "más de" y "mehr als") toma el mínimo y lo marca como dudoso. Con sodio o Natrium, `sal = sodio × 2,5`.
   - Si solo hay valores por ración y lee su peso, los convierte a 100 g. También lee el contenido neto ("Peso neto", "Nettofüllmenge", "Inhalt"…).
   - Marca como dudosos los valores sin unidad o incoherentes (saturadas > grasas, azúcares > hidratos, kcal que no cuadran con los macros).
4. Hoja de revisión (`LabelReviewSheet`) con la foto, los valores y avisos. Los valores pasan al formulario y **nunca se guardan sin que el usuario confirme**. El origen queda como `etiqueta_ocr`.

El reconocedor se inyecta con `labelRecognizerProvider` (sustituible en tests).

---

## Calorías: objetivos, TDEE y día

- **Objetivos**:
  - `proteinas = peso × g/kg`
  - `grasas = peso × g/kg`
  - **carbohidratos = residuo calórico**: `(kcalObjetivo − (proteinas·4 + grasas·9)) / 4`, nunca negativo
  - Una sola implementación: getters `proteinsRequired`, `fatsRequired` y `carbsRequired` de `UserSettings`.
- **TDEE** (`SettingsView`):
  - Con % de grasa corporal válido: **Katch-McArdle**, `TMB = 370 + 21,6 × masa magra` (el sexo no interviene y su selector se deshabilita).
  - Si no: **Mifflin-St Jeor**, `10·peso + 6,25·altura − 5·edad + (5 | −161)`.
  - `TDEE = TMB × factor de actividad`.
- **Agregar** (`AddFoodToMeal`): `factor = cantidad / 100` sobre la tabla del alimento. **Editar la cantidad** (`updateMealItem`) aplica `ratio = nueva / anterior` sobre lo ya guardado, sin volver a consultar el alimento.
- **Comidas**: se nombran `Comida_N` con `nextMealName` (el mayor N + 1, nunca un nombre que ya exista). La cantidad sugerida es el máximo que cabe en todas las metas restantes. Las porciones caseras aparecen como atajos.
- **Exportar el día** (`ExportDayToCsv`): TAB, cabecera `nombre_comida\tcantidad\talimento\tgrasas\tcarbos\tproteinas\tkcal`, fila final `Total`. **Tras exportar con éxito vacía `comidas` e `items_comida`.**
- **Nuevo día** (`CheckNewDayOnStartup`): al abrir la app **o al volver a primer plano** (`AppLifecycleListener` → `HomeNotifier.syncToday()`), si hay items **y** la última fecha es anterior a hoy, se ofrece exportar o descartar el día anterior. Si la app quedó abierta pasada la medianoche, el contador pasa solo al día nuevo.
- **Decimales**: los campos numéricos aceptan coma o punto, y Material está en español (`flutter_localizations`, `es-ES`).

---

## Configuración Android

- **Toolchain**: AGP 9.1.0, Gradle 9.3.1 y KGP 2.4.0, con `android.builtInKotlin=false` y `android.newDsl=false`, los mismos flags que la plantilla de Flutter 3.47 (su plugin de Gradle aún no soporta `newDsl=true`). Con `builtInKotlin=false` cada plugin aplica KGP. Revisar al actualizar Flutter.
- **`file_picker` 13+**: la 11 omitía KGP bajo AGP 9 y su código Kotlin no se compilaba. Desde la 12, `saveFile(fileName:, bytes:)` escribe el archivo con SAF y devuelve `Uri?` (se muestra con `AppUtils.formatRutaGuardada`), y `pickFile()` devuelve un `PlatformFile?` que se lee con `readAsBytes()`.
- **`google_mlkit_text_recognition` ^1.0.3**: desde la 0.17 usa el Kotlin integrado de AGP. La 0.16 aplicaba KGP por su cuenta y Flutter 3.47 avisaba de que versiones futuras no compilarán con plugins así.
- **R8** (`android/app/proguard-rules.pro`): `-dontwarn` para los reconocedores de chino, devanagari, japonés y coreano que referencia ML Kit pero que la app no incluye (solo usa el alfabeto latino). Sin ellas, `flutter build apk --release` falla en `minifyReleaseWithR8`.
- **SQLite**: la incluye el paquete `sqlite3` mediante *build hooks*. Durante el build descarga binarios precompilados, así que el build necesita internet.
- **Permisos**: `CAMERA` (escáner de códigos con `mobile_scanner` y fotos con `image_picker`), con `uses-feature camera required=false`: sin cámara se escribe el código a mano. **Sin permisos de almacenamiento**: importar y exportar usa SAF.
- **Sin `INTERNET` en release**: ML Kit lo añade para su telemetría (`com.google.android.datatransport`) y el manifiesto principal lo quita con `tools:node="remove"`. Los manifiestos de debug y profile lo declaran para las herramientas de Flutter.
- **Firma de release** opcional con `android/key.properties` (no versionado: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`). Sin él se firma con la clave de debug.
- **iOS**: `Info.plist` incluye `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription`. No se ha probado en iOS.
- `file_saver` se eliminó (aplicaba KGP y bloqueaba la toolchain); no reintroducirlo.

---

## Dependencias

| Paquete | Uso |
|---|---|
| `flutter_riverpod` 2.6 | Estado e inyección de dependencias |
| `drift`, `drift_flutter`, `sqlite3` | Base de datos (Drift sobre SQLite incluida, FTS5) |
| `uuid` | Identidad global de alimentos, presentaciones y recetas |
| `mobile_scanner` | Escáner de códigos de barras (ML Kit incluido) |
| `google_mlkit_text_recognition` (1.0), `image_picker` | OCR de etiquetas |
| `file_picker` | Guardar/abrir archivos con SAF |
| `path_provider`, `path` | Directorios (base de datos antigua, temporales, copia automática) |
| `shared_preferences` | Ajustes del usuario y tema |
| `csv`, `intl`, `equatable` | CSV diario, formato es-ES, igualdad de entidades |
| dev: `drift_dev`, `build_runner` | Generación de código de Drift |
| dev: `flutter_lints`, `plugin_platform_interface` | Análisis; mock de `file_picker` |

---

## Pruebas

- `test/unit/db_repositories_test.dart`: repositorios Drift en memoria: claves foráneas y cascadas, FTS (tildes, prefijos, sinónimos, código), duplicados, archivado, pendientes, porciones, compras y purga, alta en tienda (transaccional), carrito, recetas, comidas y CSV.
- `test/unit/domain_services_test.dart`: GTIN, céntimos, cantidades de ingredientes, `NutritionFacts` y cálculo nutricional de recetas.
- `test/unit/backup_test.dart`:
  - repertorio de ida y vuelta, importar dos veces, huecos y conflictos, emparejado por código y versiones
  - catálogo base
  - TSV (incluido el formato antiguo)
  - respaldo completo
  - lectura del `.db` de la v1.2 (`test/fixtures/`) y migración completa de una instalación antigua
- `test/unit/nutrition_label_parser_test.dart`: 23 casos: una y dos columnas, ruido de OCR, solo kJ, multilingüe, alemán, ración, sodio, trazas, "<" y ">", incoherencias, agrupación por geometría y peso neto.
- `test/unit/phase7_test.dart`:
  - adivinador de categorías e instalación nueva con categorías
  - **migración v1 → v2 con datos** (desde `test/fixtures/schema_v1.sql`, comparando el esquema con una instalación nueva)
  - asignación automática, filtro por categoría, orden por tienda, crear/renombrar/borrar categorías
  - agrupación por pasillos y gasto por categoría
  - categoría en repertorio, TSV y respaldo
  - etiquetas de báscula: parseo, lectura, aprendizaje por tienda, carrito acumulado y clave de 6 dígitos
- `test/widget/`:
  - `modules_smoke_test.dart`: recorre la app real sobre una base de datos en memoria: alimentos, agregar ingesta, recetas con vinculación automática, compras y modo carrito con cámara simulada.
  - `onboarding_test.dart`: primer arranque.
  - `label_review_test.dart`: revisión de la lectura de etiquetas.
  - `phase7_widget_test.dart`: lista agrupada por pasillos, categoría sugerida y filtro; flujo completo de báscula en el modo carrito; pantalla de categorías.
  - `add_food_popup_test.dart`: "Nueva comida" no reutiliza un `Comida_N` existente y la cantidad acepta coma decimal.
- De la auditoría técnica (`docs/AUDITORIA_TECNICA.md`): `home_notifier_test.dart` (cambio de día con la app abierta, errores de carga, borrar el día), `meal_naming_test.dart`, `app_utils_test.dart` (decimales y ruta guardada), `ingredient_matcher_test.dart`, `recipe_text_codec_test.dart`, `settings_test.dart` y `theme_provider_test.dart`.
- Integración continua (`.github/workflows/ci.yml`): `flutter analyze` y `flutter test` en cada push y pull request.

---

## Reglas que no deben romperse

1. **El repertorio es el núcleo**: lo que se compra, se cocina o se come apunta a `alimentos`. No crear catálogos paralelos.
2. **Desconocido ≠ 0**: los nutrientes desconocidos son `NULL`. Un pendiente no se registra en el contador.
3. **Nada de `REPLACE`** sobre `alimentos`: editar con `update` conserva id, uuid, vínculos y uso.
4. **Claves foráneas activas**: no borrar padres a mano esperando huérfanos. Un alimento con compras se archiva.
5. **Dinero en céntimos** (`precio_cent`). Para mostrarlo, `AppUtils.formatPrecioCent` ("1,05 €"); para leer lo que escribe el usuario, `parsePrecioCent` (acepta coma o punto).
6. **El carrito no duplica datos**: unidades y precio se leen de la compra enlazada (`compra_id`).
7. **Historial = 3 meses + la última compra de cada presentación.** No borrar nunca esa última compra.
8. **`items_comida` es histórico**: valores ya escalados y nombre copiado. Editar la cantidad escala por proporción.
9. **`ExportDayToCsv` vacía el día tras un export con éxito** (deliberado). Para exportar sin vaciar, crear otro caso de uso.
10. **`CheckNewDayOnStartup`** exige items **y** última fecha anterior a hoy.
11. **Esquema**: tocar `tables.dart` implica subir `schemaVersion`, escribir la migración en `MigrationStrategy`, regenerar con `build_runner` y cubrirlo con tests.
12. **Formatos de intercambio estables**: el repertorio y el respaldo están versionados. Ampliarlos sin romper los archivos ya compartidos.
13. **Normalización simétrica**: `ingredient_matcher.dart` se aplica igual a recetas, búsqueda y sugerencias. No guardar columnas derivadas.
14. **Todo en local**: no consultar servicios online (ni para códigos de barras ni para OCR).
15. **Idioma español** en la interfaz, en las columnas de la base de datos, en las claves de SharedPreferences y en los comentarios.
16. **`UserSettings`**: cada campo nuevo necesita su clave en `SettingsRepositoryImpl.getSettings()` (con valor por defecto) y en `saveSettings()`.
17. **Tema** solo con `themeProvider`. Estilos centralizados en `AppStyles`.
18. **Códigos de báscula**: un EAN-13 con prefijo `2` nunca se guarda como `codigo_barras` de una presentación. Su clave va en `codigos_bascula`, por tienda.
19. **Categorías por nombre** en repertorios, TSV y respaldos; nunca por id.
20. **Diálogos con campos de texto**: crear los controladores con `DialogControllers` (`widgets/dialog_controllers.dart`). Liberarlos justo después de `await showDialog` provoca "used after being disposed" mientras el diálogo aún se cierra.

\*\*
NOTA PERSONAL:
Como generar el APK?

El comando es simplemente:

flutter build apk --release

Lo ejecutas desde la raíz del proyecto (d:/DESARROLLO/FlutterProjects/cal_counter).

El APK queda en build/app/outputs/flutter-apk/app-release.apk.

Si en algún momento el build falla con errores de cache (como pasó hoy), el procedimiento de rescate es:

flutter clean && flutter pub get && flutter build apk --release
\*\*
