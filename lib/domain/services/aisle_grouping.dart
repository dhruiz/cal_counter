import '../entities/category.dart';
import '../entities/shopping_list.dart';
import 'category_guesser.dart';
import 'ingredient_matcher.dart';

/// Artículos de una sección del súper.
class AisleGroup {
  /// Null = sin categoría ("Otros"), siempre al final.
  final Category? categoria;
  final List<ShoppingItem> items;

  const AisleGroup(this.categoria, this.items);

  String get titulo => categoria?.nombre ?? 'Otros';
}

/// Agrupa los artículos por categoría en el orden de los pasillos
/// ([ordenadas] ya viene en el orden de la tienda o en el general).
///
/// Un artículo vinculado usa la categoría de su alimento; uno de texto libre
/// ("Fruta") se clasifica por su nombre con [guessCategoryName]. Dentro de
/// cada grupo se respeta el orden de la lista.
List<AisleGroup> groupByAisle(
  List<ShoppingItem> items,
  List<Category> ordenadas,
) {
  final porId = {for (final c in ordenadas) c.id: c};
  final porNombre = {for (final c in ordenadas) normalizeText(c.nombre): c};
  final grupos = <int?, List<ShoppingItem>>{};
  for (final i in items) {
    Category? c = i.categoriaId == null ? null : porId[i.categoriaId];
    if (c == null && i.categoriaId == null) {
      final guess = guessCategoryName(i.texto);
      if (guess != null) c = porNombre[normalizeText(guess)];
    }
    grupos.putIfAbsent(c?.id, () => []).add(i);
  }
  return [
    for (final c in ordenadas)
      if (grupos.containsKey(c.id)) AisleGroup(c, grupos[c.id]!),
    if (grupos.containsKey(null)) AisleGroup(null, grupos[null]!),
  ];
}
