import '../../domain/entities/food.dart';

class FoodModel extends Food {
  const FoodModel({
    super.id,
    required super.name,
    required super.grasasPer100,
    required super.carbsPer100,
    required super.proteinsPer100,
    required super.kcalPer100,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as int?,
      name: json['alimento'] as String,
      grasasPer100: (json['grasas'] as num).toDouble(),
      carbsPer100: (json['carbohidratos'] as num).toDouble(),
      proteinsPer100: (json['proteinas'] as num).toDouble(),
      kcalPer100: (json['kCal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alimento': name,
      'grasas': grasasPer100,
      'carbohidratos': carbsPer100,
      'proteinas': proteinsPer100,
      'kCal': kcalPer100,
    };
  }

  factory FoodModel.fromEntity(Food food) {
    return FoodModel(
      id: food.id,
      name: food.name,
      grasasPer100: food.grasasPer100,
      carbsPer100: food.carbsPer100,
      proteinsPer100: food.proteinsPer100,
      kcalPer100: food.kcalPer100,
    );
  }
}
