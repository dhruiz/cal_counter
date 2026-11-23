import '../entities/recipe.dart';
import '../entities/shopping_list.dart';
import '../repositories/shopping_list_repository.dart';
import '../services/ingredient_matcher.dart';

/// Añade ingredientes de una receta a una lista de compra.
///
/// Cada línea se separa en nombre ("Patatas") y cantidad ("500 g"). Si el
/// ingrediente está vinculado a un alimento, el artículo hereda el vínculo
/// (así en el modo carrito coincide exactamente al escanearlo). Se omiten
/// los que ya están pendientes en la lista (mismo alimento o mismo nombre).
/// Devuelve cuántos artículos se añadieron.
class AddIngredientsToShoppingList {
  final ShoppingListRepository repository;

  AddIngredientsToShoppingList(this.repository);

  Future<int> call({
    required int listaId,
    required List<RecipeIngredient> ingredientes,
  }) async {
    final items = await repository.getItems(listaId);
    final pendientes = items.where((i) => !i.comprado).toList();
    final nombres = pendientes.map((i) => normalizeText(i.texto)).toSet();
    final alimentos = pendientes
        .map((i) => i.alimentoId)
        .whereType<int>()
        .toSet();

    var added = 0;
    for (final ing in ingredientes) {
      final parsed = parseIngredientLine(ing.texto);
      final key = normalizeText(parsed.nombre);
      if (key.isEmpty || nombres.contains(key)) continue;
      if (ing.alimentoId != null && alimentos.contains(ing.alimentoId)) {
        continue;
      }
      await repository.addItem(
        ShoppingItem(
          listaId: listaId,
          alimentoId: ing.alimentoId,
          texto: parsed.nombre,
          cantidad: parsed.cantidad,
        ),
      );
      nombres.add(key);
      if (ing.alimentoId != null) alimentos.add(ing.alimentoId!);
      added++;
    }
    return added;
  }
}
