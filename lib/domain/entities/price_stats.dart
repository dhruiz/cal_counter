import 'package:equatable/equatable.dart';
import 'product.dart';

/// Resumen de precios de un producto en un periodo.
class PriceStats extends Equatable {
  final Purchase? ultima;
  final double? minimo;
  final double? maximo;
  final double? promedio;
  final int numCompras;

  /// Último precio conocido en cada establecimiento, del más barato al más caro.
  final List<Purchase> ultimoPorEstablecimiento;

  const PriceStats({
    this.ultima,
    this.minimo,
    this.maximo,
    this.promedio,
    this.numCompras = 0,
    this.ultimoPorEstablecimiento = const [],
  });

  /// Establecimiento donde el último precio conocido es el más bajo
  /// (solo tiene sentido con 2 o más establecimientos).
  Purchase? get masBarato => ultimoPorEstablecimiento.length >= 2
      ? ultimoPorEstablecimiento.first
      : null;

  @override
  List<Object?> get props => [
    ultima,
    minimo,
    maximo,
    promedio,
    numCompras,
    ultimoPorEstablecimiento,
  ];
}
