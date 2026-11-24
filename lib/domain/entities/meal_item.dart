import 'package:equatable/equatable.dart';

/// Alimento registrado en una comida. Los valores están YA escalados a la
/// cantidad consumida y el nombre se copia: es un histórico inmutable aunque
/// el alimento del repertorio cambie o se borre. [alimentoId] es solo un
/// vínculo informativo (estadísticas, repetir).
class MealItem extends Equatable {
  final int? id;
  final int mealId;
  final int? alimentoId;
  final String alimento;
  final double cantidad; // g o ml
  final double grasas;
  final double carbohidratos;
  final double proteinas;
  final double kcal;

  const MealItem({
    this.id,
    required this.mealId,
    this.alimentoId,
    required this.alimento,
    required this.cantidad,
    required this.grasas,
    required this.carbohidratos,
    required this.proteinas,
    required this.kcal,
  });

  @override
  List<Object?> get props => [
    id,
    mealId,
    alimentoId,
    alimento,
    cantidad,
    grasas,
    carbohidratos,
    proteinas,
    kcal,
  ];
}
