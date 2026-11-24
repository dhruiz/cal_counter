# Auditoría técnica integral — cal_counter

Fecha: 24-11-2026 · Rama: `claude/flutter-sdk-environment-r2k60q` · Base: `b2f9d7e` (árbol limpio al empezar).
Los cambios **no están commiteados** (pendiente de autorización).

Entorno: Flutter 3.44.9 · Dart 3.12.2 · AGP 8.13.1 · Kotlin 2.3.20 · Gradle 9.1.0 · JDK 21 (target JVM 17) · compileSdk/targetSdk 36 · minSdk 24 · NDK 28.2.13676358.

---

## A. Resumen ejecutivo

**Alcance.** Todo el código propio: los 110 archivos Dart de `lib/` y `test/`, configuración Android (Gradle KTS, 3 manifiestos, `MainActivity.kt`, recursos XML), `pubspec.yaml`/`pubspec.lock`, `analysis_options.yaml`, la BD precargada (esquema y datos) y la documentación. En total, **142 archivos** inventariados (sección B). Quedan fuera los SDK, los paquetes de `pub-cache` y los artefactos de `build/`. Algunos paquetes se leyeron para verificar comportamientos: `mobile_scanner` 7.5.0, `sqflite_android` 2.4.3 y `sqflite_common_ffi` 2.4.2.

**Estado inicial.** La base era buena: Clean Architecture bien aplicada en general, sin `analyze` issues y con 82 tests en verde. Los módulos recientes (recetas, productos, compras) son claramente más sólidos que el contador original. Aun así se encontraron fallos reales que ni el analizador ni los tests detectaban:

- **Datos e integridad.** Al dar de alta un alimento con un nombre existente se sobrescribía en silencio (`REPLACE`): cambiaba su id, se rompían los vínculos de recetas y productos y se perdía su contador de uso. Además, la apertura concurrente de la BD en el primer arranque podía copiar el asset encima de una conexión ya abierta.
- **Funcionalidad en Android.** La exportación de la BD completa escribía en una ruta elegida con `getDirectoryPath`. Fallaba en Android 7–10, porque el permiso de escritura nunca se pedía, y en Android 11+ fuera de Descargas/Documentos. Además, el día del contador no cambiaba nunca mientras la app seguía en memoria, así que lo registrado tras la medianoche se guardaba en el día anterior.
- **Privacidad.** El APK de release declaraba `INTERNET` por la telemetría de ML Kit, en contra de la decisión documentada de que todo sea local.
- **Corrección de resultados.** En Android los contadores de importación incluían los duplicados. "Nueva comida" podía añadir el alimento a otra comida ya existente.
- **Rendimiento.** La búsqueda de recetas por ingredientes tardaba unos 130 ms por pulsación con 300 recetas; ahora tarda entre 3 y 5 ms.
- **UX en español.** Los campos de gramos, macros y ajustes no aceptaban la coma decimal que escribe el teclado español, y los widgets de Material aparecían en inglés.

**Resultado.** Hay 55 hallazgos registrados: 0 críticos, 4 altos, 13 medios, 27 bajos y 11 informativos. Están corregidos los 4 altos, 12 de los 13 medios (el de firma de release, M-11, queda parcial) y 22 de los 27 bajos. Lo que queda pendiente se detalla en la sección L, con su motivo.

**Verificación final.** `flutter analyze` sin incidencias. `dart format` limpio. **113 tests** en verde (eran 82; se añadieron 38 de regresión y se eliminaron 7 que no probaban código de la app). APK debug y release compilados, y permisos del APK final comprobados con `aapt2`. **No se ha probado en un dispositivo ni en un emulador** (no hay ninguno disponible en este entorno).

**Valoración.** El proyecto queda en un estado técnicamente sólido para uso personal en producción. Los riesgos residuales son de baja probabilidad o requieren decisiones de producto (sección L).

---

## B. Inventario del proyecto auditado

Excluidos justificadamente: `ios/`, `macos/`, `linux/`, `windows/` y `web/` (plataformas no objetivo; código de plantilla generado), iconos PNG, `build/`, `.dart_tool/` y `android/.gradle/`. En `windows/flutter/generated_*` solo cambió el registro de plugins, regenerado por `pub get` al quitar `permission_handler`.

