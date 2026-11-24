import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_item.dart';
import '../providers/home_provider.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../widgets/meal_items_dialog.dart';

/// Vista de gestión del día: lista las comidas registradas, permite editar las
/// cantidades de sus ingredientes (vía [MealItemsDialog]), renombrar una comida,
/// guardarla como alimento en la BD principal, exportar el día y eliminarlo.
class DayManagementView extends ConsumerWidget {
  const DayManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(state.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión del Día'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppStyles.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (state.meals.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Toca para editar ingredientes · mantén pulsado para más opciones',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: state.meals.isEmpty
                      ? const Center(
                          child: Text('No hay comidas registradas hoy.'),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppStyles.paddingMedium,
                          ),
                          children: state.meals
                              .map(
                                (meal) =>
                                    _buildMealCard(context, ref, state, meal),
                              )
                              .toList(),
                        ),
                ),
                _buildBottomActions(context, ref, state),
              ],
            ),
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
    Meal meal,
  ) {
    final items = state.mealItems[meal.id] ?? [];
    double mealKcal = 0, mealFats = 0, mealCarbs = 0, mealProteins = 0;
    for (final i in items) {
      mealKcal += i.kcal;
      mealFats += i.grasas;
      mealCarbs += i.carbohidratos;
      mealProteins += i.proteinas;
    }

    return Card(
      child: ListTile(
        title: Text(meal.name),
        subtitle: Text(
          '${items.length} items - ${mealKcal.toStringAsFixed(0)} kcal\n'
          'G: ${mealFats.toStringAsFixed(1)}g  '
          'C: ${mealCarbs.toStringAsFixed(1)}g  '
          'P: ${mealProteins.toStringAsFixed(1)}g',
        ),
        onTap: () {
          // Editar cantidades de los ingredientes.
          showDialog(
            context: context,
            builder: (ctx) =>
                MealItemsDialog(mealName: meal.name, items: items),
          );
        },
        onLongPress: () => _showMealActions(context, ref, meal, items),
      ),
    );
  }

  /// Acciones por comida (long-press): renombrar, guardar como alimento,
  /// eliminar.
  void _showMealActions(
    BuildContext context,
    WidgetRef ref,
    Meal meal,
    List<MealItem> items,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                meal.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Renombrar'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, ref, meal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Guardar como alimento'),
              onTap: () {
                Navigator.pop(ctx);
                _showSaveAsFoodDialog(context, ref, meal, items);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar'),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteMealConfirmation(context, ref, meal);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingSmall),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final export = ref.read(exportDayToCsvProvider);
                  final path = await export(state.selectedDate);
                  // Cancelado: antes se mostraba "Exportado a: " vacío.
                  if (path.isEmpty) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Exportado a: $path')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error al exportar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Exportar Día'),
            ),
            TextButton.icon(
              onPressed: () => _showDeleteDayConfirmation(context, ref, state),
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                'Eliminar Día',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Meal meal) {
    final controller = TextEditingController(text: meal.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar Comida'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre no puede estar vacío'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await ref.read(homeProvider.notifier).renameMeal(meal.id!, name);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showSaveAsFoodDialog(
    BuildContext context,
    WidgetRef ref,
    Meal meal,
    List<MealItem> items,
  ) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La comida no tiene ingredientes.')),
      );
      return;
    }

    final nameController = TextEditingController(text: meal.name);

    // Peso sugerido = suma de los pesos de cada ingrediente. Editable porque
    // ingredientes como arroz crudo cambian de peso al cocinarse y falsearían
    // el valor por 100g de la preparación.
    final suggestedGrams = items.fold<double>(0, (sum, i) => sum + i.cantidad);
    final weightController = TextEditingController(
      text: AppUtils.formatNumero(suggestedGrams),
    );
    // Resaltar el peso y dejar el foco/teclado sobre él para editarlo rápido.
    weightController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: weightController.text.length,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar como Alimento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Se calculará el valor nutricional por 100g a partir del total '
              'de la comida y su peso. Ajusta el peso si la preparación cambió '
              'al cocinarse.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppStyles.paddingSmall),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del alimento',
              ),
            ),
            const SizedBox(height: AppStyles.paddingSmall),
            TextField(
              controller: weightController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Peso total de la preparación',
                suffixText: 'g',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre no puede estar vacío'),
                  ),
                );
                return;
              }
              final totalGrams = AppUtils.parseDecimal(weightController.text);
              if (totalGrams == null || totalGrams <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Ingrese un peso válido')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _saveMealAsFood(context, ref, name, items, totalGrams);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMealAsFood(
    BuildContext context,
    WidgetRef ref,
    String name,
    List<MealItem> items,
    double totalGrams,
  ) async {
    // ¿Ya existe un alimento genérico con ese nombre (sin tildes ni
    // mayúsculas)? Si se sobrescribe se ACTUALIZA ese alimento: conserva su
    // id, sus vínculos en recetas y su uso.
    final matches = await ref.read(foodRepositoryProvider).search(name);
    final existing = matches
        .where(
          (f) =>
              normalizeText(f.nombre) == normalizeText(name) &&
              f.marca.trim().isEmpty,
        )
        .firstOrNull;

    if (existing != null) {
      if (!context.mounted) return;
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alimento existente'),
          content: Text(
            'Ya existe un alimento llamado "$name". ¿Desea sobrescribirlo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sobrescribir'),
            ),
          ],
        ),
      );
      if (overwrite != true) return;
    }

    try {
      await ref
          .read(saveMealAsFoodProvider)
          .call(
            name: name,
            items: items,
            totalGrams: totalGrams,
            sobrescribir: existing,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alimento "$name" guardado.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteMealConfirmation(
    BuildContext context,
    WidgetRef ref,
    Meal meal,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Comida'),
        content: const Text(
          '¿Seguro que desea eliminar esta comida y sus items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(homeProvider.notifier).deleteMeal(meal.id!);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDayConfirmation(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Día'),
        content: const Text(
          '¿Seguro que desea eliminar TODAS las comidas de hoy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(homeProvider.notifier)
                  .deleteMeals(state.meals.map((m) => m.id!));
            },
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );
  }
}
