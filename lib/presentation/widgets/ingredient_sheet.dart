import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/services/ingredient_text.dart';
import '../../domain/services/nutrition_calculator.dart';
import '../../domain/services/quantity_parser.dart';
import '../providers/foods_provider.dart';
import '../views/food_picker_view.dart';
import 'food_widgets.dart';

/// Resultado de la hoja de ingrediente: la línea guardada o quitarla.
class IngredientEdit {
  final RecipeIngredient? ingrediente;
  final bool quitar;

  const IngredientEdit.guardar(RecipeIngredient this.ingrediente)
    : quitar = false;
  const IngredientEdit.quitar() : ingrediente = null, quitar = true;
}

/// Ingrediente de una receta elegido desde el buscador (como en el
/// contador): alimento, cantidad en g/ml o en una de sus porciones ("2
/// dientes"), nota y opcional. El texto de la línea se genera solo.
class IngredientSheet extends ConsumerStatefulWidget {
  final Food alimento;

  /// Línea que se edita (null = nueva).
  final RecipeIngredient? ingrediente;

  /// Alimentos que no se ofrecen al cambiar (el de la propia receta).
  final Set<int> excluir;

  const IngredientSheet({
    super.key,
    required this.alimento,
    this.ingrediente,
    this.excluir = const {},
  });

  /// Elige un alimento en el buscador (solo alimentos) y abre la hoja.
  /// Con [ingrediente] sin vincular, busca por su nombre y propone la
  /// cantidad escrita en la línea.
  static Future<IngredientEdit?> pickAndEdit(
    BuildContext context, {
    RecipeIngredient? ingrediente,
    Set<int> excluir = const {},
  }) async {
    final texto = ingrediente?.texto ?? '';
    final food = await FoodPickerView.pick(
      context,
      initialQuery: texto.isEmpty ? '' : parseIngredientLine(texto).nombre,
      title: texto.isEmpty ? 'Añadir ingrediente' : 'Vincular «$texto»',
      soloAlimentos: true,
      excluir: excluir,
    );
    if (food == null || !context.mounted) return null;
    return show(
      context,
      alimento: food,
      ingrediente: ingrediente,
      excluir: excluir,
    );
  }

  static Future<IngredientEdit?> show(
    BuildContext context, {
    required Food alimento,
    RecipeIngredient? ingrediente,
    Set<int> excluir = const {},
  }) => showModalBottomSheet<IngredientEdit>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => IngredientSheet(
      alimento: alimento,
      ingrediente: ingrediente,
      excluir: excluir,
    ),
  );

  @override
  ConsumerState<IngredientSheet> createState() => _IngredientSheetState();
}

class _IngredientSheetState extends ConsumerState<IngredientSheet> {
  late Food _food;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _notaCtrl;
  late String _unidad;
  late bool _opcional;

  bool get _editando => widget.ingrediente?.vinculado ?? false;

