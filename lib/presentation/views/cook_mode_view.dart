import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/ingredient_text.dart';
import '../providers/recipes_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/final_weight_dialog.dart';
import '../widgets/food_widgets.dart';
import '../widgets/recipe_nutrition_card.dart';

/// Modo cocina: la receta paso a paso con letra grande. La primera página
/// reúne los ingredientes y, si falta algún dato nutricional, lo pide sin
/// bloquear (es el momento ideal: el envase está en la mano para leer la
/// etiqueta). Al terminar pide el peso final (descontando la olla) y marca
/// la receta como preparada hoy. Con [factor] muestra las cantidades
/// escaladas.
class CookModeView extends ConsumerStatefulWidget {
  final int recipeId;

  /// Escala de las cantidades (×2 = el doble de todo).
  final double factor;

  const CookModeView({super.key, required this.recipeId, this.factor = 1});

  static Future<void> open(
    BuildContext context,
    int recipeId, {
    double factor = 1,
  }) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CookModeView(recipeId: recipeId, factor: factor),
    ),
  );

  @override
  ConsumerState<CookModeView> createState() => _CookModeViewState();
}

class _CookModeViewState extends ConsumerState<CookModeView> {
  final _pages = PageController();
  final Set<int> _preparados = {};
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Al cerrar desde la última página: preparada hoy.
  Future<void> _finish() async {
    await ref
        .read(recipeRepositoryProvider)
        .setLastPrepared(widget.recipeId, DateTime.now());
    if (mounted) Navigator.pop(context);
  }

  String _linea(RecipeIngredient ing, Map<int, Food> alimentos) {
    final f = ing.alimentoId == null ? null : alimentos[ing.alimentoId];
    return scaledIngredientText(
      texto: ing.texto,
      factor: widget.factor,
      nombreAlimento: f?.nombre,
      cantidad: ing.cantidad,
      unidad: ing.unidad,
      nota: ing.nota,
      opcional: ing.opcional,
    );
  }

  void _go(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final analisis = ref
        .watch(recipeAnalysisProvider(widget.recipeId))
        .valueOrNull;
    final theme = Theme.of(context);
    if (analisis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cocinar')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final r = analisis.receta;
    final pasos = r.pasos;
    final total = pasos.length + 2; // ingredientes + pasos + final

    final pages = <Widget>[
      ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (analisis.nutricion.issues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InfoBanner(
                color: AppStyles.semaphBlue,
                icon: Icons.document_scanner_outlined,
                text:
                    'Mientras cocinas, aprovecha para completar los datos que '
                    'faltan (puedes leer la etiqueta del envase).',
              ),
            ),
          RecipeNutritionCard(analisis: analisis, acciones: false),
          if (widget.factor != 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InfoBanner(
                color: AppStyles.semaphBlue,
                icon: Icons.tune,
                text:
                    'Cantidades a ×${AppUtils.formatNumero(widget.factor)} '
                    'de la receta.',
              ),
            ),
          const SectionTitle('Ingredientes'),
          for (var i = 0; i < r.ingredientes.length; i++)
            CheckboxListTile(
              value: _preparados.contains(i),
              onChanged: (v) => setState(
                () => v == true ? _preparados.add(i) : _preparados.remove(i),
              ),
              title: Text(
                _linea(r.ingredientes[i], analisis.alimentos),
                style: TextStyle(
                  fontSize: 18,
                  decoration: _preparados.contains(i)
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
      for (var i = 0; i < pasos.length; i++)
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppStyles.paddingLarge),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppStyles.primary,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  pasos[i],
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ListView(
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.celebration_outlined,
            size: 64,
            color: AppStyles.semaphGreen,
          ),
          const SizedBox(height: 12),
          Text(
            '¡Listo!',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FilledButton.icon(
              onPressed: () => FinalWeightDialog.askAndSave(
                context,
                ref,
                r,
                factor: widget.factor,
              ),
              icon: const Icon(Icons.scale_outlined),
              label: Text(
                analisis.nutricion.pesoFinalConocido
                    ? 'Volver a pesar la preparación'
                    : 'Pesar la preparación',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              'Pésala recién hecha (descontando la olla): así la tabla de su '
              'alimento es exacta.',
              textAlign: TextAlign.center,
              style: AppStyles.labelText,
            ),
          ),
          RecipeNutritionCard(analisis: analisis, factor: widget.factor),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(r.nombre),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_page + 1) / total),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (p) => setState(() => _page = p),
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: _page == 0 ? null : () => _go(_page - 1),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Anterior'),
              ),
              const Spacer(),
              Text(
                _page == 0
                    ? 'Ingredientes'
                    : (_page <= pasos.length
                          ? 'Paso $_page de ${pasos.length}'
                          : 'Fin'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _page >= total - 1 ? _finish : () => _go(_page + 1),
                icon: Icon(
                  _page >= total - 1 ? Icons.check : Icons.chevron_right,
                ),
                label: Text(_page >= total - 1 ? 'Cerrar' : 'Siguiente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
