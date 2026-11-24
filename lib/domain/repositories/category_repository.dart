import '../entities/category.dart';

/// Categorías (secciones del súper) y orden de los pasillos.
abstract class CategoryRepository {
  /// Categorías en el orden de los pasillos de [tienda] (nombre del
  /// establecimiento) si tiene uno propio; si no, en el orden general.
  Stream<List<Category>> watchCategories({String? tienda});
  Future<List<Category>> getCategories({String? tienda});

  /// Inserta o renombra. Lanza `ValidationException` si el nombre ya existe.
  Future<int> saveCategory(Category categoria);

  /// Borra la categoría (sus alimentos quedan sin categoría).
  Future<void> deleteCategory(int id);

  /// Guarda el orden de los pasillos: el general, o el de [tienda].
  Future<void> reorder(List<int> idsEnOrden, {String? tienda});

  /// La tienda vuelve a usar el orden general.
  Future<void> resetStoreOrder(String tienda);

  /// ¿Tiene [tienda] un orden de pasillos propio?
  Stream<bool> watchHasStoreOrder(String tienda);

  /// Asigna la categoría a varios alimentos de una vez.
  Future<void> assignCategory(Iterable<int> alimentoIds, int? categoriaId);

  /// Categoría que sugiere un nombre (si existe), para formularios.
  Future<Category?> suggestFor(String nombre);
}
