import 'package:cal_counter/data/models/food_model.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/meal.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
import 'package:cal_counter/domain/entities/product.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/entities/shopping_list.dart';
import 'package:cal_counter/domain/repositories/food_repository.dart';
import 'package:cal_counter/domain/repositories/meal_repository.dart';
import 'package:cal_counter/domain/repositories/product_repository.dart';
import 'package:cal_counter/domain/repositories/recipe_repository.dart';
import 'package:cal_counter/domain/repositories/shopping_list_repository.dart';

/// Repositorios en memoria para tests de widgets (sin SQLite).

class FakeRecipeRepository implements RecipeRepository {
  final Map<int, Recipe> data = {};
  int _next = 1;

  FakeRecipeRepository([List<Recipe> seed = const []]) {
    for (final r in seed) {
      saveRecipe(r);
    }
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
    final list = data.values.toList()
      ..sort((a, b) {
        if (a.favorita != b.favorita) return a.favorita ? -1 : 1;
        return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      });
    return list;
  }

  @override
  Future<Recipe?> getRecipe(int id) async => data[id];

  @override
  Future<int> saveRecipe(Recipe recipe) async {
    final id = recipe.id ?? _next++;
    data[id] = recipe.copyWith(id: id);
    return id;
  }

  @override
  Future<void> deleteRecipe(int id) async => data.remove(id);

  @override
  Future<void> setFavorite(int id, bool favorita) async =>
      data[id] = data[id]!.copyWith(favorita: favorita);
}

class FakeProductRepository implements ProductRepository {
  final Map<int, Product> products = {};
  final List<Purchase> purchases = [];
  int _next = 1;

  Product _withLast(Product p) {
    final mine = purchases.where((c) => c.productoId == p.id).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return Product(
      id: p.id,
      codigoBarras: p.codigoBarras,
      nombre: p.nombre,
      marca: p.marca,
      presentacion: p.presentacion,
      alimentoId: p.alimentoId,
      ultimaCompra: mine.isEmpty ? null : mine.first,
    );
  }

  @override
  Future<List<Product>> getProducts() async =>
      products.values.map(_withLast).toList();

  @override
  Future<Product?> getProduct(int id) async =>
      products[id] == null ? null : _withLast(products[id]!);

  @override
  Future<Product?> getProductByBarcode(String codigoBarras) async {
    for (final p in products.values) {
      if (p.codigoBarras == codigoBarras) return _withLast(p);
    }
    return null;
  }

  @override
  Future<int> saveProduct(Product product) async {
    final id = product.id ?? _next++;
    products[id] = product.copyWith(id: id);
    return id;
  }

  @override
  Future<void> deleteProduct(int id) async {
    products.remove(id);
    purchases.removeWhere((c) => c.productoId == id);
  }

  @override
  Future<List<Purchase>> getPurchases(int productoId) async =>
      purchases.where((c) => c.productoId == productoId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

  @override
  Future<int> addPurchase(Purchase purchase) async {
    final id = purchases.length + 1;
    purchases.add(
      Purchase(
        id: id,
        productoId: purchase.productoId,
        fecha: purchase.fecha,
        precio: purchase.precio,
        establecimiento: purchase.establecimiento,
      ),
    );
    return id;
  }

  @override
  Future<void> updatePurchase(Purchase purchase) async {
    final idx = purchases.indexWhere((c) => c.id == purchase.id);
    if (idx >= 0) purchases[idx] = purchase;
  }

  @override
  Future<void> deletePurchase(int id) async =>
      purchases.removeWhere((c) => c.id == id);

  @override
  Future<List<String>> getStores() async =>
      purchases.map((c) => c.establecimiento).toSet().toList();

  @override
  Future<int> purgePurchasesBefore(DateTime fecha) async => 0;

  @override
  Future<List<({Product producto, Purchase compra})>> getPurchaseHistorySince(
    DateTime fecha,
  ) async => [
    for (final c in purchases)
      if (!c.fecha.isBefore(fecha))
        (producto: products[c.productoId]!, compra: c),
  ];
}

class FakeShoppingListRepository implements ShoppingListRepository {
  final Map<int, String> lists = {};
  final List<ShoppingItem> items = [];
  final FakeProductRepository? productRepo;
  int _nextList = 1;
  int _nextItem = 1;

  FakeShoppingListRepository({this.productRepo});

  @override
  Future<List<ShoppingList>> getLists() async => [
    for (final e in lists.entries)
      ShoppingList(
        id: e.key,
        nombre: e.value,
        creada: DateTime(2026, 11, 20),
        totalItems: items.where((i) => i.listaId == e.key).length,
        comprados: items.where((i) => i.listaId == e.key && i.comprado).length,
      ),
  ];

