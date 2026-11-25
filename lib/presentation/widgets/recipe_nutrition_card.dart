import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/services/nutrition_calculator.dart';
import '../../domain/usecases/recipe_food.dart';
import '../providers/recipes_provider.dart';
import '../views/food_detail_view.dart';
import '../views/food_flows.dart';
import '../views/recipe_actions.dart';
import '../views/recipe_link_view.dart';
import 'final_weight_dialog.dart';
import 'food_widgets.dart';

/// Nutrición calculada de una receta y su alimento en el repertorio.
///
/// - Por 100 g es la tabla del alimento «Nombre · Receta», que se registra
///   en el contador como cualquier otro.
/// - Sin peso final se calcula con el peso de los ingredientes en crudo y
///   se marca como aproximada, con un botón para introducir el peso.
/// - Si falta algún dato de los ingredientes, se calcula con lo que hay y se
///   lista qué falta con una acción directa para cada caso.
class RecipeNutritionCard extends ConsumerWidget {
  final RecipeAnalysis analisis;

  /// Muestra los botones (registrar, peso final...).
  final bool acciones;

  /// Escala con la que se está cocinando (para el peso final).
  final double factor;

  const RecipeNutritionCard({
    super.key,
    required this.analisis,
    this.acciones = true,
    this.factor = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = analisis.nutricion;
    final receta = analisis.receta;
    final theme = Theme.of(context);
    final porPorcion = n.porPorcion;
    final por100 = n.por100;
    final alimento = analisis.alimentoReceta;
    final sinVincular = receta.ingredientes.any(
      (i) => !i.vinculado && !i.opcional,
    );

    String linea(NutritionFacts f) {
      String v(double? x) => x == null ? '—' : AppUtils.formatNumero(x);
      return '${v(f.kcal)} kcal · G ${v(f.grasas)} · C ${v(f.carbohidratos)} '
          '· P ${v(f.proteinas)}';
    }

    final titulo = !n.tieneDatos
        ? 'Nutrición'
        : (n.exacta ? 'Nutrición' : 'Nutrición (aproximada)');
    final aprox = n.exacta ? '' : '≈ ';

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
                  n.exacta
                      ? Icons.local_fire_department
                      : Icons.local_fire_department_outlined,
                  color: n.exacta ? AppStyles.ringKcal : AppStyles.neutral,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(titulo, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (n.tieneDatos) ...[
              if (por100 != null)
                Text(
                  '${aprox}Por 100 g: ${linea(por100)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              if (porPorcion != null)
                Text(
                  '${aprox}Por porción'
                  '${n.pesoPorcion == null ? '' : ' (${AppUtils.formatNumero(n.pesoPorcion!)} g)'}: '
                  '${linea(porPorcion)}',
                ),
              Text(
                'Total: ${AppUtils.formatNumero(n.total.kcal ?? 0)} kcal en '
                '${AppUtils.formatNumero(n.peso)} g'
                '${n.pesoFinalConocido ? ' (peso final)' : ' (ingredientes en crudo)'}',
                style: AppStyles.labelText,
              ),
            ] else
              const Text(
                'Añade los ingredientes desde tus alimentos, con su cantidad, '
                'para calcular las calorías.',
              ),
            if (n.tieneDatos) _pesoFinal(context, ref, theme),
            if (n.issues.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                n.tieneDatos
                    ? 'Para un cálculo exacto faltan:'
                    : 'Para calcular las calorías faltan:',
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
                  trailing: _accion(issue.tipo) == null
                      ? null
                      : TextButton(
                          onPressed: () => RecipeActions.resolve(
                            context,
                            ref,
                            analisis,
                            issue,
                          ),
                          child: Text(_accion(issue.tipo)!),
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
            if (acciones) _alimento(context, ref, theme),
            if (acciones && alimento != null && !alimento.pendiente) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  final ok = await FoodFlows.registerIntake(
                    context,
                    ref,
                    alimento,
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
                label: const Text('Registrar en el día'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Peso final: aviso si falta (valor aproximado) o el peso guardado.
  Widget _pesoFinal(BuildContext context, WidgetRef ref, ThemeData theme) {
    final receta = analisis.receta;
    final n = analisis.nutricion;
    final pedir = acciones
        ? TextButton(
            onPressed: () => FinalWeightDialog.askAndSave(
              context,
              ref,
              receta,
              factor: factor,
            ),
            child: Text(n.pesoFinalConocido ? 'Cambiar' : 'Introducir'),
          )
        : null;
    if (!n.pesoFinalConocido) {
      return InfoBanner(
        color: AppStyles.semaphOrange,
        icon: Icons.scale_outlined,
        text:
            'Valor aproximado: falta el peso final de la preparación. Se '
            'calcula con los ingredientes en crudo; cuando termines, pésala '
            '(descontando la olla) para un valor exacto.',
        action: pedir,
      );
    }
    final fecha = receta.ultimaPreparacion;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.scale_outlined, size: 18, color: AppStyles.neutral),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Peso final: ${AppUtils.formatNumero(receta.pesoFinalG!)} g'
              '${fecha == null ? '' : ' · preparada el ${DateFormat('d/M/y').format(fecha)}'}',
              style: AppStyles.labelText,
            ),
          ),
          ?pedir,
        ],
      ),
    );
  }

  /// Estado del alimento de la receta en el repertorio.
  Widget _alimento(BuildContext context, WidgetRef ref, ThemeData theme) {
    final alimento = analisis.alimentoReceta;
    final conflicto = analisis.conflicto;
    final n = analisis.nutricion;
    if (alimento != null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: const Icon(Icons.kitchen_outlined),
        title: Text('En tus alimentos como «${alimento.nombreCompleto}»'),
        subtitle: Text(
          alimento.pendiente
              ? 'Aún no se puede contar: faltan datos esenciales.'
              : (alimento.aproximado
                    ? 'Búscalo en Calorías y apunta los gramos de tu plato. '
                          'Su tabla es aproximada.'
                    : 'Búscalo en Calorías y apunta los gramos de tu plato.'),
        ),
        onTap: () => FoodDetailView.open(context, alimento.id!),
      );
    }
    if (conflicto != null) {
      return InfoBanner(
        color: AppStyles.semaphRed,
        icon: Icons.warning_amber_outlined,
        text:
            'Ya existe el alimento «${conflicto.nombreCompleto}» y no es de '
            'esta receta, así que no se ha tocado. Cambia el nombre de la '
            'receta para crear su alimento.',
      );
    }
    if (n.tieneDatos) {
      return InfoBanner(
        color: AppStyles.semaphBlue,
        icon: Icons.info_outline,
        text:
            'Se añadirá a tus alimentos como «${analisis.receta.nombre.trim()} '
            '· $kMarcaReceta» en cuanto se conozcan sus kcal, proteínas, grasas '
            'y carbohidratos.',
      );
    }
    return const SizedBox.shrink();
  }

  static IconData _icon(IngredientIssueKind k) => switch (k) {
    IngredientIssueKind.sinVincular => Icons.link_off,
    IngredientIssueKind.alimentoNoEncontrado => Icons.link_off,
    IngredientIssueKind.sinCantidad => Icons.scale_outlined,
    IngredientIssueKind.unidadSinEquivalencia => Icons.straighten,
    IngredientIssueKind.alimentoPendiente => Icons.document_scanner_outlined,
    IngredientIssueKind.circular => Icons.loop,
  };

  static String? _accion(IngredientIssueKind k) => switch (k) {
    IngredientIssueKind.sinVincular => 'Vincular',
    IngredientIssueKind.alimentoNoEncontrado => 'Vincular',
    IngredientIssueKind.sinCantidad => 'Cantidad',
    IngredientIssueKind.unidadSinEquivalencia => 'Añadir peso',
    IngredientIssueKind.alimentoPendiente => 'Completar',
    IngredientIssueKind.circular => 'Cambiar',
  };
}
