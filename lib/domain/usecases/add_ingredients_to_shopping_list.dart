import '../entities/food.dart';
import '../entities/recipe.dart';
import '../entities/shopping_list.dart';
import '../repositories/food_repository.dart';
import '../repositories/shopping_list_repository.dart';
import '../services/ingredient_matcher.dart';
import '../services/ingredient_text.dart';
import '../services/nutrition_calculator.dart';
import '../services/quantity_parser.dart';

/// Resultado de llevar ingredientes a una lista.
class ShoppingAddResult {
  /// Artículos nuevos en la lista.
  final int anadidos;

  /// Artículos que ya estaban y suben su cantidad mínima.
  final int actualizados;

  const ShoppingAddResult({this.anadidos = 0, this.actualizados = 0});

  int get total => anadidos + actualizados;
}

/// Añade ingredientes de una receta a una lista de compra.
///
/// - Cada línea se lleva como artículo con su cantidad multiplicada por
///   [factor] (la escala de la receta). Si se sabe en gramos o mililitros
///   (cantidad del ingrediente vinculado, sus porciones o lo escrito en la
///   línea), se guarda como cantidad mínima.
/// - Un ingrediente vinculado hereda el vínculo (así en el modo carrito
///   coincide exactamente al escanearlo) y se lista con el nombre del
///   alimento.
/// - Si ya está pendiente en la lista (mismo alimento o mismo nombre) no se
///   repite: su cantidad mínima se suma a la que ya tenía (dos recetas con
///   arroz). Si no hay cantidades que sumar, se deja como estaba.
class AddIngredientsToShoppingList {
  final ShoppingListRepository repository;
  final FoodRepository foods;

  AddIngredientsToShoppingList(this.repository, this.foods);

  Future<ShoppingAddResult> call({
    required int listaId,
    required List<RecipeIngredient> ingredientes,
    double factor = 1,
  }) async {
    final f = factor > 0 ? factor : 1.0;
    final items = await repository.getItems(listaId);
    final pendientes = items.where((i) => !i.comprado).toList();
    final ids = {
      for (final i in ingredientes)
        if (i.alimentoId != null) i.alimentoId!,
    };
    final alimentos = await foods.getFoodsByIds(ids);
    final porciones = await foods.getPortionsFor(ids);

    var anadidos = 0;
    var actualizados = 0;
    for (final ing in ingredientes) {
      final food = ing.alimentoId == null ? null : alimentos[ing.alimentoId];
      final parsed = parseIngredientLine(ing.texto);
      final nombre = food?.nombre ?? parsed.nombre;
      final key = normalizeText(nombre);
      if (key.isEmpty) continue;
      final c = _cantidad(ing, food, porciones[food?.id] ?? const [], f);

      final idx = pendientes.indexWhere(
        (i) =>
            (ing.alimentoId != null && i.alimentoId == ing.alimentoId) ||
            normalizeText(i.texto) == key,
      );
      if (idx >= 0) {
        final actual = pendientes[idx];
        final minima = c.minima;
        if (minima == null || c.unidad == null) continue;
        final sinCantidad = (actual.cantidad ?? '').trim().isEmpty;
        if (actual.cantidadMinima == null && !sinCantidad) continue;
        final suma = (actual.cantidadMinima ?? 0) + minima;
        final nuevo = actual.copyWith(
          cantidad: humanQuantity(suma, c.unidad!),
          cantidadMinima: suma,
          alimentoId: actual.alimentoId ?? ing.alimentoId,
        );
        await repository.updateItem(nuevo);
        pendientes[idx] = nuevo;
        actualizados++;
        continue;
      }

      final item = ShoppingItem(
        listaId: listaId,
        alimentoId: ing.alimentoId,
        texto: nombre,
        cantidad: c.texto,
        cantidadMinima: c.minima,
      );
      final id = await repository.addItem(item);
      pendientes.add(
        ShoppingItem(
          id: id,
          listaId: listaId,
          alimentoId: item.alimentoId,
          texto: item.texto,
          cantidad: item.cantidad,
          cantidadMinima: item.cantidadMinima,
        ),
      );
      anadidos++;
    }
    return ShoppingAddResult(anadidos: anadidos, actualizados: actualizados);
  }

  /// Cantidad escalada: mínima en g/ml (si se sabe) y texto para mostrar.
  static ({double? minima, String? unidad, String? texto}) _cantidad(
    RecipeIngredient ing,
    Food? food,
    List<FoodPortion> porciones,
    double factor,
  ) {
    if (food != null) {
      final g = gramsForIngredient(ing, food, porciones);
      if (g != null) {
        final v = g * factor;
        return (minima: v, unidad: food.u, texto: humanQuantity(v, food.u));
      }
      final cant = ing.cantidad;
      final unidad = ing.unidad;
      if (cant != null && unidad != null) {
        return (
          minima: null,
          unidad: null,
          texto: quantityText(cant * factor, unidad),
        );
      }
    }
    final parsed = parseIngredientLine(ing.texto);
    final q = parseQuantity(ing.texto);
    if (q == null) return (minima: null, unidad: null, texto: parsed.cantidad);
    final v = q.cantidad * factor;
    final medible = q.esMasa || q.esVolumen;
    final texto = factor == 1 && parsed.cantidad != null
        ? parsed.cantidad
        : (medible ? humanQuantity(v, q.unidad) : quantityText(v, q.unidad));
    return (
      minima: medible ? v : null,
      unidad: medible ? q.unidad : null,
      texto: texto,
    );
  }
}
