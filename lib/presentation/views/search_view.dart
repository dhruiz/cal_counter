import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/styles.dart';
import '../providers/search_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/add_food_popup.dart';
import 'food_form_view.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear search results when entering the view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.clear();
      ref.read(searchResultsProvider.notifier).search('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshSearch() {
    if (_searchController.text.isNotEmpty) {
      ref.read(searchResultsProvider.notifier).search(_searchController.text);
    }
  }

  Future<void> _showDatabaseOptions() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gestión de Base de Datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Exportar Base de Datos'),
              onTap: () {
                Navigator.pop(ctx);
                _exportDatabase();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Importar Base de Datos'),
              onTap: () {
                Navigator.pop(ctx);
                _importDatabase();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDatabase() async {
    try {
      // Let user select destination directory
      String? outputPath = await FilePicker.platform.getDirectoryPath();

      if (outputPath == null) {
        return; // User cancelled
      }

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Export database
      final fileName = 'db_alimentos_export.db';
      final fullPath = '$outputPath/$fileName';
      await ref.read(exportDatabaseProvider).call(fullPath);

      // Hide loading
      if (!mounted) return;
      Navigator.pop(context);

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Base de datos exportada a: $fullPath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hide loading if showing
      if (mounted) Navigator.pop(context);

      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importDatabase() async {
    try {
      // Let user select the database file to import
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      final sourcePath = result.files.single.path!;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Import database
      final importedCount = await ref
          .read(importDatabaseProvider)
          .call(sourcePath);

      // Hide loading
      if (!mounted) return;
      Navigator.pop(context);

      // Refresh search if there's a query
      _refreshSearch();

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$importedCount alimentos importados exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hide loading if showing
      if (mounted) Navigator.pop(context);

      // Show error message
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
    final results = ref.watch(searchResultsProvider);
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar alimentos...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          onChanged: (val) {
            ref.read(searchResultsProvider.notifier).search(val);
          },
        ),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: _showDatabaseOptions,
            tooltip: 'Gestión de Base de Datos',
          ),
        ],
      ),
      body: results.isEmpty
          ? Center(
              child: _searchController.text.isEmpty
                  ? const Text('Escribe para buscar')
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No se encontraron resultados'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final created = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FoodFormView(),
                              ),
                            );
                            if (created == true) {
                              _refreshSearch();
                            }
                          },
                          child: const Text('Agregar nuevo alimento'),
                        ),
                      ],
                    ),
            )
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (ctx, index) {
                final food = results[index];
                return ListTile(
                  title: Text(food.name),
                  subtitle: Text(
                    '${food.kcalPer100} kcal | G: ${food.grasasPer100} | C: ${food.carbsPer100} | P: ${food.proteinsPer100} (por 100g)',
                    style: AppStyles.labelText,
                  ),
                  onTap: () async {
                    // Check if we are trying to add to a previous day
                    final today = DateTime.now();
                    final selected = homeState.selectedDate;
                    final isPreviousDay = DateTime(
                      selected.year,
                      selected.month,
                      selected.day,
                    ).isBefore(DateTime(today.year, today.month, today.day));

                    if (isPreviousDay) {
                      // Warning logic could go here
                    }

                    // Capture context before async operation
                    final navigator = Navigator.of(context);

                    final added = await showDialog<bool>(
                      context: context,
                      builder: (_) => AddFoodPopup(
                        food: food,
                        availableMeals: homeState.meals,
                        selectedDate: homeState.selectedDate,
                      ),
                    );

                    if (added == true) {
                      if (!mounted) return;
                      navigator.pop(); // Close search view
                    }
                  },
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodFormView(foodToEdit: food),
                          ),
                        );
                        if (updated == true) {
                          _refreshSearch();
                        }
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar Alimento'),
                            content: Text('¿Eliminar ${food.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await ref
                              .read(foodRepositoryProvider)
                              .deleteFood(food.id!);
                          _refreshSearch();
                        }
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FoodFormView()),
          );
          if (created == true) {
            _refreshSearch();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
