import 'package:equatable/equatable.dart';
import 'food.dart';

/// Establecimiento donde se compra.
class Store extends Equatable {
  final int? id;
  final String nombre;

  const Store({this.id, required this.nombre});

  @override
  List<Object?> get props => [id, nombre];
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

  /// Nombre del establecimiento (al leer; al escribir se usa para buscar o
  /// crear la fila de `establecimientos`).
  final String establecimiento;

  const Purchase({
    this.id,
    required this.presentacionId,
    required this.fecha,
    required this.precioCent,
    this.unidades = 1,
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
    String? establecimiento,
  }) {
    return Purchase(
      id: id ?? this.id,
      presentacionId: presentacionId ?? this.presentacionId,
      fecha: fecha ?? this.fecha,
      precioCent: precioCent ?? this.precioCent,
      unidades: unidades ?? this.unidades,
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

  /// Precio por kg o por litro (céntimos) si se conoce el contenido neto.
  int? get precioPorKiloCent {
    final c = presentacion.contenido;
    if (c == null || c <= 0) return null;
    return (compra.precioCent * 1000 / c).round();
  }

  @override
  List<Object?> get props => [compra, presentacion, alimento];
}
