import '../entities/category.dart';
import '../entities/food.dart';
import '../entities/purchase.dart';

/// Compras (historial de precios) y establecimientos.
abstract class PurchaseRepository {
  /// Nombres de establecimientos, del usado más recientemente al más antiguo.
  Future<List<String>> getStoreNames();
  Stream<List<String>> watchStoreNames();

  Future<Purchase?> getPurchase(int id);

  /// Inserta la compra (crea el establecimiento si no existe). Devuelve id.
  Future<int> addPurchase(Purchase compra);
  Future<void> updatePurchase(Purchase compra);
  Future<void> deletePurchase(int id);

  /// Compras de todas las presentaciones de un alimento, recientes primero.
  Stream<List<PurchaseRecord>> watchPurchasesForFood(int alimentoId);
  Future<List<PurchaseRecord>> getPurchasesForFood(int alimentoId);

  /// Última compra del alimento (en [establecimiento] si se indica y existe).
  Future<PurchaseRecord?> lastPurchaseForFood(
    int alimentoId, {
    String? establecimiento,
  });

  /// Alimentos con compras y su última compra, por fecha descendente.
  Stream<List<PurchaseRecord>> watchLastPurchasePerFood();

  /// Borra compras anteriores a [fecha] salvo la última de cada
  /// presentación. Devuelve cuántas se borraron.
  Future<int> purgeBefore(DateTime fecha);

  /// Compras desde [fecha] (incluida), por alimento y fecha.
  Future<List<PurchaseRecord>> historySince(DateTime fecha);

  /// Gasto por categoría desde [desde] (incluida), de mayor a menor.
  Future<List<CategorySpending>> spendingByCategory(DateTime desde);
}

/// Atajo para mostrar presentaciones con su última compra.
class PackageWithLastPurchase {
  final FoodPackage presentacion;
  final Purchase? ultima;

  const PackageWithLastPurchase(this.presentacion, this.ultima);
}
