import 'package:equatable/equatable.dart';

/// Recipiente de cocina con su peso en vacío ("Olla grande · 1.240 g"), para
/// descontarlo al pesar una preparación.
class CookingPot extends Equatable {
  final String nombre;
  final double gramos;

  const CookingPot({required this.nombre, required this.gramos});

  @override
  List<Object?> get props => [nombre, gramos];
}

/// Peso de la preparación: total con el recipiente menos el recipiente.
/// Null si no tiene sentido (vacío o el recipiente pesa más).
double? netWeight(double? total, double? recipiente) {
  if (total == null || total <= 0) return null;
  final neto = total - (recipiente ?? 0);
  return neto > 0 ? neto : null;
}
