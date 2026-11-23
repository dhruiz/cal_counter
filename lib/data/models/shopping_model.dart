import '../../domain/entities/shopping_list.dart';

/// Serializa filas de `listas_compra` e `items_lista_compra` ↔ entidades.
class ShoppingListModel {
  static ShoppingList fromMap(Map<String, dynamic> m) {
    return ShoppingList(
      id: m['id'] as int?,
      nombre: m['nombre'] as String,
      creada: DateTime.parse(m['creada'] as String),
      totalItems: (m['total'] as int?) ?? 0,
      comprados: (m['comprados'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShoppingItemModel {
  /// [m] puede traer `ref_precio` / `ref_establecimiento` (LEFT JOIN compras).
  static ShoppingItem fromMap(Map<String, dynamic> m) {
    return ShoppingItem(
      id: m['id'] as int?,
      listaId: m['lista_id'] as int,
      texto: m['texto'] as String,
      cantidad: m['cantidad'] as String?,
      productoId: m['producto_id'] as int?,
      comprado: (m['comprado'] as int? ?? 0) == 1,
      orden: (m['orden'] as int?) ?? 0,
      precioReferencia: (m['ref_precio'] as num?)?.toDouble(),
      establecimientoReferencia: m['ref_establecimiento'] as String?,
    );
  }

  static Map<String, dynamic> toMap(ShoppingItem i) {
    final cantidad = i.cantidad?.trim();
    return {
      'lista_id': i.listaId,
      'texto': i.texto.trim(),
      'cantidad': (cantidad == null || cantidad.isEmpty) ? null : cantidad,
      'producto_id': i.productoId,
      'comprado': i.comprado ? 1 : 0,
    };
  }
}
