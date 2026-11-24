import 'package:equatable/equatable.dart';
import 'purchase.dart';

/// Resumen de precios (céntimos) de un alimento o presentación en un periodo.
class PriceStats extends Equatable {
  final Purchase? ultima;
  final int? minimoCent;
  final int? maximoCent;
  final int? promedioCent;
  final int numCompras;

  /// Último precio conocido en cada establecimiento, del más barato al más caro.
  final List<Purchase> ultimoPorEstablecimiento;

  const PriceStats({
    this.ultima,
    this.minimoCent,
    this.maximoCent,
    this.promedioCent,
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
    minimoCent,
    maximoCent,
    promedioCent,
    numCompras,
    ultimoPorEstablecimiento,
  ];
}
