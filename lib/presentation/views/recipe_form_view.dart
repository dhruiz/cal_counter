import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/services/money.dart';
import '../providers/recipes_provider.dart';
import '../widgets/food_widgets.dart';
import '../widgets/ingredient_sheet.dart';
import 'recipe_link_view.dart';

/// Alta o edición de una receta. Los ingredientes se añaden desde el
/// buscador, como en el contador de calorías: cada uno es un alimento de tu
/// lista (o uno que se crea en ese momento) con su cantidad. Las líneas de
/// texto de recetas antiguas, pegadas o importadas quedan «por vincular»
/// hasta que se buscan. Devuelve el id guardado.
class RecipeFormView extends ConsumerStatefulWidget {
  final Recipe? recipe;

  const RecipeFormView({super.key, this.recipe});

  @override
  ConsumerState<RecipeFormView> createState() => _RecipeFormViewState();
}

class _RecipeFormViewState extends ConsumerState<RecipeFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _servingsCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _stepsCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _weightCtrl;
  late List<RecipeIngredient> _ings;

  /// Clave estable de cada fila (para reordenar).
  late List<int> _keys;
  int _nextKey = 0;
  Map<int, Food> _foods = const {};
  bool _saving = false;

  Set<int> get _excluir => {?widget.recipe?.alimentoId};

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameCtrl = TextEditingController(text: r?.nombre ?? '');
    _categoryCtrl = TextEditingController(text: r?.categoria ?? '');
    _servingsCtrl = TextEditingController(text: r?.porciones?.toString() ?? '');
    _timeCtrl = TextEditingController(text: r?.tiempoMin?.toString() ?? '');
    _stepsCtrl = TextEditingController(text: r?.elaboracion ?? '');
    _notesCtrl = TextEditingController(text: r?.notas ?? '');
    _weightCtrl = TextEditingController(
      text: r?.pesoFinalG == null ? '' : AppUtils.formatNumero(r!.pesoFinalG!),
    );
    _ings = [...?r?.ingredientes];
    _keys = [for (final _ in _ings) _nextKey++];
    _loadFoods();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _categoryCtrl,
      _servingsCtrl,
      _timeCtrl,
      _stepsCtrl,
      _notesCtrl,
      _weightCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFoods() async {
    final ids = {
      for (final i in _ings)
        if (i.alimentoId != null) i.alimentoId!,
    };
    final foods = await ref.read(foodRepositoryProvider).getFoodsByIds(ids);
    if (mounted) setState(() => _foods = foods);
  }

  void _apply(int? indice, IngredientEdit? res) {
    if (res == null) return;
    setState(() {
      if (res.quitar) {
        if (indice != null) {
          _ings.removeAt(indice);
          _keys.removeAt(indice);
        }
      } else if (indice == null) {
        _ings.add(res.ingrediente!);
        _keys.add(_nextKey++);
      } else {
        _ings[indice] = res.ingrediente!;
      }
    });
    _loadFoods();
  }

  Future<void> _add() async {
    final res = await IngredientSheet.pickAndEdit(context, excluir: _excluir);
    _apply(null, res);
  }

  Future<void> _edit(int i) async {
    final ing = _ings[i];
    final food = ing.alimentoId == null ? null : _foods[ing.alimentoId];
    final res = food == null
        ? await IngredientSheet.pickAndEdit(
            context,
            ingrediente: ing,
            excluir: _excluir,
          )
        : await IngredientSheet.show(
            context,
            alimento: food,
            ingrediente: ing,
            excluir: _excluir,
          );
    _apply(i, res);
  }

  void _remove(int i) {
    setState(() {
      _ings.removeAt(i);
      _keys.removeAt(i);
    });
  }

  /// Propone alimentos para las líneas por vincular (sin guardar aún).
  Future<void> _autoLink() async {
    final list = await RecipeLinkView.review(
      context,
      _recipe().copyWith(ingredientes: _ings),
    );
    if (list == null || !mounted) return;
    setState(() => _ings = list);
    _loadFoods();
  }

  /// Pega una lista de ingredientes (WhatsApp, una web...): cada línea entra
  /// por vincular y se ofrece vincularlas.
  Future<void> _paste() async {
    final texto = await showDialog<String>(
      context: context,
      builder: (_) => const _PasteDialog(),
    );
    if (texto == null || !mounted) return;
    final lineas = texto
        .split('\n')
        .map((l) => l.trim().replaceFirst(RegExp(r'^[-•*]+\s*'), ''))
        .where((l) => l.isNotEmpty)
        .toList();
    if (lineas.isEmpty) return;
    setState(() {
      for (final l in lineas) {
        _ings.add(RecipeIngredient(texto: l));
        _keys.add(_nextKey++);
      }
    });
    await _autoLink();
  }

  Recipe _recipe() {
    final base = widget.recipe ?? const Recipe(nombre: '');
    final peso = parseDecimal(_weightCtrl.text);
    return base.copyWith(
      nombre: _nameCtrl.text.trim(),
      categoria: _categoryCtrl.text.trim(),
      porciones: int.tryParse(_servingsCtrl.text.trim()),
      tiempoMin: int.tryParse(_timeCtrl.text.trim()),
      ingredientes: _ings,
      elaboracion: _stepsCtrl.text.trim(),
      notas: _notesCtrl.text.trim(),
      pesoFinalG: (peso ?? 0) > 0 ? peso : null,
      clearPesoFinal: (peso ?? 0) <= 0,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un ingrediente.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ref.read(recipesProvider.notifier).save(_recipe());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receta guardada')));
      Navigator.pop(context, id);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Widget _row(int i) {
    final ing = _ings[i];
    final food = ing.alimentoId == null ? null : _foods[ing.alimentoId];
    final vinculado = ing.alimentoId != null;
    return ListTile(
      key: ValueKey(_keys[i]),
      contentPadding: const EdgeInsets.only(left: 0, right: 0),
      leading: ReorderableDragStartListener(
        index: i,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.drag_indicator),
        ),
      ),
      title: Text(ing.texto),
      subtitle: vinculado
          ? Row(
              children: [
                Flexible(
                  child: Text(
                    food == null ? '…' : '→ ${food.nombreCompleto}',
                    style: AppStyles.labelText,
                  ),
                ),
                if (food != null && food.pendiente) ...[
                  const SizedBox(width: 6),
                  const PendingChip(),
                ],
              ],
            )
          : const Text(
              'Por vincular: búscalo en tus alimentos',
              style: TextStyle(color: AppStyles.semaphOrange),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!vinculado)
            TextButton(onPressed: () => _edit(i), child: const Text('Buscar')),
          IconButton(
            tooltip: 'Quitar',
            icon: const Icon(Icons.close),
            onPressed: () => _remove(i),
          ),
        ],
      ),
      onTap: () => _edit(i),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categorias = ref
        .watch(recipesProvider)
        .recipes
        .map((r) => r.categoria)
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList();
    final porVincular = _ings.where((i) => !i.vinculado).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'Nueva receta' : 'Editar receta'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Guardar',
            icon: const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: widget.recipe == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre de la receta *',
                hintText: 'Ej: Lentejas cocidas',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _categoryCtrl.text),
              optionsBuilder: (v) {
                final q = v.text.toLowerCase();
                return categorias.where((c) => c.toLowerCase().contains(q));
              },
              onSelected: (v) => _categoryCtrl.text = v,
              fieldViewBuilder: (context, controller, focusNode, _) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (v) => _categoryCtrl.text = v,
                  decoration: const InputDecoration(
                    labelText: 'Categoría (opcional)',
                    hintText: 'Ej: Desayuno, Postre, Plato principal',
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Porciones'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _timeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Tiempo',
                      suffixText: 'min',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Ingredientes * (${_ings.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Búscalos en tus alimentos (o créalos) con su cantidad, como en '
              'el contador de calorías.',
              style: AppStyles.labelText,
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _ings.length,
              onReorderItem: (from, to) => setState(() {
                _ings.insert(to, _ings.removeAt(from));
                _keys.insert(to, _keys.removeAt(from));
              }),
              itemBuilder: (_, i) => _row(i),
            ),
            if (porVincular > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _autoLink,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(
                    'Vincular automáticamente ($porVincular por vincular)',
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton.tonalIcon(
                  key: const Key('anadir_ingrediente'),
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir ingrediente'),
                ),
                TextButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste),
                  label: const Text('Pegar lista'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _stepsCtrl,
              minLines: 5,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Preparación (un paso por línea)',
                alignLabelWithHint: true,
                hintText:
                    'Pelar y cortar las patatas.\nFreírlas a fuego medio.\n...',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              minLines: 2,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Peso final ya cocinado (opcional)',
                suffixText: 'g',
                helperText:
                    'Sin la olla. Si no lo sabes aún, déjalo vacío: se calcula '
                    'con los ingredientes en crudo (aproximado) y puedes '
                    'añadirlo después desde la receta o al terminar de cocinar.',
                helperMaxLines: 3,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Guardar receta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasteDialog extends StatefulWidget {
  const _PasteDialog();

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pegar lista de ingredientes'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        minLines: 5,
        maxLines: 10,
        decoration: const InputDecoration(
          hintText: '4 huevos\n500 g de patatas\n1 cebolla',
          helperText: 'Uno por línea. Después se buscan en tus alimentos.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}
