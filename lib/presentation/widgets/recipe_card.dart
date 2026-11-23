import 'package:flutter/material.dart';
import '../../core/styles.dart';
import '../../data/parsers/recipe_text_codec.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_match.dart';
import '../../domain/services/ingredient_matcher.dart';

/// Tarjeta de receta. Con [match] muestra cuántos ingredientes tiene el
/// usuario y cuáles le faltan.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final RecipeMatch? match;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.match,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = match;
    final meta = <Widget>[
      if ((recipe.categoria ?? '').isNotEmpty)
        _Meta(Icons.label_outline, recipe.categoria!),
      if (recipe.tiempoMin != null)
        _Meta(
          Icons.timer_outlined,
          RecipeTextCodec.formatMinutes(recipe.tiempoMin!),
        ),
      if (recipe.porciones != null)
        _Meta(Icons.people_outline, '${recipe.porciones}'),
      _Meta(Icons.format_list_bulleted, '${recipe.ingredientes.length} ingr.'),
      if (recipe.ingredientes.isNotEmpty &&
          recipe.ingredientes.every((i) => i.vinculado || i.opcional))
        const _Meta(Icons.local_fire_department_outlined, 'calculable')
      else if (recipe.ingredientes.any((i) => i.vinculado))
        _Meta(
          Icons.link,
          '${recipe.ingredientes.where((i) => i.vinculado).length}/'
          '${recipe.ingredientes.length} vinculados',
        ),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (recipe.favorita)
                    Icon(Icons.star, color: Colors.amber[700], size: 20),
                  if (m != null && m.completa) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.semaphGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '¡Puedes hacerla!',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Wrap(spacing: 12, runSpacing: 4, children: meta),
              if (m != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: m.cobertura,
                    minHeight: 6,
                    color: m.completa
                        ? AppStyles.semaphGreen
                        : AppStyles.semaphOrange,
                    backgroundColor: Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tienes ${m.disponibles.length} de ${m.totalRequeridos} ingredientes',
                  style: AppStyles.labelText,
                ),
                if (m.faltantes.isNotEmpty)
                  Text(
                    'Te falta: ${_resumen(m.faltantes)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppStyles.semaphRed,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _resumen(List<String> lineas) {
    final nombres = lineas
        .map((l) => parseIngredientLine(l).nombre.toLowerCase())
        .toList();
    if (nombres.length <= 3) return nombres.join(', ');
    return '${nombres.take(3).join(', ')} y ${nombres.length - 3} más';
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppStyles.neutral),
        const SizedBox(width: 3),
        Text(text, style: AppStyles.labelText),
      ],
    );
  }
}
