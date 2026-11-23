import '../entities/shopping_list.dart';
import '../repositories/product_repository.dart';
import '../repositories/shopping_list_repository.dart';

/// Saca un artículo del carrito (lo metiste por error o lo devolviste al
/// estante): borra la compra que se registró desde él y lo deja pendiente.
///
/// Distinto de desmarcar (`setItemBought(false)`), que conserva la compra en
/// el historial.
class RemoveFromCart {
  final ShoppingListRepository shopping;
  final ProductRepository products;

  RemoveFromCart(this.shopping, this.products);

  Future<void> call(ShoppingItem item) async {
    if (item.compraId != null) {
      await products.deletePurchase(item.compraId!);
    }
    if (item.id != null) {
      await shopping.setItemBought(item.id!, false);
    }
  }
}
