# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> El `README.md` contiene la documentación exhaustiva (arquitectura completa, esquema SQL, fórmulas, todas las vistas/widgets). Consúltalo para el detalle; aquí está lo esencial.

## Comandos

```bash
flutter pub get                                   # dependencias
flutter run                                        # ejecutar (Android primario)
flutter analyze                                    # lint (flutter_lints)
flutter test                                       # todos los tests
flutter test test/unit/usecases_test.dart          # un archivo de test
flutter test --name "nombre del test"              # un test concreto por nombre
flutter build apk --release                        # APK → build/app/outputs/flutter-apk/app-release.apk
```

- Build que falla por caché: `flutter clean && flutter pub get && flutter build apk --release`.
- Los tests que tocan SQLite usan `sqflite_common_ffi`: requieren `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` en `setUpAll` (ver `test/unit/local_data_source_test.dart`). `path_provider` se mockea vía `MethodChannel`. Con FFI las rutas relativas se resuelven en `.dart_tool/sqflite_common_ffi/databases/`: limpiar con `databaseFactory.deleteDatabase(...)`, no borrando el directorio.
- Tests de widgets de los módulos nuevos: `test/widget/modules_smoke_test.dart` con repositorios en memoria (`test/widget/fakes.dart`) inyectados vía `ProviderScope(overrides: ...)`.

## Arquitectura

Clean Architecture en 3 capas, dependencias hacia el dominio:

- **`lib/domain/`** — Dart puro (solo `equatable`). Entidades, interfaces de repositorio, casos de uso (cada uno una clase con un único `call(...)`).
- **`lib/data/`** — implementa las interfaces. `LocalDataSourceImpl` (SQLite vía `sqflite`) con `static Database? _database` singleton; `SettingsRepositoryImpl` (SharedPreferences); `FoodModel` serializa filas SQLite ↔ entidad.
- **`lib/presentation/`** — Riverpod `StateNotifierProvider` (sin `setState` salvo dentro de formularios). Providers en `home_provider.dart` (incluye `localDataSourceProvider`, el único punto de creación del data source) y `search_provider.dart`; módulos nuevos en `recipes_provider.dart`, `products_provider.dart`, `shopping_provider.dart`. Vistas y widgets consumen providers; nunca acceden a `data/` directamente.

Navegación imperativa (`Navigator.push`/`pop` + `MaterialPageRoute`). La raíz es `MainShell` (`NavigationBar` + `IndexedStack`): pestañas Calorías (`HomeView`), Recetas, Compras y Productos. Tras cada `push(...).then(...)` o escritura en DB de comidas se llama a `HomeNotifier.refresh()`; desde recetas/productos usar `AddFoodPopup.showForToday`, que ya lo hace.

## Modelo de datos (claves)

- `db_alimentos`: macros **por 100g**. Columna `alimento` es `UNIQUE`. Nombres de columna exactos: `alimento`, `kCal`, `grasas`, `carbohidratos`, `proteinas`. Columnas de uso `uso_count` (INTEGER, default 0) y `ultimo_uso` (TEXT ISO8601, nullable) — alimentan la lista "más usados" de `SearchView`; persisten al vaciado de comidas. Migración idempotente vía `_ensureColumn` (PRAGMA + ALTER) en `_createTables`. `FoodModel.toJson` no las incluye, así que TSV/export/import no se ven afectados.
- `items_comida`: macros **ya escalados** a la cantidad consumida (valores absolutos, no por 100g). Guarda el nombre del alimento **desnormalizado** (sin FK al alimento original). `comida_id` con `ON DELETE CASCADE`.
- `comidas`: `fecha` se guarda como `String` `YYYY-MM-DD` (nunca timestamp). Nuevas comidas se auto-nombran `Comida_N`.
- DB precargada (`assets/db/db_ctrl_calorias.db`, ~1700 alimentos) se copia a `getApplicationDocumentsDirectory()` en el primer arranque.
- **Foreign keys desactivadas** (sqflite no activa `PRAGMA foreign_keys`): los `ON DELETE CASCADE` no actúan. Al borrar padres, borrar hijos explícitamente en transacción. `deleteMeal` ya lo hace con `items_comida`; `_createTables` limpia huérfanos antiguos en cada apertura y `hasMealItems` cuenta con JOIN a `comidas`.
- Tablas de módulos (DDL en `lib/data/datasources/module_tables.dart`, llamado desde `_createTables`): `recetas` + `ingredientes_receta` (líneas de texto libre), `productos` (`codigo_barras` UNIQUE, NULL si no tiene) + `compras` (`fecha` `YYYY-MM-DD`, precio unitario, establecimiento), `listas_compra` + `items_lista_compra` (`producto_id` opcional). `recetas.alimento_id`/`productos.alimento_id` apuntan a `db_alimentos` sin FK (borrado = sin vincular). Los data sources nuevos reciben `LocalDataSource` y usan su getter `database`.

## Lógica de negocio crítica