| Archivo | Tipo | Función | Estado |
|---|---|---|---|
| `.gitignore` | Config | Exclusiones de git | Auditado |
| `.metadata` | Config | Metadatos de Flutter (generado) | Auditado (generado) |
| `.vscode/settings.json` | Config | settings.json | Auditado |
| `CLAUDE.md` | Markdown | Guía del proyecto | Auditado · modificado |
| `README.md` | Markdown | Documentación técnica | Auditado · modificado |
| `analysis_options.yaml` | YAML | Reglas de lint (flutter_lints) | Auditado |
| `android/.gitignore` | Config | Exclusiones Android | Auditado |
| `android/app/build.gradle.kts` | Gradle KTS | Módulo app: SDK, NDK, firma | Auditado · modificado |
| `android/app/src/debug/AndroidManifest.xml` | XML Android | INTERNET para herramientas (debug) | Auditado |
| `android/app/src/main/AndroidManifest.xml` | XML Android | Manifiesto principal: permisos, actividad | Auditado · modificado |
| `android/app/src/main/kotlin/com/example/cal_counter/MainActivity.kt` | Kotlin | FlutterActivity sin código nativo propio | Auditado |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | XML Android | Splash v21 | Auditado |
| `android/app/src/main/res/drawable/launch_background.xml` | XML Android | Splash | Auditado |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | XML Android | Icono adaptativo | Auditado |
| `android/app/src/main/res/values-night/styles.xml` | XML Android | Temas de arranque (oscuro) | Auditado |
| `android/app/src/main/res/values/styles.xml` | XML Android | Temas de arranque | Auditado |
| `android/app/src/profile/AndroidManifest.xml` | XML Android | INTERNET para herramientas (profile) | Auditado |
| `android/build.gradle.kts` | Gradle KTS | Gradle raíz (repos, buildDir) | Auditado |
| `android/gradle.properties` | Properties | JVM, Jetifier, flags AGP | Auditado |
| `android/gradle/wrapper/gradle-wrapper.properties` | Properties | Gradle 9.1.0 | Auditado |
| `android/settings.gradle.kts` | Gradle KTS | Plugins AGP 8.13.1 / Kotlin 2.3.20 | Auditado |
| `assets/db/db_ctrl_calorias.db` | SQLite | BD SQLite precargada (678 alimentos) | Inspeccionado (esquema y datos) |
| `lib/core/constants.dart` | Dart | AppConstants (sin uso) | Auditado · **eliminado** |
| `lib/core/styles.dart` | Dart | AppStyles, temas | Auditado · modificado |
| `lib/core/utils.dart` | Dart | Formato de precios/fechas/números, parseo decimal | Auditado · modificado |
| `lib/data/datasources/local_data_source.dart` | Dart | SQLite: apertura, alimentos, comidas, import/export | Auditado · modificado |
| `lib/data/datasources/module_tables.dart` | Dart | DDL y migraciones de módulos | Auditado |
| `lib/data/datasources/product_local_data_source.dart` | Dart | Productos y compras (SQL) | Auditado |
| `lib/data/datasources/recipe_local_data_source.dart` | Dart | Recetas e ingredientes (SQL) | Auditado |
| `lib/data/datasources/shopping_local_data_source.dart` | Dart | Listas de compra (SQL) | Auditado |
| `lib/data/models/food_model.dart` | Dart | Fila db_alimentos ↔ Food | Auditado |
| `lib/data/models/product_model.dart` | Dart | Filas productos/compras ↔ entidades | Auditado |
| `lib/data/models/recipe_model.dart` | Dart | Fila recetas ↔ Recipe | Auditado |
| `lib/data/models/shopping_model.dart` | Dart | Filas listas ↔ entidades | Auditado |
| `lib/data/parsers/recipe_text_codec.dart` | Dart | Import/export de recetas (texto/JSON/CSV) | Auditado · modificado |
| `lib/data/repositories/food_repository_impl.dart` | Dart | FoodRepository sobre SQLite | Auditado · modificado |
| `lib/data/repositories/meal_repository_impl.dart` | Dart | MealRepository + CSV del día (FilePicker) | Auditado · modificado |
| `lib/data/repositories/product_repository_impl.dart` | Dart | ProductRepository (delegación) | Auditado |
| `lib/data/repositories/recipe_repository_impl.dart` | Dart | RecipeRepository (delegación) | Auditado |
| `lib/data/repositories/settings_repository_impl.dart` | Dart | Ajustes en SharedPreferences | Auditado |
| `lib/data/repositories/shopping_list_repository_impl.dart` | Dart | ShoppingListRepository (delegación) | Auditado |
| `lib/domain/entities/food.dart` | Dart | Entidad food | Auditado |
| `lib/domain/entities/meal.dart` | Dart | Entidad meal | Auditado |
| `lib/domain/entities/meal_item.dart` | Dart | Entidad meal_item | Auditado |
| `lib/domain/entities/price_stats.dart` | Dart | Entidad price_stats | Auditado |
| `lib/domain/entities/product.dart` | Dart | Entidad product | Auditado |
| `lib/domain/entities/recipe.dart` | Dart | Entidad recipe | Auditado |
| `lib/domain/entities/recipe_match.dart` | Dart | Entidad recipe_match | Auditado |
| `lib/domain/entities/shopping_list.dart` | Dart | Entidad shopping_list | Auditado |
| `lib/domain/entities/user_settings.dart` | Dart | Entidad user_settings | Auditado · modificado |
| `lib/domain/errors.dart` | Dart | Excepciones de dominio (DuplicateFoodNameException) | **Nuevo** |
| `lib/domain/repositories/food_repository.dart` | Dart | Interfaz food_repository | Auditado · modificado |
| `lib/domain/repositories/meal_repository.dart` | Dart | Interfaz meal_repository | Auditado |
| `lib/domain/repositories/product_repository.dart` | Dart | Interfaz product_repository | Auditado |
| `lib/domain/repositories/recipe_repository.dart` | Dart | Interfaz recipe_repository | Auditado |
| `lib/domain/repositories/settings_repository.dart` | Dart | Interfaz settings_repository | Auditado |
| `lib/domain/repositories/shopping_list_repository.dart` | Dart | Interfaz shopping_list_repository | Auditado |
| `lib/domain/services/cart_matching.dart` | Dart | Artículo de lista para un producto escaneado | Auditado |
| `lib/domain/services/dates.dart` | Dart | dateKey, dateOnly, threeMonthsAgo | Auditado |
| `lib/domain/services/ingredient_matcher.dart` | Dart | Normalización y búsqueda por ingredientes | Auditado · modificado |
| `lib/domain/services/meal_naming.dart` | Dart | Nombre automático Comida_N | **Nuevo** |
| `lib/domain/usecases/add_food_to_meal.dart` | Dart | Caso de uso add_food_to_meal | Auditado |
| `lib/domain/usecases/add_ingredients_to_shopping_list.dart` | Dart | Caso de uso add_ingredients_to_shopping_list | Auditado |
| `lib/domain/usecases/add_product_to_cart.dart` | Dart | Caso de uso add_product_to_cart | Auditado |
| `lib/domain/usecases/check_new_day_on_startup.dart` | Dart | Caso de uso check_new_day_on_startup | Auditado |
| `lib/domain/usecases/create_meal_if_not_exists.dart` | Dart | Caso de uso create_meal_if_not_exists | Auditado |
| `lib/domain/usecases/export_database.dart` | Dart | Caso de uso export_database | Auditado · modificado |
| `lib/domain/usecases/export_day_csv.dart` | Dart | Caso de uso export_day_csv | Auditado |
| `lib/domain/usecases/export_foods_tsv.dart` | Dart | Caso de uso export_foods_tsv | Auditado · modificado |
| `lib/domain/usecases/export_price_history_csv.dart` | Dart | Caso de uso export_price_history_csv | Auditado |
| `lib/domain/usecases/get_most_used_foods.dart` | Dart | Caso de uso get_most_used_foods | Auditado |
| `lib/domain/usecases/get_price_stats.dart` | Dart | Caso de uso get_price_stats | Auditado |
| `lib/domain/usecases/import_database.dart` | Dart | Caso de uso import_database | Auditado · modificado |
| `lib/domain/usecases/import_foods_tsv.dart` | Dart | Caso de uso import_foods_tsv | Auditado · modificado |
| `lib/domain/usecases/import_recipes.dart` | Dart | Caso de uso import_recipes | Auditado |
| `lib/domain/usecases/purge_old_purchases.dart` | Dart | Caso de uso purge_old_purchases | Auditado |
| `lib/domain/usecases/record_food_usage.dart` | Dart | Caso de uso record_food_usage | Auditado |
| `lib/domain/usecases/register_purchase.dart` | Dart | Caso de uso register_purchase | Auditado |
| `lib/domain/usecases/remove_from_cart.dart` | Dart | Caso de uso remove_from_cart | Auditado |
| `lib/domain/usecases/reset_food_usage.dart` | Dart | Caso de uso reset_food_usage | Auditado |
| `lib/domain/usecases/save_meal_as_food.dart` | Dart | Caso de uso save_meal_as_food | Auditado · modificado |
| `lib/domain/usecases/search_foods.dart` | Dart | Caso de uso search_foods | Auditado |
| `lib/domain/usecases/search_recipes_by_ingredients.dart` | Dart | Caso de uso search_recipes_by_ingredients | Auditado · modificado |
| `lib/domain/usecases/update_cart_item.dart` | Dart | Caso de uso update_cart_item | Auditado |
| `lib/main.dart` | Dart | Punto de entrada, MaterialApp, localización | Auditado · modificado |
| `lib/presentation/providers/home_provider.dart` | Dart | Providers/Notifiers (home_provider) | Auditado · modificado |
| `lib/presentation/providers/products_provider.dart` | Dart | Providers/Notifiers (products_provider) | Auditado · modificado |
| `lib/presentation/providers/recipes_provider.dart` | Dart | Providers/Notifiers (recipes_provider) | Auditado · modificado |
| `lib/presentation/providers/search_provider.dart` | Dart | Providers/Notifiers (search_provider) | Auditado · modificado |
| `lib/presentation/providers/settings_provider.dart` | Dart | Providers/Notifiers (settings_provider) | Auditado · modificado |
| `lib/presentation/providers/shopping_provider.dart` | Dart | Providers/Notifiers (shopping_provider) | Auditado · modificado |
| `lib/presentation/providers/theme_provider.dart` | Dart | Providers/Notifiers (theme_provider) | Auditado · modificado |
| `lib/presentation/views/barcode_scanner_view.dart` | Dart | Pantalla barcode_scanner_view | Auditado · modificado |
| `lib/presentation/views/cart_mode_view.dart` | Dart | Pantalla cart_mode_view | Auditado |
| `lib/presentation/views/day_management_view.dart` | Dart | Pantalla day_management_view | Auditado · modificado |
| `lib/presentation/views/food_form_view.dart` | Dart | Pantalla food_form_view | Auditado · modificado |
| `lib/presentation/views/food_picker_view.dart` | Dart | Pantalla food_picker_view | Auditado · modificado |
| `lib/presentation/views/home_view.dart` | Dart | Pantalla home_view | Auditado · modificado |
| `lib/presentation/views/main_shell.dart` | Dart | Pantalla main_shell | Auditado |
| `lib/presentation/views/product_detail_view.dart` | Dart | Pantalla product_detail_view | Auditado |
| `lib/presentation/views/product_form_view.dart` | Dart | Pantalla product_form_view | Auditado |
| `lib/presentation/views/product_picker_view.dart` | Dart | Pantalla product_picker_view | Auditado |
| `lib/presentation/views/products_view.dart` | Dart | Pantalla products_view | Auditado |
| `lib/presentation/views/recipe_detail_view.dart` | Dart | Pantalla recipe_detail_view | Auditado |
| `lib/presentation/views/recipe_form_view.dart` | Dart | Pantalla recipe_form_view | Auditado |
| `lib/presentation/views/recipe_import_view.dart` | Dart | Pantalla recipe_import_view | Auditado · modificado |
| `lib/presentation/views/recipes_view.dart` | Dart | Pantalla recipes_view | Auditado |
| `lib/presentation/views/search_view.dart` | Dart | Pantalla search_view | Auditado · modificado |
| `lib/presentation/views/settings_view.dart` | Dart | Pantalla settings_view | Auditado · modificado |
| `lib/presentation/views/shopping_list_detail_view.dart` | Dart | Pantalla shopping_list_detail_view | Auditado |
| `lib/presentation/views/shopping_lists_view.dart` | Dart | Pantalla shopping_lists_view | Auditado |
| `lib/presentation/widgets/add_food_popup.dart` | Dart | Widget add_food_popup | Auditado · modificado |
| `lib/presentation/widgets/add_to_shopping_list_dialog.dart` | Dart | Widget add_to_shopping_list_dialog | Auditado · modificado |
| `lib/presentation/widgets/cart_price_sheet.dart` | Dart | Widget cart_price_sheet | Auditado |
| `lib/presentation/widgets/empty_state.dart` | Dart | Widget empty_state | Auditado |
| `lib/presentation/widgets/meal_items_dialog.dart` | Dart | Widget meal_items_dialog | Auditado · modificado |
| `lib/presentation/widgets/nutrient_ring.dart` | Dart | Widget nutrient_ring | Auditado |
| `lib/presentation/widgets/purchase_dialog.dart` | Dart | Widget purchase_dialog | Auditado |
| `lib/presentation/widgets/recipe_card.dart` | Dart | Widget recipe_card | Auditado |
| `pubspec.lock` | Lock | Versiones resueltas (generado por pub) | Auditado · modificado (generado) |
| `pubspec.yaml` | YAML | Dependencias y assets | Auditado · modificado |
| `test/integration/add_food_flow_test.dart` | Dart | Test add_food_flow_test | Auditado |
| `test/unit/app_utils_test.dart` | Dart | Test app_utils_test | **Nuevo** |
| `test/unit/cart_matching_test.dart` | Dart | Test cart_matching_test | Auditado |
| `test/unit/csv_export_test.dart` | Dart | Test csv_export_test | Auditado · modificado |
| `test/unit/food_catalog_test.dart` | Dart | Test food_catalog_test | **Nuevo** |
| `test/unit/home_notifier_test.dart` | Dart | Test home_notifier_test | **Nuevo** |
| `test/unit/ingredient_matcher_test.dart` | Dart | Test ingredient_matcher_test | Auditado · modificado |
| `test/unit/local_data_source_test.dart` | Dart | Test local_data_source_test | Auditado |
| `test/unit/meal_naming_test.dart` | Dart | Test meal_naming_test | **Nuevo** |
| `test/unit/modules_data_source_test.dart` | Dart | Test modules_data_source_test | Auditado |
| `test/unit/price_history_test.dart` | Dart | Test price_history_test | Auditado |
| `test/unit/recipe_search_test.dart` | Dart | Test recipe_search_test | Auditado |
| `test/unit/recipe_text_codec_test.dart` | Dart | Test recipe_text_codec_test | Auditado · modificado |
| `test/unit/semaphor_test.dart` | Dart | Test semaphor_test | Auditado · **eliminado** |
| `test/unit/settings_repository_test.dart` | Dart | Test settings_repository_test | Auditado |
| `test/unit/settings_test.dart` | Dart | Test settings_test | Auditado · modificado |
| `test/unit/theme_and_food_usecases_test.dart` | Dart | Test theme_and_food_usecases_test | **Nuevo** |
| `test/unit/usecases_test.dart` | Dart | Test usecases_test | Auditado |
| `test/widget/add_food_popup_test.dart` | Dart | Test add_food_popup_test | **Nuevo** |
| `test/widget/fakes.dart` | Dart | Test fakes | Auditado · modificado |
| `test/widget/modules_smoke_test.dart` | Dart | Test modules_smoke_test | Auditado |