  @override
  Future<int> createList(String nombre) async {
    final id = _nextList++;
    lists[id] = nombre;
    return id;
  }

  @override
  Future<void> renameList(int id, String nombre) async => lists[id] = nombre;

  @override
  Future<void> deleteList(int id) async {
    lists.remove(id);
    items.removeWhere((i) => i.listaId == id);
  }

  @override
  Future<List<ShoppingItem>> getItems(int listaId) async {
    final res = <ShoppingItem>[];
    for (final i in items.where((i) => i.listaId == listaId)) {
      final p = i.productoId == null
          ? null
          : await productRepo?.getProduct(i.productoId!);
      res.add(
        ShoppingItem(
          id: i.id,
          listaId: i.listaId,
          texto: i.texto,
          cantidad: i.cantidad,
          productoId: i.productoId,
          comprado: i.comprado,
          orden: i.orden,
          unidades: i.unidades,
          precioPagado: i.precioPagado,
          compraId: i.compraId,
          precioReferencia: p?.ultimaCompra?.precio,
          establecimientoReferencia: p?.ultimaCompra?.establecimiento,
        ),
      );
    }
    res.sort((a, b) {
      if (a.comprado != b.comprado) return a.comprado ? 1 : -1;
      return a.orden.compareTo(b.orden);
    });
    return res;
  }

  /// Copia "como se guardaría": sin datos de referencia.
  ShoppingItem _stored(ShoppingItem i, {required int id, required int orden}) =>
      ShoppingItem(
        id: id,
        listaId: i.listaId,
        texto: i.texto,
        cantidad: i.cantidad,
        productoId: i.productoId,
        comprado: i.comprado,
        orden: orden,
        unidades: i.unidades,
        precioPagado: i.precioPagado,
        compraId: i.compraId,
      );

  ShoppingItem _setBought(ShoppingItem i, bool comprado) =>
      i.copyWith(comprado: comprado, limpiarCarrito: !comprado);

  @override
  Future<int> addItem(ShoppingItem item) async {
    final id = _nextItem++;
    items.add(_stored(item, id: id, orden: id));
    return id;
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    final idx = items.indexWhere((i) => i.id == item.id);
    items[idx] = _stored(item, id: item.id!, orden: items[idx].orden);
  }

  @override
  Future<void> setItemBought(int itemId, bool comprado) async {
    final idx = items.indexWhere((i) => i.id == itemId);
    items[idx] = _setBought(items[idx], comprado);
  }

  @override
  Future<void> deleteItem(int itemId) async =>
      items.removeWhere((i) => i.id == itemId);

  @override
  Future<void> deleteBoughtItems(int listaId) async =>
      items.removeWhere((i) => i.listaId == listaId && i.comprado);

  @override
  Future<void> setAllBought(int listaId, bool comprado) async {
    for (var k = 0; k < items.length; k++) {
      if (items[k].listaId == listaId) {
        items[k] = _setBought(items[k], comprado);
      }
    }
  }
}

class FakeFoodRepository implements FoodRepository {
  final List<Food> foods;

  FakeFoodRepository(this.foods);

  @override
  Future<List<Food>> searchFoods(String query) async => foods
      .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  Future<Food?> getFoodById(int id) async {
    for (final f in foods) {
      if (f.id == id) return f;
    }
    return null;
  }

  @override
  Future<int> insertFood(FoodModel food) async => 0;

  @override
  Future<int> updateFood(FoodModel food) async => 0;

  @override
  Future<int> deleteFood(int id) async => 0;

  @override
  Future<void> incrementUsage(int foodId) async {}

  @override
  Future<void> resetUsage(int foodId) async {}

  @override
  Future<List<Food>> getMostUsedFoods({int limit = 20}) async => const [];
}

class FakeMealRepository implements MealRepository {
  @override
  Future<int> createMeal(String name, DateTime date) async => 1;
  @override
  Future<List<Meal>> getMealsByDate(DateTime date) async => const [];
  @override
  Future<DateTime?> getLastMealDate() async => null;
  @override
  Future<int> addItemToMeal(MealItem item) async => 1;
  @override
  Future<List<MealItem>> getMealItems(int mealId) async => const [];
  @override
  Future<String> exportMealsByDateCSV(DateTime date) async => '';
  @override
  Future<void> deleteMeal(int id) async {}
  @override
  Future<void> deleteMealItem(int id) async {}
  @override
  Future<void> updateMealItem(int id, double newCantidad) async {}
  @override
  Future<void> updateMealName(int id, String name) async {}
  @override
  Future<bool> hasMealItems() async => false;
  @override
  Future<void> clearMealsAndItems() async {}
}
