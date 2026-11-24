import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/styles.dart';
import '../../data/backup/full_backup.dart';
import '../../data/backup/legacy_db.dart';
import '../../data/backup/repertoire_codec.dart';
import '../providers/data_provider.dart';
import '../widgets/file_transfer.dart';
import 'main_shell.dart';

/// Decide qué mostrar al abrir la app: la bienvenida (primera vez con el
/// repertorio vacío) o la app.
class StartupGate extends ConsumerWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needs = ref.watch(needsOnboardingProvider);
    return needs.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const MainShell(),
      data: (n) => n ? const OnboardingView() : const MainShell(),
    );
  }
}

/// Bienvenida: cómo empezar el repertorio.
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  bool _busy = false;
  String? _estado;

  Future<void> _finish([String? mensaje]) async {
    await markOnboardingDone();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    if (mensaje != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<void> _run(String estado, Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _estado = estado;
    });
    try {
      final msg = await action();
      if (msg == '') {
        // Cancelado: se queda en la bienvenida.
        if (mounted) setState(() => _busy = false);
        return;
      }
      await _finish(msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppStyles.semaphRed),
      );
    }
  }

  Future<void> _legacy(String path) =>
      _run('Importando tus datos...', () async {
        final report = await ref.read(migrateLegacyProvider)(
          LegacyData.read(path),
        );
        await markLegacyMigrated();
        return 'Importado: ${report.resumen}';
      });

  Future<void> _produce() => _run('Cargando frutas y verduras...', () async {
    final r = await ref.read(importRepertoireProvider)(
      await loadProduceCatalog(),
    );
    await markProduceCatalogDone();
    return '${r.nuevos} alimentos añadidos.';
  });

  /// Empezar vacío: tampoco se añade sola la lista de frutas y verduras.
  Future<void> _empty() async {
    await markProduceCatalogDone();
    await _finish();
  }

  Future<void> _import() => _run('Importando...', () async {
    final file = await FileTransfer.pick();
    if (file == null) return '';
    if (file.esSqlite) {
      final data = LegacyData.read(await file.aArchivoTemporal());
      final r = await ref.read(migrateLegacyProvider)(data);
      return 'Importado: ${r.resumen}';
    }
    final texto = file.texto.trimLeft();
    if (texto.contains('"${FullBackupService.formato}"')) {
      await ref
          .read(fullBackupProvider)
          .restore(texto, ajustesDeLosDatos: kAjustesDeLosDatos);
      return 'Respaldo restaurado.';
    }
    final r = await ref.read(importRepertoireProvider)(
      RepertoireCodec.decode(texto),
    );
    return 'Importado: ${r.resumen}';
  });

  @override
  Widget build(BuildContext context) {
    final legacy = ref.watch(legacyDatabaseProvider).valueOrNull;
    final theme = Theme.of(context);
    Widget option({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      bool destacada = false,
    }) {
      return Card(
        color: destacada ? theme.colorScheme.primaryContainer : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(icon, size: 32),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          onTap: _busy ? null : onTap,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppStyles.paddingLarge),
          children: [
            const SizedBox(height: 24),
            Icon(Icons.kitchen, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Tus alimentos, en el centro de todo',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'El repertorio de alimentos alimenta el contador de calorías, '
              'las recetas y las compras. ¿Cómo quieres empezar?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_busy) ...[
              const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_estado ?? '', textAlign: TextAlign.center),
              ),
            ],
            if (legacy != null)
              option(
                icon: Icons.history,
                title: 'Importar mis datos de la versión anterior',
                subtitle:
                    'Alimentos, productos, compras, recetas y listas. El '
                    'archivo antiguo se conserva intacto.',
                onTap: () => _legacy(legacy),
                destacada: true,
              ),
            option(
              icon: Icons.eco_outlined,
              title: 'Empezar con frutas y verduras',
              subtitle:
                  '${AppConstants.produceCatalogCount} frutas, verduras y '
                  'hortalizas con su tabla nutricional.',
              onTap: _produce,
              destacada: legacy == null,
            ),
            option(
              icon: Icons.file_open_outlined,
              title: 'Restaurar un respaldo o importar un repertorio',
              subtitle: 'Archivo .json, .tsv o .db.',
              onTap: _import,
            ),
            option(
              icon: Icons.crop_square,
              title: 'Empezar vacío',
              subtitle:
                  'Irás creando tus alimentos al escanearlos o comprarlos.',
              onTap: _empty,
            ),
          ],
        ),
      ),
    );
  }
}
