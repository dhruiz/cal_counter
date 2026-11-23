import 'package:equatable/equatable.dart';

/// Producto comprado habitualmente (con o sin código de barras).
class Product extends Equatable {
  final int? id;
  final String? codigoBarras;
  final String nombre;
  final String? marca;

  /// Formato o tamaño del envase: "1 L", "500 g", "pack 6"...
  final String? presentacion;

  /// Vínculo opcional a `db_alimentos` para registrar ingestas escaneando.
  final int? alimentoId;

  /// Última compra registrada (solo se rellena en listados/detalle).
  final Purchase? ultimaCompra;

  const Product({
    this.id,
    this.codigoBarras,
    required this.nombre,
    this.marca,
    this.presentacion,
    this.alimentoId,
    this.ultimaCompra,
  });

  /// "Nombre · Marca · Presentación" sin partes vacías.
  String get descripcion => [
    nombre,
    marca,
    presentacion,
  ].where((s) => s != null && s.trim().isNotEmpty).join(' · ');

  Product copyWith({
    int? id,
    String? codigoBarras,
    String? nombre,
    String? marca,
    String? presentacion,
    int? alimentoId,
    bool clearAlimento = false,
  }) {
    return Product(
      id: id ?? this.id,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      nombre: nombre ?? this.nombre,
      marca: marca ?? this.marca,
      presentacion: presentacion ?? this.presentacion,
      alimentoId: clearAlimento ? null : (alimentoId ?? this.alimentoId),
      ultimaCompra: ultimaCompra,
    );
  }

  @override
  List<Object?> get props => [
    id,
    codigoBarras,
    nombre,
    marca,
    presentacion,
    alimentoId,
    ultimaCompra,
  ];
}

/// Compra de un producto: precio unitario pagado en un establecimiento y fecha.
class Purchase extends Equatable {
  final int? id;
  final int productoId;

  /// Solo fecha (la hora se ignora); se guarda como `YYYY-MM-DD`.
  final DateTime fecha;
  final double precio;
  final String establecimiento;

  const Purchase({
    this.id,
    required this.productoId,
    required this.fecha,
    required this.precio,
    required this.establecimiento,
  });

  @override
  List<Object?> get props => [id, productoId, fecha, precio, establecimiento];
}
