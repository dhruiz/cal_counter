import '../entities/product.dart';

abstract class ProductRepository {
  /// Productos con su última compra, ordenados por nombre.
  Future<List<Product>> getProducts();
  Future<Product?> getProduct(int id);
  Future<Product?> getProductByBarcode(String codigoBarras);

  /// Inserta (id null) o actualiza. Lanza si el código de barras ya existe.
  Future<int> saveProduct(Product product);

  /// Borra el producto, sus compras y desvincula los artículos de listas.
  Future<void> deleteProduct(int id);

  /// Compras de un producto, de la más reciente a la más antigua.
  Future<List<Purchase>> getPurchases(int productoId);
  Future<int> addPurchase(Purchase purchase);
  Future<void> deletePurchase(int id);

  /// Establecimientos usados, del más reciente al más antiguo.
  Future<List<String>> getStores();

  /// Borra compras anteriores a [fecha] salvo la última de cada producto.
  /// Devuelve cuántas se borraron.
  Future<int> purgePurchasesBefore(DateTime fecha);

  /// Compras desde [fecha] (incluida) con su producto, por producto y fecha.
  Future<List<({Product producto, Purchase compra})>> getPurchaseHistorySince(
    DateTime fecha,
  );
}
