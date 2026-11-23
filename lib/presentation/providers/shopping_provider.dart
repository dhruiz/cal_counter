import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/shopping_local_data_source.dart';
import '../../data/repositories/shopping_list_repository_impl.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import '../../domain/usecases/add_ingredients_to_shopping_list.dart';
import 'home_provider.dart'; // localDataSourceProvider

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepositoryImpl(
    ShoppingLocalDataSourceImpl(ref.watch(localDataSourceProvider)),
  );
});

final addIngredientsToShoppingListProvider =
    Provider<AddIngredientsToShoppingList>((ref) {
      return AddIngredientsToShoppingList(
        ref.watch(shoppingListRepositoryProvider),
      );
    });

class ShoppingListsState {
  final List<ShoppingList> lists;
  final bool isLoading;

  const ShoppingListsState({this.lists = const [], this.isLoading = false});
}

class ShoppingListsNotifier extends StateNotifier<ShoppingListsState> {
  final Ref _ref;
  ShoppingListRepository get _repo => _ref.read(shoppingListRepositoryProvider);

  ShoppingListsNotifier(this._ref)
    : super(const ShoppingListsState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    final lists = await _repo.getLists();
    if (!mounted) return;
    state = ShoppingListsState(lists: lists);
  }

  Future<int> create(String nombre) async {
    final id = await _repo.createList(nombre);
    await load();
    return id;
  }

  Future<void> rename(int id, String nombre) async {
    await _repo.renameList(id, nombre);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.deleteList(id);
    await load();
  }

  /// Añade ingredientes de una receta. Devuelve cuántos se añadieron.
  Future<int> addIngredients(int listaId, List<String> lineas) async {
    final n = await _ref.read(addIngredientsToShoppingListProvider)(
      listaId: listaId,
      lineas: lineas,
    );
    _ref.invalidate(shoppingItemsProvider(listaId));
    await load();
    return n;
  }
}

final shoppingListsProvider =
    StateNotifierProvider<ShoppingListsNotifier, ShoppingListsState>(
      (ref) => ShoppingListsNotifier(ref),
    );

class ShoppingItemsState {
  final List<ShoppingItem> items;
  final bool isLoading;

  const ShoppingItemsState({this.items = const [], this.isLoading = false});

  List<ShoppingItem> get pendientes => items.where((i) => !i.comprado).toList();
  List<ShoppingItem> get comprados => items.where((i) => i.comprado).toList();

  /// Suma de precios de referencia (último precio de los productos vinculados).
  double get totalEstimado =>
      items.fold(0, (sum, i) => sum + (i.precioReferencia ?? 0));
  int get sinPrecio => items.where((i) => i.precioReferencia == null).length;
}

/// Artículos de una lista concreta.
class ShoppingItemsNotifier extends StateNotifier<ShoppingItemsState> {
  final Ref _ref;
  final int listaId;
  ShoppingListRepository get _repo => _ref.read(shoppingListRepositoryProvider);

  ShoppingItemsNotifier(this._ref, this.listaId)
    : super(const ShoppingItemsState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    final items = await _repo.getItems(listaId);
    if (!mounted) return;
    state = ShoppingItemsState(items: items);
  }

  Future<void> _reloadAll() async {
    await load();
    await _ref.read(shoppingListsProvider.notifier).load();
  }

  Future<int> add({
    required String texto,
    String? cantidad,
    int? productoId,
    bool comprado = false,
  }) async {
    final id = await _repo.addItem(
      ShoppingItem(
        listaId: listaId,
        texto: texto,
        cantidad: cantidad,
        productoId: productoId,
        comprado: comprado,
      ),
    );
    await _reloadAll();
    return id;
  }

  Future<void> update(ShoppingItem item) async {
    await _repo.updateItem(item);
    await _reloadAll();
  }

  Future<void> setBought(ShoppingItem item, bool comprado) async {
    if (item.id == null) return;
    // Actualización optimista: la casilla responde al instante.
    state = ShoppingItemsState(
      items: [
        for (final i in state.items)
          i.id == item.id ? _withBought(i, comprado) : i,
      ],
    );
    await _repo.setItemBought(item.id!, comprado);
    await _reloadAll();
  }

  Future<void> delete(ShoppingItem item) async {
    if (item.id == null) return;
    // Se quita del estado de inmediato (requisito de Dismissible).
    state = ShoppingItemsState(
      items: state.items.where((i) => i.id != item.id).toList(),
    );
    await _repo.deleteItem(item.id!);
    await _reloadAll();
  }

  Future<void> deleteBought() async {
    await _repo.deleteBoughtItems(listaId);
    await _reloadAll();
  }

  Future<void> setAllBought(bool comprado) async {
    await _repo.setAllBought(listaId, comprado);
    await _reloadAll();
  }
}

ShoppingItem _withBought(ShoppingItem i, bool comprado) => ShoppingItem(
  id: i.id,
  listaId: i.listaId,
  texto: i.texto,
  cantidad: i.cantidad,
  productoId: i.productoId,
  comprado: comprado,
  orden: i.orden,
  precioReferencia: i.precioReferencia,
  establecimientoReferencia: i.establecimientoReferencia,
);

final shoppingItemsProvider = StateNotifierProvider.autoDispose
    .family<ShoppingItemsNotifier, ShoppingItemsState, int>(
      (ref, listaId) => ShoppingItemsNotifier(ref, listaId),
    );
