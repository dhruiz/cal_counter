import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../providers/recipes_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/food_widgets.dart';
import '../widgets/recipe_nutrition_card.dart';

/// Modo cocina: la receta paso a paso con letra grande. La primera página
/// reúne los ingredientes y, si falta algún dato nutricional, lo pide sin
/// bloquear (es el momento ideal: el envase está en la mano para leer la
/// etiqueta). Al terminar se puede registrar una porción.
class CookModeView extends ConsumerStatefulWidget {
  final int recipeId;

  const CookModeView({super.key, required this.recipeId});

  static Future<void> open(BuildContext context, int recipeId) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CookModeView(recipeId: recipeId)),
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
          const SectionTitle('Ingredientes'),
          for (var i = 0; i < r.ingredientes.length; i++)
            CheckboxListTile(
              value: _preparados.contains(i),
              onChanged: (v) => setState(
                () => v == true ? _preparados.add(i) : _preparados.remove(i),
              ),
              title: Text(
                r.ingredientes[i].texto,
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
          RecipeNutritionCard(analisis: analisis),
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
                onPressed: _page >= total - 1
                    ? () => Navigator.pop(context)
                    : () => _go(_page + 1),
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