---

## C. Evaluación por categorías

| § | Categoría | Resultado | Hallazgos |
|---|---|---|---|
| 5.1 | Código muerto | Revisado con observaciones · corregido | B-14 |
| 5.2 | Redundancia / duplicación | Revisado con observaciones · corregido | M-08, B-14, B-18 |
| 5.3 | Robustez | Revisado con observaciones · corregido | M-09, B-03, B-07, B-08, B-13 |
| 5.4 | Dart (tipos, asincronía, recursos) | Revisado con observaciones | B-09, B-10, B-15, B-20 |
| 5.5 | Flutter (ciclo de vida, render, estado, navegación) | Revisado con observaciones | H-04, M-12, B-02, B-12, B-16, M-15 |
| 5.6 | Seguridad Flutter/Android | Revisado con observaciones | M-01, M-10, M-11, I-05 |
| 5.7 | Rendimiento y recursos | Revisado · medido | M-06, B-06, B-12, I-10 |
| 5.8 | APIs, red | **Sin hallazgos**: la app no hace peticiones de red; no hay HTTP, tokens ni sesiones. Solo telemetría de terceros (M-01) | M-01 |
| 5.9 | Persistencia e integridad | Revisado con observaciones · corregido | H-01, H-03, M-02, M-03, B-03, B-05, B-21 |
| 5.10 | Integración Flutter–Android | Revisado: sin platform channels propios (`MainActivity` vacía). Plugins revisados | B-20 (cámara) |
| 5.11 | Configuración / compilación Android | Revisado con observaciones | M-01, M-10, M-11, I-03, I-04, I-06 |
| 5.12 | Dependencias | Revisado con observaciones | B-14, I-07 |
| 5.13 | Testing | Revisado con observaciones · ampliado | M-17 + 38 tests nuevos |
| 5.14 | Legibilidad / mantenibilidad | Revisado con observaciones | M-07, I-01, I-02, B-17 |

