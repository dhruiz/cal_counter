import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../data/parsers/recipe_text_codec.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../providers/recipes_provider.dart';

/// Importación de recetas en dos pasos: (1) pegar texto (si no viene ya de
/// un archivo) y (2) vista previa con casillas antes de guardar.
class RecipeImportView extends ConsumerStatefulWidget {
  /// Recetas ya leídas de un archivo. Si es null se empieza pegando texto.
  final List<Recipe>? initialRecipes;

  const RecipeImportView({super.key, this.initialRecipes});

  @override
  ConsumerState<RecipeImportView> createState() => _RecipeImportViewState();
}

class _RecipeImportViewState extends ConsumerState<RecipeImportView> {
  final _textCtrl = TextEditingController();
  List<Recipe>? _parsed;
  final Set<int> _selected = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipes != null) _setParsed(widget.initialRecipes!);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Set<String> get _existingNames => ref
      .read(recipesProvider)
      .recipes
      .map((r) => normalizeText(r.nombre))
      .toSet();

  void _setParsed(List<Recipe> recipes) {
    final existing = _existingNames;
    _parsed = recipes;
    _selected
      ..clear()
      ..addAll([
        for (var i = 0; i < recipes.length; i++)
          if (!existing.contains(normalizeText(recipes[i].nombre))) i,
      ]);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El portapapeles está vacío')),
        );
      }
      return;
    }
    setState(() => _textCtrl.text = text);
  }

  void _analyze() {
    final List<Recipe> recipes;
    try {
      recipes = RecipeTextCodec.parse(_textCtrl.text);
    } catch (e) {
      // Antes la excepción se perdía y el botón no hacía nada visible.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo leer el texto: $e')));
      return;
    }
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró ninguna receta. La primera línea debe ser el '
            'nombre y después los ingredientes.',
          ),
        ),
      );
      return;
    }
    setState(() => _setParsed(recipes));
  }

  Future<void> _save() async {
    final parsed = _parsed!;
    setState(() => _saving = true);
    final toSave = [
      for (var i = 0; i < parsed.length; i++)
        if (_selected.contains(i)) parsed[i],
    ];
    final int saved;
    try {
      saved = await ref.read(recipesProvider.notifier).importRecipes(toSave);
    } catch (e) {
      // Sin esto el botón quedaba deshabilitado (_saving) para siempre.
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al importar: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved == 1 ? '1 receta importada' : '$saved recetas importadas',
        ),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _preview(Recipe r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          child: SelectableText(RecipeTextCodec.formatRecipe(r)),
        ),
      ),
    );
  }

  Widget _buildPaste() {
    return ListView(
      padding: const EdgeInsets.all(AppStyles.paddingMedium),
      children: [
        const Text(
          'Pega aquí el texto de una o varias recetas (desde WhatsApp, una '
          'web, una nota...). La primera línea se usa como nombre; las líneas '
          'con cantidades se reconocen como ingredientes. Para separar varias '
          'recetas usa una línea con ---',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pasteFromClipboard,
          icon: const Icon(Icons.content_paste),
          label: const Text('Pegar del portapapeles'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textCtrl,
          minLines: 12,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            hintText:
                'Tortilla de patatas\n'
                'INGREDIENTES:\n- 4 huevos\n- 500 g de patatas\n'
                'PREPARACIÓN:\n1. Pelar y freír las patatas...',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _analyze,
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Revisar recetas'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(List<Recipe> parsed) {
    final existing = _existingNames;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          child: Text(
            'Se encontraron ${parsed.length} '
            '${parsed.length == 1 ? 'receta' : 'recetas'}. Marca las que '
            'quieres guardar (toca una para ver cómo quedó).',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: parsed.length,
            itemBuilder: (ctx, i) {
              final r = parsed[i];
              final dup = existing.contains(normalizeText(r.nombre));
              final warnings = [
                if (dup) 'Ya existe una receta con este nombre',
                if (r.ingredientes.isEmpty) 'Sin ingredientes',
              ];
              return CheckboxListTile(
                value: _selected.contains(i),
                onChanged: dup
                    ? null
                    : (v) => setState(
                        () =>
                            v == true ? _selected.add(i) : _selected.remove(i),
                      ),
                title: Text(r.nombre),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.ingredientes.length} ingredientes · ${r.pasos.length} pasos',
                    ),
                    ...warnings.map(
                      (w) => Text(
                        w,
                        style: const TextStyle(color: AppStyles.semaphOrange),
                      ),
                    ),
                  ],
                ),
                secondary: IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'Ver',
                  onPressed: () => _preview(r),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.paddingMedium),
            child: ElevatedButton.icon(
              onPressed: _saving || _selected.isEmpty ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _selected.length == 1
                    ? 'Guardar 1 receta'
                    : 'Guardar ${_selected.length} recetas',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    return Scaffold(
      appBar: AppBar(
        title: Text(parsed == null ? 'Pegar recetas' : 'Revisar importación'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        leading: parsed != null && widget.initialRecipes == null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Volver al texto',
                onPressed: () => setState(() => _parsed = null),
              )
            : null,
      ),
      body: parsed == null ? _buildPaste() : _buildPreview(parsed),
    );
  }
}
