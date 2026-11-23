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

## Arquitectura

Clean Architecture en 3 capas, con las dependencias apuntando al dominio:

- **`lib/domain/`**: Dart puro (solo `equatable`). Contiene entidades, interfaces de repositorio (las listas devuelven `Stream`), `TransactionRunner`, servicios puros y casos de uso (cada uno una clase con un único `call(...)`). **No importa nada de `data/`.**
- **`lib/data/`**:
  - `db/`: esquema Drift en `tables.dart`, `app_database.dart` (+ `.g.dart`) y `mappers.dart`.
  - `repositories/`: implementaciones Drift.
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
- **Esquema**: cambiarlo exige subir `schemaVersion`, añadir la migración en `MigrationStrategy`, ejecutar `build_runner` y escribir tests.

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
  - Los formatos ya compartidos no deben romperse.
- **Catálogo base**: `assets/semilla/alimentos_base.json` (678 alimentos, uuid v5 determinista).
- **OCR**: `NutritionLabelParser` (Dart puro, con tests) y `MlKitLabelRecognizer`. Los valores se revisan (`LabelReviewSheet`) y pasan al formulario: **nunca se guardan sin confirmar**.
- **Precios**: mostrar con `AppUtils.formatPrecioCent` ("1,05 €"); campos con `suffixText: '€'`; leer con `parsePrecioCent` (coma o punto).
- **Escáner**: `mobile_scanner`; siempre se ofrece escribir el código a mano. **Todo local**: no consultar servicios online.

## Toolchain Android (no tocar sin revisar)

- AGP 8.13.1 + `android.builtInKotlin=false` / `android.newDsl=false`. Flutter 3.44 no soporta el DSL de AGP 9, y bajo AGP 9 `file_picker` no compila.
- **`google_mlkit_text_recognition` anclado a `^0.16.0`**: 0.17+ y 1.x requieren AGP 9 con Kotlin integrado.
- `file_saver` se eliminó; no reintroducirlo.
- SQLite la incluye `sqlite3` mediante build hooks (descarga binarios al compilar).

## Convenciones

- **Idioma español** en la interfaz, columnas de la base de datos, claves de SharedPreferences y comentarios. No mezclar idiomas. Nombres de clases en inglés (`Food`, `Recipe`...), campos en español.
- Al añadir campos a `UserSettings`: añadir su clave en `SettingsRepositoryImpl` tanto en `getSettings()` (con default de `UserSettings.initial()`) como en `saveSettings()`.
- Tema global solo vía `themeProvider`; estilos centralizados en `lib/core/styles.dart` (`AppStyles`). Avisos con `InfoBanner` y alimentos con `FoodTile`/`PendingChip` (`widgets/food_widgets.dart`).