**Seguridad (resumen).** SQL siempre parametrizado (los nombres de tabla en `PRAGMA` y `ALTER` son constantes internas). Sin secretos en el código (búsqueda de claves, tokens y contraseñas sin resultados). Una sola actividad exportada: el launcher, que es lo esperado. Sin deep links, WebView, `FileProvider` ni receptores propios. El `ProfileInstallReceiver` exportado de AndroidX está protegido con `android.permission.DUMP`. No hay tráfico de red propio ni configuración TLS que desactive la validación.

---

## D. Registro de hallazgos

Confianza: **C** = confirmado (reproducido o demostrado con test, herramienta o fuente) · **A** = alta (evidencia técnica sólida, sin reproducción) · **M** = media.

| ID | Archivo / ubicación | Categoría | Problema | Sev. | Conf. | Estado |
|---|---|---|---|---|---|---|
| H-01 | `local_data_source.dart` · `database`/`initDb` | Persistencia, asincronía | Apertura de la BD sin memoizar: en el primer arranque las 4 pestañas (IndexedStack) llamaban a `initDb` a la vez; cada llamada copiaba el asset sobre el archivo, aunque otra ya lo hubiera abierto y migrado | Alta | A | Corregido |
| H-02 | `search_view.dart` · `_exportDatabase` + `exportDatabase(path)` | Compatibilidad, funcionalidad | Export de la BD a una ruta de `getDirectoryPath` con `File`/sqflite: falla en Android 7–10 (`WRITE_EXTERNAL_STORAGE` nunca se pedía en tiempo de ejecución) y en 11+ fuera de Download/Documents; con nombre fijo, reexportar mezclaba con el archivo existente | Alta | A | Corregido |
| H-03 | `local_data_source.dart` · `insertFood` / `food_form_view.dart` | Integridad de datos | `ConflictAlgorithm.replace`: crear un alimento con un nombre existente borraba el original sin avisar (id nuevo → vínculos `alimento_id` rotos, `uso_count` perdido) | Alta | C | Corregido |
| H-04 | `home_provider.dart` · `HomeState.selectedDate` | Ciclo de vida | La fecha se fijaba al crear el notifier y no cambiaba nunca: con la app en memoria tras la medianoche, las ingestas se guardaban en el día anterior y no aparecía el diálogo de nuevo día | Alta | C | Corregido |
| M-01 | Manifiesto fusionado (release) | Seguridad, privacidad | `INTERNET` y `ACCESS_NETWORK_STATE` añadidos por `com.google.android.datatransport` (telemetría de ML Kit), en contra de "todo local" | Media | C | Corregido (INTERNET) |
| M-02 | `local_data_source.dart` · `importFoodsTsvFromString` | Persistencia | El conteo usaba `inserted != 0`: en Android un insert ignorado devuelve **-1** (en FFI, 0), así que contaba los duplicados como importados. Los tests no podían detectarlo | Media | C | Corregido |
| M-03 | `local_data_source.dart` · `importDatabase` | Persistencia, recursos | Contaba todas las filas aunque se ignoraran; sin transacción; la BD origen no se cerraba si la consulta fallaba | Media | C | Corregido |
| M-04 | `add_food_popup.dart` · `_submit` | Lógica | `Comida_{nº+1}` coincidía con una comida existente tras borrar o renombrar → `CreateMealIfNotExists` reutilizaba esa comida en silencio | Media | C | Corregido |
| M-05 | `add_food_popup`, `food_form_view`, `settings_view`, `meal_items_dialog`, `day_management_view` | UX, robustez | Los campos decimales solo aceptaban punto (formateador `^\d+\.?\d*` y `double.tryParse`); el teclado numérico en español escribe coma, que se descartaba o hacía fallar la validación | Media | C | Corregido |
| M-06 | `ingredient_matcher.dart` / `search_recipes_by_ingredients.dart` | Rendimiento | `RegExp` creado por carácter y por token; cada línea se interpretaba 3 veces; se recalculaba en cada pulsación. 300 recetas × 10 líneas ≈ **130 ms** | Media | C (medido) | Corregido → 3–5 ms |
| M-07 | `domain/repositories/food_repository.dart`, 5 casos de uso | Arquitectura | El dominio importaba `data/` (`FoodModel`, `LocalDataSource`), en contra de la regla de `CLAUDE.md` ("Dart puro") | Media | C | Corregido |
| M-08 | `home_view`, `settings_view`, `settings_provider` | Redundancia | Fórmula de requerimientos copiada 3 veces; solo una recortaba los carbohidratos negativos (anillo con objetivo negativo frente a 0 en Ajustes) | Media | C | Corregido |
| M-09 | `HomeNotifier`, `ProductsNotifier`, `RecipesNotifier`, listas | Robustez | Cargas sin `try/catch`: un error de BD dejaba el indicador de carga girando para siempre, con un error asíncrono sin manejar | Media | C | Corregido |
| M-10 | `AndroidManifest.xml` | Seguridad (mínimo privilegio) | `READ/WRITE_EXTERNAL_STORAGE` y `requestLegacyExternalStorage` sin ningún uso real tras H-02 | Media | C | Corregido |
| M-11 | `android/app/build.gradle.kts` | Configuración | Release firmado siempre con la clave de debug (TODO de plantilla) | Media | C | Parcial: firma opcional con `key.properties` |
| M-12 | `search_view.dart` · export/import BD | Navegación | Si el error ocurría antes de mostrar el diálogo de carga, `catch` hacía `Navigator.pop` y cerraba la búsqueda; el botón Atrás durante la carga producía el mismo efecto | Media | A | Corregido |
| M-17 | `test/unit/semaphor_test.dart`, `settings_test.dart` | Testing | Probaban **copias** de la lógica escritas dentro del propio test (el semáforo ya no existe en la app): cobertura falsa | Media | C | Corregido |
| M-18 | `UserSettings.tolerancePercent` / Ajustes | Código muerto (UI) | "Tolerancia (%)" se guarda y edita pero ninguna pantalla la usa desde que se quitó el semáforo | Baja | C | **Pendiente** (decisión de producto) |
| B-01 | `home_view`, `day_management_view` · exportar día | UX, robustez | Al cancelar el guardado se mostraba "Exportado a: " vacío; sin `try/catch` | Baja | C | Corregido |
| B-02 | `add_food_popup.dart` | Asincronía | "Ok" seguía activo durante el guardado: dos toques añadían el item dos veces | Baja | A | Corregido |
| B-03 | `local_data_source.dart` · `updateMealItem` | Robustez | Cantidad guardada 0 → factor infinito/NaN en los macros; lectura y escritura sin transacción | Baja | C | Corregido |
| B-04 | `local_data_source.dart` · `searchFoods` | Robustez | `LIKE` sin `ESCAPE`: buscar `_` coincidía con todo y `%` actuaba como comodín | Baja | C | Corregido |
| B-05 | `day_management_view` · guardar comida como alimento | Integridad | La UI preguntaba "¿sobrescribir?" sin distinguir mayúsculas, pero `UNIQUE` sí las distingue → se creaba un duplicado en vez de sobrescribir | Baja | A | Corregido |
| B-06 | `day_management_view` · Eliminar día | Rendimiento | Una recarga completa del día por cada comida borrada | Baja | C | Corregido |
| B-07 | `ingredient_matcher.dart` · `parseIngredientLine` | Robustez | Línea vacía → `RangeError` (`nombre[0]`) | Baja | C | Corregido |
| B-08 | `recipe_text_codec.dart` | Robustez | JSON con `"recetas"` que no es lista → `TypeError` (no `FormatException`); un entero enorme abortaba todo el import; BOM como literal invisible en el código | Baja | C | Corregido |
| B-09 | `SearchNotifier`, `FoodPickerView` | Asincronía | Un resultado en vuelo podía pisar la lista tras vaciar o cambiar la búsqueda; errores del timer sin capturar | Baja | A | Corregido |
| B-10 | `SettingsNotifier` | Estado | La carga inicial asíncrona podía sobrescribir un guardado hecho antes de que terminara | Baja | M | Corregido |
| B-11 | `food_form_view.dart` | Validación | Un nombre formado solo por espacios pasaba la validación y se guardaba vacío | Baja | C | Corregido |
| B-12 | `food_picker_view.dart` | Rendimiento | `ListView` no perezoso con cientos de resultados en cada pulsación | Baja | A | Corregido |
| B-13 | `recipe_import_view`, `add_to_shopping_list_dialog` | Robustez | Sin `try/catch`: un error dejaba los botones deshabilitados (`_saving`) o no daba ninguna respuesta visible | Baja | A | Corregido |
| B-14 | Varios | Código muerto | `core/constants.dart` (sin uso), `AppStyles.heading1/bodyText/defaultFontFamily`, `if (meals.isEmpty)` duplicado, `_ensureColumn` duplicado, dependencias `permission_handler` y `cupertino_icons` sin importar | Baja | C | Corregido |
| B-15 | `meal_repository_impl.dart` | Tipado | Acceso `dynamic` implícito a las filas (`e['cantidad']` → `double`) | Baja | A | Corregido |
| B-16 | `HomeNotifier.loadDailyData` | Render | Cada vuelta de otra pantalla sustituía todo el contenido por el indicador de carga (parpadeo) | Baja | C | Corregido |
| B-17 | 7 archivos | Mantenibilidad | Sin formatear según `dart format` | Baja | C | Corregido |
| B-18 | `local_data_source`, `meal_repository_impl` | Redundancia | Fechas con `toIso8601String().split('T')` en vez de `dateKey` | Baja | C | Corregido |
| M-15 | `ThemeNotifier` / `settings_view` | Estado, UX | Estado inicial `light` pero valor cargado por defecto `system`: el interruptor mostraba "claro" con el tema oscuro y el primer toque no cambiaba nada visible; un índice corrupto lanzaba `RangeError` | Baja | A | Corregido |
| M-16 | `main.dart` | UX / i18n | Sin `flutter_localizations`: el selector de fecha y los menús de texto aparecían en inglés; título "Calorie Counter" | Baja | C | Corregido |
| B-19 | `local_data_source.dart` · copia del asset | Persistencia | Copia no atómica: si se interrumpía, quedaba una BD corrupta para siempre | Baja | A | Corregido |
| M-14 | `barcode_scanner_view.dart` | Ciclo de vida, batería | Con controlador propio, `MobileScanner` no pausa la cámara al salir de la app (verificado en el código de mobile_scanner 7.5.0); en Android lo mitiga CameraX | Baja | A | Corregido |
| B-20 | Diálogos con `TextEditingController` local | Ciclo de vida | `dispose()` justo después de `showDialog` (durante la animación de salida) o sin `dispose` | Baja | M | No corregido (no reproducido; tests en verde) |
| B-21 | `product_local_data_source` · purga y borrados | Integridad | `items_lista_compra.compra_id` puede apuntar a una compra purgada o borrada (la corrección posterior es un no-op silencioso) | Baja | A | No corregido |
| B-22 | `product_local_data_source.getStores` | SQL | Columna sin agregar junto a 2 agregados (fila indeterminada); `LOWER` solo ASCII | Baja | A | No corregido |
| B-23 | `AddProductToCart`, `UpdateCartItem` | Atomicidad | Compra + artículo en dos escrituras sin transacción común | Baja | A | No corregido |
| I-01 | `meal_repository_impl.exportMealsByDateCSV` | Arquitectura | La capa de datos abre `FilePicker` (UI) | Info | C | No corregido |
| I-02 | `recipes_view`, `recipe_detail_view`, `recipe_import_view` | Arquitectura | Las vistas importan `data/parsers/recipe_text_codec.dart` | Info | C | No corregido |
| I-03 | `AndroidManifest.xml` | i18n | `android:label="cal_counter"` (nombre en el lanzador) | Info | C | Decisión de producto |
| I-04 | `build.gradle.kts` | Configuración | `namespace com.example.cal_counter` frente a `applicationId com.dhruiz.cal_counter` | Info | C | No corregido |
| I-05 | `AndroidManifest.xml` | Seguridad | `allowBackup` por defecto (true): peso y % de grasa en la copia de Google | Info | C | Decisión de producto |
| I-06 | `gradle.properties` | Build | `android.enableJetifier=true` probablemente innecesario | Info | M | No verificado |
| I-07 | `pubspec.yaml` | Dependencias | Versiones mayores disponibles (riverpod 3, file_picker 13, csv 8…) | Info | C | No actualizadas a propósito |
| I-08 | `ExportDayToCsv` | Datos | Vacía **todas** las fechas: si se canceló el diálogo de nuevo día, exportar hoy borra también el día anterior sin exportarlo | Info | C | Documentado; no cambiado (regla del proyecto) |
| I-09 | `RegisterPurchase.parsePrecio` | Lógica | "1.234" se interpreta como 1,234 € (decisión documentada) | Info | C | — |
| I-10 | APK | Tamaño | 74,3 MB (3 ABIs + ML Kit); `flutter_localizations` añade ~1,4 MB | Info | C | Recomendación |
| I-11 | `README.md`, `CLAUDE.md` | Documentación | Describían el semáforo eliminado, ~1700 alimentos (hay 678), `permission_handler`… | Info | C | Corregido |

