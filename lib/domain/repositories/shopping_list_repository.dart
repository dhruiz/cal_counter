import '../entities/shopping_list.dart';

abstract class ShoppingListRepository {
  /// Listas con contadores, de la más reciente a la más antigua.
  Stream<List<ShoppingList>> watchLists();
  Future<int> createList(String nombre);
  Future<void> renameList(int id, String nombre);

  /// Borra la lista y sus artículos (las compras del historial se conservan).
  Future<void> deleteList(int id);

  /// Artículos (pendientes primero, luego por orden de alta) con los datos de
  /// su compra en el carrito y el precio de referencia de su alimento.
  Stream<List<ShoppingItem>> watchItems(int listaId);
  Future<List<ShoppingItem>> getItems(int listaId);

  /// Añade al final de la lista. Devuelve el id.
  Future<int> addItem(ShoppingItem item);

  /// Actualiza texto, cantidad, alimento, comprado y compra enlazada.
  Future<void> updateItem(ShoppingItem item);

  /// Marca o desmarca. Desmarcar saca el artículo del carrito (quita el
  /// vínculo a la compra) sin borrar la compra del historial.
  Future<void> setItemBought(int itemId, bool comprado);
  Future<void> deleteItem(int itemId);
  Future<void> deleteBoughtItems(int listaId);

  /// Como [setItemBought] para toda la lista.
  Future<void> setAllBought(int listaId, bool comprado);
}
