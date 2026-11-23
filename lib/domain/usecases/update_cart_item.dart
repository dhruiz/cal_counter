import '../entities/product.dart';
import '../entities/shopping_list.dart';
import '../repositories/product_repository.dart';
import '../repositories/shopping_list_repository.dart';
import 'register_purchase.dart';

/// Fija precio y unidades de un artículo del carrito y lo marca comprado.
///
/// Si el artículo tiene una compra registrada ([ShoppingItem.compraId]) y el
/// precio cambia, corrige esa fila de `compras` (conserva su fecha y tienda).
/// Para artículos sin producto vinculado el precio solo cuenta para el total
/// del carrito (no hay producto al que asociar historial).
class UpdateCartItem {
  final ShoppingListRepository shopping;
  final ProductRepository products;

  UpdateCartItem(this.shopping, this.products);

  Future<ShoppingItem> call({
    required ShoppingItem item,
    required double precio,
    required int unidades,
  }) async {
    RegisterPurchase.validarPrecio(precio);
    if (unidades < 1) throw ArgumentError('Las unidades deben ser al menos 1.');
    final precioR = RegisterPurchase.redondear(precio);

    final compraId = item.compraId;
    final productoId = item.productoId;
    if (compraId != null &&
        productoId != null &&
        item.precioPagado != precioR) {
      final compras = await products.getPurchases(productoId);
      for (final c in compras) {
        if (c.id == compraId) {
          await products.updatePurchase(
            Purchase(
              id: c.id,
              productoId: c.productoId,
              fecha: c.fecha,
              precio: precioR,
              establecimiento: c.establecimiento,
            ),
          );
          break;
        }
      }
    }

    final updated = item.copyWith(
      comprado: true,
      unidades: unidades,
      precioPagado: precioR,
    );
    await shopping.updateItem(updated);
    return updated;
  }
}
