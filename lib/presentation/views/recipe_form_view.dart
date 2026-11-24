import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/money.dart';
import '../providers/recipes_provider.dart';

/// Alta o edición de una receta con campos de texto libres: ingredientes y
/// pasos "uno por línea", como en un cuaderno. Al editar, las líneas que no
/// cambian conservan su vínculo al repertorio (cantidad y unidad). Devuelve
/// el id guardado.
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
  late final TextEditingController _ingredientsCtrl;
  late final TextEditingController _stepsCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _weightCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameCtrl = TextEditingController(text: r?.nombre ?? '');
    _categoryCtrl = TextEditingController(text: r?.categoria ?? '');
    _servingsCtrl = TextEditingController(text: r?.porciones?.toString() ?? '');
    _timeCtrl = TextEditingController(text: r?.tiempoMin?.toString() ?? '');
    _ingredientsCtrl = TextEditingController(text: r?.lineas.join('\n') ?? '');
    _stepsCtrl = TextEditingController(text: r?.elaboracion ?? '');
    _notesCtrl = TextEditingController(text: r?.notas ?? '');
    _weightCtrl = TextEditingController(
      text: r?.pesoFinalG == null ? '' : AppUtils.formatNumero(r!.pesoFinalG!),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _categoryCtrl,
      _servingsCtrl,
      _timeCtrl,
      _ingredientsCtrl,
      _stepsCtrl,
      _notesCtrl,
      _weightCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _ingredientLines => _ingredientsCtrl.text
      .split('\n')
      .map((l) => l.trim().replaceFirst(RegExp(r'^[-•*]+\s*'), ''))
      .where((l) => l.isNotEmpty)
      .toList();

  /// Ingredientes del texto, reutilizando el vínculo de las líneas que ya
  /// existían con el mismo texto.
  List<RecipeIngredient> get _ingredientes {
    final previos = [...?widget.recipe?.ingredientes];
    return [
      for (final linea in _ingredientLines)
        () {
          final i = previos.indexWhere((p) => p.texto.trim() == linea);
          if (i < 0) return RecipeIngredient(texto: linea);
          return previos.removeAt(i);
        }(),
    ];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final base = widget.recipe ?? const Recipe(nombre: '');
    final peso = parseDecimal(_weightCtrl.text);
    final recipe = base.copyWith(
      nombre: _nameCtrl.text.trim(),
      categoria: _categoryCtrl.text.trim(),
      porciones: int.tryParse(_servingsCtrl.text.trim()),
      tiempoMin: int.tryParse(_timeCtrl.text.trim()),
      ingredientes: _ingredientes,
      elaboracion: _stepsCtrl.text.trim(),
      notas: _notesCtrl.text.trim(),
      pesoFinalG: (peso ?? 0) > 0 ? peso : null,
      clearPesoFinal: (peso ?? 0) <= 0,
    );
    try {
      final id = await ref.read(recipesProvider.notifier).save(recipe);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receta guardada')));
      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
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
                hintText: 'Ej: Tortilla de patatas',
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _ingredientsCtrl,
              minLines: 5,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Ingredientes * (uno por línea)',
                alignLabelWithHint: true,
                hintText:
                    '4 huevos\n500 g de patatas\n1 cebolla (opcional)\nSal',
                helperText:
                    'Añade "(opcional)" a lo que no sea imprescindible.',
              ),
              validator: (_) => _ingredientLines.isEmpty
                  ? 'Añade al menos un ingrediente'
                  : null,
            ),
            const SizedBox(height: 16),
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
                    'Si no se indica, se usa la suma de los ingredientes. '
                    'Sirve para calcular bien las calorías por 100 g.',
                helperMaxLines: 2,
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
