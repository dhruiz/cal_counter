# Traspaso de sesión — cal_counter

> Documento para continuar el trabajo en otra sesión. Fecha: 2026-11-23.
> Rama: `claude/database-tables-recipes-kyqj0h`. Léelo junto con `CLAUDE.md`,
> `README.md` y `docs/PLAN_REDISENO_BD.md`.
>
> **Actualización (sesión siguiente):** la fase 7 ya está documentada,
> verificada y subida a la rama `claude/traspaso-md-continuation-77gbi5`, que
> continúa `claude/database-tables-recipes-kyqj0h` sin reescribir su historia.
> No queda nada pendiente de este plan (ver §4). Las secciones 5 y 6 siguen
> vigentes para preparar el entorno y respetar las decisiones.
>
> **Actualización (24-11-2026): rama unificada `claude/peaceful-hawking-ishyo2`.**
> Reúne el rediseño (`traspaso-md-continuation-77gbi5`), el commit WIP de
> `claude/tender-cray-63vymf` y la rama `claude/flutter-sdk-environment-r2k60q`
> (auditoría técnica + AGP 9.1, Gradle 9.3.1, Kotlin 2.4.0 y file_picker 13).
> Qué se portó de la auditoría y qué quedó resuelto por el rediseño: nota al
> principio de `docs/AUDITORIA_TECNICA.md`. Verificado con Flutter 3.47.9:
> `flutter analyze` limpio y 168 tests en verde. Las ramas anteriores quedan
> como histórico; se trabaja sobre la unificada.

## 1. Contexto

El usuario (habla en español; toda la app, la base de datos y los comentarios
van en español) pidió rediseñar la app para que el **repertorio de alimentos
sea el núcleo** de calorías, recetas y compras. Se planificó en
`docs/PLAN_REDISENO_BD.md` y el usuario **aprobó todas las recomendaciones**.

Fases y estado:

| Fase | Contenido | Estado |
|---|---|---|
| 0–6 | Drift + esquema v1, repertorio, compras, recetas, import/export, migración, OCR | ✅ Hecho, commit y push (último: `8fa48b1`) |
| **7** | **Categorías y orden de pasillo + etiquetas de báscula (peso/precio variable)** | ✅ Código y tests (`2872624`), documentación en el commit siguiente |

El usuario pidió explícitamente la fase 7 completa ("haz ambas").

## 2. Estado exacto al cerrar la sesión

- La fase 7 está **implementada y probada**: `flutter analyze` sin avisos y
  **150 tests en verde** (`flutter test`).
- Los cambios de la fase 7 se suben en el mismo commit que este documento
  (ver §7). Si al abrir la sesión `git log` no muestra ese commit, el trabajo
  sigue sin confirmar en el árbol de trabajo.
- `lib/data/db/app_database.g.dart` está regenerado para el esquema v2 (se
  versiona en el repositorio).

## 3. Qué se hizo en la fase 7

### 3.1 Esquema v2 (`lib/data/db/tables.dart`, `app_database.dart`)

`schemaVersion = 2`. Migración `onUpgrade` (from < 2):

- Tablas nuevas:
  - `categorias` (`nombre` único NOCASE, `orden` general).
  - `orden_pasillos` (PK `establecimiento_id + categoria_id`, `orden`): orden propio de cada tienda.
  - `codigos_bascula` (`establecimiento_id`, `clave`, `presentacion_id`; único por tienda + clave).
- Columnas nuevas:
  - `alimentos.categoria_id` (FK `SET NULL`).
  - `establecimientos.formato_bascula` (`'precio'|'peso'|NULL`).
  - `establecimientos.longitud_clave` (6 o 7; por defecto 7).
  - `compras.peso_g` (peso real de la compra, para €/kg de frescos).
- La migración siembra las categorías por defecto (`sembrarCategorias`) y clasifica los alimentos existentes por su nombre (`clasificarAlimentos`). `onCreate` hace lo mismo.
- Fixture del esquema v1 para el test de migración: `test/fixtures/schema_v1.sql`.

