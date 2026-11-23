import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import 'core_providers.dart';

export 'core_providers.dart';

/// Listas de compra con contadores (se actualizan solas).
final shoppingListsProvider = StreamProvider<List<ShoppingList>>(
  (ref) => ref.watch(shoppingListRepositoryProvider).watchLists(),
);

/// Acciones sobre las listas.
final shoppingListsActionsProvider = Provider<ShoppingListsActions>(
  (ref) => ShoppingListsActions(ref),
);

class ShoppingListsActions {
  final Ref _ref;

  ShoppingListsActions(this._ref);

  ShoppingListRepository get _repo => _ref.read(shoppingListRepositoryProvider);

  Future<int> create(String nombre) => _repo.createList(nombre);

  Future<void> rename(int id, String nombre) => _repo.renameList(id, nombre);

  Future<void> delete(int id) => _repo.deleteList(id);

  /// Añade ingredientes de una receta. Devuelve cuántos se añadieron.
  Future<int> addIngredients(
    int listaId,
    List<RecipeIngredient> ingredientes,
  ) => _ref.read(addIngredientsToShoppingListProvider)(
    listaId: listaId,
    ingredientes: ingredientes,
  );
}

class ShoppingItemsState {
  final List<ShoppingItem> items;
  final bool isLoading;

  const ShoppingItemsState({this.items = const [], this.isLoading = false});

  List<ShoppingItem> get pendientes => items.where((i) => !i.comprado).toList();
  List<ShoppingItem> get comprados => items.where((i) => i.comprado).toList();

  /// Total del carrito (céntimos): unidades × precio de lo ya comprado.
  int get totalCarritoCent =>
      comprados.fold(0, (sum, i) => sum + (i.subtotalCent ?? 0));

  /// Unidades en el carrito (2 leches cuentan 2).
  int get articulosEnCarrito => comprados.fold(
    0,
    (sum, i) => sum + (i.compraId == null ? 1 : i.unidades),
  );

  /// Comprados sin compra registrada (sin precio).
  int get compradosSinPrecio =>
      comprados.where((i) => i.compraId == null).length;

  /// Lo que falta por comprar, estimado con el último precio conocido.
  int get estimadoPendienteCent =>
      pendientes.fold(0, (sum, i) => sum + (i.precioReferenciaCent ?? 0));

  /// Pendientes sin precio de referencia (no entran en la estimación).
  int get pendientesSinPrecio =>
      pendientes.where((i) => i.precioReferenciaCent == null).length;

  bool get hayCarrito => comprados.any((i) => i.compraId != null);
}

/// Artículos de una lista concreta (observa la base de datos).
class ShoppingItemsNotifier extends StateNotifier<ShoppingItemsState> {
  final Ref _ref;
  final int listaId;
  StreamSubscription<List<ShoppingItem>>? _sub;

  ShoppingItemsNotifier(this._ref, this.listaId)
    : super(const ShoppingItemsState(isLoading: true)) {
    _sub = _repo.watchItems(listaId).listen((items) {
      if (mounted) state = ShoppingItemsState(items: items);
    });
  }

  ShoppingListRepository get _repo => _ref.read(shoppingListRepositoryProvider);

  Future<int> add({
    required String texto,
    String? cantidad,
    int? alimentoId,
    bool comprado = false,
  }) => _repo.addItem(
    ShoppingItem(
      listaId: listaId,
      texto: texto,
      cantidad: cantidad,
      alimentoId: alimentoId,
      comprado: comprado,
    ),
  );

  Future<void> update(ShoppingItem item) => _repo.updateItem(item);

  /// Marca o desmarca a mano. Desmarcar saca el artículo del carrito pero
  /// conserva la compra del historial (ver [removeFromCart] para deshacerla).
  Future<void> setBought(ShoppingItem item, bool comprado) async {
    if (item.id == null) return;
    // Actualización optimista: la casilla responde al instante.
    state = ShoppingItemsState(
      items: [
        for (final i in state.items)
          i.id == item.id
              ? i.copyWith(comprado: comprado, clearCompra: !comprado)
              : i,
      ],
    );
    await _repo.setItemBought(item.id!, comprado);
  }

  /// Mete un alimento en el carrito y registra la compra. Ver [AddToCart].
  Future<int> addToCart({
    required Food alimento,
    int? presentacionId,
    int? itemId,
    required int precioCent,
    required String establecimiento,
    int unidades = 1,
    bool alPeso = false,
    double? pesoG,
  }) => _ref.read(addToCartProvider)(
    listaId: listaId,
    alimento: alimento,
    presentacionId: presentacionId,
    itemId: itemId,
    precioCent: precioCent,
    establecimiento: establecimiento,
    unidades: unidades,
    alPeso: alPeso,
    pesoG: pesoG,
  );

  /// Corrige precio/unidades. Ver [UpdateCartItem].
  Future<void> updateCartItem(
    ShoppingItem item, {
    required int precioCent,
    required int unidades,
  }) => _ref.read(updateCartItemProvider)(
    item: item,
    precioCent: precioCent,
    unidades: unidades,
  );

  /// Saca del carrito y borra la compra registrada. Ver [RemoveFromCart].
  Future<void> removeFromCart(ShoppingItem item) =>
      _ref.read(removeFromCartProvider)(item);

  Future<void> delete(ShoppingItem item) async {
    if (item.id == null) return;
    // Se quita del estado de inmediato (requisito de Dismissible).
    state = ShoppingItemsState(
      items: state.items.where((i) => i.id != item.id).toList(),
    );
    await _repo.deleteItem(item.id!);
  }

  Future<void> deleteBought() => _repo.deleteBoughtItems(listaId);

  Future<void> setAllBought(bool comprado) =>
      _repo.setAllBought(listaId, comprado);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final shoppingItemsProvider = StateNotifierProvider.autoDispose
    .family<ShoppingItemsNotifier, ShoppingItemsState, int>(
      (ref, listaId) => ShoppingItemsNotifier(ref, listaId),
    );