> Nota de numeración: M-14, M-15, M-16 y M-18 conservan el identificador asignado durante la auditoría, aunque tras evaluarlos su severidad final es Baja.

### Detalle de los hallazgos altos y medios

**H-01 · Apertura concurrente de la BD** — `LocalDataSourceImpl.database` (`lib/data/datasources/local_data_source.dart`).
*Causa:* `if (_database != null) return; await initDb();` sin compartir el Future en curso. *Consecuencia:* en el primer arranque, `HomeNotifier`, `RecipesNotifier`, `ShoppingListsNotifier` y `ProductsNotifier` (las 4 pestañas del `IndexedStack`) piden la BD a la vez. Cada llamada ve que no existe y reescribe el archivo con `writeAsBytes` mientras otra ya lo ha abierto y le ha hecho `ALTER TABLE`, con riesgo de corrupción o de perder la migración. *Solución:* `static Future<Database>? _opening` compartido, reintento si falla, y `close()` coherente con una apertura en curso. Copia del asset a `.tmp` + `rename` (B-19). *Verificación:* test "aperturas simultáneas…" (instancia idéntica, 678 alimentos, columnas migradas, sin `.tmp`). La carrera no se reprodujo de forma determinista con el código antiguo.

**H-02 · Exportación de la BD rota en Android** — `SearchView._exportDatabase`, `LocalDataSource.exportDatabase(path)`.
*Causa:* `FilePicker.getDirectoryPath()` + `openDatabase('$dir/db_alimentos_export.db')`. *Consecuencia:* en API 24–28, `WRITE_EXTERNAL_STORAGE` es un permiso peligroso que nunca se pedía en tiempo de ejecución (`permission_handler` no se importaba en ninguna parte). En API 29, `requestLegacyExternalStorage` no basta sin ese permiso. En API 30+ (target 36) se ignora y solo se pueden crear archivos en algunas carpetas públicas; además, un archivo existente de una instalación anterior no es del usuario actual de la app. *Solución:* `exportDatabaseBytes()` genera el `.db` en la caché (transacción + batch) y la UI lo guarda con `FilePicker.saveFile(bytes:)` (SAF), como el resto de exportaciones; nombre con fecha y hora. La importación pasa a usar `FileType.any`, porque `.db` no tiene tipo MIME estándar; el contenido se valida al abrirlo. *Verificación:* test de exportación → cabecera `SQLite format 3` → reimportación. Sin dispositivo no se ha probado el diálogo SAF real.

