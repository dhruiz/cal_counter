import 'package:cal_counter/domain/entities/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';

UserSettings _settings({
  double weightKg = 70.0,
  int kcalTarget = 2000,
  double proteinsPerKg = 1.5,
  double fatsPerKg = 0.5,
}) => UserSettings(
  weightKg: weightKg,
  kcalTarget: kcalTarget,
  proteinsPerKg: proteinsPerKg,
  fatsPerKg: fatsPerKg,
  tolerancePercent: 10,
  heightCm: 170.0,
  age: 30,
  sex: 'male',
  activityFactor: 1.2,
);

void main() {
  // Antes este test recalculaba la fórmula dentro del propio test (no probaba
  // código de la app); ahora prueba la implementación única de UserSettings.
  test('requerimientos: proteínas y grasas por kg, carbos = residuo', () {
    final s = _settings();
    expect(s.proteinsRequired, 105.0); // 70 * 1.5
    expect(s.fatsRequired, 35.0); // 70 * 0.5
    // 2000 - (105*4 + 35*9) = 1265 → 1265 / 4 = 316.25
    expect(s.carbsRequired, 316.25);
  });

  test('carbos objetivo nunca negativos', () {
    // 100 kg * 3 g/kg * 4 = 1200 kcal + 100 * 1.5 * 9 = 1350 → 2550 > 1500
    final s = _settings(
      weightKg: 100,
      kcalTarget: 1500,
      proteinsPerKg: 3,
      fatsPerKg: 1.5,
    );
    expect(s.carbsRequired, 0);
  });

  test('UserSettings defaults', () {
    final settings = UserSettings.initial();
    expect(settings.weightKg, 70.0);
    expect(settings.kcalTarget, 2000);
  });
}
