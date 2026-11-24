# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> El `README.md` contiene la documentación completa (arquitectura, esquema, formatos, flujos). `docs/PLAN_REDISENO_BD.md` recoge el diseño y las decisiones del modelo. Aquí está lo esencial.

## Comandos

```bash
flutter pub get
dart run build_runner build                 # tras tocar lib/data/db/tables.dart (el .g.dart se versiona)
flutter analyze                             # lint (flutter_lints)
flutter test                                # todos los tests
flutter test test/unit/backup_test.dart     # un archivo
flutter test --name "modo carrito"          # un test por nombre
flutter build apk --release                 # build/app/outputs/flutter-apk/app-release.apk
```

- Build que falla por caché: `flutter clean && flutter pub get && flutter build apk --release`.
- Tests de base de datos: `memoryDb()` de `test/helpers/test_db.dart` (Drift `NativeDatabase.memory()`, mismo esquema que en el móvil). Sin FFI ni rutas.
- Tests de widgets: app real con `ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(db)])`. Para leer la base de datos desde un `testWidgets` usar `tester.runAsync(...)`. Al final, `pumpWidget(SizedBox())` para cancelar los streams. Las listas largas necesitan `scrollUntilVisible`.
- `CartModeView.scannerBuilder` permite sustituir la cámara. `labelRecognizerProvider` permite sustituir el OCR.
- Entorno sin Flutter (contenedor en la nube): ver `docs/TRASPASO.md` §5 para instalar el SDK. Tras `dart format`, revertir `lib/domain/entities/user_settings.dart` (el formateador lo cambia y no es parte del trabajo).

## Arquitectura

Clean Architecture en 3 capas, con las dependencias apuntando al dominio:

- **`lib/domain/`**: Dart puro (solo `equatable`). Contiene entidades, interfaces de repositorio (las listas devuelven `Stream`), `TransactionRunner`, servicios puros y casos de uso (cada uno una clase con un único `call(...)`). **No importa nada de `data/`.**
- **`lib/data/`**:
  - `db/`: esquema Drift en `tables.dart`, `app_database.dart` (+ `.g.dart`) y `mappers.dart`.
  - `repositories/`: implementaciones Drift (alimentos, comidas, recetas, listas, compras, `category_repository_impl` y `scale_repository_impl`).
  - `backup/`: códecs de repertorio, TSV, respaldo completo y `.db` antiguo.
  - `ocr/`: ML Kit.
  - `parsers/`: recetas desde texto.
- **`lib/presentation/`**:
  - Riverpod 2.6. `core_providers.dart` es el **único punto de creación** de la base de datos (`appDatabaseProvider`), los repositorios y los casos de uso. Hay providers por módulo: `foods_provider`, `home_provider`, `recipes_provider`, `shopping_provider`, `purchases_provider` y `data_provider`.
  - Las vistas consumen providers; nunca instancian clases de `data/`.

**Reactividad**: los repositorios exponen `watch…()` y las pantallas se actualizan solas tras cualquier escritura. **No añadir `refresh()` ni cadenas de `invalidate` manuales.** `HomeNotifier.refresh()` solo cambia de día si la app pasó la medianoche abierta.

**Transacciones**: los casos de uso que escriben en varias tablas reciben `TransactionRunner` (Drift `transaction`, que se puede anidar).

**Navegación** imperativa (`Navigator.push`/`pop`). Raíz: `StartupGate`, que muestra la bienvenida la primera vez o `MainShell`. Pestañas: Calorías, Alimentos, Recetas y Compras.

## Modelo de datos (claves)

`alimentos` es el **núcleo**: recetas, compras, listas y comidas apuntan a él.

