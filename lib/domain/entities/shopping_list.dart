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

/// Artículo de una lista de compra.
///
/// Si está vinculado a un alimento ([alimentoId]) se rellena el último precio
/// conocido de cualquiera de sus presentaciones ([precioReferenciaCent]).
///
/// Modo carrito: el artículo no copia nada de la compra; [compraId] apunta a
/// la fila de `compras` y de ella salen [unidades] y [precioCent] (solo
/// lectura). Total del carrito = Σ unidades × precio de los comprados.
class ShoppingItem extends Equatable {
  final int? id;
  final int listaId;
  final int? alimentoId;
  final String texto;
  final String? cantidad;
  final bool comprado;
  final int orden;
  final int? compraId;

  // Datos de la compra enlazada (solo lectura).
  final int? presentacionId;
  final int unidades;
  final int? precioCent;

  // Referencia: última compra conocida del alimento (solo lectura).
  final int? precioReferenciaCent;
  final String? establecimientoReferencia;

  const ShoppingItem({
    this.id,
    required this.listaId,
    this.alimentoId,
    required this.texto,
    this.cantidad,
    this.comprado = false,
    this.orden = 0,
    this.compraId,
    this.presentacionId,
    this.unidades = 1,
    this.precioCent,
    this.precioReferenciaCent,
    this.establecimientoReferencia,
  });

  /// Está en el carrito con una compra registrada.
  bool get enCarrito => comprado && compraId != null;

  /// Importe en el carrito (céntimos), o null sin compra.
  int? get subtotalCent => precioCent == null ? null : precioCent! * unidades;

  ShoppingItem copyWith({
    int? id,
    int? alimentoId,
    bool clearAlimento = false,
    String? texto,
    String? cantidad,
    bool? comprado,
    int? orden,
    int? compraId,
    bool clearCompra = false,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listaId: listaId,
      alimentoId: clearAlimento ? null : (alimentoId ?? this.alimentoId),
      texto: texto ?? this.texto,
      cantidad: cantidad ?? this.cantidad,
      comprado: comprado ?? this.comprado,
      orden: orden ?? this.orden,
      compraId: clearCompra ? null : (compraId ?? this.compraId),
      presentacionId: clearCompra ? null : presentacionId,
      unidades: clearCompra ? 1 : unidades,
      precioCent: clearCompra ? null : precioCent,
      precioReferenciaCent: precioReferenciaCent,
      establecimientoReferencia: establecimientoReferencia,
    );
  }

  @override
  List<Object?> get props => [
    id,
    listaId,
    alimentoId,
    texto,
    cantidad,
    comprado,
    orden,
    compraId,
    presentacionId,
    unidades,
    precioCent,
    precioReferenciaCent,
    establecimientoReferencia,
  ];
}