**H-03 · Sobrescritura silenciosa de alimentos** — `insertFood` (`ConflictAlgorithm.replace`), `FoodFormView._save`.
*Consecuencia:* `REPLACE` borra la fila en conflicto e inserta otra con un id nuevo: se pierden los macros originales sin aviso, `recetas.alimento_id`/`productos.alimento_id` quedan "sin vincular" y `uso_count`/`ultimo_uso` vuelven a 0. *Solución:* `insertFood`/`updateFood` con `abort` → `DuplicateFoodNameException` (dominio) → mensaje "Ya existe un alimento llamado…". Para "Guardar comida como alimento", que sí debe sobrescribir tras confirmar, se usa `saveFoodByName`: actualiza en su sitio (coincidencia exacta y, si no, `COLLATE NOCASE`) y conserva id y uso. No se usa `UPSERT` porque minSdk 24 trae SQLite 3.9. *Verificación:* 4 tests (duplicado conserva el original; renombrado duplicado; sobrescritura con mismo id y uso; alta nueva).

**H-04 · El día no cambia con la app abierta** — `HomeNotifier`, `HomeView`.
*Solución:* `HomeNotifier.syncToday()` (reloj inyectable) y `AppLifecycleListener(onResume:)` en `HomeView`, que también relanza el diálogo de nuevo día (con protección contra duplicados). La fecha se normaliza a medianoche y las cargas obsoletas se descartan con un número de secuencia. *Verificación:* test con reloj simulado 23:50 → 08:00 del día siguiente.

**M-01 · INTERNET en release** — confirmado en `manifest-merger-release-report.txt` (origen: `transport-backend-cct`) y con `aapt2 dump permissions`. *Solución:* `tools:node="remove"` en el manifiesto principal; debug y profile lo vuelven a declarar (comprobado en sus manifiestos fusionados). `ACCESS_NETWORK_STATE` se mantiene: el planificador de `datatransport` lo usa y quitarlo podría provocar `SecurityException`. Las cargas de telemetría fallarán silenciosamente. El escaneo usa el modelo empaquetado de ML Kit, que no necesita red. *Riesgo residual:* verificar el escaneo en un dispositivo.

**M-02 / M-03 · Contadores de importación** — verificado leyendo `sqflite_android` (`SQLiteStatement.executeInsert()` devuelve -1 si no inserta) y `sqflite_common_ffi` (devuelve `null` → 0). *Solución:* contar `id > 0`, una sola transacción (antes, un commit por fila), filas con macros no finitos o negativos ignoradas, BOM y coma decimal aceptados en el TSV, y la BD origen cerrada en `finally`.

**M-04 · "Nueva comida" que no es nueva** — `nextMealName()` (`lib/domain/services/meal_naming.dart`): el mayor `Comida_N` + 1, sin bajar de nº + 1 y sin repetir nombre. Conserva la numeración anterior cuando no hay conflicto. *Verificación:* 5 tests unitarios + test de widget (Comida_1 y Comida_3 → "Comida_4").

**M-05 · Coma decimal** — `AppUtils.parseDecimal`, `decimalInputFormatter` y `formatDecimalEditable`/`formatNumero` (que ahora usa coma, como decía su propio comentario). *Verificación:* tests unitarios + widget ("12,5" g → 12,5 g y 16,25 kcal).

**M-06 · Rendimiento del matcher** — `normalizeText` por códigos de carácter, `RegExp` precompilados, `coveredByUserTokens`/`coversTokens` para no reinterpretar líneas, y caché acotada (4096 entradas) de `parseIngredientLine` (función pura, `tokens` inmodificable). *Medición* (`dart run`, JIT, misma máquina, mismos 9000 resultados): **130 ms → 3–5 ms por búsqueda**. Todos los tests del matcher siguen en verde y se añadieron casos de equivalencia.

**M-07 · Dirección de dependencias** — `FoodRepository` trabaja con `Food` e incorpora exportar/importar (TSV y BD). Los casos de uso `Export/ImportDatabase` y `Export/ImportFoodsTsv` dependen del repositorio, y `SaveMealAsFood` ya no conoce `FoodModel`. `grep "data/" lib/domain` queda vacío.

**M-08 · Fórmula única** — getters `proteinsRequired`, `fatsRequired` y `carbsRequired` (mínimo 0) en `UserSettings`, usados por las tres pantallas. Se eliminaron los getters duplicados del notifier.

**M-09 · Cargas sin manejo de errores** — `try/catch` con `log` y estado final coherente (`isLoading=false`; `HomeState.error` con botón "Reintentar"). *Verificación:* test de `HomeNotifier` con repositorio que falla.

**M-10 / M-11 · Manifiesto y firma** — eliminados los permisos de almacenamiento y la marca legacy. Firma: `android/key.properties` opcional (ya ignorado por git); sin él se mantiene la firma debug para que `flutter run --release` siga funcionando. No se generó ni configuró ninguna clave (fuera del alcance autorizado).

**M-12 · Indicador de carga** — helper `_withLoading` que solo cierra el diálogo que ha abierto, con `PopScope(canPop:false)`.