- **Claves foráneas activas** (`PRAGMA foreign_keys = ON` en `beforeOpen`). Las cascadas y los `SET NULL` funcionan. `compras → presentaciones` es `RESTRICT`: un alimento o presentación con compras se **archiva**, no se borra (`deleteFood`/`deletePackage`).
- **`alimentos`**:
  - `uuid` único (identidad para compartir) y `UNIQUE(nombre, marca)` con `COLLATE NOCASE`. Los duplicados sin tildes se detectan en `findByNameAndBrand`.
  - Tabla nutricional por 100 g/ml con 8 nutrientes **nulables** (`NULL` = desconocido ≠ 0).
  - "Pendiente" = le falta alguno de kcal, proteínas, grasas o carbohidratos. **Un pendiente no se registra en el contador** (`AddFoodToMeal` lanza; la interfaz ofrece completarlo con `FoodFlows.ensureComplete`).
  - **Nunca `REPLACE`**: editar es `update` (conserva id, uuid, vínculos y `uso_count`).
- **`presentaciones`**: aquí viven los códigos de barras (únicos, **normalizados** con `normalizeBarcode`: solo dígitos, UPC-A → EAN-13) y el `contenido` neto (€/kg). Un alimento puede tener varias.
- **`compras`**: `precio_cent` (**dinero en céntimos**), `unidades`, `establecimiento_id` y fecha `YYYY-MM-DD`. **Historial = 3 meses + la última compra de cada presentación** (`PurgeOldPurchases` al abrir la app y antes de exportar).
- **Carrito**: `items_lista.compra_id` apunta a la compra y de ahí salen unidades y precio (**nada se copia**). Desmarcar quita el vínculo y conserva la compra. "Quitar del carrito" borra la compra.
- **`ingredientes_receta`**: `texto` original siempre, más `alimento_id`/`cantidad`/`unidad` opcionales (`g`, `ml` o nombre de una porción). Al editar una receta, las líneas con el mismo texto conservan su vínculo.
- **`items_comida`**: valores **ya escalados** y nombre copiado (histórico), más un `alimento_id` informativo. Editar la cantidad aplica `ratio = nueva/anterior` sobre lo guardado.
- **Búsqueda**: FTS5 (`alimentos_fts`, triggers) por prefijo, sin tildes, con singular y sinónimos (`searchVariants`). 8–14 dígitos se buscan como código.
- **Categorías** (v2): `categorias` (`nombre` único NOCASE, `orden` general) y `alimentos.categoria_id` (`SET NULL`). `orden_pasillos` (PK tienda + categoría) guarda el orden propio de una tienda; sin filas se usa el general. 13 categorías por defecto (`defaultCategories`), sembradas con `sembrarCategorias`.
- **Báscula** (v2): `establecimientos.formato_bascula` (`'precio'|'peso'|NULL`) y `longitud_clave` (6 o 7). `codigos_bascula` (único por tienda + `clave`) apunta a la presentación "Al peso" del alimento. `compras.peso_g` es el peso real de la compra.
- **Esquema actual: v2** (`schemaVersion = 2`). Cambiarlo exige subir `schemaVersion`, añadir la migración en `onUpgrade` (`if (from < N)`), ejecutar `build_runner` y escribir tests. El test de migración v1→v2 parte de `test/fixtures/schema_v1.sql` y compara con una instalación nueva.

## Lógica de negocio crítica

- **Alta según el contexto**:
  - En la tienda (carrito/lista), un código desconocido avisa "no registrado" y pide solo nombre, marca, presentación y precio (`RegisterFoodInStore`, transaccional). **Nunca la tabla nutricional.**
  - En casa (`FoodFlows.foodForBarcode`) se ofrece el alta completa u "otra presentación de…".
