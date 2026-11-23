import '../entities/product.dart';
import '../entities/shopping_list.dart';
import '../repositories/product_repository.dart';
import '../repositories/shopping_list_repository.dart';
import '../services/cart_matching.dart';
import '../services/dates.dart';
import 'register_purchase.dart';

/// Modo carrito: mete un producto escaneado en el carrito de una lista.
///
/// - Si ya estaba en el carrito, suma [unidades] (sin nueva fila en
///   `compras`; si el precio cambió, corrige la compra ya registrada).
/// - Si no, registra la compra en el historial (precio unitario, tienda, hoy)
///   y marca como comprado el artículo correspondiente
///   ([findItemForProduct]), vinculándolo al producto; si no estaba en la
///   lista, lo añade ya comprado. La UI pregunta antes de ese último caso.
///
/// Devuelve el artículo resultante.
class AddProductToCart {
  final ShoppingListRepository shopping;
  final ProductRepository products;

  AddProductToCart(this.shopping, this.products);

  Future<ShoppingItem> call({
    required int listaId,
    required Product producto,
    required double precio,
    required String establecimiento,
    int unidades = 1,
    DateTime? fecha,
  }) async {
    RegisterPurchase.validarPrecio(precio);
    if (unidades < 1) throw ArgumentError('Las unidades deben ser al menos 1.');
    final store = RegisterPurchase.normalizarEstablecimiento(establecimiento);
    final precioR = RegisterPurchase.redondear(precio);
    final dia = dateOnly(fecha ?? DateTime.now());
    final productoId = producto.id!;

    Purchase compra({int? id}) => Purchase(
      id: id,
      productoId: productoId,
      fecha: dia,
      precio: precioR,
      establecimiento: store,
    );

    final items = await shopping.getItems(listaId);
    final target = findItemForProduct(items, producto);

    // 1. Ya en el carrito: más unidades. Si solo estaba marcado a mano (sin
    // precio ni compra) aún no contaba en el carrito: se fijan las unidades.
    if (target != null && target.comprado) {
      final enCarrito = target.precioPagado != null || target.compraId != null;
      var compraId = target.compraId;
      if (compraId == null) {
        compraId = await products.addPurchase(compra());
      } else if (target.precioPagado != precioR) {
        await products.updatePurchase(compra(id: compraId));
      }
      final updated = target.copyWith(
        unidades: enCarrito ? target.unidades + unidades : unidades,
        precioPagado: precioR,
        compraId: compraId,
      );
      await shopping.updateItem(updated);
      return updated;
    }

    final compraId = await products.addPurchase(compra());

    // 2. Estaba en la lista: se marca y se vincula al producto.
    if (target != null) {
      final updated = target.copyWith(
        productoId: productoId,
        comprado: true,
        unidades: unidades,
        precioPagado: precioR,
        compraId: compraId,
      );
      await shopping.updateItem(updated);
      return updated;
    }

    // 3. No estaba: se añade ya comprado.
    final nuevo = ShoppingItem(
      listaId: listaId,
      texto: producto.nombre,
      productoId: productoId,
      comprado: true,
      unidades: unidades,
      precioPagado: precioR,
      compraId: compraId,
    );
    final id = await shopping.addItem(nuevo);
    return nuevo.copyWith(id: id);
  }
}
