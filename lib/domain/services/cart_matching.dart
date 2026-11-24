import '../entities/food.dart';
import '../entities/shopping_list.dart';
import 'ingredient_matcher.dart';

/// Artículo de la lista al que corresponde un alimento escaneado en el modo
/// carrito, por orden de preferencia:
///
/// 1. Ya está en el carrito (comprado) con ese alimento → se suman unidades.
/// 2. Pendiente vinculado a ese alimento.
/// 3. Pendiente **sin vincular** cuyo texto coincide por tokens con el nombre
///    del alimento ("Leche" ↔ "Leche entera"), con la misma normalización que
///    las recetas (tildes, plurales, sinónimos).
///
/// Devuelve null si el alimento no está en la lista.
ShoppingItem? findItemForFood(List<ShoppingItem> items, Food food) {
  for (final i in items) {
    if (i.comprado && i.alimentoId != null && i.alimentoId == food.id) {
      return i;
    }
  }
  for (final i in items) {
    if (!i.comprado && i.alimentoId != null && i.alimentoId == food.id) {
      return i;
    }
  }
  final foodTokens = keyTokens(food.nombre);
  for (final i in items) {
    if (!i.comprado &&
        i.alimentoId == null &&
        tokensMatch(keyTokens(i.texto), foodTokens)) {
      return i;
    }
  }
  return null;
}
