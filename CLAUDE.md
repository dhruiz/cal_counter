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
- Los tests que tocan SQLite usan `sqflite_common_ffi`: requieren `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` en `setUpAll` (ver `test/unit/local_data_source_test.dart`). `path_provider` se mockea vía `MethodChannel`.

## Arquitectura

Clean Architecture en 3 capas, dependencias hacia el dominio:

- **`lib/domain/`** — Dart puro (solo `equatable`). Entidades, interfaces de repositorio, casos de uso (cada uno una clase con un único `call(...)`).
- **`lib/data/`** — implementa las interfaces. `LocalDataSourceImpl` (SQLite vía `sqflite`) con `static Database? _database` singleton; `SettingsRepositoryImpl` (SharedPreferences); `FoodModel` serializa filas SQLite ↔ entidad.
- **`lib/presentation/`** — Riverpod `StateNotifierProvider` (sin `setState` salvo dentro de formularios). Providers en `home_provider.dart` (incluye `localDataSourceProvider`, el único punto de creación del data source) y `search_provider.dart`. Vistas y widgets consumen providers; nunca acceden a `data/` directamente.

Navegación imperativa (`Navigator.push`/`pop` + `MaterialPageRoute`); `HomeView` es la raíz. Tras cada `push(...).then(...)` o escritura en DB se llama a `HomeNotifier.refresh()`.

## Modelo de datos (claves)

- `db_alimentos`: macros **por 100g**. Columna `alimento` es `UNIQUE`. Nombres de columna exactos: `alimento`, `kCal`, `grasas`, `carbohidratos`, `proteinas`. Columnas de uso `uso_count` (INTEGER, default 0) y `ultimo_uso` (TEXT ISO8601, nullable) — alimentan la lista "más usados" de `SearchView`; persisten al vaciado de comidas. Migración idempotente vía `_ensureColumn` (PRAGMA + ALTER) en `_createTables`. `FoodModel.toJson` no las incluye, así que TSV/export/import no se ven afectados.
- `items_comida`: macros **ya escalados** a la cantidad consumida (valores absolutos, no por 100g). Guarda el nombre del alimento **desnormalizado** (sin FK al alimento original). `comida_id` con `ON DELETE CASCADE`.
- `comidas`: `fecha` se guarda como `String` `YYYY-MM-DD` (nunca timestamp). Nuevas comidas se auto-nombran `Comida_N`.
- DB precargada (`assets/db/db_ctrl_calorias.db`, ~1700 alimentos) se copia a `getApplicationDocumentsDirectory()` en el primer arranque.

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

## Convenciones

- **Idioma español** en toda la UI, columnas de DB, claves de SharedPreferences y comentarios. No mezclar idiomas.
- Al añadir campos a `UserSettings`: añadir su clave en `SettingsRepositoryImpl` tanto en `getSettings()` (con default de `UserSettings.initial()`) como en `saveSettings()`.
- Tema global solo vía `themeProvider`; estilos centralizados en `lib/core/styles.dart` (`AppStyles`).