### 3.2 Categorías y pasillos

| Pieza | Archivo |
|---|---|
| Entidades `Category`, `CategorySpending` | `lib/domain/entities/category.dart` |
| 13 categorías por defecto con palabras clave y frases; `guessCategoryName(nombre)` | `lib/domain/services/category_guesser.dart` |
| `groupByAisle(items, categoriasOrdenadas)`: los artículos vinculados usan la categoría de su alimento; el texto libre se clasifica por nombre; "Otros" al final | `lib/domain/services/aisle_grouping.dart` |
| `CategoryRepository` (orden general/por tienda, reordenar, restablecer, asignar, sugerir) | `domain/repositories/category_repository.dart` + `data/repositories/category_repository_impl.dart` |

- **Asignación automática**: `FoodRepositoryImpl.saveFood(food, {adivinarCategoria = true})` asigna la categoría sugerida al insertar si `categoriaId` es null. El formulario pasa `adivinarCategoria: false`, porque ya muestra la sugerencia y el usuario decide.
- **Filtro por categoría**: `search`/`watchSearch(categoriaId:)`; `kSinCategoria = 0` filtra los alimentos sin categoría.
- **Gasto por categoría**: `PurchaseRepository.spendingByCategory(desde)`.
- **Intercambio**: la categoría viaja **por nombre**, nunca por id:
  - Repertorio JSON: campo opcional `categoria` (se crea en destino si no existe).
  - TSV: nueva columna final `categoria`.
  - Respaldo completo: incluye `categorias`, `orden_pasillos` y `codigos_bascula`. Al restaurar un respaldo v1 se resiembran las categorías y se reclasifican los alimentos.
- **Interfaz**:
  - `CategoriesView`: reordenar arrastrando, selector "General / tienda", crear, renombrar, borrar y "Usar el general". Se abre desde Ajustes ("Categorías y pasillos") y desde el menú de la lista.
  - `CategoryDropdown` y `pickCategory` (`widgets/category_widgets.dart`).
  - Formulario de alimento: categoría sugerida en vivo.
  - Ficha del alimento: chip para cambiar la categoría.
  - Pestaña Alimentos: chip de filtro por categoría.
  - Lista de compra: agrupada por pasillos (opción en el menú y orden de una tienda concreta).
  - Modo carrito: "Te falta" agrupado con el orden de la tienda actual.
  - Historial de precios: tarjeta "Gasto por categoría" (30 días / 3 meses).

### 3.3 Etiquetas de báscula (frescos al peso)

Una etiqueta de báscula es un EAN-13 que empieza por `2`. Sus partes:

- **Clave** (identifica el producto): los primeros 7 dígitos, o 6 si la tienda usa dígito de control del precio en la posición 7.
- **Valor**: siempre las cifras 8 a 12, que son un importe en céntimos o un peso en gramos según la tienda.

| Pieza | Archivo |
|---|---|
| `ScaleFormat`, `ScaleLabel.parse(code, longitudClave)`, `priceForWeight`, `pricePerKilo` | `lib/domain/services/scale_barcode.dart` |
| `ScaleReading`, `readScaleLabel`, `LinkScaleCode` (crea la presentación "Al peso" y guarda la clave) | `lib/domain/usecases/scale_labels.dart` |
| `ScaleRepository`: `ensureStore`, `setScaleFormat`, `findCode`, `findByShortKey`, `findAnyStore`, `useShortKeys`, `saveCode`, `lastPricePerKiloCent` | `domain/repositories/scale_repository.dart` + `data/repositories/scale_repository_impl.dart` |

