import '../entities/product.dart';
import '../entities/shopping_list.dart';
import 'ingredient_matcher.dart';

/// Artículo de la lista al que corresponde un producto escaneado en el modo
/// carrito, por orden de preferencia:
///
/// 1. Ya está en el carrito (comprado) con ese producto → se suman unidades.
/// 2. Pendiente vinculado a ese producto.
/// 3. Pendiente **sin vincular** cuyo texto coincide por tokens con el nombre
///    del producto ("Leche" ↔ "Leche entera"), con la misma normalización que
///    las recetas (tildes, plurales, sinónimos).
///
/// Devuelve null si el producto no está en la lista.
ShoppingItem? findItemForProduct(List<ShoppingItem> items, Product product) {
  for (final i in items) {
    if (i.comprado && i.productoId != null && i.productoId == product.id) {
      return i;
    }
  }
  for (final i in items) {
    if (!i.comprado && i.productoId != null && i.productoId == product.id) {
      return i;
    }
  }
  final productTokens = keyTokens(product.nombre);
  for (final i in items) {
    if (!i.comprado &&
        i.productoId == null &&
        tokensMatch(keyTokens(i.texto), productTokens)) {
      return i;
    }
  }
  return null;
}
