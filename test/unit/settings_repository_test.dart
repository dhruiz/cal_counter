import 'package:cal_counter/data/repositories/settings_repository_impl.dart';
import 'package:cal_counter/domain/entities/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SettingsRepositoryImpl();
  });

  test('Should return default settings when no data is saved', () async {
    final settings = await repository.getSettings();
    expect(settings, UserSettings.initial());
  });

  test('Should save and retrieve settings', () async {
    final newSettings = UserSettings(
      weightKg: 80,
      kcalTarget: 2500,
      proteinsPerKg: 2.0,
      fatsPerKg: 1.0,
      tolerancePercent: 5,
      heightCm: 175.0,
      age: 25,
      sex: 'female',
      activityFactor: 1.55,
    );

    await repository.saveSettings(newSettings);

    final savedSettings = await repository.getSettings();
    expect(savedSettings, newSettings);
  });
}
