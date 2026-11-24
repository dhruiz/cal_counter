import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/styles.dart';
import '../../domain/entities/food.dart';
import '../providers/search_provider.dart';
import '../providers/home_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/add_food_popup.dart';
import 'barcode_scanner_view.dart';
import 'food_form_view.dart';
import 'food_picker_view.dart';
import 'product_form_view.dart';

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

  /// Muestra un indicador modal mientras corre [task]. El indicador solo se
  /// cierra si se llegó a mostrar: antes, un error previo (p. ej. al abrir el
  /// selector) hacía `Navigator.pop` y cerraba la propia búsqueda.
  Future<T> _withLoading<T>(Future<T> Function() task) async {
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      // Sin PopScope el botón Atrás cerraba el indicador y el `pop` final
      // cerraba entonces la propia búsqueda.
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    try {
      return await task();
    } finally {
      navigator.pop();
    }
  }

  void _snack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  /// La copia se genera en la caché y se guarda con el selector del sistema
  /// (SAF), igual que el resto de exportaciones. Antes se escribía en una
  /// carpeta elegida con `getDirectoryPath`, lo que en Android 7-10 fallaba
  /// sin permiso de almacenamiento y en 11+ solo funcionaba en algunas carpetas.
  Future<void> _exportDatabase() async {
    try {
      final bytes = await _withLoading(
        () => ref.read(exportDatabaseProvider).call(),
      );
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Exportar base de datos',
        fileName: 'db_alimentos_export_$timestamp.db',
        bytes: bytes,
      );
      if (saved == null || saved.isEmpty) return; // Cancelado
      _snack('Base de datos exportada a: $saved', Colors.green);
    } catch (e) {
      _snack('Error al exportar: $e', Colors.red);
    }
  }

  Future<void> _importDatabase() async {
    try {
      // FileType.any: la extensión .db no tiene tipo MIME estándar y algunos
      // selectores no la filtran; el contenido se valida al abrirla.
      final result = await FilePicker.pickFiles(type: FileType.any);
      final sourcePath = result?.files.single.path;
      if (sourcePath == null) return; // Cancelado
      if (!mounted) return;

      final importedCount = await _withLoading(
        () => ref.read(importDatabaseProvider).call(sourcePath),
      );
      _refreshSearch();
      _snack('$importedCount alimentos importados exitosamente', Colors.green);
    } catch (e) {
      _snack('Error al importar: $e', Colors.red);
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

  /// Menú de acciones (long-press) sobre un alimento: editar o eliminar.
  void _showFoodActions(Food food) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                food.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(ctx);
                _editFood(food);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar'),
              onTap: () {
                Navigator.pop(ctx);
                _deleteFood(food);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editFood(Food food) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodFormView(foodToEdit: food)),
    );
    if (updated == true) {
      _refreshSearch();
    }
  }

  Future<void> _deleteFood(Food food) async {
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
      try {
        await ref.read(foodRepositoryProvider).deleteFood(food.id!);
      } catch (e) {
        _snack('Error al eliminar: $e', Colors.red);
      }
      _refreshSearch();
    }
  }

  /// Abre [AddFoodPopup] y, si se agregó, cierra la búsqueda.
  Future<void> _openAddPopup(Food food) async {
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
  }

  Future<bool> _confirm(String title, String message, String ok) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ok),
          ),
        ],
      ),
    );
    return res == true;
  }

  /// Registrar ingesta escaneando el envase: busca el producto por código y
  /// abre el alimento vinculado. Si el producto no existe o no está
  /// vinculado, ofrece registrarlo/vincularlo en el momento.
  Future<void> _scanProduct() async {
    final code = await BarcodeScannerView.scan(
      context,
      title: 'Escanear envase',
    );
    if (code == null || !mounted) return;
    final productRepo = ref.read(productRepositoryProvider);
    var product = await productRepo.getProductByBarcode(code);
    if (!mounted) return;

    if (product == null) {
      final create = await _confirm(
        'Producto no registrado',
        'El código $code no está en tus productos. ¿Quieres registrarlo y '
            'vincularlo a un alimento del contador?',
        'Registrar',
      );
      if (!create || !mounted) return;
      final id = await Navigator.push<int>(
        context,
        MaterialPageRoute(builder: (_) => ProductFormView(codigoBarras: code)),
      );
      if (id == null || !mounted) return;
      product = await productRepo.getProduct(id);
      if (product == null || !mounted) return;
    }

    final alimentoId = product.alimentoId;
    Food? food = alimentoId == null
        ? null
        : await ref.read(foodRepositoryProvider).getFoodById(alimentoId);
    if (!mounted) return;
    if (food == null) {
      final link = await _confirm(
        'Sin alimento vinculado',
        '"${product.nombre}" no está vinculado a ningún alimento del contador. '
            '¿Quieres elegirlo ahora? La próxima vez bastará con escanear.',
        'Elegir alimento',
      );
      if (!link || !mounted) return;
      food = await FoodPickerView.pick(context, initialQuery: product.nombre);
      if (food == null || !mounted) return;
      await ref
          .read(productsProvider.notifier)
          .saveProduct(product.copyWith(alimentoId: food.id));
      _refreshSearch();
      if (!mounted) return;
    }
    await _openAddPopup(food);
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
      onTap: () => _openAddPopup(food),
      onLongPress: () => _showFoodActions(food),
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
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanProduct,
            tooltip: 'Escanear envase',
          ),
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
