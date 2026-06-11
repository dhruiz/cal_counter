import 'package:equatable/equatable.dart';

class UserSettings extends Equatable {
  final double weightKg;
  final int kcalTarget;
  final double proteinsPerKg;
  final double fatsPerKg;
  final int tolerancePercent;

  // TDEE calculation fields
  final double?
  bodyFatPercent; // Optional, 0-60%, if null or 0 use Mifflin-St Jeor
  final double heightCm;
  final int age;
  final String sex; // "male" or "female"
  final double activityFactor; // 1.2 to 1.9

  const UserSettings({
    required this.weightKg,
    required this.kcalTarget,
    required this.proteinsPerKg,
    required this.fatsPerKg,
    required this.tolerancePercent,
    this.bodyFatPercent,
    required this.heightCm,
    required this.age,
    required this.sex,
    required this.activityFactor,
  });

  // Defaults
  factory UserSettings.initial() {
    return const UserSettings(
      weightKg: 70.0,
      kcalTarget: 2000,
      proteinsPerKg: 1.5,
      fatsPerKg: 0.5,
      tolerancePercent: 10,
      bodyFatPercent: null,
      heightCm: 170.0,
      age: 30,
      sex: 'male',
      activityFactor: 1.2,
    );
  }

  UserSettings copyWith({
    double? weightKg,
    int? kcalTarget,
    double? proteinsPerKg,
    double? fatsPerKg,
    int? tolerancePercent,
    double? bodyFatPercent,
    double? heightCm,
    int? age,
    String? sex,
    double? activityFactor,
  }) {
    return UserSettings(
      weightKg: weightKg ?? this.weightKg,
      kcalTarget: kcalTarget ?? this.kcalTarget,
      proteinsPerKg: proteinsPerKg ?? this.proteinsPerKg,
      fatsPerKg: fatsPerKg ?? this.fatsPerKg,
      tolerancePercent: tolerancePercent ?? this.tolerancePercent,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      activityFactor: activityFactor ?? this.activityFactor,
    );
  }

  @override
  List<Object?> get props => [
    weightKg,
    kcalTarget,
    proteinsPerKg,
    fatsPerKg,
    tolerancePercent,
    bodyFatPercent,
    heightCm,
    age,
    sex,
    activityFactor,
  ];
}
