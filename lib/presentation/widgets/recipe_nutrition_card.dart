import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/services/nutrition_calculator.dart';
import '../providers/recipes_provider.dart';
import '../views/food_flows.dart';
import '../views/recipe_actions.dart';
import '../views/recipe_link_view.dart';

/// Nutrición calculada de una receta. Si falta algo, lista qué falta con una
/// acción directa para cada caso (vincular, completar la tabla con la
/// etiqueta, añadir el peso de una porción...).
class RecipeNutritionCard extends ConsumerWidget {
  final RecipeAnalysis analisis;

  /// Muestra los botones de registrar/añadir al repertorio.
  final bool acciones;

  const RecipeNutritionCard({
    super.key,
    required this.analisis,
    this.acciones = true,
  });

  Future<void> _saveAsFood(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(saveRecipeAsFoodProvider)(
        analisis.receta,
        analisis.nutricion,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '"${analisis.receta.nombre}" está en tus alimentos (preparado).',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = analisis.nutricion;
    final receta = analisis.receta;
    final theme = Theme.of(context);
    final porPorcion = n.porPorcion;
    final por100 = n.por100;
    final sinVincular = receta.ingredientes.any(
      (i) => !i.vinculado && !i.opcional,
    );

    String linea(NutritionFacts f) {
      String v(double? x) => x == null ? '—' : AppUtils.formatNumero(x);
      return '${v(f.kcal)} kcal · G ${v(f.grasas)} · C ${v(f.carbohidratos)} '
          '· P ${v(f.proteinas)}';
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  n.completa
                      ? Icons.local_fire_department
                      : Icons.local_fire_department_outlined,
                  color: n.completa ? AppStyles.ringKcal : AppStyles.neutral,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    n.completa ? 'Nutrición' : 'Nutrición (incompleta)',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (n.tieneDatos) ...[
              if (porPorcion != null)
                Text(
                  '${n.completa ? '' : '≥ '}Por porción'
                  '${n.pesoPorcion == null ? '' : ' (${AppUtils.formatNumero(n.pesoPorcion!)} g)'}: '
                  '${linea(porPorcion)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              if (por100 != null)
                Text('${n.completa ? '' : '≥ '}Por 100 g: ${linea(por100)}'),
              Text(
                'Total: ${AppUtils.formatNumero(n.total.kcal ?? 0)} kcal en '
                '${AppUtils.formatNumero(n.peso)} g'
                '${receta.pesoFinalG == null ? ' (suma de ingredientes)' : ' (peso final)'}',
                style: AppStyles.labelText,
              ),
            ] else
              const Text(
                'Vincula los ingredientes a tus alimentos (con su cantidad) '
                'para calcular las calorías.',
              ),
            if (n.issues.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Para calcular las calorías faltan:',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppStyles.semaphOrange,
                ),
              ),
              for (final issue in n.issues)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _icon(issue.tipo),
                    color: AppStyles.semaphOrange,
                  ),
                  title: Text(
                    issue.alimento?.nombreCompleto ?? issue.ingrediente.texto,
                  ),
                  subtitle: Text(issue.descripcion),
                  trailing: TextButton(
                    onPressed: () =>
                        RecipeActions.resolve(context, ref, analisis, issue),
                    child: Text(_accion(issue.tipo)),
                  ),
                ),
              if (sinVincular)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => RecipeLinkView.open(context, receta),
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Vincular automáticamente'),
                  ),
                ),
            ],
            if (acciones && n.completa) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      final food = analisis.comoAlimento;
                      if (food == null) return;
                      final ok = await FoodFlows.registerIntake(
                        context,
                        ref,
                        food,
                        initialQuantity: n.pesoPorcion,
                      );
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${receta.nombre} añadido al día'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(
                      n.pesoPorcion == null
                          ? 'Registrar en el día'
                          : 'Registrar porción',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _saveAsFood(context, ref),
                    icon: const Icon(Icons.kitchen_outlined),
                    label: Text(
                      receta.alimentoId == null
                          ? 'Añadir a mis alimentos'
                          : 'Actualizar en mis alimentos',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _icon(IngredientIssueKind k) => switch (k) {
    IngredientIssueKind.sinVincular => Icons.link_off,
    IngredientIssueKind.alimentoNoEncontrado => Icons.link_off,
    IngredientIssueKind.sinCantidad => Icons.scale_outlined,
    IngredientIssueKind.unidadSinEquivalencia => Icons.straighten,
    IngredientIssueKind.alimentoPendiente => Icons.document_scanner_outlined,
  };

  static String _accion(IngredientIssueKind k) => switch (k) {
    IngredientIssueKind.sinVincular => 'Vincular',
    IngredientIssueKind.alimentoNoEncontrado => 'Vincular',
    IngredientIssueKind.sinCantidad => 'Cantidad',
    IngredientIssueKind.unidadSinEquivalencia => 'Añadir peso',
    IngredientIssueKind.alimentoPendiente => 'Completar',
  };
}