**M-17 · Tests que no probaban la app** — `semaphor_test.dart` (7 tests sobre una función copiada dentro del propio test) eliminado. `settings_test.dart` reescrito para probar `UserSettings`, con el caso de carbohidratos negativos.

---

## E. Código muerto, redundante y duplicado

- **Eliminado:** `lib/core/constants.dart`; `AppStyles.heading1`, `bodyText` y `defaultFontFamily`; condición duplicada en `HomeView._checkNewDay`; `_ensureColumn` (se reutiliza `ensureColumn` de `module_tables.dart`); getters duplicados de `SettingsNotifier`; `_formatGrams` (sustituido por `AppUtils.formatNumero`); dependencias `permission_handler` (con sus 5 paquetes de plataforma) y `cupertino_icons`; `test/unit/semaphor_test.dart`.
- **Fusionado:** fórmula de requerimientos → `UserSettings`; formato y lectura de decimales → `AppUtils`; fechas → `dateKey`; proveedores de exportar/importar TSV → `search_provider.dart`, junto al resto de alimentos.
- **Conservado a propósito:** `AppStyles.semaph*` (lo usan los anillos y varias vistas); `tolerancePercent` (dato persistido, pendiente de decisión, M-18); `RecipeTextCodec` en `data/` (depende de `csv`, así que no puede ir al dominio puro); los tres `_nullIfBlank` de los modelos (duplicación mínima y local; unificarlos no aporta nada).
- **Sin poder demostrar inutilidad:** ningún elemento adicional; no hay reflexión, generación de código ni rutas por nombre.

## F. Auditoría de seguridad

- **Vulnerabilidades confirmadas:** ninguna explotable remotamente; la app no tiene superficie de red. Riesgo de privacidad confirmado y corregido: telemetría de ML Kit con `INTERNET` (M-01).
- **Configuraciones inseguras corregidas:** permisos de almacenamiento innecesarios (M-10). Firma de release con clave de debug: queda parcial (M-11).
- **Dependencias:** no se dispone de un escáner de vulnerabilidades (sin acceso a una base de avisos). No se conocen avisos para las versiones fijadas. Se quitaron 7 paquetes sin uso. `intl` pasa de 0.19.0 a 0.20.2, requisito de `flutter_localizations` del SDK; sin cambios de API para los usos del proyecto, validado con tests y compilación.
- **Riesgos residuales:** `allowBackup` (I-05); entradas de importación (`.db`, TSV, recetas) procesadas en el hilo principal sin límite de tamaño, con impacto solo local; datos de salud en SQLite sin cifrar dentro del almacenamiento privado de la app (aceptable para una app personal sin cuenta).

## G. Auditoría de rendimiento

| Medida | Antes | Después | Método |
|---|---|---|---|
| Búsqueda de recetas por ingredientes (300 recetas × 10 líneas, 5 términos) | ~130 ms | ~3–5 ms | Benchmark `dart run` (JIT), 30 repeticiones tras calentamiento, mismos resultados |
| Importar TSV / BD | 1 commit por fila | 1 transacción | Revisión de código (no medido) |
| Exportar BD | 1 insert por alimento sin transacción | batch en transacción | Revisión de código (no medido) |
| Eliminar día con N comidas | N recargas | 1 recarga | Test |

Sin profiling en un dispositivo, quedan como pendientes de medir: renderizado de listas largas en `SearchView` (ya es perezosa), arranque en frío (copia de 0,1 MB del asset) y consumo de la cámara en modo carrito.

## H. Auditoría Flutter y Dart

- **Ciclo de vida:** controladores de formularios con `dispose` correcto; nuevo `AppLifecycleListener` (H-04) y observador de la cámara (M-14) liberados en `dispose`. Los diálogos con controladores locales se dejan como están (B-20).
- **Asincronía:** uso de `context` tras `await` revisado en todas las vistas (los módulos nuevos ya comprobaban `mounted`). Corregidos los resultados obsoletos (B-09), los dobles envíos (B-02) y la falta de manejo de errores (M-09, B-13).
- **Estado (Riverpod 2):** sin cambio de framework. Corregidas la carga frente al guardado de ajustes (B-10), las cargas solapadas del día (número de secuencia) y la incoherencia del tema (M-15).
- **Render:** `FoodPickerView` perezoso (B-12) y sin parpadeo en `HomeView` (B-16). No se añadieron `RepaintBoundary` ni otras optimizaciones sin medir.
- **Navegación:** imperativa y coherente; corregidos los `pop` erróneos (M-12).
- **Persistencia:** ver H-01, H-03, M-02, M-03, B-03 y B-05. Las migraciones existentes (`ensureColumn`) son idempotentes y no destructivas; no se añadió ninguna.

## I. Auditoría Android

- **Kotlin/Java:** `MainActivity` sin lógica propia y sin platform channels.
- **Manifiesto:** una actividad exportada (launcher), `singleTop` y `taskAffinity=""` (plantilla segura). Sin permisos de almacenamiento ni `INTERNET` en release; cámara opcional (`required=false`).
- **Gradle:** AGP 8.13.1, Kotlin 2.3.20, Gradle 9.1, JVM 17 y NDK 28.2, coherentes con las notas de `gradle.properties` y `CLAUDE.md`. Sin cambios de versiones.
- **Debug/release:** ambos compilan. Release con R8 (por defecto del plugin de Flutter) y firma opcional (M-11).
- **Compatibilidad:** minSdk 24 → SQLite 3.9 (por eso no se usa `UPSERT`); SAF para todo el acceso a archivos.

## J. Modificaciones realizadas