- **`AddToCart(alPeso: true, pesoG:)`**: varios paquetes del mismo producto se acumulan en una sola compra (importe y peso sumados, 1 unidad). `PurchaseRecord.precioPorKiloCent` usa `compra.pesoG` si existe.
- **Modo carrito** (`CartModeView._onScaleLabel`):
  1. Primera etiqueta de una tienda: se pregunta "¿Importe X € o peso Y kg?" y se guarda el formato.
  2. Producto desconocido: se elige o crea con `FoodPickerView` y se asocia.
  3. Si otra bandeja difiere solo en la cifra 7, pregunta si es el mismo producto. Con un "sí", la tienda pasa a clave de 6 (`useShortKeys`).
  4. Formato peso: importe = peso × último €/kg de esa presentación en la tienda; la primera vez pide el importe.
  5. `CartPriceSheet(alPeso: true)` pide "Importe del paquete" sin unidades.
- **En casa** (`FoodFlows.scanAtHome`): reconoce la etiqueta en cualquier tienda y, si el formato es peso, precarga los gramos en "Agregar ingesta" (`SearchView._scan`).
- `isVariableMeasure` (en `barcode.dart`) detecta estos códigos. Un código de báscula **nunca** se guarda como `codigo_barras` de una presentación.

### 3.4 Arreglo transversal

Liberar un `TextEditingController` justo después de `await showDialog` provoca "used after being disposed" mientras el diálogo aún se cierra. Se arregló con un widget nuevo, `lib/presentation/widgets/dialog_controllers.dart` (`DialogControllers`), aplicado en:

- `barcode_scanner_view` (`askBarcodeManually`)
- `shopping_lists_view` (`askName`)
- `food_detail_view` (porciones y presentaciones)
- `recipe_actions` (`addPortion`)
- `shopping_list_detail_view` (`_edit`)
- `categories_view`, con su propio `_CategoryNameDialog`

**Regla para diálogos nuevos con campos de texto: usar `DialogControllers`.**

### 3.5 Tests nuevos

- `test/unit/phase7_test.dart` (12 tests):
  - adivinador de categorías
  - instalación nueva con categorías
  - **migración v1→v2 con datos** (compara el esquema con una instalación nueva)
  - asignación automática y filtro por categoría
  - orden por tienda
  - crear, renombrar y borrar categorías
  - agrupación por pasillos
  - gasto por categoría
  - categoría en repertorio, TSV y respaldo
  - etiquetas de báscula: parseo, lectura, aprendizaje por tienda, carrito acumulado y clave de 6
- `test/widget/phase7_widget_test.dart` (3 tests):
  - lista agrupada, categoría sugerida y filtro
  - flujo completo de báscula en el modo carrito
  - pantalla de categorías

## 4. Lo que faltaba (todo hecho en la sesión siguiente)

Pendiente de verdad, fuera de este contenedor:

- **Probar un APK real** en el móvil. Aquí no hay SDK de Android porque
  `dl.google.com` está bloqueado.
- Crear un PR solo si el usuario lo pide.

Lista original, ya completada:

1. ✅ **Documentar la fase 7**:
   - `README.md`:
     - Tabla de pestañas/funciones: categorías y pasillos, báscula.
     - Modelo de datos: tablas y columnas v2.
     - Flujos: código de báscula en la tienda y en casa.
     - Exportar/importar: campo `categoria` y columna TSV.
     - Pruebas: los nuevos archivos de test.
     - Reglas: no guardar códigos de báscula como `codigo_barras`; usar `DialogControllers`.
   - `CLAUDE.md`: resumir lo anterior en "Modelo de datos (claves)" y "Lógica de negocio crítica". Añadir `category_repository`, `scale_repository` y `DialogControllers`. El esquema actual es **v2**.
   - `docs/PLAN_REDISENO_BD.md`: marcar la fase 7 como implementada; quitar la nota de "Fase 7 pendiente" de la cabecera.
2. ✅ `flutter analyze` y `flutter test`. Commit y push (a `claude/traspaso-md-continuation-77gbi5`, la rama asignada a la sesión siguiente).
3. ✅ Responder al usuario con un resumen en español. Recordarle que **sigue sin probarse un APK real**: en el contenedor no hay SDK de Android, porque `dl.google.com` está bloqueado.
4. El usuario **no ha pedido PR**. No crear PR salvo que lo pida.

