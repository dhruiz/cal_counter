import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String keyWeight = 'weight_kg';
  static const String keyKcal = 'kcal_target';
  static const String keyProteins = 'proteins_per_kg';
  static const String keyFats = 'fats_per_kg';
  static const String keyTolerance = 'tolerance_percent';
  static const String keyBodyFat = 'body_fat_percent';
  static const String keyHeight = 'height_cm';
  static const String keyAge = 'age';
  static const String keySex = 'sex';
  static const String keyActivity = 'activity_factor';

  @override
  Future<UserSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return UserSettings(
      weightKg: prefs.getDouble(keyWeight) ?? 70.0,
      kcalTarget: prefs.getInt(keyKcal) ?? 2000,
      proteinsPerKg: prefs.getDouble(keyProteins) ?? 1.5,
      fatsPerKg: prefs.getDouble(keyFats) ?? 0.5,
      tolerancePercent: prefs.getInt(keyTolerance) ?? 10,
      bodyFatPercent: prefs.getDouble(keyBodyFat),
      heightCm: prefs.getDouble(keyHeight) ?? 170.0,
      age: prefs.getInt(keyAge) ?? 30,
      sex: prefs.getString(keySex) ?? 'male',
      activityFactor: prefs.getDouble(keyActivity) ?? 1.2,
    );
  }

  @override
  Future<void> saveSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyWeight, settings.weightKg);
    await prefs.setInt(keyKcal, settings.kcalTarget);
    await prefs.setDouble(keyProteins, settings.proteinsPerKg);
    await prefs.setDouble(keyFats, settings.fatsPerKg);
    await prefs.setInt(keyTolerance, settings.tolerancePercent);

    // Save TDEE fields
    if (settings.bodyFatPercent != null) {
      await prefs.setDouble(keyBodyFat, settings.bodyFatPercent!);
    } else {
      await prefs.remove(keyBodyFat);
    }
    await prefs.setDouble(keyHeight, settings.heightCm);
    await prefs.setInt(keyAge, settings.age);
    await prefs.setString(keySex, settings.sex);
    await prefs.setDouble(keyActivity, settings.activityFactor);
  }
}
