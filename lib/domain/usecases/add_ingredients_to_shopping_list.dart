import '../entities/shopping_list.dart';
import '../repositories/shopping_list_repository.dart';
import '../services/ingredient_matcher.dart';

/// Añade líneas de ingredientes de una receta a una lista de compra.
///
/// Cada línea se separa en nombre ("Patatas") y cantidad ("500 g"). Se omiten
/// las que ya están pendientes en la lista con el mismo nombre.
/// Devuelve cuántos artículos se añadieron.
class AddIngredientsToShoppingList {
  final ShoppingListRepository repository;

  AddIngredientsToShoppingList(this.repository);

  Future<int> call({required int listaId, required List<String> lineas}) async {
    final items = await repository.getItems(listaId);
    final pendientes = items
        .where((i) => !i.comprado)
        .map((i) => normalizeText(i.texto))
        .toSet();

    var added = 0;
    for (final linea in lineas) {
      final parsed = parseIngredientLine(linea);
      final key = normalizeText(parsed.nombre);
      if (key.isEmpty || pendientes.contains(key)) continue;
      await repository.addItem(
        ShoppingItem(
          listaId: listaId,
          texto: parsed.nombre,
          cantidad: parsed.cantidad,
        ),
      );
      pendientes.add(key);
      added++;
    }
    return added;
  }
}
