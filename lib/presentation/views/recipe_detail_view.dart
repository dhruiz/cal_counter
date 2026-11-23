import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../data/parsers/recipe_text_codec.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../providers/recipes_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/add_food_popup.dart';
import '../widgets/add_to_shopping_list_dialog.dart';
import '../widgets/empty_state.dart';
import 'food_picker_view.dart';
import 'recipe_form_view.dart';

/// Detalle de una receta: ingredientes (marcando los que el usuario tiene si
/// viene de una búsqueda), pasos, notas, calorías si está vinculada a un
/// alimento, y acciones (lista de compra, copiar, editar, borrar).
class RecipeDetailView extends ConsumerWidget {
  final int recipeId;

  /// Ingredientes que el usuario dijo tener (búsqueda por ingredientes).
  final List<String> terminos;
  final bool incluirBasicos;

  const RecipeDetailView({
    super.key,
    required this.recipeId,
    this.terminos = const [],
    this.incluirBasicos = true,
  });

  Future<void> _delete(BuildContext context, WidgetRef ref, Recipe r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text('¿Eliminar "${r.nombre}"?'),
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
    if (ok != true) return;
    await ref.read(recipesProvider.notifier).delete(r.id!);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _copy(BuildContext context, Recipe r) async {
    await Clipboard.setData(
      ClipboardData(text: RecipeTextCodec.formatRecipe(r)),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receta copiada. Pégala en WhatsApp, un correo...'),
        ),
      );
    }
  }

  Future<void> _linkFood(BuildContext context, WidgetRef ref, Recipe r) async {
    final food = await FoodPickerView.pick(context, initialQuery: r.nombre);
    if (food == null || !context.mounted) return;
    final grams = await _askPortion(context, r.pesoPorcionG);
    await ref
        .read(recipesProvider.notifier)
        .save(r.copyWith(alimentoId: food.id, pesoPorcionG: grams));
  }

  Future<double?> _askPortion(BuildContext context, double? current) async {
    final ctrl = TextEditingController(
      text: current == null ? '' : AppUtils.formatNumero(current),
    );
    final res = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Peso de una porción'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Gramos por porción (opcional)',
            suffixText: 'g',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Omitir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              ctx,
              double.tryParse(ctrl.text.replaceAll(',', '.')),
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return res;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recipeDetailProvider(recipeId));
    final recipe = async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe?.nombre ?? 'Receta'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          if (recipe != null) ...[
            IconButton(
              tooltip: recipe.favorita ? 'Quitar de favoritas' : 'Favorita',
              icon: Icon(recipe.favorita ? Icons.star : Icons.star_border),
              onPressed: () =>
                  ref.read(recipesProvider.notifier).toggleFavorite(recipe),
            ),
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeFormView(recipe: recipe),
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'copy') _copy(context, recipe);
                if (v == 'delete') _delete(context, ref, recipe);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'copy', child: Text('Copiar como texto')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (r) {
          if (r == null) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Receta no encontrada',
              message: 'Puede que se haya eliminado.',
            );
          }
          return _RecipeBody(
            recipe: r,
            availability: terminos.isEmpty
                ? null
                : IngredientAvailability(
                    terminos,
                    incluirBasicos: incluirBasicos,
                  ),
            onLinkFood: () => _linkFood(context, ref, r),
          );
        },
      ),
    );
  }
}

class _RecipeBody extends ConsumerWidget {
  final Recipe recipe;
  final IngredientAvailability? availability;
  final VoidCallback onLinkFood;

