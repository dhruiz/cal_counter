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
class ShoppingItem extends Equatable {
  final int? id;
  final int listaId;
  final String texto;
  final String? cantidad;
  final int? productoId;
  final bool comprado;
  final int orden;

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
    this.precioReferencia,
    this.establecimientoReferencia,
  });

  @override
  List<Object?> get props => [
    id,
    listaId,
    texto,
    cantidad,
    productoId,
    comprado,
    orden,
    precioReferencia,
    establecimientoReferencia,
  ];
}
