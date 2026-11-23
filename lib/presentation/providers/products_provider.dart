import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/product_local_data_source.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/price_stats.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/usecases/export_price_history_csv.dart';
import '../../domain/usecases/get_price_stats.dart';
import '../../domain/usecases/purge_old_purchases.dart';
import '../../domain/usecases/register_purchase.dart';
import 'home_provider.dart'; // localDataSourceProvider
import 'shopping_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    ProductLocalDataSourceImpl(ref.watch(localDataSourceProvider)),
  );
});

final registerPurchaseProvider = Provider<RegisterPurchase>((ref) {
  return RegisterPurchase(ref.watch(productRepositoryProvider));
});

final getPriceStatsProvider = Provider<GetPriceStats>((ref) => GetPriceStats());

final purgeOldPurchasesProvider = Provider<PurgeOldPurchases>((ref) {
  return PurgeOldPurchases(ref.watch(productRepositoryProvider));
});

final exportPriceHistoryCsvProvider = Provider<ExportPriceHistoryCsv>((ref) {
  return ExportPriceHistoryCsv(ref.watch(productRepositoryProvider));
});

class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String query;

  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.query = '',
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? query,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final Ref _ref;
  ProductRepository get _repo => _ref.read(productRepositoryProvider);

  ProductsNotifier(this._ref) : super(const ProductsState()) {
    _init();
  }

  /// Al abrir la app se purga el historial de más de 3 meses (conservando
  /// la última compra de cada producto) y se cargan los productos.
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _ref.read(purgeOldPurchasesProvider)();
    await load();
  }

  Future<void> load() async {
    final products = await _repo.getProducts();
    if (!mounted) return;
    state = state.copyWith(products: products, isLoading: false);
  }

  void setQuery(String q) => state = state.copyWith(query: q);

  /// Recarga todo lo que muestra precios: listado, detalles, tiendas y
  /// precios de referencia de las listas de compra.
  Future<void> _refreshAll() async {
    _ref.invalidate(productDetailProvider);
    _ref.invalidate(storesProvider);
    _ref.invalidate(shoppingItemsProvider);
    await load();
  }

  Future<int> saveProduct(Product product) async {
    final id = await _repo.saveProduct(product);
    await _refreshAll();
    return id;
  }

  Future<void> deleteProduct(int id) async {
    await _repo.deleteProduct(id);
    await _refreshAll();
  }

  Future<void> registerPurchase({
    required int productoId,
    required double precio,
    required String establecimiento,
    DateTime? fecha,
  }) async {
    await _ref.read(registerPurchaseProvider)(
      productoId: productoId,
      precio: precio,
      establecimiento: establecimiento,
      fecha: fecha,
    );
    await _refreshAll();
  }

  Future<void> deletePurchase(int id) async {
    await _repo.deletePurchase(id);
    await _refreshAll();
  }

  /// Purga y genera el historial de 3 meses (texto TAB).
  Future<String> exportHistory() async {
    await _ref.read(purgeOldPurchasesProvider)();
    final tsv = await _ref.read(exportPriceHistoryCsvProvider)();
    await _refreshAll();
    return tsv;
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>(
  (ref) => ProductsNotifier(ref),
);

/// Productos filtrados por nombre, marca o código de barras.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final s = ref.watch(productsProvider);
  final q = normalizeText(s.query);
  if (q.isEmpty) return s.products;
  return s.products.where((p) {
    return normalizeText(p.nombre).contains(q) ||
        normalizeText(p.marca ?? '').contains(q) ||
        (p.codigoBarras ?? '').contains(s.query.trim());
  }).toList();
});

/// Establecimientos usados (para autocompletar), del más reciente.
final storesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(productRepositoryProvider).getStores();
});

class ProductDetail {
  final Product? product;
  final List<Purchase> compras;
  final PriceStats stats;

  const ProductDetail({
    required this.product,
    required this.compras,
    required this.stats,
  });
}

final productDetailProvider = FutureProvider.autoDispose
    .family<ProductDetail, int>((ref, id) async {
      final repo = ref.watch(productRepositoryProvider);
      final product = await repo.getProduct(id);
      final compras = product == null
          ? <Purchase>[]
          : await repo.getPurchases(id);
      return ProductDetail(
        product: product,
        compras: compras,
        stats: ref.read(getPriceStatsProvider)(compras),
      );
    });
