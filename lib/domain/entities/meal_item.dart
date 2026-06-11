import 'package:equatable/equatable.dart';

class MealItem extends Equatable {
  final int? id;
  final int mealId;
  final String alimento;
  final double cantidad; // grams
  final double grasas;
  final double carbohidratos;
  final double proteinas;
  final double kcal;

  const MealItem({
    this.id,
    required this.mealId,
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
    alimento,
    cantidad,
    grasas,
    carbohidratos,
    proteinas,
    kcal,
  ];
}
