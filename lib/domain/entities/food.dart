import 'package:equatable/equatable.dart';

class Food extends Equatable {
  final int? id;
  final String name;
  final double grasasPer100;
  final double carbsPer100;
  final double proteinsPer100;
  final double kcalPer100;

  const Food({
    this.id,
    required this.name,
    required this.grasasPer100,
    required this.carbsPer100,
    required this.proteinsPer100,
    required this.kcalPer100,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    grasasPer100,
    carbsPer100,
    proteinsPer100,
    kcalPer100,
  ];
}
