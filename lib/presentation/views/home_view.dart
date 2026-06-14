import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/styles.dart';
import '../providers/home_provider.dart';
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
  @override
  void initState() {
    super.initState();
    // Check for new day on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNewDay();
    });
  }

  Future<void> _checkNewDay() async {
    final checkNewDay = ref.read(checkNewDayOnStartupProvider);
    final lastDate = await checkNewDay();

    if (lastDate != null && mounted) {
      // Check if there are meals to export
      final meals = await ref
          .read(mealRepositoryProvider)
          .getMealsByDate(lastDate);
      if (meals.isEmpty) return;

      if (meals.isEmpty) return;

      if (!mounted) return;

      final dateStr = DateFormat('yyyy-MM-dd').format(lastDate);
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
                await ref.read(mealRepositoryProvider).clearMealsAndItems();
                ref.read(homeProvider.notifier).refresh();
              },
              child: const Text('Descartar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final export = ref.read(exportDayToCsvProvider);
                final path = await export(lastDate);
                if (path.isNotEmpty) {
                  ref.read(homeProvider.notifier).refresh();
                }
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Exportado a: $path')));
                }
              },
              child: const Text('Exportar'),
            ),
          ],
        ),
      );
    }
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
        type: FileType.custom,
        allowedExtensions: ['tsv'],
        bytes: bytes,
      );
      if (!mounted) return;
      if (saved == null || saved.isEmpty) return; // User cancelled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alimentos exportados a: $saved'),
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
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tsv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) {
        throw Exception('No se pudo leer el contenido del archivo.');
      }
      final content = utf8.decode(bytes);
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

    // Targets
    final double targetKcal = settings.kcalTarget.toDouble();
    final double targetProt = settings.weightKg * settings.proteinsPerKg;
    final double targetFats = settings.weightKg * settings.fatsPerKg;
    final double targetCarbs =
        (targetKcal - (targetProt * 4 + targetFats * 9)) / 4;

    // Consumed
    final double consumedKcal = homeState.totalKcal;
    final double consumedProt = homeState.totalProteins;
    final double consumedFats = homeState.totalFats;
    final double consumedCarbs = homeState.totalCarbs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Counter'),
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
