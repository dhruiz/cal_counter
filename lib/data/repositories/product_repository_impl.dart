import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource dataSource;

  ProductRepositoryImpl(this.dataSource);

  @override
  Future<List<Product>> getProducts() => dataSource.getProducts();

  @override
  Future<Product?> getProduct(int id) => dataSource.getProduct(id);

  @override
  Future<Product?> getProductByBarcode(String codigoBarras) =>
      dataSource.getProductByBarcode(codigoBarras);

  @override
  Future<int> saveProduct(Product product) => dataSource.saveProduct(product);

  @override
  Future<void> deleteProduct(int id) => dataSource.deleteProduct(id);

  @override
  Future<List<Purchase>> getPurchases(int productoId) =>
      dataSource.getPurchases(productoId);

  @override
  Future<int> addPurchase(Purchase purchase) =>
      dataSource.addPurchase(purchase);

  @override
  Future<void> updatePurchase(Purchase purchase) =>
      dataSource.updatePurchase(purchase);

  @override
  Future<void> deletePurchase(int id) => dataSource.deletePurchase(id);

  @override
  Future<List<String>> getStores() => dataSource.getStores();

  @override
  Future<int> purgePurchasesBefore(DateTime fecha) =>
      dataSource.purgePurchasesBefore(fecha);

  @override
  Future<List<({Product producto, Purchase compra})>> getPurchaseHistorySince(
    DateTime fecha,
  ) => dataSource.getPurchaseHistorySince(fecha);
}
