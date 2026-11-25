import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../data/parsers/recipe_text_codec.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/services/ingredient_text.dart';
import '../providers/recipes_provider.dart';
import '../widgets/add_to_shopping_list_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/recipe_nutrition_card.dart';
import 'cook_mode_view.dart';
import 'recipe_actions.dart';
import 'recipe_form_view.dart';
import 'recipe_link_view.dart';

/// Detalle de una receta: nutrición calculada de sus ingredientes (con lo
/// que falta para calcularla), ingredientes con su vínculo al repertorio
/// (marcando los que el usuario tiene si viene de una búsqueda), pasos y
/// acciones (cocinar, lista de compra, copiar, editar, borrar).
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
        content: Text(
          '¿Eliminar "${r.nombre}"?'
          '${r.alimentoId == null ? '' : ' Su alimento se queda en tus alimentos y se puede seguir registrando en el día.'}',
        ),
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
              onSelected: (v) async {
                if (v == 'cooked') {
                  await ref
                      .read(recipeRepositoryProvider)
                      .setLastPrepared(recipe.id!, DateTime.now());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marcada como preparada hoy'),
                      ),
                    );
                  }
                }
                if (!context.mounted) return;
                if (v == 'link') RecipeLinkView.open(context, recipe);
                if (v == 'copy') _copy(context, recipe);
                if (v == 'delete') _delete(context, ref, recipe);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'cooked',
                  child: Text('La he preparado hoy'),
                ),
                PopupMenuItem(
                  value: 'link',
                  child: Text('Vincular ingredientes'),
                ),
                PopupMenuItem(value: 'copy', child: Text('Copiar como texto')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ],
      ),
      floatingActionButton: recipe == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'cocinar',
              onPressed: () => CookModeView.open(
                context,
                recipe.id!,
                factor: ref.read(recipeScaleProvider(recipe.id!)),
              ),
              icon: const Icon(Icons.soup_kitchen),
              label: const Text('Cocinar'),
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
          );
        },
      ),
    );
  }
}

class _RecipeBody extends ConsumerWidget {
  final Recipe recipe;
  final IngredientAvailability? availability;

  const _RecipeBody({required this.recipe, required this.availability});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final r = recipe;
    final av = availability;
    final pasos = r.pasos;
    final analisis = ref.watch(recipeAnalysisProvider(r.id!)).valueOrNull;
    final alimentos = analisis?.alimentos ?? const <int, Food>{};
    final factor = ref.watch(recipeScaleProvider(r.id!));

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
        : r.lineas.where((l) => !av.covers(l)).toSet();

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (meta.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(spacing: 8, runSpacing: 4, children: meta),
          ),
        if (analisis != null)
          RecipeNutritionCard(analisis: analisis, factor: factor),
        SectionTitle('Ingredientes (${r.ingredientes.length})'),
        _ScaleControl(receta: r, factor: factor),
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
        for (var i = 0; i < r.ingredientes.length; i++)
          _ingredientTile(context, ref, r, i, alimentos, av, theme, factor),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            onPressed: r.ingredientes.isEmpty
                ? null
                : () => AddToShoppingListDialog.show(
                    context,
                    ingredientes: r.ingredientes,
                    preseleccionados: faltantes,
                    factor: factor,
                    textos: [
                      for (final ing in r.ingredientes)
                        _texto(ing, alimentos, factor),
                    ],
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
          for (var i = 0; i < pasos.length; i++)
            Padding(
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
            ),
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

  Widget _ingredientTile(
    BuildContext context,
    WidgetRef ref,
    Recipe r,
    int i,
    Map<int, Food> alimentos,
    IngredientAvailability? av,
    ThemeData theme,
    double factor,
  ) {
    final ing = r.ingredientes[i];
    final linea = ing.texto;
    final tiene = av?.covers(linea);
    final food = ing.alimentoId == null ? null : alimentos[ing.alimentoId];
    // Un opcional que falta no se marca en rojo: no es imprescindible.
    final faltaColor = (ing.opcional || parseIngredientLine(linea).opcional)
        ? AppStyles.neutral
        : AppStyles.semaphRed;
    final Widget leading;
    if (tiene != null) {
      leading = Icon(
        tiene ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 22,
        color: tiene ? AppStyles.semaphGreen : faltaColor,
      );
    } else {
      leading = Icon(
        food == null
            ? Icons.circle
            : (food.pendiente ? Icons.error_outline : Icons.link),
        size: food == null ? 8 : 20,
        color: food == null
            ? theme.colorScheme.primary
            : (food.pendiente ? AppStyles.semaphOrange : AppStyles.semaphGreen),
      );
    }
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: SizedBox(width: 24, child: Center(child: leading)),
      title: Text(
        _texto(ing, alimentos, factor),
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: food == null
          ? null
          : Text(
              '→ ${food.nombreCompleto}${food.pendiente ? ' (pendiente)' : ''}',
              style: AppStyles.labelText,
            ),
      onTap: () => RecipeActions.edit(
        context,
        ref,
        r,
        i,
        alimento: food,
        porciones: food == null
            ? const []
            : ref
                      .read(recipeAnalysisProvider(r.id!))
                      .valueOrNull
                      ?.porciones[food.id] ??
                  const [],
      ),
    );
  }
}

/// Texto de la línea con la escala aplicada.
String _texto(RecipeIngredient ing, Map<int, Food> alimentos, double factor) {
  final f = ing.alimentoId == null ? null : alimentos[ing.alimentoId];
  return scaledIngredientText(
    texto: ing.texto,
    factor: factor,
    nombreAlimento: f?.nombre,
    cantidad: ing.cantidad,
    unidad: ing.unidad,
    nota: ing.nota,
    opcional: ing.opcional,
  );
}

/// Escala de la receta: por raciones si se conocen, si no por factor
/// (×½, ×1, ×1½, ×2...). Las cantidades, la lista de compra y el modo
/// cocina la usan.
class _ScaleControl extends ConsumerWidget {
  final Recipe receta;
  final double factor;

  const _ScaleControl({required this.receta, required this.factor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recipeScaleProvider(receta.id!).notifier);
    final porciones = receta.porciones;
    final String etiqueta;
    final double? menos;
    final double mas;
    if (porciones != null && porciones > 0) {
      final n = (factor * porciones).round();
      etiqueta = '$n ${n == 1 ? 'ración' : 'raciones'}';
      menos = n > 1 ? (n - 1) / porciones : null;
      mas = (n + 1) / porciones;
    } else {
      etiqueta = '×${formatQuantity(factor)}';
      menos = factor > 0.5 ? factor - 0.5 : null;
      mas = factor + 0.5;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.tune, size: 18, color: AppStyles.neutral),
          const SizedBox(width: 6),
          const Text('Cantidades para', style: AppStyles.labelText),
          IconButton(
            tooltip: 'Menos',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: menos == null ? null : () => notifier.state = menos!,
          ),
          Text(etiqueta, key: const Key('escala_receta')),
          IconButton(
            tooltip: 'Más',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => notifier.state = mas,
          ),
          if (factor != 1)
            TextButton(
              onPressed: () => notifier.state = 1,
              child: const Text('Original'),
            ),
        ],
      ),
    );
  }
}