- **Recetas** (`nutrition_calculator.dart`): gramos = cantidad (g/ml) o cantidad × porción; total, por 100 g (con `peso_final_g`) y por porción. `issues` lista lo que falta con su acción (vincular, cantidad, peso de la porción, completar). `SuggestIngredientLinks` propone vínculos y `SaveRecipeAsFood` crea un alimento `preparado`.
- **Carbohidratos objetivo = residuo calórico**: `(kcal − (prot·4 + grasas·9))/4`. **TDEE**: Katch-McArdle si hay % de grasa válido (ignora el sexo); si no, Mifflin-St Jeor. Después, `× factor de actividad`.
- **`ExportDayToCsv` vacía `comidas` e `items_comida` tras un export con éxito.** Es deliberado; no quitarlo. CSV con TAB y extensión `.csv`.
- **`CheckNewDayOnStartup`** solo dispara si hay items **y** la última fecha es anterior a hoy.
- **Intercambio** (`data/backup/`):
  - Repertorio JSON versionado (`cal_counter/repertorio` v1) **sin datos personales**. Fusión con `ImportRepertoire`: uuid → código → nombre y marca, rellena huecos, `ConflictPolicy` para valores distintos, una transacción, `dryRun` para la vista previa.
  - Respaldo completo (`cal_counter/respaldo`) que reemplaza todo y guarda antes una copia automática.
  - TSV ampliado; acepta la cabecera antigua de 6 columnas.
  - `.db` antiguo (`LegacyData`) y migración de la instalación anterior (`MigrateLegacyData`), sin tocar el archivo original.
  - Los formatos ya compartidos no deben romperse: solo campos **añadidos y opcionales**.
  - **La categoría viaja por nombre**, nunca por id: campo `categoria` del repertorio (se crea en destino si no existe; un alimento local solo la toma si no tenía), columna final `categoria` del TSV y tablas `categorias`/`orden_pasillos`/`codigos_bascula` en el respaldo. Al restaurar un respaldo v1 se resiembran las categorías y se reclasifican los alimentos.
- **Categorías y pasillos** (`category_guesser.dart`, `aisle_grouping.dart`, `CategoryRepository`):
  - `FoodRepository.saveFood(food, {adivinarCategoria = true})` asigna al insertar la categoría de `guessCategoryName` si `categoriaId` es null. El formulario pasa `adivinarCategoria: false` (muestra la sugerencia y decide el usuario).
  - Filtro: `search`/`watchSearch(categoriaId:)`; `kSinCategoria = 0` = sin categoría.
  - `groupByAisle`: un artículo vinculado usa la categoría de su alimento, el texto libre se clasifica por nombre y "Otros" va al final. Listas y "Te falta" del modo carrito se agrupan así.
  - Gasto por categoría: `PurchaseRepository.spendingByCategory(desde)`.
- **Etiquetas de báscula** (`scale_barcode.dart`, `scale_labels.dart`, `ScaleRepository`): EAN-13 con prefijo `2`. Clave = 7 primeros dígitos (6 si la tienda lleva dígito de control del precio en la 7ª); valor = cifras 8–12, importe en céntimos o peso en gramos según la tienda.
  - Se aprende **por tienda**: formato (primera etiqueta), producto (`LinkScaleCode` → presentación "Al peso") y clave de 6 (`useShortKeys`, si dos bandejas solo difieren en la cifra 7 y el usuario confirma).
  - Formato peso: importe = peso × último €/kg (`lastPricePerKiloCent`); la primera vez se pide.
  - `AddToCart(alPeso: true, pesoG:)` acumula varios paquetes en una sola compra (importe y peso sumados, 1 unidad). `PurchaseRecord.precioPorKiloCent` usa `peso_g` si existe.
  - En casa, `FoodFlows.scanAtHome` la reconoce en cualquier tienda y con formato peso precarga los gramos.
  - **Un código de báscula nunca se guarda como `codigo_barras`** de una presentación.
