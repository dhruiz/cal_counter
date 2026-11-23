# cal_counter — Calorie Counter App

Aplicación Flutter de seguimiento de calorías y macronutrientes. Interfaz y datos completamente en **español**. Diseñada para Android (primario), con soporte potencial para otras plataformas Flutter.

---

## Tabla de contenidos

1. [Descripción general](#descripción-general)
2. [Entorno y versiones](#entorno-y-versiones)
3. [Estructura del proyecto](#estructura-del-proyecto)
4. [Arquitectura](#arquitectura)
5. [Capa de Dominio — entidades, repositorios, casos de uso](#capa-de-dominio)
6. [Capa de Datos — base de datos, modelos, implementaciones](#capa-de-datos)
7. [Capa de Presentación — providers, vistas, widgets](#capa-de-presentación)
8. [Estilos y constantes](#estilos-y-constantes)
9. [Flujo de navegación](#flujo-de-navegación)
10. [Esquema de la base de datos SQLite](#esquema-de-la-base-de-datos-sqlite)
11. [Persistencia de configuración (SharedPreferences)](#persistencia-de-configuración-sharedpreferences)
12. [Lógica de negocio crítica](#lógica-de-negocio-crítica)
13. [Módulos: Recetas, Listas de compra y Productos](#módulos-recetas-listas-de-compra-y-productos)
14. [Configuración Android](#configuración-android)
15. [Dependencias](#dependencias)
16. [Cómo ejecutar el proyecto](#cómo-ejecutar-el-proyecto)
17. [Convenciones y reglas que NO deben romperse](#convenciones-y-reglas-que-no-deben-romperse)

---

## Descripción general

**cal_counter** es un contador de calorías y macronutrientes diario. El usuario:

- Busca alimentos en una base de datos SQLite precargada con ~1700 alimentos en español.
- Agrega alimentos a "comidas" del día (Comida_1, Comida_2, etc.).
- Ve en tiempo real los totales diarios de kcal, grasas, carbohidratos y proteínas.
- Compara lo consumido contra sus metas personales con un sistema de semáforo de colores.
- Configura sus metas personales y calcula su TDEE automáticamente.
- Exporta el día a CSV (vacía las tablas tras éxito).
- Exporta/importa la lista de alimentos (`db_alimentos`) en formato TSV mediante SAF (Android 13+).

Además, en pestañas independientes (barra inferior), la app incluye:

- **Recetas**: repertorio personal con búsqueda por los ingredientes que el usuario tiene a mano, importación desde texto pegado / plantilla `.txt` / `.csv` / `.json` y vínculo opcional con el contador de calorías.
- **Compras**: listas de compra con precio de referencia, total estimado y modo "escanear en el súper".
- **Productos**: alta por código de barras (cámara), historial de precios por establecimiento (3 meses) y exportación CSV.

Ver [Módulos: Recetas, Listas de compra y Productos](#módulos-recetas-listas-de-compra-y-productos).

---

## Entorno y versiones

| Componente         | Versión                                        |
| ------------------ | ---------------------------------------------- |
| Flutter SDK        | `^3.8.1` (Dart SDK `^3.8.1`)                   |
| Versión de la app  | `1.0.0+1`                                      |
| Android minSdk     | Valor de `flutter.minSdkVersion`               |
| Android targetSdk  | Valor de `flutter.targetSdkVersion`            |
| Android compileSdk | Valor de `flutter.compileSdkVersion`           |
| Android NDK        | 27.0                                           |
| Kotlin             | compatible con Gradle Kotlin DSL               |
| Java               | 11 (sourceCompatibility y targetCompatibility) |
| Material Design    | Material 3 (`useMaterial3: true`)              |

---

## Estructura del proyecto

```
cal_counter/
├── assets/
│   └── db/
│       └── db_ctrl_calorias.db        ← Base de datos SQLite precargada (~1700 alimentos)
├── lib/
│   ├── main.dart                      ← Entry point. Inicializa locale 'es', ProviderScope
│   ├── core/
│   │   ├── constants.dart             ← AppConstants (appName, dbName)
│   │   ├── styles.dart                ← AppStyles (colores, temas, paddings)
│   │   └── utils.dart                 ← Utilidades generales
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── food.dart              ← Entidad Food (macros por 100g)
│   │   │   ├── meal.dart              ← Entidad Meal (comida del día)
│   │   │   ├── meal_item.dart         ← Entidad MealItem (alimento en comida)
│   │   │   └── user_settings.dart     ← Entidad UserSettings con defaults y copyWith
│   │   ├── repositories/
│   │   │   ├── food_repository.dart   ← Interfaz abstracta para alimentos
│   │   │   ├── meal_repository.dart   ← Interfaz abstracta para comidas
│   │   │   └── settings_repository.dart ← Interfaz abstracta para configuración
│   │   └── usecases/
│   │       ├── add_food_to_meal.dart
│   │       ├── check_new_day_on_startup.dart
│   │       ├── create_meal_if_not_exists.dart
│   │       ├── export_database.dart
│   │       ├── export_day_csv.dart
│   │       ├── export_foods_tsv.dart
│   │       ├── import_database.dart
│   │       ├── import_foods_tsv.dart
│   │       └── search_foods.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   └── local_data_source.dart ← Clase abstracta + LocalDataSourceImpl (SQLite)
│   │   ├── models/
│   │   │   └── food_model.dart        ← Extiende Food; serializa JSON ↔ entidad
│   │   └── repositories/
│   │       ├── food_repository_impl.dart
│   │       ├── meal_repository_impl.dart
│   │       └── settings_repository_impl.dart ← Usa SharedPreferences
│   └── presentation/
│       ├── providers/
│       │   ├── home_provider.dart     ← HomeState + HomeNotifier + providers de infraestructura
│       │   ├── search_provider.dart   ← SearchNotifier (debounce 200ms) + providers
│       │   ├── settings_provider.dart ← SettingsNotifier + cálculos derivados
│       │   └── theme_provider.dart    ← ThemeNotifier (light/dark con persistencia)
│       ├── views/
│       │   ├── home_view.dart         ← Pantalla principal (semáforo + resumen)
│       │   ├── search_view.dart       ← Búsqueda de alimentos + gestión de DB
│       │   ├── settings_view.dart     ← Configuración personal + cálculo TDEE
│       │   └── food_form_view.dart    ← Crear / editar alimento
│       └── widgets/
│           ├── add_food_popup.dart    ← Dialog para agregar alimento a comida
│           ├── meal_items_dialog.dart ← Dialog con items de una comida (editar/eliminar)
│           └── nutrient_card.dart     ← Card reutilizable (label + valor + color)
├── android/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/main/
│   │       └── AndroidManifest.xml
│   └── build.gradle.kts
├── pubspec.yaml
├── pubspec.lock
└── analysis_options.yaml
```

Archivos de los módulos de recetas, compras y productos:

```
lib/
├── domain/
│   ├── entities/        recipe.dart, recipe_match.dart, product.dart (Product + Purchase),
│   │                    price_stats.dart, shopping_list.dart (ShoppingList + ShoppingItem)
│   ├── repositories/    recipe_repository.dart, product_repository.dart, shopping_list_repository.dart
│   ├── services/        ingredient_matcher.dart (normalizar/comparar ingredientes), dates.dart
│   └── usecases/        search_recipes_by_ingredients, import_recipes, add_ingredients_to_shopping_list,
│                        register_purchase, get_price_stats, purge_old_purchases, export_price_history_csv
├── data/
│   ├── datasources/     module_tables.dart (DDL), recipe_/product_/shopping_local_data_source.dart
│   ├── models/          recipe_model.dart, product_model.dart, shopping_model.dart
│   ├── parsers/         recipe_text_codec.dart (import txt/json/csv, export txt, plantilla)
│   └── repositories/    recipe_/product_/shopping_list_repository_impl.dart
└── presentation/
    ├── providers/       recipes_provider.dart, products_provider.dart, shopping_provider.dart
    ├── views/           main_shell.dart (barra inferior), recipes_view, recipe_detail_view,
    │                    recipe_form_view, recipe_import_view, shopping_lists_view,
    │                    shopping_list_detail_view, products_view, product_detail_view,
    │                    product_form_view, barcode_scanner_view, food_picker_view, product_picker_view
    └── widgets/         recipe_card, purchase_dialog, add_to_shopping_list_dialog, empty_state
```

---

## Arquitectura

El proyecto implementa **Clean Architecture** con tres capas claramente separadas:

```
Presentación  →  Dominio  ←  Datos
(Riverpod)       (puro)      (SQLite + SharedPreferences)
```

- **Dominio**: Solo Dart puro. Entidades, interfaces de repositorios y casos de uso. Sin dependencias de Flutter ni de paquetes externos (excepto `equatable`).
- **Datos**: Implementa las interfaces del dominio. Gestiona `sqflite`, `shared_preferences`, `path_provider`, CSV.
- **Presentación**: Consume los providers de Riverpod. Widgets Flutter. No accede directamente a la capa de datos.

**Estado global**: Riverpod `StateNotifierProvider`. No existe `setState` a nivel de app; solo se usa dentro de widgets de formulario donde es semánticamente correcto.

---

## Capa de Dominio

### Entidades

#### `Food` — `lib/domain/entities/food.dart`

Representa un alimento con sus valores nutricionales **por 100 gramos**.

```dart
class Food extends Equatable {
  final int? id;
  final String name;          // nombre del alimento (UNIQUE en DB)
  final double grasasPer100;  // grasas en g por 100g
  final double carbsPer100;   // carbohidratos en g por 100g
  final double proteinsPer100;// proteínas en g por 100g
  final double kcalPer100;    // kilocalorías por 100g
}
```

#### `Meal` — `lib/domain/entities/meal.dart`

Representa una comida del día (contenedor de items).

```dart
class Meal extends Equatable {
  final int? id;
  final String name;    // "Comida_1", "Comida_2", etc.
  final DateTime date;  // fecha de la comida (solo la parte de fecha, sin hora)
}
```

#### `MealItem` — `lib/domain/entities/meal_item.dart`

Representa un alimento específico dentro de una comida, con sus macros **ya escalados** a la cantidad consumida.

```dart
class MealItem extends Equatable {
  final int? id;
  final int mealId;           // FK a Meal.id
  final double cantidad;      // gramos consumidos
  final String alimento;      // nombre del alimento (copia desnormalizada)
  final double grasas;        // grasas escaladas (no por 100g)
  final double carbohidratos; // carbs escalados
  final double proteinas;     // proteínas escaladas
  final double kcal;          // kcal escaladas
}
```

> **IMPORTANTE**: `MealItem` almacena los macros ya calculados para la cantidad concreta. Al editar la cantidad se recalcula usando el ratio `newCantidad / oldCantidad` directamente sobre los valores almacenados (no se re-consulta el alimento base).

#### `UserSettings` — `lib/domain/entities/user_settings.dart`

Configuración personal del usuario. Se persiste completa en `SharedPreferences`.

```dart
class UserSettings extends Equatable {
  final double weightKg;         // Peso en kg
  final int kcalTarget;          // Meta calórica diaria
  final double proteinsPerKg;    // Proteínas objetivo (g por kg de peso)
  final double fatsPerKg;        // Grasas objetivo (g por kg de peso)
  final int tolerancePercent;    // % de tolerancia sobre el objetivo (0-100)
  final double? bodyFatPercent;  // % grasa corporal (null → usar Mifflin-St Jeor)
  final double heightCm;         // Altura en cm
  final int age;                 // Edad en años
  final String sex;              // "male" o "female"
  final double activityFactor;   // 1.2 | 1.375 | 1.55 | 1.725 | 1.9
}
```

**Valores por defecto** (`UserSettings.initial()`):

| Campo            | Default |
| ---------------- | ------- |
| weightKg         | 70.0    |
| kcalTarget       | 2000    |
| proteinsPerKg    | 1.5     |
| fatsPerKg        | 0.5     |
| tolerancePercent | 10      |
| bodyFatPercent   | null    |
| heightCm         | 170.0   |
| age              | 30      |
| sex              | "male"  |
| activityFactor   | 1.2     |

### Interfaces de repositorios (abstractas)

#### `FoodRepository`

```dart
abstract class FoodRepository {
  Future<List<Food>> searchFoods(String query);
  Future<int> insertFood(Food food);
  Future<int> updateFood(Food food);
  Future<int> deleteFood(int id);
}
```

#### `MealRepository`

```dart
abstract class MealRepository {
  Future<int> createMeal(String name, DateTime date);
  Future<List<Meal>> getMealsByDate(DateTime date);
  Future<DateTime?> getLastMealDate();
  Future<int> addItemToMeal(MealItem item);
  Future<List<MealItem>> getMealItems(int mealId);
  Future<void> deleteMeal(int id);
  Future<void> deleteMealItem(int id);
  Future<void> updateMealItem(int id, double newCantidad);
  Future<String> exportMealsByDateCSV(DateTime date);
  Future<bool> hasMealItems();           // ¿hay al menos un item en items_comida?
  Future<void> clearMealsAndItems();     // vacía las tablas comidas e items_comida
}
```

#### `SettingsRepository`

```dart
abstract class SettingsRepository {
  Future<UserSettings> getSettings();
  Future<void> saveSettings(UserSettings settings);
}
```

### Casos de uso

Cada caso de uso es una clase con un único método `call(...)`.

| Caso de uso             | Descripción                                                                                                                                                                                 |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SearchFoods`           | Delegación directa a `FoodRepository.searchFoods`                                                                                                                                           |
| `AddFoodToMeal`         | Calcula macros escalados y llama a `MealRepository.addItemToMeal`                                                                                                                           |
| `CreateMealIfNotExists` | Consulta si existe comida con ese nombre en esa fecha; si no, la crea                                                                                                                       |
| `CheckNewDayOnStartup`  | Devuelve la última `DateTime` de comidas **solo si** `hasMealItems()` es `true` y la fecha es anterior a hoy. En cualquier otro caso devuelve `null`.                                       |
| `ExportDayToCsv`        | Llama a `MealRepository.exportMealsByDateCSV(date)`. **Si el path resultante es no vacío (export exitoso), llama después a `clearMealsAndItems()`** para vaciar `comidas` e `items_comida`. |
| `ExportDatabase`        | Llama a `LocalDataSource.exportDatabase(destinationPath)` (formato `.db` completo, legacy)                                                                                                  |
| `ImportDatabase`        | Llama a `LocalDataSource.importDatabase(sourcePath)` (formato `.db` completo, legacy)                                                                                                       |
| `ExportFoodsTsv`        | Llama a `LocalDataSource.exportFoodsTsv()`. Devuelve un `String` con el contenido TSV completo de `db_alimentos`.                                                                           |
| `ImportFoodsTsv`        | Llama a `LocalDataSource.importFoodsTsvFromString(String)`. Devuelve el número de alimentos insertados con éxito (los duplicados por UNIQUE en `alimento` se ignoran).                      |

---

## Capa de Datos

### `LocalDataSource` — `lib/data/datasources/local_data_source.dart`

**Clase abstracta** `LocalDataSource` + **implementación** `LocalDataSourceImpl`.

#### Inicialización de la base de datos

En el primer lanzamiento:

1. Comprueba si existe el archivo `db_ctrl_calorias.db` en `getApplicationDocumentsDirectory()`.
2. Si no existe, copia el archivo desde `assets/db/db_ctrl_calorias.db` usando `rootBundle.load`.
3. Abre la BD con `sqflite.openDatabase` versión 1.
4. Llama a `_createTables` tanto en `onCreate` como en `onOpen` (usa `CREATE TABLE IF NOT EXISTS`).

#### Singleton de base de datos

`LocalDataSourceImpl` usa un campo estático `static Database? _database`. La instancia se comparte entre todas las llamadas. Si se cierra con `close()`, el campo se pone a `null` para permitir re-inicialización.

#### Operaciones críticas de `updateMealItem`

Al editar la cantidad de un `MealItem`, **no** se consulta el alimento original. Se usa el ratio:

```dart
final ratio = newCantidad / oldCantidad;
nuevosGrasas   = grasasActuales   * ratio;
nuevosCarbos   = carbosActuales   * ratio;
nuevasProteinas = proteinasActuales * ratio;
nuevasKcal     = kcalActuales     * ratio;
```

#### Importación de base de datos completa (`.db` legacy)

`importDatabase(String sourcePath)` usa `ConflictAlgorithm.ignore` sobre la restricción `UNIQUE` de la columna `alimento`. Los duplicados se saltan silenciosamente. Devuelve el número de registros insertados con éxito.

#### Exportación de base de datos completa (`.db` legacy)

`exportDatabase(String destinationPath)` crea un nuevo archivo `.db` en `destinationPath` con la misma estructura y copia todos los alimentos actuales.

#### Exportación / importación TSV de `db_alimentos`

Métodos modernos para intercambiar **solo la tabla `db_alimentos`** en formato TSV:

- `Future<String> exportFoodsTsv()` — devuelve el contenido completo del TSV. Header (línea 1):

  ```
  id\talimento\tkCal\tgrasas\tcarbohidratos\tproteinas
  ```

  Cada fila contiene los 6 campos separados por tabulador. En el campo `alimento`, los caracteres `\t`, `\n` y `\r` se reemplazan por espacios para no romper el formato.

- `Future<int> importFoodsTsvFromString(String tsvContent)` — parsea el TSV. Validaciones:
  - Si el contenido está vacío o el header no coincide exactamente, lanza `FormatException`.
  - Líneas vacías se saltan; líneas con número de columnas distinto de 6 se ignoran (con log).
  - **El campo `id` del TSV se ignora** al insertar (autoincremento de SQLite). El `UNIQUE` en `alimento` previene duplicados vía `ConflictAlgorithm.ignore`.
  - Devuelve el número de filas insertadas con éxito.

#### Verificación y limpieza de comidas

- `Future<bool> hasMealItems()` — `SELECT COUNT(*) FROM items_comida` ; devuelve `true` si hay al menos un item.
- `Future<void> clearMealsAndItems()` — borra todas las filas de `items_comida` y `comidas` dentro de una **transacción atómica**. El orden importa: primero items, luego comidas (aunque `ON DELETE CASCADE` lo cubriría).

### `FoodModel` — `lib/data/models/food_model.dart`

Extiende `Food`. Añade serialización desde/hacia `Map<String, dynamic>` (filas de SQLite):

- Columna `id` → `food.id`
- Columna `alimento` → `food.name`
- Columna `kCal` → `food.kcalPer100`
- Columna `grasas` → `food.grasasPer100`
- Columna `carbohidratos` → `food.carbsPer100`
- Columna `proteinas` → `food.proteinsPer100`

> **CRÍTICO**: Los nombres de columnas en la DB son `kCal`, `grasas`, `carbohidratos`, `proteinas`, `alimento`. Cualquier nueva query debe usar exactamente estos nombres.

### Implementaciones de repositorios

#### `MealRepositoryImpl`

- Convierte `Map<String, dynamic>` de SQLite a entidades `Meal` y `MealItem`.
- `exportMealsByDateCSV`: usa el paquete `csv` (`ListToCsvConverter`) con separador tabulador (`\t`). Escribe el archivo en `getApplicationDocumentsDirectory()`.

#### `SettingsRepositoryImpl`

Persiste cada campo de `UserSettings` como una clave independiente en `SharedPreferences`:

| Clave SharedPreferences | Campo                             |
| ----------------------- | --------------------------------- |
| `weightKg`              | `weightKg`                        |
| `kcalTarget`            | `kcalTarget`                      |
| `proteinsPerKg`         | `proteinsPerKg`                   |
| `fatsPerKg`             | `fatsPerKg`                       |
| `tolerancePercent`      | `tolerancePercent`                |
| `bodyFatPercent`        | `bodyFatPercent` (puede ser nulo) |
| `heightCm`              | `heightCm`                        |
| `age`                   | `age`                             |
| `sex`                   | `sex`                             |
| `activityFactor`        | `activityFactor`                  |

Si una clave no existe, se devuelven los valores de `UserSettings.initial()`.

---

## Capa de Presentación

### Providers de Riverpod

#### `home_provider.dart`

Providers de infraestructura definidos aquí (y reutilizados desde `search_provider.dart`):

```dart
// Instancia única de la fuente de datos (singleton)
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return LocalDataSourceImpl();
});

final mealRepositoryProvider       = Provider<MealRepository>(...);
final checkNewDayOnStartupProvider = Provider<CheckNewDayOnStartup>(...);
final exportDayToCsvProvider       = Provider<ExportDayToCsv>(...);
final exportFoodsTsvProvider       = Provider<ExportFoodsTsv>(...);
final importFoodsTsvProvider       = Provider<ImportFoodsTsv>(...);

// Provider principal de estado de la pantalla home
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(...);
```

**`HomeState`**:

```dart
class HomeState {
  final DateTime selectedDate;           // Fecha mostrada (hoy por defecto)
  final List<Meal> meals;                // Comidas del día
  final Map<int, List<MealItem>> mealItems; // mealId → lista de items
  final double totalKcal;
  final double totalProteins;
  final double totalFats;
  final double totalCarbs;
  final bool isLoading;
}
```

**`HomeNotifier`**:

- Carga datos al construirse (`loadDailyData()`).
- `loadDailyData()`: obtiene comidas del día, itera items de cada comida, acumula totales.
- `deleteMeal(id)`, `deleteMealItem(id)`, `updateMealItemQuantity(id, newCantidad)`: ejecutan la operación y llaman `loadDailyData()`.
- `refresh()`: alias de `loadDailyData()`.

#### `search_provider.dart`

```dart
final foodRepositoryProvider   = Provider<FoodRepository>(...);
final searchFoodsProvider      = Provider<SearchFoods>(...);
final exportDatabaseProvider   = Provider<ExportDatabase>(...);
final importDatabaseProvider   = Provider<ImportDatabase>(...);
final searchResultsProvider    = StateNotifierProvider<SearchNotifier, List<Food>>(...);
```

**`SearchNotifier`**: Implementa debounce de **200 ms** con `dart:async Timer`. Si la query está vacía, el estado se limpia inmediatamente (sin esperar el debounce).

#### `settings_provider.dart`

```dart
final settingsRepositoryProvider = Provider<SettingsRepository>(...);
final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>(...);
```

**`SettingsNotifier`** expone getters calculados derivados del estado:

```dart
double get proteinsRequired => state.weightKg * state.proteinsPerKg;
double get fatsRequired     => state.weightKg * state.fatsPerKg;
double get carbsRequired {
  final proteinKcal = proteinsRequired * 4;
  final fatKcal     = fatsRequired * 9;
  return (state.kcalTarget - (proteinKcal + fatKcal)) / 4;
}
```

> **IMPORTANTE**: Los carbohidratos se calculan **como residuo** del total calórico. El usuario solo fija proteínas y grasas (g/kg); los carbos se derivan. Esta es la lógica central del plan nutricional.

#### `theme_provider.dart`

```dart
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(...);
```

Persiste el tema en `SharedPreferences` con la clave `isDarkMode` (bool). Método `toggleTheme()`.

### Vistas

#### `HomeView` — `lib/presentation/views/home_view.dart`

Tipo: `ConsumerStatefulWidget`

**Estructura de la pantalla** (de arriba a abajo):

1. `AppBar` con título "Calorie Counter". `actions` (de izquierda a derecha):
   - `PopupMenuButton` con icono `Icons.import_export`, dos opciones:
     - **Exportar Alimentos (TSV)** → genera el TSV (`exportFoodsTsvProvider`), lo codifica a UTF-8 y lo guarda con `FileSaver.instance.saveAs` (SAF en Android 13+). Nombre: `db_alimentos_export_<yyyy-MM-dd_HH-mm-ss>.tsv`.
     - **Importar Alimentos (TSV)** → `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['tsv'], withData: true)`, decodifica UTF-8 y llama a `importFoodsTsvProvider`.
   - `IconButton` `Icons.settings` → navega a `SettingsView`.
2. Sección **"Metas (Objetivo)"**: grid 4 columnas (Kcal, Grasas, Carbs, Prot) en color `AppStyles.neutral`.
3. Sección **"Consumido"**: mismo grid con color calculado por semáforo.
4. Sección **"Restante"**: mismo grid con color calculado por semáforo de restante.
5. Botón **"Agregar Ingesta"** (navega a `SearchView`).
6. `Card` con `ExpansionTile` **"Resumen del Día"** (expandido por defecto).
   - Lista cada `Meal` como `ListTile` con: nombre, count items, totales de kcal/G/C/P.
   - Tap en `ListTile` → `MealItemsDialog`.
   - Icono delete → dialog de confirmación → `HomeNotifier.deleteMeal`.
   - Botones al pie: "Exportar Día" y "Eliminar Día" (rojo).

**Lógica de semáforo** — `_computeColorForConsumed(target, consumed, tolerance)`:

| Condición                                          | Color          |
| -------------------------------------------------- | -------------- |
| `consumed < target` (por debajo, con epsilon 0.01) | `semaphRed`    |
| `consumed ≈ target` (±0.01)                        | `semaphGreen`  |
| `target < consumed ≤ target * (1 + tolerance/100)` | `semaphOrange` |
| `consumed > target * (1 + tolerance/100)`          | `semaphRed`    |

**Lógica de semáforo** — `_computeColorForRemaining(remaining)`:

| Condición                                   | Color          |
| ------------------------------------------- | -------------- |
| `remaining ≤ -10` o `remaining ≥ 10`        | `semaphRed`    |
| `-9 ≤ remaining ≤ -3` o `3 ≤ remaining ≤ 9` | `semaphOrange` |
| `-2 ≤ remaining ≤ 2`                        | `semaphBlue`   |

**Cálculo de targets en la vista** (fórmulas exactas):

```dart
final double targetKcal  = settings.kcalTarget.toDouble();
final double targetProt  = settings.weightKg * settings.proteinsPerKg;
final double targetFats  = settings.weightKg * settings.fatsPerKg;
final double targetCarbs = (targetKcal - (targetProt * 4 + targetFats * 9)) / 4;
```

**Detección de nuevo día** (en `initState` via `addPostFrameCallback`):

1. Llama `CheckNewDayOnStartup`. **Solo devuelve no-null si hay items en `items_comida` Y la última fecha es anterior a hoy** (cualquier comida sin items o cualquier fecha = hoy → no muestra dialog).
2. Si devuelve una fecha, muestra `AlertDialog` con tres opciones: Cancelar, Descartar, Exportar.
   - **Descartar**: llama a `MealRepository.clearMealsAndItems()` (vacía completamente ambas tablas) y luego `refresh()`.
   - **Exportar**: llama a `ExportDayToCsv(lastDate)`. Si el path es no vacío (export exitoso), `clearMealsAndItems()` se ejecuta dentro del use case, luego `refresh()` y se muestra `SnackBar`.

#### `SearchView` — `lib/presentation/views/search_view.dart`

Tipo: `ConsumerStatefulWidget`

**Funcionalidades**:

- Campo de texto con búsqueda en tiempo real (via `SearchNotifier`).
- Lista de resultados de `searchResultsProvider`.
- Tap en alimento → `AddFoodPopup`.
- Icono editar en alimento → `FoodFormView` (modo edición).
- Icono eliminar en alimento → confirmación → `FoodRepository.deleteFood`.
- `FloatingActionButton` (+) → `FoodFormView` (modo creación).
- Menú en `AppBar`: "Exportar DB" y "Importar DB".
  - Exportar: usa `FilePicker.saveFile` (con `bytes:`) para guardar el archivo exportado.
  - Importar: usa `file_picker` para seleccionar `.db`, luego `ImportDatabase`.

#### `SettingsView` — `lib/presentation/views/settings_view.dart`

Tipo: `ConsumerStatefulWidget`

**Campos del formulario** (todos con validación):

| Campo               | Tipo                      | Validación                           |
| ------------------- | ------------------------- | ------------------------------------ |
| Peso (kg)           | decimal, requerido        | > 0                                  |
| Altura (cm)         | decimal, requerido        | > 0                                  |
| Edad (años)         | entero, requerido         | > 0                                  |
| % Grasa Corporal    | decimal, **opcional**     | 1–60 si se ingresa                   |
| Sexo                | `SegmentedButton`         | "male" / "female"                    |
| Factor de Actividad | `DropdownButtonFormField` | uno de: 1.2, 1.375, 1.55, 1.725, 1.9 |
| Kcal Objetivo       | entero, requerido         | > 0                                  |
| Proteínas (g/kg)    | decimal, requerido        | > 0                                  |
| Grasas (g/kg)       | decimal, requerido        | > 0                                  |
| Tolerancia (%)      | entero, requerido         | 0–100                                |

> **Nota**: El selector de Sexo se **deshabilita** automáticamente cuando se ingresa un % de grasa corporal válido (porque Katch-McArdle no depende del sexo).

**Cálculo TDEE** (botón "Calcular TDEE"):

- Si `bodyFatPercent` es válido (> 0 y ≤ 60): **Katch-McArdle**
  ```
  lbm = weight * (1 - bodyFat/100)
  TMB = 370 + (21.6 * lbm)
  ```
- Si no: **Mifflin-St Jeor**
  ```
  c   = sex == 'male' ? 5 : -161
  TMB = (10 * weight) + (6.25 * height) - (5 * age) + c
  ```
- En ambos casos: `TDEE = TMB * activityFactor` → se redondea y se escribe en `_kcalController`.

**Toggle de tema** en `AppBar` (switch con icono de sol/luna).

**Card "Requerimientos Calculados"**: actualizada en tiempo real mientras el usuario edita campos (via `onChanged: (_) => setState({})`). Muestra proteínas, grasas y carbohidratos absolutos en gramos.

#### `FoodFormView` — `lib/presentation/views/food_form_view.dart`

Tipo: `ConsumerStatefulWidget`

Modo creación: recibe `food: null`. Modo edición: recibe `food: Food`.

Campos: nombre (texto), kcal/100g, grasas/100g, carbohidratos/100g, proteínas/100g.

Al guardar: `FoodRepository.insertFood` (modo creación) o `FoodRepository.updateFood` (modo edición).

### Widgets

#### `NutrientCard` — `lib/presentation/widgets/nutrient_card.dart`

Widget sin estado. Recibe: `label`, `value` (String), `unit`, `valueColor`.

Renderiza una `Card` con el label arriba, el valor numérico grande en `valueColor`, y la unidad debajo.

#### `AddFoodPopup` — `lib/presentation/widgets/add_food_popup.dart`

`AlertDialog` para agregar un alimento a una comida.

**Lógica interna**:

1. Carga la lista de comidas del día actual (`MealRepository.getMealsByDate`).
2. Muestra dropdown de comidas existentes + opción "Nueva comida" (auto-nombrada `Comida_N+1` donde N es el número de comidas existentes).
3. Campo de texto para cantidad en gramos.
4. Al confirmar:
   - Si seleccionó "Nueva comida": llama `CreateMealIfNotExists` para crearla.
   - Llama `AddFoodToMeal` con el `mealId`, el alimento y la cantidad.
   - Llama `HomeNotifier.refresh()`.

#### `MealItemsDialog` — `lib/presentation/widgets/meal_items_dialog.dart`

`AlertDialog` con lista de `MealItem` de una comida.

- Muestra: nombre del alimento, cantidad (g), kcal, G/C/P.
- Botón editar → dialog para cambiar cantidad → `HomeNotifier.updateMealItemQuantity`.
- Botón eliminar → confirmación → `HomeNotifier.deleteMealItem`.

---

## Estilos y constantes

### `AppStyles` — `lib/core/styles.dart`

```dart
// Colores
static const Color primary      = Color(0xFF6200EE);
static const Color semaphRed    = Color(0xFFD32F2F);
static const Color semaphGreen  = Color(0xFF388E3C);
static const Color semaphOrange = Color(0xFFF57C00);
static const Color semaphBlue   = Color(0xFF1976D2);
static const Color neutral      = Color(0xFF757575);

// Paddings
static const double paddingSmall  = 8.0;
static const double paddingMedium = 16.0;
static const double paddingLarge  = 24.0;

static const double borderRadius  = 8.0;
```

Ambos temas (light y dark) usan `useMaterial3: true` con `seedColor: primary`.

- **Light**: AppBar fondo `primary`, foreground `Colors.white`.
- **Dark**: AppBar fondo `Colors.grey[900]`, foreground `Colors.white`. Cards en `Colors.grey[850]`.

### `AppConstants` — `lib/core/constants.dart`

```dart
static const String appName = 'Calorie Counter';
static const String dbName  = 'db_ctrl_calorias.db';
```

---

## Flujo de navegación

```
MyApp (MaterialApp)
  └── MainShell  ← raíz: NavigationBar + IndexedStack (cada pestaña conserva su estado)
        ├── [0] HomeView      (Calorías)
        ├── [1] RecipesView   (Recetas)  → RecipeDetailView / RecipeFormView / RecipeImportView
        ├── [2] ShoppingListsView (Compras) → ShoppingListDetailView
        └── [3] ProductsView  (Productos) → ProductDetailView / ProductFormView / BarcodeScannerView

HomeView (pestaña Calorías)
        ├── [push] SettingsView
        │           └── [pop] → HomeView.refresh()
        ├── [push] SearchView
        │           ├── [push] FoodFormView (crear)
        │           │           └── [pop] → SearchView
        │           ├── [push] FoodFormView (editar)
        │           │           └── [pop] → SearchView
        │           └── [push] BarcodeScannerView (registrar ingesta escaneando el envase)
        └── [showDialog] AlertDialog (confirmar eliminación, nuevo día, etc.)
```

> Las subpantallas de los módulos se abren con `Navigator.push` sobre la barra inferior. Los selectores reutilizables (`FoodPickerView`, `ProductPickerView`, `BarcodeScannerView.scan`) devuelven su resultado con `Navigator.pop(context, valor)`.

> La navegación usa `Navigator.push` y `MaterialPageRoute` en todos los casos. No hay `go_router` ni ningún paquete de navegación declarativa. Las rutas con nombre no están definidas.

> Después de cada `Navigator.push(...).then((_) => ...)`, se llama a `HomeNotifier.refresh()` o `SearchNotifier.search(query)` para actualizar la UI.

---

## Esquema de la base de datos SQLite

Nombre del archivo: `db_ctrl_calorias.db`  
Ubicación en runtime: `getApplicationDocumentsDirectory()/db_ctrl_calorias.db`  
Versión de esquema: 1

### Tabla `db_alimentos`

```sql
CREATE TABLE IF NOT EXISTS db_alimentos (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  alimento      TEXT NOT NULL UNIQUE,   -- nombre del alimento (clave de unicidad)
  kCal          REAL NOT NULL,          -- kcal por 100g
  grasas        REAL NOT NULL,          -- grasas en g por 100g
  carbohidratos REAL NOT NULL,          -- carbohidratos en g por 100g
  proteinas     REAL NOT NULL,          -- proteínas en g por 100g
  uso_count     INTEGER NOT NULL DEFAULT 0, -- nº de veces agregado a una comida
  ultimo_uso    TEXT                    -- timestamp ISO8601 del último uso (nullable)
);
```

> Las columnas `uso_count` y `ultimo_uso` alimentan la lista **"Usados con frecuencia"** que `SearchView` muestra bajo el buscador cuando está vacío (orden `uso_count DESC, ultimo_uso DESC`). El contador se incrementa en `AddFoodPopup` al agregar un alimento a una comida, por lo que **persiste** aunque `ExportDayToCsv` vacíe `comidas`/`items_comida`. Como la BD precargada de assets no tiene estas columnas, `_createTables` ejecuta una migración idempotente (`PRAGMA table_info` + `ALTER TABLE ADD COLUMN`). `FoodModel` no las serializa, por lo que el formato TSV y export/import `.db` no cambian.

### Tabla `comidas`

```sql
CREATE TABLE IF NOT EXISTS comidas (
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,                -- "Comida_1", "Comida_2", etc.
  fecha  TEXT NOT NULL                 -- ISO8601 fecha solo: "YYYY-MM-DD"
);
```

### Tabla `items_comida`

```sql
CREATE TABLE IF NOT EXISTS items_comida (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  comida_id     INTEGER NOT NULL REFERENCES comidas(id) ON DELETE CASCADE,
  cantidad      REAL NOT NULL,         -- gramos consumidos
  alimento      TEXT NOT NULL,         -- nombre del alimento (copia desnormalizada)
  grasas        REAL NOT NULL,         -- grasas ya escaladas a 'cantidad'
  carbohidratos REAL NOT NULL,         -- carbos ya escalados a 'cantidad'
  proteinas     REAL NOT NULL,         -- proteínas ya escaladas a 'cantidad'
  kCal          REAL NOT NULL          -- kcal ya escaladas a 'cantidad'
);
```

> **IMPORTANTE**: sqflite **no** activa `PRAGMA foreign_keys` (SQLite las trae desactivadas por defecto) y la app no lo hace en `onConfigure`, así que los `REFERENCES ... ON DELETE CASCADE` son solo documentales. Hoy `deleteMeal` deja huérfanos los `items_comida` de esa comida. Los módulos nuevos borran sus hijos explícitamente en una transacción.

### Tablas de recetas, productos y listas de compra

Definidas en `lib/data/datasources/module_tables.dart` (`createModuleTables`, llamado desde `_createTables`; todo `IF NOT EXISTS`). Los `alimento_id` apuntan a `db_alimentos.id` sin FK: si el alimento se borra, el vínculo se trata como "sin vincular".

```sql
CREATE TABLE recetas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL, categoria TEXT, porciones INTEGER, tiempo_min INTEGER,
  elaboracion TEXT NOT NULL DEFAULT '',   -- un paso por línea
  notas TEXT, favorita INTEGER NOT NULL DEFAULT 0,
  alimento_id INTEGER,                    -- vínculo opcional a db_alimentos
  peso_porcion_g REAL,                    -- gramos de una porción (para "Registrar porción")
  creada TEXT NOT NULL, actualizada TEXT NOT NULL
);
CREATE TABLE ingredientes_receta (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  receta_id INTEGER NOT NULL, orden INTEGER NOT NULL,
  texto TEXT NOT NULL                     -- línea tal cual: "200 g de arroz"
);
CREATE TABLE productos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  codigo_barras TEXT UNIQUE,              -- NULL si no tiene (varios NULL permitidos)
  nombre TEXT NOT NULL, marca TEXT, presentacion TEXT,
  alimento_id INTEGER,                    -- vínculo opcional a db_alimentos
  creado TEXT NOT NULL
);
CREATE TABLE compras (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  producto_id INTEGER NOT NULL,
  fecha TEXT NOT NULL,                    -- "YYYY-MM-DD"
  precio REAL NOT NULL,                   -- precio unitario, 2 decimales
  establecimiento TEXT NOT NULL
);
CREATE TABLE listas_compra (
  id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL, creada TEXT NOT NULL
);
CREATE TABLE items_lista_compra (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lista_id INTEGER NOT NULL, texto TEXT NOT NULL, cantidad TEXT,
  producto_id INTEGER,                    -- vínculo opcional: precio de referencia
  comprado INTEGER NOT NULL DEFAULT 0, orden INTEGER NOT NULL
);
-- Índices: ingredientes_receta(receta_id, orden), compras(producto_id, fecha), items_lista_compra(lista_id)
```

---

## Persistencia de configuración (SharedPreferences)

El paquete `shared_preferences` se usa exclusivamente para dos propósitos:

1. **Tema** (clave `isDarkMode`, tipo `bool`).
2. **Configuración del usuario** (10 claves, ver tabla en sección [SettingsRepositoryImpl](#settingsrepositoryimpl)).

No se usa para ningún otro tipo de estado.

---

## Lógica de negocio crítica

### Escalado de macronutrientes

Al agregar un alimento (`AddFoodToMeal`):

```dart
final factor = cantidad / 100.0;
final grasas        = food.grasasPer100  * factor;
final carbos        = food.carbsPer100   * factor;
final proteinas     = food.proteinsPer100 * factor;
final kcal          = food.kcalPer100    * factor;
```

Al editar la cantidad de un `MealItem` (`LocalDataSourceImpl.updateMealItem`):

```dart
final ratio         = newCantidad / oldCantidad;
// Todos los macros se multiplican por ratio
```

### Cálculo de carbohidratos objetivo

Los carbohidratos **no** tienen una meta directa en g/kg. Se calculan como residuo:

```dart
proteinsReq = weightKg * proteinsPerKg;
fatsReq     = weightKg * fatsPerKg;
carbsReq    = (kcalTarget - (proteinsReq * 4 + fatsReq * 9)) / 4;
```

> Coeficientes calóricos: proteínas = 4 kcal/g, grasas = 9 kcal/g, carbohidratos = 4 kcal/g.

### Nomenclatura de comidas

Las nuevas comidas se nombran automáticamente `Comida_N` donde `N` es el número de comidas que ya existen para ese día + 1. El `AddFoodPopup` calcula este valor consultando `getMealsByDate` antes de mostrar el popup.

### Exportación CSV diaria

El CSV diario usa separador **tabulador** (`\t`), generado con `csv.ListToCsvConverter(fieldDelimiter: '\t')`. Cada fila corresponde a un `MealItem`. Header: `nombre_comida\tcantidad\talimento\tgrasas\tcarbos\tproteinas\tkcal`. Se añade una fila final con totales (`Total`). El archivo se guarda con `FilePicker.platform.saveFile` (SAF) y nombre `comidas_<yyyy-MM-dd>.csv`.

> **IMPORTANTE**: Aunque la extensión del archivo es `.csv` (compatibilidad histórica), el delimitador real es **TAB**, no coma. No cambiar a coma sin actualizar también los tests y el comportamiento esperado por el usuario.

### Limpieza tras exportar (`ExportDayToCsv`)

Tras una exportación CSV diaria exitosa (path devuelto no vacío), `ExportDayToCsv` invoca `clearMealsAndItems()`. **Esto afecta a los DOS callsites** de `exportDayToCsvProvider` en la UI:

1. Botón **"Exportar"** del dialog "Nuevo Día Detectado" → exporta + vacía + `refresh()` (idempotente porque la home muestra hoy y hoy estará vacío).
2. Botón **"Exportar Día"** del resumen del día → exporta + vacía + `refresh()` (la home queda visiblemente vacía tras la operación).

Si el usuario cancela el diálogo SAF, el path devuelto es vacío y NO se vacía nada.

### Formato TSV de alimentos

Header (línea 1, exacto):

```
id<TAB>alimento<TAB>kCal<TAB>grasas<TAB>carbohidratos<TAB>proteinas
```

Cada fila contiene los 6 campos separados por TAB. Reglas:

- En exportación: caracteres `\t`, `\n` y `\r` del nombre se reemplazan por espacio.
- En importación: el campo `id` se ignora (autoincrement). `UNIQUE` en `alimento` filtra duplicados con `ConflictAlgorithm.ignore`.
- Encoding UTF-8 sin BOM.
- Nombre de archivo de exportación: `db_alimentos_export_<yyyy-MM-dd_HH-mm-ss>.tsv` (los `:` de la hora se reemplazan por `-` para compatibilidad con Windows).

---

## Módulos: Recetas, Listas de compra y Productos

Los tres módulos son independientes del contador (pestañas propias) pero comparten la BD y se conectan entre sí y con las calorías:

| Conexión | Dónde |
| --- | --- |
| Receta → lista de compra | `RecipeDetailView` → "Añadir lo que me falta a la lista" (`AddIngredientsToShoppingList` separa nombre y cantidad y omite los ya pendientes) |
| Lista ↔ productos | Artículos vinculados a un producto muestran su último precio y suman al **total estimado**; al marcarlos se ofrece "Registrar precio"; el escáner de la lista marca/añade el producto y abre el diálogo de compra |
| Receta ↔ calorías | `recetas.alimento_id` + `peso_porcion_g`: el detalle muestra kcal/macros por 100 g y por porción y "Registrar porción" abre `AddFoodPopup` con esa cantidad |
| Producto ↔ calorías | `productos.alimento_id`: en `SearchView` el botón de escáner busca el producto y abre `AddFoodPopup` con su alimento (ofrece registrar/vincular si falta) |

### Recetas

- **Búsqueda por ingredientes** (`SearchRecipesByIngredients`, Dart puro): el usuario escribe "huevo, patata y cebolla". `ingredient_matcher.dart` normaliza (sin tildes, minúsculas), singulariza de forma consistente (tomates→tomate, limones→limon, nueces→nuez), descarta cantidades/unidades/palabras vacías y unifica sinónimos regionales (papa=patata, palta=aguacate, choclo=elote=maíz...). Un ingrediente coincide si los tokens de uno contienen a los del otro ("pollo" ↔ "pechuga de pollo").
- **Ranking**: primero las recetas completas ("¡Puedes hacerla!"), luego mayor % cubierto, más coincidencias y nombre. Las líneas con "(opcional)" no cuentan como faltantes. Opción para asumir **básicos** (sal, pimienta, agua, aceite) y para mostrar solo las completas. Una receta solo aparece si al menos un ingrediente lo indicó el usuario (los básicos no bastan).
- **Datos**: los ingredientes se guardan como líneas libres (`ingredientes_receta.texto`); el nombre para comparar se calcula al vuelo, así que mejorar el parser no requiere migrar datos.
- **Importación** (`RecipeTextCodec.parse`, por extensión o contenido) con vista previa (`RecipeImportView`) y omisión de duplicados por nombre (`ImportRecipes`):
  - **Texto / plantilla `.txt` o texto pegado** (formato principal, pensado para usuarios no técnicos). Encabezados sin importar mayúsculas ni tildes y con sinónimos: `RECETA/NOMBRE/TÍTULO`, `CATEGORÍA/TIPO`, `PORCIONES/RACIONES/PERSONAS`, `TIEMPO` ("1 h 30 min" = 90), `INGREDIENTES`, `PREPARACIÓN/ELABORACIÓN/PASOS/INSTRUCCIONES`, `NOTAS`. Viñetas y numeración se eliminan sin romper "1.5 kg"; `#` = comentario; recetas separadas por `---` o un nuevo `RECETA:`. Sin encabezados (p. ej. copiado de WhatsApp) la 1ª línea es el nombre y las líneas con viñeta o cantidad se toman como ingredientes.
  - **JSON**: lista, `{"recetas": [...]}` u objeto; claves flexibles; ingredientes/pasos como lista o texto.
  - **CSV**: cabecera obligatoria, delimitador `;`, `,` o TAB autodetectado; ingredientes separados por salto de línea, `|`, `;` o coma (sin partir "1,5").
- **Exportación**: "Exportar todas" guarda un `.txt` en el mismo formato (copia de seguridad reimportable); "Copiar como texto" lleva una receta al portapapeles; "Ver plantilla" permite copiarla o guardarla.

Ejemplo de plantilla:

```
RECETA: Tortilla de patatas
CATEGORÍA: Plato principal
PORCIONES: 4
TIEMPO: 40 min

INGREDIENTES:
- 4 huevos
- 500 g de patatas
- 1 cebolla (opcional)
- Sal

PREPARACIÓN:
1. Pelar y cortar las patatas.
2. Freírlas y cuajar con el huevo batido.
---
```

### Productos y precios

- **Escáner** (`BarcodeScannerView`, paquete `mobile_scanner` con ML Kit empaquetado → funciona sin internet): formatos de comercio EAN-13/8, UPC-A/E, Code128/39, ITF-14; linterna; entrada manual del código; mensaje claro si se niega el permiso de cámara.
- Producto conocido → detalle + diálogo de compra precargado con el último precio y establecimiento. Desconocido → `ProductFormView` con el código (incluye primera compra opcional). También se pueden añadir productos **sin código** (fruta a granel, mercado...).
- **Detalle**: último precio, mínimo/promedio/máximo de los últimos 3 meses (`GetPriceStats`), último precio en cada establecimiento con el más barato destacado, historial (mantener pulsado para borrar).
- **Retención de 3 meses** (`PurgeOldPurchases`): al abrir la app y antes de exportar se borran las compras anteriores a `threeMonthsAgo(hoy)` **salvo la última de cada producto**, que se conserva siempre.
- **Export CSV** (`ExportPriceHistoryCsv`): `historial_precios_YYYY-MM-DD.csv`, separado por **TAB** como el resto de exports, una fila por compra de los últimos 3 meses ordenada por producto y fecha. Cabecera: `fecha\tcodigo_barras\tproducto\tmarca\tpresentacion\testablecimiento\tprecio`.
- Precios: se aceptan coma o punto decimal (`RegisterPurchase.parsePrecio`); se muestran con `AppUtils.formatPrecio` ("1.234,50") sin símbolo de moneda.

### Listas de compra

- Añadir rápido escribiendo ("2 L de leche" → artículo "Leche", cantidad "2 L") o desde el catálogo de productos.
- Pendientes arriba, comprados tachados abajo. Tocar = marcar; mantener pulsado = editar (texto, cantidad, producto vinculado); deslizar a la izquierda = borrar.
- Menú: copiar como texto (para WhatsApp), desmarcar todo, quitar comprados, renombrar, eliminar.

---

## Configuración Android

### `AndroidManifest.xml`

Permisos declarados:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>
```

Lector de códigos de barras (la cámara es opcional: sin ella se escribe el código a mano):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

`mobile_scanner` pide el permiso de cámara en tiempo de ejecución al abrir el escáner y exige `minSdk 23` (Flutter 3.44 usa 24). Con AGP 8.x y `android.builtInKotlin=false` el plugin aplica KGP por sí mismo.

Flag de almacenamiento legacy (para compatibilidad):

```xml
android:requestLegacyExternalStorage="true"
```

La actividad principal soporta `processText` para integración con selección de texto del sistema.

### Permisos en runtime

El paquete `permission_handler` gestiona los permisos de almacenamiento en tiempo de ejecución, necesarios para exportar/importar la base de datos en Android < 13.

---

## Dependencias

### Runtime

| Paquete              | Versión   | Uso                                   |
| -------------------- | --------- | ------------------------------------- |
| `flutter_riverpod`   | `^2.6.1`  | State management global               |
| `sqflite`            | `^2.4.1`  | Base de datos SQLite local            |
| `path_provider`      | `^2.1.5`  | Directorios del dispositivo           |
| `path`               | `^1.9.0`  | Manipulación de rutas de archivo      |
| `csv`                | `^6.0.0`  | Generación de CSV (exportación)       |
| `intl`               | `^0.19.0` | Formato de fechas en español          |
| `equatable`          | `^2.0.7`  | Comparación de entidades de dominio   |
| `shared_preferences` | `^2.3.5`  | Persistencia de settings y tema       |
| `permission_handler` | `^11.3.1` | Permisos de almacenamiento en Android |
| `file_picker`        | `^11.0.2` | Selección y guardado de archivos      |
| `mobile_scanner`     | `^7.5.0`  | Lector de códigos de barras (cámara, ML Kit empaquetado) |
| `cupertino_icons`    | `^1.0.8`  | Iconos iOS (incluidos por defecto)    |

### Dev

| Paquete                     | Versión  | Uso                                                                                                     |
| --------------------------- | -------- | ------------------------------------------------------------------------------------------------------- |
| `flutter_lints`             | `^5.0.0` | Reglas de análisis estático                                                                             |
| `sqflite_common_ffi`        | `^2.3.6` | SQLite en tests de escritorio                                                                           |
| `plugin_platform_interface` | `^2.1.8` | Necesario para mockear `FilePicker.platform` en `csv_export_test.dart` vía `MockPlatformInterfaceMixin` |

---

## Cómo ejecutar el proyecto

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en dispositivo/emulador Android
flutter run

# Compilar APK release
flutter build apk --release

# Compilar APK debug
flutter build apk --debug
```

> El archivo de base de datos de assets (`assets/db/db_ctrl_calorias.db`) debe estar presente y declarado en `pubspec.yaml` para que el build funcione.

---

## Convenciones y reglas que NO deben romperse

Estas son las reglas de diseño que si se violan romperán la aplicación o su coherencia:

1. **Macros en `MealItem` son valores absolutos** (no por 100g). Si se agrega un campo nuevo a `items_comida` debe seguir la misma convención.

2. **La columna `alimento` en `db_alimentos` es UNIQUE**. La importación usa `ConflictAlgorithm.ignore` para no duplicar. No cambiar esto a `replace` sin analizar el impacto en los `MealItem` existentes (que guardan el nombre desnormalizado).

3. **`items_comida` NO almacena `food_id`** (FK al alimento original). El alimento se guarda desnormalizado como texto. Esta es una decisión de diseño deliberada para evitar problemas si el alimento se edita o elimina después.

4. **Las fechas en la tabla `comidas`** se almacenan como `String` en formato `YYYY-MM-DD` (solo la parte de fecha de `DateTime.toIso8601String().split('T')[0]`). Nunca almacenar timestamps completos.

5. **`localDataSourceProvider` es el único punto de creación de `LocalDataSourceImpl`**. Es un `Provider` (no `StateNotifierProvider`), lo que garantiza que Riverpod reutilice la misma instancia. No crear instancias adicionales de `LocalDataSourceImpl` directamente.

6. **El estado del tema** se gestiona exclusivamente a través de `themeProvider`. No llamar `Theme.of(context)` para cambiar el tema global; solo para leerlo.

7. **`HomeNotifier.refresh()`** debe llamarse después de cualquier operación de escritura en la DB que afecte las comidas del día (agregar item, eliminar item, eliminar comida). Esto es lo que hace que la pantalla principal se actualice.

8. **`SearchNotifier.search(query)` con query vacía limpia inmediatamente** el estado (sin debounce). No cambiar este comportamiento sin actualizar la UI de `SearchView` correspondientemente.

9. **Los campos de `UserSettings`** se serializan uno a uno en `SharedPreferences`. Si se añaden nuevos campos a `UserSettings`, deben añadirse las claves correspondientes en `SettingsRepositoryImpl` tanto en `getSettings()` (con valor por defecto) como en `saveSettings()`.

10. **Los temas usan `AppStyles.lightTheme` y `AppStyles.darkTheme`** definidos en `lib/core/styles.dart`. Toda modificación visual de la app debe pasar por allí o usar el `Theme.of(context)` para respetar el sistema de temas.

11. **La navegación es imperativa** (`Navigator.push`/`pop`). No introducir navegación declarativa (go_router, auto_route, etc.) sin migrar todo el sistema de navegación.

12. **El idioma de la interfaz es español**. Todos los textos visibles al usuario, nombres de campos en la DB, claves de SharedPreferences y comentarios relevantes están en español. No mezclar idiomas en la UI.

13. **`ExportDayToCsv` tiene un efecto secundario crítico**: tras una exportación exitosa, vacía `comidas` e `items_comida`. Si se necesitase un export "limpio" sin vaciar, debe crearse un use case separado, no modificar este. Cualquier callsite de `exportDayToCsvProvider` debe llamar a `homeProvider.notifier.refresh()` después de un éxito.

14. **`CheckNewDayOnStartup` requiere AMBAS condiciones**: (a) `hasMealItems()` debe ser `true` y (b) la última fecha en `comidas` debe ser anterior a hoy. Una comida vacía o un día actual con datos no dispara el dialog. No relajar esta condición sin replantear el flujo.

15. **El TSV de `db_alimentos` usa header fijo**: `id\talimento\tkCal\tgrasas\tcarbohidratos\tproteinas`. La importación lo valida exactamente. Cambiar nombres de columnas o añadir/quitar campos rompe los archivos exportados previamente. Si se debe migrar el formato, mantener compatibilidad detectando el header.

16. **SAF en Android 13+**: la app evita `READ_EXTERNAL_STORAGE`/`WRITE_EXTERNAL_STORAGE` en versiones modernas usando `FilePicker.saveFile(bytes:)` y `FilePicker.pickFiles(withData: true)`. No reintroducir manejo manual de paths absolutos ni añadir permisos al manifest sin justificación clara.

17. **Raíz = `MainShell`** (barra inferior). `HomeView` es la primera pestaña y sigue llamando a `HomeNotifier.refresh()` tras sus escrituras; desde recetas/productos se registra comida con `AddFoodPopup.showForToday`, que ya refresca `homeProvider`.

18. **Foreign keys desactivadas**: al borrar recetas, productos o listas, borrar explícitamente los hijos en la misma transacción (ver data sources). No depender de `ON DELETE CASCADE`.

19. **Historial de compras = 3 meses + la última compra de cada producto**. `PurgeOldPurchases` se ejecuta al cargar `ProductsNotifier` y antes de exportar. No borrar nunca la última compra de un producto: es su "último precio".

20. **Ingredientes de recetas como texto libre**: el nombre comparable se deriva con `ingredient_matcher.dart`; no guardar columnas derivadas. Cambios en la normalización deben aplicarse por igual a recetas y búsqueda (son simétricos) y cubrirse en `test/unit/ingredient_matcher_test.dart`.

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
