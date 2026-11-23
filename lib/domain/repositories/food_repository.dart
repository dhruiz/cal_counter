import '../entities/food.dart';

/// Filtros del repertorio.
enum FoodFilter {
  todos('Todos'),
  pendientes('Pendientes'),
  envasados('Envasados'),
  genericos('Genéricos'),
  preparados('Preparados'),
  archivados('Archivados');

  final String etiqueta;

  const FoodFilter(this.etiqueta);
}

/// Resultado de borrar un alimento.
enum FoodDeletion {
  /// Se borró de verdad (no tenía historial).
  borrado,

  /// Tenía compras: se archivó para no romper el historial.
  archivado,
}

/// Repertorio de alimentos: el núcleo de la app.
abstract class FoodRepository {
  /// Búsqueda por texto (sin tildes, por prefijo de palabra) o por código de
  /// barras si lo escrito lo parece. Con [query] vacío lista todo según
  /// [filter]. Los archivados solo aparecen con [FoodFilter.archivados].
  Stream<List<Food>> watchSearch(
    String query, {
    FoodFilter filter = FoodFilter.todos,
    int limit = 200,
  });

  Future<List<Food>> search(
    String query, {
    FoodFilter filter = FoodFilter.todos,
    int limit = 200,
  });

  Future<Food?> getFood(int id);
  Stream<Food?> watchFood(int id);
  Future<Map<int, Food>> getFoodsByIds(Iterable<int> ids);

  /// Alimentos (por id) con sus porciones; emite de nuevo si cambian (p. ej.
  /// al completar la tabla de un ingrediente con la receta abierta).
  Stream<FoodsWithPortions> watchFoodsWithPortions(Set<int> ids);
  Future<List<Food>> getAllFoods({bool incluirArchivados = false});

  /// Alimento y presentación de un código de barras (se normaliza).
  Future<BarcodeMatch?> findByBarcode(String codigo);

  /// Alimento por su identificador global (repertorios compartidos).
  Future<Food?> findByUuid(String uuid);

  /// Alimento con exactamente ese nombre y marca, sin distinguir tildes ni
  /// mayúsculas (incluye archivados).
  Future<Food?> findByNameAndBrand(String nombre, String marca);

  /// Alimentos con nombre parecido (sin tildes ni mayúsculas) para avisar de
  /// posibles duplicados antes de crear uno nuevo.
  Future<List<Food>> findSimilar(String nombre, {String marca = ''});

  /// Inserta (id null) o actualiza. Lanza [DuplicateFoodException] si ya
  /// existe otro con el mismo nombre y marca. Devuelve el id.
  Future<int> saveFood(Food food);

  /// Borra si no tiene compras; si las tiene, lo archiva.
  Future<FoodDeletion> deleteFood(int id);
  Future<void> setArchived(int id, bool archivado);

  Future<void> incrementUsage(int id);
  Future<void> resetUsage(int id);

  /// Fija el contador de uso (migración desde versiones anteriores).
  Future<void> setUsage(int id, int count, DateTime? ultimoUso);
  Stream<List<Food>> watchMostUsed({int limit = 20});

  /// Pendientes de completar, por prioridad: usados en recetas, comprados
  /// recientemente y el resto.
  Stream<List<Food>> watchPending();
  Stream<int> watchPendingCount();

  // Porciones ---------------------------------------------------------------
  Stream<List<FoodPortion>> watchPortions(int alimentoId);
  Future<Map<int, List<FoodPortion>>> getPortionsFor(Iterable<int> ids);
  Future<int> savePortion(FoodPortion portion);
  Future<void> deletePortion(int id);

  // Presentaciones ----------------------------------------------------------
  Stream<List<FoodPackage>> watchPackages(int alimentoId);
  Future<List<FoodPackage>> getPackages(int alimentoId);
  Future<Map<int, List<FoodPackage>>> getPackagesFor(Iterable<int> ids);
  Future<FoodPackage?> getPackage(int id);

  /// Inserta o actualiza. Lanza [DuplicateBarcodeException] si el código ya
  /// es de otra presentación. Devuelve el id.
  Future<int> savePackage(FoodPackage package);

  /// Borra si no tiene compras; si las tiene, la archiva.
  Future<void> deletePackage(int id);

  /// Presentación sin código ("Sin presentación") del alimento, creada si no
  /// existe. Se usa para registrar compras de algo sin presentación elegida.
  Future<int> defaultPackageId(int alimentoId);
}

/// Alimentos y porciones por id de alimento.
class FoodsWithPortions {
  final Map<int, Food> alimentos;
  final Map<int, List<FoodPortion>> porciones;

  const FoodsWithPortions(this.alimentos, this.porciones);

  static const vacio = FoodsWithPortions({}, {});
}
