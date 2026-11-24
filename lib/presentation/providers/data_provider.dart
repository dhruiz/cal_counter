import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../data/backup/full_backup.dart';
import '../../data/backup/legacy_db.dart';
import '../../data/backup/repertoire_codec.dart';
import '../../domain/entities/repertoire.dart';
import '../../domain/usecases/repertoire_exchange.dart';
import 'core_providers.dart';

export 'core_providers.dart';

/// Claves de SharedPreferences del arranque.
const String kOnboardingDone = 'onboarding_completado';
const String kLegacyMigrated = 'migracion_legado_hecha';

final exportRepertoireProvider = Provider<ExportRepertoire>(
  (ref) => ExportRepertoire(
    ref.watch(foodRepositoryProvider),
    ref.watch(recipeRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);

final importRepertoireProvider = Provider<ImportRepertoire>(
  (ref) => ImportRepertoire(
    ref.watch(foodRepositoryProvider),
    ref.watch(recipeRepositoryProvider),
    ref.watch(transactionRunnerProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);

final fullBackupProvider = Provider<FullBackupService>(
  (ref) => FullBackupService(ref.watch(appDatabaseProvider)),
);

final migrateLegacyProvider = Provider<MigrateLegacyData>(
  (ref) => MigrateLegacyData(
    foods: ref.watch(foodRepositoryProvider),
    purchases: ref.watch(purchaseRepositoryProvider),
    shopping: ref.watch(shoppingListRepositoryProvider),
    recipes: ref.watch(recipeRepositoryProvider),
    meals: ref.watch(mealRepositoryProvider),
    tx: ref.watch(transactionRunnerProvider),
  ),
);

/// Catálogo base incluido en la app (678 alimentos genéricos).
final seedCatalogProvider = FutureProvider<Repertoire>((ref) async {
  final json = await rootBundle.loadString(AppConstants.seedCatalogAsset);
  return RepertoireCodec.decode(json);
});

/// Ruta de la base de datos de la versión anterior si existe y aún no se
/// migró. El archivo nunca se modifica.
final legacyDatabaseProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(kLegacyMigrated) ?? false) return null;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, kLegacyDatabaseName);
    return File(path).existsSync() ? path : null;
  } catch (_) {
    return null;
  }
});

/// ¿Hay que mostrar la pantalla de bienvenida? Solo la primera vez y con el
/// repertorio vacío.
final needsOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(kOnboardingDone) ?? false) return false;
  final foods = await ref.read(foodRepositoryProvider).search('', limit: 1);
  if (foods.isNotEmpty) {
    await prefs.setBool(kOnboardingDone, true);
    return false;
  }
  return true;
});

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kOnboardingDone, true);
}

Future<void> markLegacyMigrated() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kLegacyMigrated, true);
}

/// Guarda una copia del estado actual antes de restaurar un respaldo.
/// Devuelve la ruta del archivo.
Future<String?> saveAutomaticBackup(FullBackupService service) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File(p.join(dir.path, 'respaldo_automatico_$ts.json'));
    await file.writeAsString(await service.export());
    return file.path;
  } catch (_) {
    return null;
  }
}