## 5. Preparar el entorno en una sesión nueva

Flutter no viene instalado. En el contenedor anterior se instaló así (la red
permite `storage.googleapis.com`, `pub.dev` y GitHub; `dl.google.com` está
bloqueado):

```bash
mkdir -p /opt/flutter-sdk && cd /opt/flutter-sdk
curl -sS https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.9-stable.tar.xz -o f.tar.xz
tar xf f.tar.xz && rm f.tar.xz
git config --global --add safe.directory /opt/flutter-sdk/flutter
export PATH=/opt/flutter-sdk/flutter/bin:$PATH
flutter --disable-analytics
cd /home/user/cal_counter && flutter pub get
flutter analyze && flutter test        # esperado: 168 tests en verde
```

Notas:

- **`dart format`**: tras ejecutarlo, revertir `lib/domain/entities/user_settings.dart` (`git checkout HEAD -- lib/domain/entities/user_settings.dart`). El formateador lo cambia y no es parte del trabajo.
- **Tras tocar `tables.dart`**: `dart run build_runner build`. El `.g.dart` se versiona y la CI comprueba que esté al día.
- **Tests de widgets**:
  - Base de datos en memoria con `ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(db)])`.
  - Lecturas de la base de datos con `tester.runAsync`.
  - Al final, `pumpWidget(SizedBox())` + `pump(1 s)`.
  - Las listas largas necesitan `scrollUntilVisible`.

## 6. Decisiones y avisos importantes

- **Toolchain Android**: AGP 9.1.0, Gradle 9.3.1, KGP 2.4.0, `android.builtInKotlin=false`, `android.newDsl=false` (plantilla de Flutter 3.47).
  - `file_picker` 13+ (la 11 no compila bajo AGP 9). API: `saveFile` → `Uri?`, `pickFile()` + `readAsBytes()`.
  - `google_mlkit_text_recognition` **anclado a `^0.16.0`** (con AGP 9 podría subirse; no hace falta).
  - No reintroducir `file_saver`.
- **SQLite** viene con el paquete `sqlite3` (build hooks; descarga binarios al compilar).
- **Reglas que no se rompen** (detalle en `README.md` y `CLAUDE.md`):
  - nada de `REPLACE` sobre `alimentos`
  - `NULL` = desconocido ≠ 0
  - un pendiente no se registra en el contador
  - dinero en céntimos
  - el carrito no copia datos de la compra
  - historial = 3 meses + la última compra de cada presentación
  - `ExportDayToCsv` vacía el día (deliberado)
  - todo local (sin servicios online)
- **Formatos de intercambio estables**: el repertorio (`cal_counter/repertorio` v1) y el respaldo (`cal_counter/respaldo` v1) solo admiten campos **añadidos y opcionales**.
- **Commits**: el mensaje termina con las líneas de atribución que indique el sistema en la sesión. No incluir identificadores de modelo en commits ni en el código.

## 7. Mensaje de commit sugerido para la fase 7

```
Fase 7: categorías con orden de pasillo y etiquetas de báscula

- Esquema v2 con migración probada: categorías, orden de pasillos por
  tienda, códigos de báscula por tienda, formato de báscula de cada
  tienda y peso real de las compras.
- Categoría sugerida por el nombre al crear alimentos, filtro y chip en
  la ficha; listas y modo carrito agrupados por pasillos; gasto por
  categoría en el historial; pantalla para ordenar los pasillos.
- Etiquetas de báscula: el modo carrito aprende por tienda si el código
  lleva importe o peso, asocia cada producto y calcula el importe con el
  €/kg; varios paquetes se suman en una compra. En casa precarga los
  gramos al registrar la ingesta.
- La categoría viaja por nombre en repertorios, TSV y respaldos.
- DialogControllers evita liberar controladores de texto antes de que
  se cierre el diálogo.
```