- **Catálogo base**: `assets/semilla/alimentos_base.json` (678 alimentos, uuid v5 determinista).
- **OCR**: `NutritionLabelParser` (Dart puro, con tests) y `MlKitLabelRecognizer`. Los valores se revisan (`LabelReviewSheet`) y pasan al formulario: **nunca se guardan sin confirmar**.
- **Precios**: mostrar con `AppUtils.formatPrecioCent` ("1,05 €"); campos con `suffixText: '€'`; leer con `parsePrecioCent` (coma o punto).
- **Escáner**: `mobile_scanner`; siempre se ofrece escribir el código a mano. **Todo local**: no consultar servicios online.
- **Fórmula de requerimientos única**: getters `proteinsRequired`, `fatsRequired` y `carbsRequired` (recortado a 0) de `UserSettings`; no duplicarla en vistas ni notifiers.
- **Cambio de día con la app abierta**: `HomeView` escucha `AppLifecycleListener(onResume:)` → `HomeNotifier.syncToday()` (reloj inyectable), que mueve `selectedDate` al día actual, vuelve a observar `watchDay` y relanza el diálogo de nuevo día. `refresh()` también reintenta si el flujo del día falló (`HomeState.error`).
- **Comidas nuevas**: `nextMealName` (mayor `Comida_N` + 1, nunca un nombre existente).
- **Campos numéricos**: coma o punto (`parseDecimal` de `money.dart` o `AppUtils.parseDecimal`, `AppUtils.decimalInputFormatter`); precargar con `AppUtils.formatNumero`/`formatDecimalEditable`.
- **Búsqueda de recetas por ingredientes** (`ingredient_matcher.dart`): se ejecuta en cada pulsación; `parseIngredientLine` tiene caché (función pura, `ParsedIngredient.tokens` inmodificable). No crear `RegExp` dentro de bucles.

## Toolchain Android (no tocar sin revisar)

- AGP 9.1.0 + Gradle 9.3.1 + KGP 2.4.0, con `android.builtInKotlin=false` / `android.newDsl=false` (los flags de la plantilla de Flutter 3.47: su plugin de Gradle aún no soporta `newDsl=true`). Flutter de referencia: 3.47.x.
- **`file_picker` 13+** (la 11 no aplicaba KGP bajo AGP 9 y no compilaba). API 12+: `saveFile(fileName:, bytes:)` escribe el archivo vía SAF y devuelve `Uri?` (mostrar con `AppUtils.formatRutaGuardada`; ruta vacía = cancelado para `ExportDayToCsv`); `pickFile()` devuelve `PlatformFile?` y se lee con `readAsBytes()` (sin `withData` ni `FilePickerResult`). Todo pasa por `FileTransfer` salvo el CSV del día, recetas e historial.
- **`google_mlkit_text_recognition` anclado a `^0.16.0`**. Aplica KGP por su cuenta: Flutter 3.47 avisa de que versiones futuras no compilarán con plugins así; al actualizar Flutter, subirlo a una versión con Kotlin integrado.
- **R8**: `android/app/proguard-rules.pro` lleva `-dontwarn` para los reconocedores de chino/devanagari/japonés/coreano que referencia ML Kit y que no se incluyen (solo `TextRecognitionScript.latin`). Sin esas reglas el build release falla en `minifyReleaseWithR8`.
- **Manifiesto**: sin permisos de almacenamiento (todo por SAF) y sin `INTERNET` en release (`tools:node="remove"`; lo añade la telemetría de ML Kit). Debug/profile lo declaran para las herramientas de Flutter. Firma de release opcional con `android/key.properties` (no versionado).
- `file_saver` se eliminó; no reintroducirlo.
- SQLite la incluye `sqlite3` mediante build hooks (descarga binarios al compilar).

## Convenciones

- **Idioma español** en la interfaz, columnas de la base de datos, claves de SharedPreferences y comentarios. No mezclar idiomas. Nombres de clases en inglés (`Food`, `Recipe`...), campos en español.
- Al añadir campos a `UserSettings`: añadir su clave en `SettingsRepositoryImpl` tanto en `getSettings()` (con default de `UserSettings.initial()`) como en `saveSettings()`.
- Tema global solo vía `themeProvider`; estilos centralizados en `lib/core/styles.dart` (`AppStyles`). Avisos con `InfoBanner` y alimentos con `FoodTile`/`PendingChip` (`widgets/food_widgets.dart`). Categorías con `CategoryDropdown`/`pickCategory` (`widgets/category_widgets.dart`).
- **Diálogos con campos de texto: usar `DialogControllers`** (`widgets/dialog_controllers.dart`). Liberar un `TextEditingController` justo después de `await showDialog` provoca "used after being disposed" mientras el diálogo aún se cierra.