  const _RecipeBody({
    required this.recipe,
    required this.availability,
    required this.onLinkFood,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final r = recipe;
    final av = availability;
    final pasos = r.pasos;

    final meta = <Widget>[
      if ((r.categoria ?? '').isNotEmpty)
        Chip(
          avatar: const Icon(Icons.label_outline, size: 18),
          label: Text(r.categoria!),
        ),
      if (r.tiempoMin != null)
        Chip(
          avatar: const Icon(Icons.timer_outlined, size: 18),
          label: Text(RecipeTextCodec.formatMinutes(r.tiempoMin!)),
        ),
      if (r.porciones != null)
        Chip(
          avatar: const Icon(Icons.people_outline, size: 18),
          label: Text(
            '${r.porciones} ${r.porciones == 1 ? 'porción' : 'porciones'}',
          ),
        ),
    ];

    // Faltantes preseleccionados para la lista de compra.
    final faltantes = av == null
        ? null
        : r.ingredientes.where((l) => !av.covers(l)).toSet();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (meta.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(spacing: 8, runSpacing: 4, children: meta),
          ),
        _NutritionCard(recipe: r, onLink: onLinkFood),
        SectionTitle('Ingredientes (${r.ingredientes.length})'),
        if (av != null)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppStyles.semaphGreen,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lo tienes, según lo que escribiste en la búsqueda',
                    style: AppStyles.labelText,
                  ),
                ),
              ],
            ),
          ),
        ...r.ingredientes.map((linea) {
          final tiene = av?.covers(linea);
          // Un opcional que falta no se marca en rojo: no es imprescindible.
          final faltaColor = parseIngredientLine(linea).opcional
              ? AppStyles.neutral
              : AppStyles.semaphRed;
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(
              tiene == null
                  ? Icons.circle
                  : (tiene ? Icons.check_circle : Icons.radio_button_unchecked),
              size: tiene == null ? 8 : 22,
              color: tiene == null
                  ? theme.colorScheme.primary
                  : (tiene ? AppStyles.semaphGreen : faltaColor),
            ),
            title: Text(linea, style: const TextStyle(fontSize: 16)),
          );
        }),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            onPressed: r.ingredientes.isEmpty
                ? null
                : () => AddToShoppingListDialog.show(
                    context,
                    lineas: r.ingredientes,
                    preseleccionados: faltantes,
                  ),
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(
              faltantes == null
                  ? 'Añadir a la lista de compra'
                  : 'Añadir lo que me falta a la lista',
            ),
          ),
        ),
        if (pasos.isNotEmpty) ...[
          const SectionTitle('Preparación'),
          ...List.generate(pasos.length, (i) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppStyles.primary,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(pasos[i], style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }),
        ],
        if ((r.notas ?? '').isNotEmpty) ...[
          const SectionTitle('Notas'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              child: Text(r.notas!, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Calorías de la receta si está vinculada a un alimento de `db_alimentos`.
class _NutritionCard extends ConsumerWidget {
  final Recipe recipe;
  final VoidCallback onLink;

  const _NutritionCard({required this.recipe, required this.onLink});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = recipe.alimentoId;
    final Food? food = id == null
        ? null
        : ref.watch(foodByIdProvider(id)).valueOrNull;

    if (food == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextButton.icon(
          onPressed: onLink,
          icon: const Icon(Icons.local_fire_department_outlined),
          label: const Text('Vincular al contador de calorías'),
        ),
      );
    }

    final g = recipe.pesoPorcionG;
    String per(double per100) =>
        g == null ? '' : ' · ${AppUtils.formatNumero(per100 * g / 100)}';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: AppStyles.ringKcal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    food.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Cambiar alimento vinculado',
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: onLink,
                ),
              ],
            ),
            Text(
              g == null
                  ? 'Por 100 g'
                  : 'Por 100 g · por porción (${AppUtils.formatNumero(g)} g)',
              style: AppStyles.labelText,
            ),
            const SizedBox(height: 4),
            Text(
              'Calorías: ${AppUtils.formatNumero(food.kcalPer100)}${per(food.kcalPer100)} kcal',
            ),
            Text(
              'Grasas ${AppUtils.formatNumero(food.grasasPer100)}${per(food.grasasPer100)} g · '
              'Carbs ${AppUtils.formatNumero(food.carbsPer100)}${per(food.carbsPer100)} g · '
              'Prot ${AppUtils.formatNumero(food.proteinsPer100)}${per(food.proteinsPer100)} g',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final added = await AddFoodPopup.showForToday(
                    context,
                    ref,
                    food,
                    initialQuantity: g,
                  );
                  if (added && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${food.name} añadido al día')),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(
                  g == null ? 'Registrar en el día' : 'Registrar porción',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
