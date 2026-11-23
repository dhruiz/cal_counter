import '../../domain/entities/product.dart';
import '../../domain/services/dates.dart';

/// Serializa filas de `productos` y `compras` ↔ entidades.
class ProductModel {
  /// [m] puede traer la última compra con prefijo `c_` (LEFT JOIN).
  static Product fromMap(Map<String, dynamic> m) {
    Purchase? ultima;
    if (m['c_id'] != null) {
      ultima = Purchase(
        id: m['c_id'] as int,
        productoId: m['id'] as int,
        fecha: DateTime.parse(m['c_fecha'] as String),
        precio: (m['c_precio'] as num).toDouble(),
        establecimiento: m['c_establecimiento'] as String,
      );
    }
    return Product(
      id: m['id'] as int?,
      codigoBarras: m['codigo_barras'] as String?,
      nombre: m['nombre'] as String,
      marca: m['marca'] as String?,
      presentacion: m['presentacion'] as String?,
      alimentoId: m['alimento_id'] as int?,
      ultimaCompra: ultima,
    );
  }

  static Map<String, dynamic> toMap(Product p) {
    return {
      'codigo_barras': nullIfBlank(p.codigoBarras),
      'nombre': p.nombre.trim(),
      'marca': nullIfBlank(p.marca),
      'presentacion': nullIfBlank(p.presentacion),
      'alimento_id': p.alimentoId,
    };
  }

  static String? nullIfBlank(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}

class PurchaseModel {
  static Purchase fromMap(Map<String, dynamic> m) {
    return Purchase(
      id: m['id'] as int?,
      productoId: m['producto_id'] as int,
      fecha: DateTime.parse(m['fecha'] as String),
      precio: (m['precio'] as num).toDouble(),
      establecimiento: m['establecimiento'] as String,
    );
  }

  static Map<String, dynamic> toMap(Purchase c) {
    return {
      'producto_id': c.productoId,
      'fecha': dateKey(c.fecha),
      'precio': c.precio,
      'establecimiento': c.establecimiento.trim(),
    };
  }
}
