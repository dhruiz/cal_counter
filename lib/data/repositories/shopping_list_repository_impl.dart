import '../../domain/entities/shopping_list.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import '../datasources/shopping_local_data_source.dart';

class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final ShoppingLocalDataSource dataSource;

  ShoppingListRepositoryImpl(this.dataSource);

  @override
  Future<List<ShoppingList>> getLists() => dataSource.getLists();

  @override
  Future<int> createList(String nombre) => dataSource.createList(nombre);

  @override
  Future<void> renameList(int id, String nombre) =>
      dataSource.renameList(id, nombre);

  @override
  Future<void> deleteList(int id) => dataSource.deleteList(id);

  @override
  Future<List<ShoppingItem>> getItems(int listaId) =>
      dataSource.getItems(listaId);

  @override
  Future<int> addItem(ShoppingItem item) => dataSource.addItem(item);

  @override
  Future<void> updateItem(ShoppingItem item) => dataSource.updateItem(item);

  @override
  Future<void> setItemBought(int itemId, bool comprado) =>
      dataSource.setItemBought(itemId, comprado);

  @override
  Future<void> deleteItem(int itemId) => dataSource.deleteItem(itemId);

  @override
  Future<void> deleteBoughtItems(int listaId) =>
      dataSource.deleteBoughtItems(listaId);

  @override
  Future<void> setAllBought(int listaId, bool comprado) =>
      dataSource.setAllBought(listaId, comprado);
}
