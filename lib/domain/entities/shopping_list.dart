import 'package:equatable/equatable.dart';

/// Lista de compra con contadores para el listado.
class ShoppingList extends Equatable {
  final int? id;
  final String nombre;
  final DateTime creada;
  final int totalItems;
  final int comprados;

  const ShoppingList({
    this.id,
    required this.nombre,
    required this.creada,
    this.totalItems = 0,
    this.comprados = 0,
  });

  @override
  List<Object?> get props => [id, nombre, creada, totalItems, comprados];
}

/// Artículo de una lista de compra. Si está vinculado a un producto
/// ([productoId]) se rellenan el último precio y establecimiento conocidos.
///
/// Modo carrito: [unidades] y [precioPagado] (precio unitario pagado en esta
/// compra) forman el total del carrito; [compraId] es la fila de `compras`
/// registrada desde este artículo, para corregirla o deshacerla.
class ShoppingItem extends Equatable {
  final int? id;
  final int listaId;
  final String texto;
  final String? cantidad;
  final int? productoId;
  final bool comprado;
  final int orden;
  final int unidades;
  final double? precioPagado;
  final int? compraId;

  // Datos de referencia del producto vinculado (solo lectura).
  final double? precioReferencia;
  final String? establecimientoReferencia;

  const ShoppingItem({
    this.id,
    required this.listaId,
    required this.texto,
    this.cantidad,
    this.productoId,
    this.comprado = false,
    this.orden = 0,
    this.unidades = 1,
    this.precioPagado,
    this.compraId,
    this.precioReferencia,
    this.establecimientoReferencia,
  });

  /// Importe en el carrito (unidades × precio pagado), o null sin precio.
  double? get subtotal =>
      precioPagado == null ? null : precioPagado! * unidades;

  ShoppingItem copyWith({
    int? id,
    String? texto,
    String? cantidad,
    int? productoId,
    bool? comprado,
    int? unidades,
    double? precioPagado,
    int? compraId,
    bool limpiarCarrito = false,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listaId: listaId,
      texto: texto ?? this.texto,
      cantidad: cantidad ?? this.cantidad,
      productoId: productoId ?? this.productoId,
      comprado: comprado ?? this.comprado,
      orden: orden,
      unidades: limpiarCarrito ? 1 : (unidades ?? this.unidades),
      precioPagado: limpiarCarrito ? null : (precioPagado ?? this.precioPagado),
      compraId: limpiarCarrito ? null : (compraId ?? this.compraId),
      precioReferencia: precioReferencia,
      establecimientoReferencia: establecimientoReferencia,
    );
  }

  @override
  List<Object?> get props => [
    id,
    listaId,
    texto,
    cantidad,
    productoId,
    comprado,
    orden,
    unidades,
    precioPagado,
    compraId,
    precioReferencia,
    establecimientoReferencia,
  ];
}