| Archivo | Modificación | Motivo | Verificación |
|---|---|---|---|
| `lib/data/datasources/local_data_source.dart` | Apertura memoizada + copia atómica; `insertFood`/`updateFood` sin REPLACE; `saveFoodByName`; `exportDatabaseBytes`; import con transacción, validación y conteo `id>0`; `LIKE ESCAPE`; `updateMealItem` con validación y transacción; `dateKey` | H-01, B-19, H-03, H-02, M-02, M-03, B-04, B-03, B-18 | `food_catalog_test` (13) + suite |
| `lib/domain/errors.dart` (nuevo) | `DuplicateFoodNameException` | H-03 | Tests |
| `lib/domain/repositories/food_repository.dart`, `data/repositories/food_repository_impl.dart`, 4 casos de uso export/import, `save_meal_as_food.dart` | El dominio deja de depender de `data/`; sobrescritura en su sitio | M-07, H-03 | `theme_and_food_usecases_test` |
| `lib/domain/services/meal_naming.dart` (nuevo), `add_food_popup.dart` | `nextMealName`, protección contra doble envío, coma decimal, metas desde `UserSettings`, manejo de errores | M-04, B-02, M-05, M-08 | `meal_naming_test`, `add_food_popup_test` |
| `lib/domain/entities/user_settings.dart`, `settings_provider.dart`, `home_view.dart`, `settings_view.dart` | Fórmula única con mínimo 0; ajustes con coma; interruptor de tema coherente | M-08, M-05, M-15, B-10 | `settings_test`, `theme_…_test` |
| `lib/domain/services/ingredient_matcher.dart`, `search_recipes_by_ingredients.dart` | Optimización + caché + guard para líneas vacías | M-06, B-07 | Benchmark + tests del matcher |
| `lib/data/parsers/recipe_text_codec.dart` | `FormatException`, `tryParse`, BOM escapado | B-08 | `recipe_text_codec_test` |
| `lib/data/repositories/meal_repository_impl.dart` | Tipado explícito, `dateKey` | B-15, B-18 | `csv_export_test` |
| `lib/presentation/providers/home_provider.dart` | `syncToday`, errores, secuencia de cargas, `deleteMeals`, sin parpadeo | H-04, M-09, B-06, B-16 | `home_notifier_test` |
| `products_provider.dart`, `recipes_provider.dart`, `shopping_provider.dart` | Manejo de errores en las cargas | M-09 | Suite de widgets |
| `search_provider.dart` | Proveedores de catálogo vía repositorio; descarte de resultados obsoletos | M-07, B-09 | Suite |
| `theme_provider.dart` | Estado inicial `system`, `setDark`, `isDarkFor`, índice protegido | M-15 | Test |
| `views/home_view.dart` | Ciclo de vida, diálogo de nuevo día protegido, export sin mensaje vacío, banner de error, título en español | H-04, B-01, M-09, M-16 | Análisis + suite |
| `views/search_view.dart` | Export de BD por SAF, `_withLoading` + `PopScope`, errores al borrar | H-02, M-12 | Análisis + compilación |
| `views/food_form_view.dart` | `Food` + mensaje de duplicado, validación con trim, coma decimal, protección contra doble envío | H-03, B-11, M-05 | Análisis |
| `views/day_management_view.dart`, `widgets/meal_items_dialog.dart` | Coma decimal, export controlado, borrado en lote | M-05, B-01, B-06 | Análisis |
| `views/food_picker_view.dart` | Lista perezosa, resultados obsoletos descartados | B-12, B-09 | Análisis |
| `views/recipe_import_view.dart`, `widgets/add_to_shopping_list_dialog.dart` | Manejo de errores | B-13 | Análisis |
| `views/barcode_scanner_view.dart` | Ciclo de vida de la cámara | M-14 | Análisis (sin cámara) |
| `lib/core/utils.dart` | `parseDecimal`, `decimalInputFormatter`, `formatDecimalEditable`; `formatNumero` con coma | M-05 | `app_utils_test` |
| `lib/main.dart`, `pubspec.yaml`, `pubspec.lock` | Localización es-ES; `intl ^0.20.2`; sin `permission_handler`/`cupertino_icons` | M-16, B-14 | `pub get`, compilación |
| `android/app/src/main/AndroidManifest.xml` | Sin almacenamiento ni legacy; `INTERNET` eliminado en release | M-01, M-10 | `aapt2` sobre el APK |
| `android/app/build.gradle.kts` | Firma opcional con `key.properties` | M-11 | Compilación release |
| `lib/core/styles.dart`, `lib/core/constants.dart` (borrado) | Código muerto | B-14 | `grep` + análisis |
| `test/…` | 6 archivos nuevos, 4 ampliados o reescritos, 1 eliminado; fakes adaptados | M-17 y regresiones | 113 tests |
| `README.md`, `CLAUDE.md` | Documentación alineada con el código (la nota personal del README no se tocó) | I-11 | Revisión |

## K. Resultados de pruebas

| Comando | Inicio | Final |
|---|---|---|
| `flutter analyze` | Sin incidencias | Sin incidencias |
| `dart format --output=none --set-exit-if-changed lib test` | 7 archivos sin formatear | Limpio |
| `flutter test` | 82 en verde | **113 en verde** (+38 nuevos, −7 que no probaban la app) |
| `flutter build apk --debug` | — | OK |
| `flutter build apk --release` | OK (72,9 MB) | OK (74,3 MB) |
| `aapt2 dump permissions app-release.apk` | CAMERA, INTERNET, ACCESS_NETWORK_STATE, R/W_EXTERNAL_STORAGE | CAMERA, ACCESS_NETWORK_STATE (+ permiso interno de AndroidX) |
| `flutter pub outdated` | Ejecutado (informativo, I-07) | — |

Tests nuevos: `food_catalog_test` (13, SQLite real con FFI), `meal_naming_test` (5), `app_utils_test` (5), `home_notifier_test` (3), `theme_and_food_usecases_test` (5), `add_food_popup_test` (1 de widget), `ingredient_matcher_test` (+4), `recipe_text_codec_test` (+3), `settings_test` (reescrito, 3).

**No realizado (limitaciones del entorno):** pruebas en dispositivo o emulador (sin KVM ni hardware); pruebas de integración con `integration_test` sobre Android; diálogos SAF reales; escaneo con cámara; profiling (DevTools); escaneo de vulnerabilidades de dependencias y de secretos con herramientas dedicadas (se hizo búsqueda manual con `grep`).

## L. Problemas pendientes

| ID | Motivo | Riesgo | Acción recomendada |
|---|---|---|---|
| M-18 | Quitar el campo "Tolerancia" cambia la UI: es una decisión de producto | Confunde al usuario (no hace nada) | Decidir si se elimina o se vuelve a usar |
| M-11 | No hay keystore; firmar o distribuir queda fuera del alcance autorizado | Los APK release van firmados con la clave de debug | Crear `android/key.properties` y la keystore |
| I-08 | `ExportDayToCsv` vacía todo por regla documentada | Perder un día no exportado si se canceló el diálogo | Valorar vaciar solo la fecha exportada (cambio funcional) |
| B-20 | No reproducido y sin impacto observable | Aserción en debug en algún diálogo | Extraer los diálogos con campos a `StatefulWidget` si aparece |
| B-21, B-22, B-23 | Bajo impacto; requieren cambios transversales | Inconsistencias menores en el historial de compras | Revisar en la próxima evolución del módulo |
| I-01, I-02 | Refactor desproporcionado para el beneficio | Acoplamiento leve | Un `DocumentSaver` en el dominio si crecen las exportaciones |
| I-03, I-05 | Nombre de la app y copia de seguridad: decisiones de producto | — | Decidir |
| I-06 | Requiere más pruebas de compilación | Compilación algo más lenta | Probar `enableJetifier=false` |
| M-01 (residual) | Sin dispositivo | Que ML Kit se comporte distinto sin `INTERNET` | Probar el escáner en un móvil real |

## M. Estado final

- **¿Compila?** Sí: APK debug y release.
- **¿Supera el análisis estático?** Sí: `flutter analyze` sin incidencias y formato limpio.
- **¿Superan las pruebas?** Sí: 113 de 113.
- **¿Integración Android verificada?** Parcialmente: compilación, manifiestos fusionados y permisos del APK con `aapt2`. **No en dispositivo.**
- **¿Vulnerabilidades pendientes?** Ninguna conocida y explotable. Queda la firma con la clave de debug mientras no exista una keystore.
- **Riesgos residuales:** sección L.
- **Sin verificar:** comportamiento en dispositivo (SAF, cámara y ML Kit sin `INTERNET`, cambio de día al reanudar), rendimiento en hardware real y vulnerabilidades de dependencias con herramientas dedicadas.

No se declara el proyecto libre de errores: la evidencia cubre el análisis estático, la compilación y las pruebas automatizadas descritas.
