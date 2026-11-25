import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/services/quantity_parser.dart';
import '../providers/recipes_provider.dart';
import '../widgets/food_widgets.dart';
import 'food_picker_view.dart';

/// Vinculación asistida: propone un alimento del repertorio para cada línea
/// sin vincular (con la cantidad que se lee en la línea). El usuario marca
/// cuáles acepta, cambia las que no encajan y guarda.
///
/// Con [guardar] en false no escribe en la base de datos: devuelve los
/// ingredientes con los vínculos (formulario de una receta sin guardar).
class RecipeLinkView extends ConsumerStatefulWidget {
  final Recipe receta;
  final bool guardar;

  const RecipeLinkView({super.key, required this.receta, this.guardar = true});

  static Future<void> open(BuildContext context, Recipe receta) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeLinkView(receta: receta)),
      );

  /// Propone vínculos para [receta] y devuelve sus ingredientes vinculados
  /// (null si se cancela), sin guardar.
  static Future<List<RecipeIngredient>?> review(
    BuildContext context,
    Recipe receta,
  ) => Navigator.push<List<RecipeIngredient>>(
    context,
    MaterialPageRoute(
      builder: (_) => RecipeLinkView(receta: receta, guardar: false),
    ),
  );

  @override
  ConsumerState<RecipeLinkView> createState() => _RecipeLinkViewState();
}

class _Propuesta {
  Food? alimento;
  double? cantidad;
  String? unidad;
  bool aceptada;

  _Propuesta({
    this.alimento,
    this.cantidad,
    this.unidad,
    this.aceptada = false,
  });
}

class _RecipeLinkViewState extends ConsumerState<RecipeLinkView> {
  final Map<int, _Propuesta> _propuestas = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sugerencias = await ref.read(suggestIngredientLinksProvider)(
      widget.receta,
    );
    if (!mounted) return;
    setState(() {
      for (final s in sugerencias) {
        _propuestas[s.indice] = _Propuesta(
          alimento: s.alimento,
          cantidad: s.cantidad,
          unidad: s.unidad,
          aceptada: true,
        );
      }
      _loading = false;
    });
  }

  Future<void> _choose(int i) async {
    final ing = widget.receta.ingredientes[i];
    final food = await FoodPickerView.pick(
      context,
      initialQuery: parseIngredientLine(ing.texto).nombre,
      title: 'Vincular «${ing.texto}»',
      soloAlimentos: true,
      excluir: {?widget.receta.alimentoId},
    );
    if (food == null) return;
    final q = parseQuantity(ing.texto);
    setState(() {
      _propuestas[i] = _Propuesta(
        alimento: food,
        cantidad: q?.cantidad,
        unidad: q == null
            ? null
            : (q.esMasa || q.esVolumen ? food.unidad.clave : q.unidad),
        aceptada: true,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final list = [
      for (var i = 0; i < widget.receta.ingredientes.length; i++)
        () {
          final ing = widget.receta.ingredientes[i];
          final p = _propuestas[i];
          if (ing.vinculado || p == null || !p.aceptada || p.alimento == null) {
            return ing;
          }
          return ing.copyWith(
            alimentoId: p.alimento!.id,
            cantidad: p.cantidad,
            unidad: p.unidad,
          );
        }(),
    ];
    if (!widget.guardar) {
      Navigator.pop(context, list);
      return;
    }
    await ref.read(saveRecipeProvider)(
      widget.receta.copyWith(ingredientes: list),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ings = widget.receta.ingredientes;
    final aceptadas = _propuestas.values.where((p) => p.aceptada).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular ingredientes'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Revisa las propuestas: marca las correctas y toca una '
                    'línea para elegir otro alimento o crearlo. El texto de '
                    'la receta no cambia.',
                  ),
                ),
                for (var i = 0; i < ings.length; i++) _tile(i, ings[i]),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _saving || _loading ? null : _save,
            icon: const Icon(Icons.link),
            label: Text(
              aceptadas == 0
                  ? 'Guardar'
                  : 'Vincular $aceptadas '
                        '${aceptadas == 1 ? 'ingrediente' : 'ingredientes'}',
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(int i, RecipeIngredient ing) {
    if (ing.vinculado) {
      return ListTile(
        leading: const Icon(Icons.check_circle, color: AppStyles.semaphGreen),
        title: Text(ing.texto),
        subtitle: const Text('Ya vinculado'),
      );
    }
    final p = _propuestas[i];
    final f = p?.alimento;
    return ListTile(
      leading: f == null
          ? const Icon(Icons.help_outline, color: AppStyles.neutral)
          : Checkbox(
              value: p!.aceptada,
              onChanged: (v) => setState(() => p.aceptada = v ?? false),
            ),
      title: Text(ing.texto),
      subtitle: f == null
          ? const Text('Sin propuesta · toca para elegir')
          : Row(
              children: [
                Flexible(
                  child: Text(
                    '→ ${f.nombreCompleto}'
                    '${p!.cantidad == null ? '' : ' · ${AppUtils.formatNumero(p.cantidad!)} ${p.unidad ?? f.u}'}',
                  ),
                ),
                if (f.pendiente) ...[
                  const SizedBox(width: 6),
                  const PendingChip(),
                ],
              ],
            ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _choose(i),
    );
  }
}
