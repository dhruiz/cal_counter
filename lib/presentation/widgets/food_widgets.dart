import 'package:flutter/material.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/entities/recipe.dart';

/// Distintivo "Pendiente" para alimentos sin tabla nutricional completa.
class PendingChip extends StatelessWidget {
  final bool dense;

  const PendingChip({super.key, this.dense = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppStyles.semaphOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppStyles.semaphOrange.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        'Pendiente',
        style: TextStyle(
          fontSize: dense ? 11 : 13,
          color: AppStyles.semaphOrange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Distintivo pequeño con texto y color ("Aproximado", "No alimentario").
class TagChip extends StatelessWidget {
  final String texto;
  final Color color;

  const TagChip(this.texto, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Distintivo "Aproximado": tabla de una receta sin peso final o con
/// ingredientes sin datos.
class ApproxChip extends StatelessWidget {
  const ApproxChip({super.key});

  @override
  Widget build(BuildContext context) =>
      const TagChip('Aproximado', color: AppStyles.semaphBlue);
}

/// Distintivo de un artículo que no es un alimento (limpieza, higiene...).
class NonFoodChip extends StatelessWidget {
  const NonFoodChip({super.key});

  @override
  Widget build(BuildContext context) =>
      const TagChip('No alimentario', color: AppStyles.neutral);
}

/// Por qué es aproximada la tabla del alimento de una receta.
String aproximadoMotivo(Recipe? receta) {
  if (receta == null) {
    return 'Valor aproximado: es el alimento de una receta sin peso final o '
        'con ingredientes sin datos.';
  }
  if (receta.pesoFinalG == null) {
    return 'Valor aproximado: no se ha introducido el peso total final de '
        '«${receta.nombre}». Para un valor más preciso, introdúcelo en la '
        'receta.';
  }
  return 'Valor aproximado: a algún ingrediente de «${receta.nombre}» le '
      'faltan datos. Para un valor más preciso, complétalos en la receta.';
}

/// Resumen de una línea: "350 kcal · G 1 · C 78 · P 7 (por 100 g)".
String nutritionSummary(Food f) {
  final n = f.nutricion;
  if (!f.esAlimento) return 'Artículo que no es un alimento';
  if (n.estaVacia) return 'Sin tabla nutricional';
  String v(double? x) => x == null ? '—' : AppUtils.formatNumero(x);
  return '${v(n.kcal)} kcal · G ${v(n.grasas)} · C ${v(n.carbohidratos)} · '
      'P ${v(n.proteinas)} (por 100 ${f.u})';
}

/// Fila de un alimento en listas y buscadores.
class FoodTile extends StatelessWidget {
  final Food food;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const FoodTile({
    super.key,
    required this.food,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  IconData get _icon => !food.esAlimento
      ? Icons.cleaning_services_outlined
      : switch (food.tipo) {
          FoodType.envasado => Icons.qr_code_2,
          FoodType.preparado => Icons.soup_kitchen_outlined,
          FoodType.generico => Icons.eco_outlined,
        };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_icon, color: AppStyles.neutral),
      title: Row(
        children: [
          Flexible(child: Text(food.nombre, overflow: TextOverflow.ellipsis)),
          if (food.pendiente) ...[
            const SizedBox(width: 6),
            const PendingChip(),
          ] else if (food.aproximado) ...[
            const SizedBox(width: 6),
            const ApproxChip(),
          ],
          if (!food.esAlimento) ...[
            const SizedBox(width: 6),
            const NonFoodChip(),
          ],
        ],
      ),
      subtitle: Text(
        [
          if (food.marca.isNotEmpty) food.marca,
          nutritionSummary(food),
        ].join('\n'),
        style: AppStyles.labelText,
      ),
      isThreeLine: food.marca.isNotEmpty,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// Tabla nutricional (orden de la etiqueta UE). Los desconocidos se muestran
/// como "—" y, si faltan esenciales, se resalta qué falta.
class NutritionTable extends StatelessWidget {
  final NutritionFacts nutricion;
  final String unidad;

  /// Si se indica, se añade una columna con la porción ("por 60 g").
  final double? gramosPorcion;

  const NutritionTable({
    super.key,
    required this.nutricion,
    this.unidad = 'g',
    this.gramosPorcion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final porcion = gramosPorcion;
    String fmt(double? v) => v == null ? '—' : AppUtils.formatNumero(v);
    final header = TextStyle(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Table(
      columnWidths: {
        0: const FlexColumnWidth(3),
        1: const FlexColumnWidth(1.4),
        if (porcion != null) 2: const FlexColumnWidth(1.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            Text('100 $unidad', style: header, textAlign: TextAlign.right),
            if (porcion != null)
              Text(
                '${AppUtils.formatNumero(porcion)} $unidad',
                style: header,
                textAlign: TextAlign.right,
              ),
          ],
        ),
        for (final n in Nutrient.values)
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: n.esSubcategoria ? 16 : 0,
                  top: 4,
                  bottom: 4,
                ),
                child: Text(
                  n.etiqueta,
                  style: TextStyle(
                    fontWeight: n.esencial ? FontWeight.w600 : null,
                    color: n.esencial && nutricion[n] == null
                        ? AppStyles.semaphOrange
                        : null,
                  ),
                ),
              ),
              Text(
                '${fmt(nutricion[n])} ${nutricion[n] == null ? '' : n.unidad}',
                textAlign: TextAlign.right,
              ),
              if (porcion != null)
                Text(
                  nutricion[n] == null
                      ? '—'
                      : '${fmt(nutricion[n]! * porcion / 100)} ${n.unidad}',
                  textAlign: TextAlign.right,
                ),
            ],
          ),
      ],
    );
  }
}

/// Aviso con icono y color (información, avisos, éxito).
class InfoBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final Widget? action;

  const InfoBanner({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          ?action,
        ],
      ),
    );
  }
}
