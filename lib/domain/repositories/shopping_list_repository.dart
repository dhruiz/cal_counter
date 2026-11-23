import '../entities/shopping_list.dart';

abstract class ShoppingListRepository {
  /// Listas con contadores, de la más reciente a la más antigua.
  Future<List<ShoppingList>> getLists();
  Future<int> createList(String nombre);
  Future<void> renameList(int id, String nombre);

  /// Borra la lista y todos sus artículos.
  Future<void> deleteList(int id);

  /// Artículos de la lista (pendientes primero, luego por orden de alta),
  /// con el precio de referencia de su producto si está vinculado.
  Future<List<ShoppingItem>> getItems(int listaId);

  /// Añade al final de la lista. Devuelve el id.
  Future<int> addItem(ShoppingItem item);

  /// Actualiza texto, cantidad, producto y estado comprado.
  Future<void> updateItem(ShoppingItem item);
  Future<void> setItemBought(int itemId, bool comprado);
  Future<void> deleteItem(int itemId);
  Future<void> deleteBoughtItems(int listaId);
  Future<void> setAllBought(int listaId, bool comprado);
}