- **Escalado al agregar** (`AddFoodToMeal`): `factor = cantidad/100`. **Al editar cantidad** (`updateMealItem`): `ratio = newCantidad/oldCantidad` sobre los valores ya almacenados — NO se re-consulta el alimento base.
- **Carbohidratos objetivo = residuo calórico**: el usuario solo fija proteínas y grasas (g/kg); `carbsReq = (kcalTarget - (proteinsReq*4 + fatsReq*9))/4`. Coeficientes: prot 4, carbs 4, grasas 9 kcal/g.
- **TDEE** (`SettingsView`): con `% grasa corporal` válido → Katch-McArdle (ignora el sexo, que se deshabilita); si no → Mifflin-St Jeor. `TDEE = TMB * activityFactor`.
- **`ExportDayToCsv` vacía `comidas` e `items_comida`** tras un export exitoso (path no vacío). Efecto secundario deliberado; no quitarlo. Para un export sin vaciar, crear un use case nuevo.
- **`CheckNewDayOnStartup`** devuelve fecha (y dispara el diálogo de nuevo día) solo si `hasMealItems()==true` **y** la última fecha es anterior a hoy.
- Export CSV diario y TSV de alimentos usan separador **TAB** (el CSV mantiene extensión `.csv` por compatibilidad). TSV header fijo: `id\talimento\tkCal\tgrasas\tcarbohidratos\tproteinas`; el `id` se ignora al importar, duplicados filtrados por `ConflictAlgorithm.ignore`. Importación de DB completa también usa `ignore`.
- Export/import en Android 13+ usa SAF (`FilePicker.saveFile` con `bytes:` / `FilePicker.pickFiles` con `withData: true`); evita permisos de almacenamiento manuales. `file_saver` se eliminó (aplicaba KGP y bloqueaba el toolchain); no reintroducirlo.
- Toolchain Android anclado a AGP 8.13.1 + flags `android.builtInKotlin/newDsl=false`: Flutter 3.44 no soporta aún el DSL nuevo de AGP 9, y bajo AGP 9 `file_picker` deja de aplicar KGP y no compila. Revisar al actualizar Flutter.
- **Lista "más usados"** (`SearchView` con buscador vacío): `mostUsedFoodsProvider` (`FutureProvider.autoDispose`) lee `getMostUsedFoods` (orden `uso_count DESC`). El contador se incrementa en `AddFoodPopup._submit` vía `recordFoodUsageProvider` tras agregar a una comida (solo si `food.id != null`). `AddFoodToMeal` no se tocó. Invalidar `mostUsedFoodsProvider` tras alta/edición/baja/import de alimentos.

## Módulos Recetas / Compras / Productos (claves)

- **Búsqueda de recetas por ingredientes** (`SearchRecipesByIngredients`) y normalización en `lib/domain/services/ingredient_matcher.dart` (tildes, plurales, sinónimos regionales, unidades). Es simétrica: lo mismo se aplica a recetas y a lo que escribe el usuario. Los nombres comparables se derivan al vuelo; no guardar columnas derivadas.
- **Import de recetas** amigable en `lib/data/parsers/recipe_text_codec.dart`: texto/plantilla (formato principal, encabezados tolerantes, texto pegado sin encabezados), JSON y CSV. Export `.txt` reimportable. Duplicados por nombre normalizado se omiten (`ImportRecipes`).
- **Historial de precios = 3 meses + última compra de cada producto**: `PurgeOldPurchases` se ejecuta al crear `ProductsNotifier` y antes de exportar. Nunca borrar la última compra de un producto.
- **Export historial** (`ExportPriceHistoryCsv`): TAB, extensión `.csv`, cabecera `fecha\tcodigo_barras\tproducto\tmarca\tpresentacion\testablecimiento\tprecio_eur` (precio numérico, sin símbolo).
- **Escáner**: `mobile_scanner` (ML Kit empaquetado, sin internet) en `BarcodeScannerView.scan`; permiso `CAMERA` en el manifest con `uses-feature camera required=false`. Siempre ofrecer entrada manual del código. No se consulta ningún servicio online (decisión del usuario: todo local).
- Tras registrar compras o editar productos, `ProductsNotifier` invalida `productDetailProvider`, `storesProvider` y `shoppingItemsProvider` (precios de referencia de listas).

- **Precios en euros**: mostrar siempre con `AppUtils.formatPrecio` ("1,05 €"); campos de precio con `suffixText: '€'` y precarga con `AppUtils.formatPrecioEditable`. Leer lo escrito con `RegisterPurchase.parsePrecio` (acepta coma o punto).

## Convenciones

- **Idioma español** en toda la UI, columnas de DB, claves de SharedPreferences y comentarios. No mezclar idiomas.
- Al añadir campos a `UserSettings`: añadir su clave en `SettingsRepositoryImpl` tanto en `getSettings()` (con default de `UserSettings.initial()`) como en `saveSettings()`.
- Tema global solo vía `themeProvider`; estilos centralizados en `lib/core/styles.dart` (`AppStyles`).
