import 'package:equatable/equatable.dart';
import '../services/scale_barcode.dart';
import 'food.dart';

/// Establecimiento donde se compra. Guarda el formato aprendido de sus
/// etiquetas de báscula (frescos al peso).
class Store extends Equatable {
  final int? id;
  final String nombre;
  final ScaleFormat? formatoBascula;

  /// Dígitos fijos que identifican el producto en sus etiquetas (6 o 7).
  final int longitudClave;

  const Store({
    this.id,
    required this.nombre,
    this.formatoBascula,
    this.longitudClave = 7,
  });

  @override
  List<Object?> get props => [id, nombre, formatoBascula, longitudClave];
}

/// Compra de una presentación: precio unitario (en céntimos), unidades,
/// establecimiento y fecha.
class Purchase extends Equatable {
  final int? id;
  final int presentacionId;

  /// Solo fecha (la hora se ignora); se guarda como `YYYY-MM-DD`.
  final DateTime fecha;

  /// Precio de UNA unidad, en céntimos (evita errores de redondeo).
  final int precioCent;
  final int unidades;

  /// Peso neto real de esta compra (frescos al peso). Si es null se usa el
  /// contenido de la presentación para el precio por kg.
  final double? pesoG;

  /// Nombre del establecimiento (al leer; al escribir se usa para buscar o
  /// crear la fila de `establecimientos`).
  final String establecimiento;

  const Purchase({
    this.id,
    required this.presentacionId,
    required this.fecha,
    required this.precioCent,
    this.unidades = 1,
    this.pesoG,
    required this.establecimiento,
  });

  /// Precio unitario en euros.
  double get precio => precioCent / 100;

  /// Unidades × precio, en céntimos.
  int get totalCent => precioCent * unidades;

  Purchase copyWith({
    int? id,
    int? presentacionId,
    DateTime? fecha,
    int? precioCent,
    int? unidades,
    double? pesoG,
    String? establecimiento,
  }) {
    return Purchase(
      id: id ?? this.id,
      presentacionId: presentacionId ?? this.presentacionId,
      fecha: fecha ?? this.fecha,
      precioCent: precioCent ?? this.precioCent,
      unidades: unidades ?? this.unidades,
      pesoG: pesoG ?? this.pesoG,
      establecimiento: establecimiento ?? this.establecimiento,
    );
  }

  @override
  List<Object?> get props => [
    id,
    presentacionId,
    fecha,
    precioCent,
    unidades,
    pesoG,
    establecimiento,
  ];
}

/// Compra con su presentación y alimento (historial, exportación, detalle).
class PurchaseRecord extends Equatable {
  final Purchase compra;
  final FoodPackage presentacion;
  final Food alimento;

  const PurchaseRecord({
    required this.compra,
    required this.presentacion,
    required this.alimento,
  });

  /// Precio por kg o por litro (céntimos) si se conoce el peso de la compra
  /// (frescos al peso: importe total / peso) o el contenido neto del envase.
  int? get precioPorKiloCent {
    final peso = compra.pesoG;
    if (peso != null && peso > 0) {
      return (compra.totalCent * 1000 / peso).round();
    }
    final c = presentacion.contenido;
    if (c == null || c <= 0) return null;
    return (compra.precioCent * 1000 / c).round();
  }

  @override
  List<Object?> get props => [compra, presentacion, alimento];
}
