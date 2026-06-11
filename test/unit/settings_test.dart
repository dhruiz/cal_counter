import 'package:cal_counter/domain/entities/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Settings calculations are correct', () {
    const settings = UserSettings(
      weightKg: 70.0,
      kcalTarget: 2000,
      proteinsPerKg: 1.5,
      fatsPerKg: 0.5,
      tolerancePercent: 10,
      heightCm: 170.0,
      age: 30,
      sex: 'male',
      activityFactor: 1.2,
    );

    final proteinsReq = settings.weightKg * settings.proteinsPerKg;
    final fatsReq = settings.weightKg * settings.fatsPerKg;
    final carbsReq =
        (settings.kcalTarget - (proteinsReq * 4 + fatsReq * 9)) / 4;

    expect(proteinsReq, 105.0); // 70 * 1.5
    expect(fatsReq, 35.0); // 70 * 0.5

    // 2000 - (105*4 + 35*9) = 2000 - (420 + 315) = 2000 - 735 = 1265
    // 1265 / 4 = 316.25
    expect(carbsReq, 316.25);
  });

  test('UserSettings defaults', () {
    final settings = UserSettings.initial();
    expect(settings.weightKg, 70.0);
    expect(settings.kcalTarget, 2000);
  });
}