  @override
  void initState() {
    super.initState();
    _food = widget.alimento;
    final ing = widget.ingrediente;
    final q = ing == null ? null : parseQuantity(ing.texto);
    final mismoAlimento = ing?.alimentoId == _food.id;
    final cantidad = (mismoAlimento ? ing?.cantidad : null) ?? q?.cantidad;
    _qtyCtrl = TextEditingController(
      text: cantidad == null ? '' : AppUtils.formatDecimalEditable(cantidad),
    );
    _notaCtrl = TextEditingController(text: ing?.nota ?? '');
    _unidad =
        (mismoAlimento ? ing?.unidad : null) ??
        (q == null || q.esMasa || q.esVolumen ? _food.u : q.unidad);
    _opcional =
        (ing?.opcional ?? false) ||
        (ing != null && parseIngredientLine(ing.texto).opcional);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  double? get _cantidad {
    final v = AppUtils.parseDecimal(_qtyCtrl.text);
    return (v == null || v <= 0) ? null : v;
  }

  Future<void> _cambiar() async {
    final f = await FoodPickerView.pick(
      context,
      initialQuery: _food.nombre,
      title: 'Cambiar alimento',
      soloAlimentos: true,
      excluir: widget.excluir,
    );
    if (f == null || !mounted) return;
    setState(() {
      _food = f;
      if (_unidad == 'g' || _unidad == 'ml') _unidad = f.u;
    });
  }

  Future<void> _nuevaPorcion() async {
    final res = await showDialog<FoodPortion>(
      context: context,
      builder: (_) => _PortionDialog(food: _food),
    );
    if (res == null || !mounted) return;
    try {
      await ref.read(foodRepositoryProvider).savePortion(res);
      if (mounted) setState(() => _unidad = res.nombre);
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    }
  }

  void _guardar() {
    final cantidad = _cantidad;
    final nota = _notaCtrl.text.trim();
    Navigator.pop(
      context,
      IngredientEdit.guardar(
        RecipeIngredient(
          id: widget.ingrediente?.id,
          texto: ingredientLine(
            nombreAlimento: _food.nombre,
            cantidad: cantidad,
            unidad: _unidad,
            nota: nota,
            opcional: _opcional,
          ),
          alimentoId: _food.id,
          cantidad: cantidad,
          unidad: _unidad,
          opcional: _opcional,
          nota: nota.isEmpty ? null : nota,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = _food;
    final porciones =
        ref.watch(foodPortionsProvider(food.id!)).valueOrNull ?? const [];
    final unidades = <String>{food.u, for (final p in porciones) p.nombre};
    if (!unidades.contains(_unidad)) unidades.add(_unidad);
    final cantidad = _cantidad;
    final gramos = cantidad == null
        ? null
        : gramsForIngredient(
            RecipeIngredient(
              texto: '',
              alimentoId: food.id,
              cantidad: cantidad,
              unidad: _unidad,
            ),
            food,
            porciones,
          );
    final kcal = food.nutricion.kcal;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editando ? 'Ingrediente' : 'Añadir ingrediente',
              style: theme.textTheme.titleLarge,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.kitchen_outlined),
              title: Text(food.nombreCompleto),
              subtitle: food.pendiente
                  ? const Row(children: [PendingChip()])
                  : Text(nutritionSummary(food)),
              trailing: TextButton(
                onPressed: _cambiar,
                child: const Text('Cambiar'),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('cantidad_ingrediente'),
                    controller: _qtyCtrl,
                    autofocus: _qtyCtrl.text.isEmpty,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [AppUtils.decimalInputFormatter],
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      suffixText: _unidad,
                      helperText: gramos == null
                          ? (cantidad == null
                                ? 'Vacío = sin cantidad (al gusto)'
                                : 'Falta el peso de 1 $_unidad')
                          : '${AppUtils.formatNumero(gramos)} ${food.u}'
                                '${kcal == null ? '' : ' · ${AppUtils.formatNumero(kcal * gramos / 100)} kcal'}',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final u in unidades)
                  ChoiceChip(
                    label: Text(u),
                    selected: _unidad == u,
                    onSelected: (_) => setState(() => _unidad = u),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Porción'),
                  tooltip: 'Nueva porción: diente, taza, cucharada...',
                  onPressed: _nuevaPorcion,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notaCtrl,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'picada, en dados, sin piel...',
              ),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Opcional'),
              subtitle: const Text('No cuenta para calorías ni faltantes'),
              value: _opcional,
              onChanged: (v) => setState(() => _opcional = v),
            ),
            Text(
              ingredientLine(
                nombreAlimento: food.nombre,
                cantidad: cantidad,
                unidad: _unidad,
                nota: _notaCtrl.text,
                opcional: _opcional,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_editando)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, const IngredientEdit.quitar()),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Quitar'),
                  ),
                const Spacer(),
                FilledButton(
                  key: const Key('guardar_ingrediente'),
                  onPressed: _guardar,
                  child: Text(_editando ? 'Guardar' : 'Añadir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nueva porción del alimento: nombre y cuánto pesa una.
class _PortionDialog extends StatefulWidget {
  final Food food;

  const _PortionDialog({required this.food});

  @override
  State<_PortionDialog> createState() => _PortionDialogState();
}

class _PortionDialogState extends State<_PortionDialog> {
  final _nombre = TextEditingController();
  final _gramos = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _gramos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = AppUtils.parseDecimal(_gramos.text);
    final nombre = _nombre.text.trim();
    final ok = nombre.isNotEmpty && g != null && g > 0;
    return AlertDialog(
      title: const Text('Nueva porción'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nombre,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'diente, taza, cucharada...',
            ),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _gramos,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AppUtils.decimalInputFormatter],
            decoration: InputDecoration(
              labelText: nombre.isEmpty
                  ? 'Peso de 1'
                  : 'Peso de 1 $nombre de ${widget.food.nombre}',
              suffixText: widget.food.u,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: ok
              ? () => Navigator.pop(
                  context,
                  FoodPortion(
                    alimentoId: widget.food.id,
                    nombre: nombre,
                    gramos: g,
                  ),
                )
              : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
