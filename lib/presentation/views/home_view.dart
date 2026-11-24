import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../providers/home_provider.dart';
import '../providers/search_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/nutrient_ring.dart';
import 'settings_view.dart';
import 'search_view.dart';
import 'day_management_view.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  late final AppLifecycleListener _lifecycle;
  bool _newDayDialogOpen = false;

  @override
  void initState() {
    super.initState();
    // Check for new day on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNewDay();
    });
    // Android mantiene la app en memoria durante días: al volver a primer
    // plano se comprueba si cambió la fecha (antes solo se hacía al arrancar
    // y lo registrado tras la medianoche iba al día anterior).
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _onResume() async {
    final changed = await ref.read(homeProvider.notifier).syncToday();
    if (changed && mounted) await _checkNewDay();
  }

  Future<void> _checkNewDay() async {
    if (_newDayDialogOpen) return;
    final DateTime? found;
    try {
      found = await _previousDayToExport();
    } catch (e) {
      _showError('No se pudo comprobar el día anterior: $e');
      return;
    }
    if (found == null || !mounted) return;
    final lastDate = found;

    final dateStr = DateFormat('yyyy-MM-dd').format(lastDate);
    _newDayDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo Día Detectado'),
        content: Text(
          '¿Desea exportar el día anterior ($dateStr) antes de iniciar el nuevo día?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Cancel -> Stay
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(mealRepositoryProvider).clearMealsAndItems();
              } catch (e) {
                _showError('No se pudo descartar el día: $e');
              }
              ref.read(homeProvider.notifier).refresh();
            },
            child: const Text('Descartar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _exportDay(lastDate);
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    ).whenComplete(() => _newDayDialogOpen = false);
  }

  /// Fecha anterior con comidas sin exportar, o null.
  Future<DateTime?> _previousDayToExport() async {
    final lastDate = await ref.read(checkNewDayOnStartupProvider)();
    if (lastDate == null) return null;
    final meals = await ref
        .read(mealRepositoryProvider)
        .getMealsByDate(lastDate);
    return meals.isEmpty ? null : lastDate;
  }

  /// Exporta el día (y vacía las comidas si se guardó, ver [ExportDayToCsv]).
  /// Si el usuario cancela el diálogo de guardado no se muestra nada (antes
  /// aparecía "Exportado a: " vacío).
  Future<void> _exportDay(DateTime date) async {
    try {
      final path = await ref.read(exportDayToCsvProvider)(date);
      if (path.isEmpty) return;
      ref.read(homeProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exportado a: $path')));
      }
    } catch (e) {
      _showError('Error al exportar: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _exportFoodsTsv() async {
    try {
      final tsv = await ref.read(exportFoodsTsvProvider).call();
      final bytes = Uint8List.fromList(utf8.encode(tsv));
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      // FilePicker.saveFile con bytes escribe el archivo vía SAF (igual que
      // el export CSV de meal_repository_impl); sustituye a file_saver.
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Exportar alimentos',
        fileName: 'db_alimentos_export_$timestamp.tsv',
        bytes: bytes,
      );
      if (!mounted) return;
      if (saved == null) return; // Cancelado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alimentos exportados a: ${AppUtils.formatRutaGuardada(saved)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importFoodsTsv() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['tsv'],
      );
      if (file == null) return; // Cancelado

      final content = utf8.decode(await file.readAsBytes());
      final imported = await ref.read(importFoodsTsvProvider).call(content);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$imported alimentos importados.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al importar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final homeState = ref.watch(homeProvider);

    // Targets (fórmula única en UserSettings)
    final double targetKcal = settings.kcalTarget.toDouble();
    final double targetProt = settings.proteinsRequired;
    final double targetFats = settings.fatsRequired;
    final double targetCarbs = settings.carbsRequired;

    // Consumed
    final double consumedKcal = homeState.totalKcal;
    final double consumedProt = homeState.totalProteins;
    final double consumedFats = homeState.totalFats;
    final double consumedCarbs = homeState.totalCarbs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador de calorías'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.import_export),
            tooltip: 'Importar / Exportar Alimentos',
            onSelected: (value) {
              if (value == 'export') {
                _exportFoodsTsv();
              } else if (value == 'import') {
                _importFoodsTsv();
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Exportar Alimentos (TSV)'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Importar Alimentos (TSV)'),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsView()),
              ).then((_) => ref.read(homeProvider.notifier).refresh());
            },
          ),
        ],
      ),
      body: homeState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (homeState.error != null)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: Text(homeState.error!),
                        trailing: TextButton(
                          onPressed: () =>
                              ref.read(homeProvider.notifier).refresh(),
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ),
                  _buildSectionTitle('Progreso Diario'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: NutrientRing(
                          label: 'Calorías',
                          consumed: consumedKcal,
                          target: targetKcal,
                          unit: 'kcal',
                          color: AppStyles.ringKcal,
                        ),
                      ),
                      const SizedBox(width: AppStyles.paddingSmall),
                      Expanded(
                        child: NutrientRing(
                          label: 'Grasas',
                          consumed: consumedFats,
                          target: targetFats,
                          unit: 'g',
                          color: AppStyles.ringFats,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.paddingSmall),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: NutrientRing(
                          label: 'Carbohidratos',
                          consumed: consumedCarbs,
                          target: targetCarbs,
                          unit: 'g',
                          color: AppStyles.ringCarbs,
                        ),
                      ),
                      const SizedBox(width: AppStyles.paddingSmall),
                      Expanded(
                        child: NutrientRing(
                          label: 'Proteínas',
                          consumed: consumedProt,
                          target: targetProt,
                          unit: 'g',
                          color: AppStyles.ringProt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.paddingLarge),

                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchView()),
                      ).then((_) => ref.read(homeProvider.notifier).refresh());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Ingesta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingMedium),

                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DayManagementView(),
                        ),
                      ).then((_) => ref.read(homeProvider.notifier).refresh());
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Gestionar Día'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppStyles.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.paddingSmall),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
