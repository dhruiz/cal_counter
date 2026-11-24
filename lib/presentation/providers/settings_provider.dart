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

/// Los requerimientos calculados (proteínas, grasas, carbohidratos) viven en
/// [UserSettings] para que haya una sola implementación de la fórmula.
class SettingsNotifier extends StateNotifier<UserSettings> {
  final SettingsRepository repository;

  /// El usuario guardó antes de que terminara la carga inicial: la carga no
  /// debe sobrescribir lo que acaba de guardar.
  bool _updatedByUser = false;

  SettingsNotifier(this.repository) : super(UserSettings.initial()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final loaded = await repository.getSettings();
    if (!mounted || _updatedByUser) return;
    state = loaded;
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    _updatedByUser = true;
    state = newSettings;
    await repository.saveSettings(newSettings);
  }
}
