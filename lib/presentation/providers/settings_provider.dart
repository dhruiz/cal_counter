import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../data/repositories/settings_repository_impl.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((
  ref,
) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});

class SettingsNotifier extends StateNotifier<UserSettings> {
  final SettingsRepository repository;

  SettingsNotifier(this.repository) : super(UserSettings.initial()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = await repository.getSettings();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    state = newSettings;
    await repository.saveSettings(newSettings);
  }

  // Calculated values
  double get proteinsRequired => state.weightKg * state.proteinsPerKg;
  double get fatsRequired => state.weightKg * state.fatsPerKg;
  double get carbsRequired {
    final proteinKcal = proteinsRequired * 4;
    final fatKcal = fatsRequired * 9;
    final remainingKcal = state.kcalTarget - (proteinKcal + fatKcal);
    return remainingKcal / 4;
  }
}
