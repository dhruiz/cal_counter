import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/styles.dart';
import '../../domain/entities/food.dart';
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

  /// Ids ya deslizados fuera de "más usados". Filtran el tile de inmediato
  /// (sincrónico) mientras el reset en BD + recarga del provider terminan,
  /// evitando el assert de Dismissible sobre la lista asíncrona.
  final Set<int> _removedRecentIds = {};

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
    // Recarga la lista de "más usados" por si cambió el catálogo (alta/edición/
    // baja/importación) mientras la vista está abierta.
    ref.invalidate(mostUsedFoodsProvider);
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
      String? outputPath = await FilePicker.getDirectoryPath();

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
      FilePickerResult? result = await FilePicker.pickFiles(
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

  /// Lista de "más usados" que se muestra cuando el campo de búsqueda está vacío.
  Widget _buildMostUsedList() {
    final mostUsed = ref.watch(mostUsedFoodsProvider);
    return mostUsed.when(
      data: (foods) {
        final visible = foods
            .where((f) => !_removedRecentIds.contains(f.id))
            .toList();
        if (visible.isEmpty) {
          return const Center(child: Text('Escribe para buscar'));
        }
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Usados con frecuencia',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...visible.map((f) => _buildFoodTile(f, inMostUsed: true)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Escribe para buscar')),
    );
  }

  /// Quita un alimento de "más usados" al deslizar el tile (izq. o der.).
  void _removeFromRecents(Food food) {
    final id = food.id;
    if (id == null) return;
    // Oculta el tile de inmediato; luego persiste el reset y recarga la lista.
    setState(() => _removedRecentIds.add(id));
    ref.read(resetFoodUsageProvider).call(id).then((_) {
      ref.invalidate(mostUsedFoodsProvider);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${food.name} quitado de recientes')),
    );
  }

  /// Fondo rojo con icono que se revela al deslizar el tile.
  Widget _swipeRemoveBackground(Alignment alignment) {
    return Container(
      color: Colors.red,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Icon(Icons.delete_sweep, color: Colors.white),
    );
  }

  /// Tile reutilizable para un alimento (resultados de búsqueda y más usados).
  /// En la lista de más usados ([inMostUsed]) se envuelve en un [Dismissible]
  /// para quitarlo de recientes deslizando hacia izquierda o derecha.
  Widget _buildFoodTile(Food food, {bool inMostUsed = false}) {
    final tile = ListTile(
      title: Text(food.name),
      subtitle: Text(
        '${food.kcalPer100} kcal | G: ${food.grasasPer100} | C: ${food.carbsPer100} | P: ${food.proteinsPer100} (por 100g)',
        style: AppStyles.labelText,
      ),
      onTap: () async {
        final homeState = ref.read(homeProvider);
        // Capture navigator before async gap.
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
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
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
              await ref.read(foodRepositoryProvider).deleteFood(food.id!);
              _refreshSearch();
            }
          }
        },
      ),
    );

    if (!inMostUsed || food.id == null) return tile;

    return Dismissible(
      key: ValueKey('recent_${food.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeRemoveBackground(Alignment.centerLeft),
      secondaryBackground: _swipeRemoveBackground(Alignment.centerRight),
      onDismissed: (_) => _removeFromRecents(food),
      child: tile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);

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
            // Rebuild para alternar entre "más usados" y resultados al instante.
            setState(() {});
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
      body: _searchController.text.isEmpty
          ? _buildMostUsedList()
          : results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No se encontraron resultados'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final created = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FoodFormView()),
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
              itemBuilder: (ctx, index) => _buildFoodTile(results[index]),
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
