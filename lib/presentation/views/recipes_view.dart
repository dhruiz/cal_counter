import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../data/parsers/recipe_text_codec.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/recipe_ideas.dart';
import '../providers/recipes_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_view.dart';
import 'recipe_form_view.dart';
import 'recipe_import_view.dart';

/// Pestaña "Recetas": repertorio personal con búsqueda por ingredientes
/// disponibles o por nombre, e importación/exportación amigable.
class RecipesView extends ConsumerStatefulWidget {
  const RecipesView({super.key});

  @override
  ConsumerState<RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends ConsumerState<RecipesView> {
  final _queryCtrl = TextEditingController();

  RecipesNotifier get _notifier => ref.read(recipesProvider.notifier);

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  void _openRecipe(Recipe r) {
    final s = ref.read(recipesProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailView(
          recipeId: r.id!,
          terminos: s.terminos,
          incluirBasicos: s.incluirBasicos,
        ),
      ),
    );
  }

  Future<void> _newRecipe() async {
    await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const RecipeFormView()),
    );
  }

  Future<void> _importFile() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // FileType.any: algunos gestores de archivos no reconocen .txt/.csv/.json
      // como tipos personalizados; el contenido se valida al leerlo.
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null) return; // Cancelado
      final content = utf8.decode(
        await file.readAsBytes(),
        allowMalformed: true,
      );
      final recipes = RecipeTextCodec.parse(content, fileName: file.name);
      if (!mounted) return;
      if (recipes.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontraron recetas. Revisa que el archivo siga la '
              'plantilla (menú ⋮ → Ver plantilla).',
            ),
          ),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeImportView(initialRecipes: recipes),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al leer el archivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pasteText() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecipeImportView()),
    );
  }

  Future<void> _saveTextFile(String fileName, String content) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Guardar archivo',
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(content)),
      );
      if (saved == null) return; // Cancelado
      messenger.showSnackBar(
        SnackBar(
          content: Text('Guardado en: ${AppUtils.formatRutaGuardada(saved)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTemplate() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plantilla de recetas'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escribe tus recetas así (en el móvil o el ordenador) e '
                  'impórtalas con "Importar desde archivo" o "Pegar texto". '
                  'Solo RECETA e INGREDIENTES son obligatorios.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.withValues(alpha: 0.15),
                  child: SelectableText(
                    RecipeTextCodec.plantilla,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: RecipeTextCodec.plantilla),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plantilla copiada')),
                );
              }
            },
            child: const Text('Copiar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveTextFile('plantilla_recetas.txt', RecipeTextCodec.plantilla);
            },
            child: const Text('Guardar archivo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAll() async {
    final recipes = ref.read(recipesProvider).recipes;
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay recetas para exportar.')),
      );
      return;
    }
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _saveTextFile(
      'mis_recetas_$date.txt',
      RecipeTextCodec.formatRecipes(recipes),
    );
  }

  /// Propone una receta al azar (favoritas y las que hace tiempo que no
  /// preparas salen más), de la categoría elegida si hay una.
  Future<void> _suggest() async {
    final s = ref.read(recipesProvider);
    final pool = s.mode == RecipeSearchMode.nombre
        ? s.deLaCategoria
        : s.recipes;
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aún no tienes recetas que sugerir.')),
      );
      return;
    }
    final elegida = await showDialog<Recipe>(
      context: context,
      builder: (_) => _SuggestDialog(recetas: pool),
    );
    if (elegida != null && mounted) _openRecipe(elegida);
  }

  void _onMenu(String v) {
    switch (v) {
      case 'file':
        _importFile();
      case 'paste':
        _pasteText();
      case 'template':
        _showTemplate();
      case 'export':
        _exportAll();
    }
  }

  Widget _buildList(RecipesState s) {
    if (s.recipes.isEmpty) {
      return EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Aún no tienes recetas',
        message:
            'Escribe tus recetas favoritas, pega el texto de una receta '
            '(de WhatsApp, una web...) o importa un archivo con la plantilla.',
        actions: [
          ElevatedButton.icon(
            onPressed: _newRecipe,
            icon: const Icon(Icons.edit),
            label: const Text('Escribir una receta'),
          ),
          OutlinedButton.icon(
            onPressed: _pasteText,
            icon: const Icon(Icons.content_paste),
            label: const Text('Pegar texto'),
          ),
          OutlinedButton.icon(
            onPressed: _importFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar archivo'),
          ),
          TextButton.icon(
            onPressed: _showTemplate,
            icon: const Icon(Icons.description_outlined),
            label: const Text('Ver plantilla'),
          ),
        ],
      );
    }

    if (s.mode == RecipeSearchMode.ingredientes && s.terminos.isNotEmpty) {
      final matches = ref.watch(recipeMatchesProvider);
      if (matches.isEmpty) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'Sin coincidencias',
          message: s.soloCompletas
              ? 'Ninguna receta se puede hacer solo con eso. Prueba a '
                    'desactivar "Solo las que puedo hacer".'
              : 'Ninguna de tus recetas usa esos ingredientes.',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: matches.length,
        itemBuilder: (_, i) => RecipeCard(
          recipe: matches[i].recipe,
          match: matches[i],
          onTap: () => _openRecipe(matches[i].recipe),
        ),
      );
    }

    final recipes = ref.watch(recipesByNameProvider);
    if (recipes.isEmpty) {
      return const Center(child: Text('Ninguna receta con ese nombre'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: recipes.length,
      itemBuilder: (_, i) =>
          RecipeCard(recipe: recipes[i], onTap: () => _openRecipe(recipes[i])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(recipesProvider);
    final byIngredients = s.mode == RecipeSearchMode.ingredientes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis recetas'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          if (s.recipes.isNotEmpty)
            IconButton(
              tooltip: 'Sugiéreme algo',
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: _suggest,
            ),
          PopupMenuButton<String>(
            onSelected: _onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'paste',
                child: ListTile(
                  leading: Icon(Icons.content_paste),
                  title: Text('Pegar texto de una receta'),
                ),
              ),
              PopupMenuItem(
                value: 'file',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Importar desde archivo'),
                  subtitle: Text('.txt, .csv o .json'),
                ),
              ),
              PopupMenuItem(
                value: 'template',
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Ver plantilla'),
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exportar todas (copia)'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nueva_receta',
        onPressed: _newRecipe,
        icon: const Icon(Icons.add),
        label: const Text('Nueva receta'),
      ),
      body: s.isLoading && s.recipes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (s.recipes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SegmentedButton<RecipeSearchMode>(
                      segments: const [
                        ButtonSegment(
                          value: RecipeSearchMode.ingredientes,
                          icon: Icon(Icons.kitchen_outlined),
                          label: Text('Lo que tengo'),
                        ),
                        ButtonSegment(
                          value: RecipeSearchMode.nombre,
                          icon: Icon(Icons.search),
                          label: Text('Por nombre'),
                        ),
                      ],
                      selected: {s.mode},
                      onSelectionChanged: (v) {
                        _queryCtrl.clear();
                        _notifier.setQuery('');
                        _notifier.setMode(v.first);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      controller: _queryCtrl,
                      onChanged: _notifier.setQuery,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(
                          byIngredients ? Icons.kitchen_outlined : Icons.search,
                        ),
                        hintText: byIngredients
                            ? 'Ej: huevo, patata, cebolla'
                            : 'Nombre o categoría',
                        helperText: byIngredients
                            ? 'Escribe lo que tienes separado por comas'
                            : null,
                        suffixIcon: s.query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _queryCtrl.clear();
                                  _notifier.setQuery('');
                                },
                              ),
                      ),
                    ),
                  ),
                  if (byIngredients)
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          ...s.terminos.map(
                            (t) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: InputChip(
                                label: Text(t),
                                onDeleted: () {
                                  _notifier.removeTermino(t);
                                  _queryCtrl.text = ref
                                      .read(recipesProvider)
                                      .query;
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: const Text(
                                'Tengo sal, aceite, agua y pimienta',
                              ),
                              selected: s.incluirBasicos,
                              onSelected: _notifier.setIncluirBasicos,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: const Text('Solo las que puedo hacer'),
                              selected: s.soloCompletas,
                              onSelected: _notifier.setSoloCompletas,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (!byIngredients && s.recipes.isNotEmpty)
                  _OrderAndCategoryRow(state: s, notifier: _notifier),
                Expanded(child: _buildList(s)),
              ],
            ),
    );
  }
}

/// Orden de la lista y filtro por categoría (modo por nombre).
class _OrderAndCategoryRow extends StatelessWidget {
  final RecipesState state;
  final RecipesNotifier notifier;

  const _OrderAndCategoryRow({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final cats = recipeCategories(state.recipes);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          PopupMenuButton<RecipeOrder>(
            tooltip: 'Ordenar',
            initialValue: state.orden,
            onSelected: notifier.setOrden,
            itemBuilder: (_) => [
              for (final o in RecipeOrder.values)
                PopupMenuItem(value: o, child: Text(o.etiqueta)),
            ],
            child: Chip(
              avatar: const Icon(Icons.sort, size: 18),
              label: Text(state.orden.etiqueta),
            ),
          ),
          if (cats.isNotEmpty) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: const Text('Todas'),
                selected: state.categoria == null,
                onSelected: (_) => notifier.setCategoria(null),
              ),
            ),
            for (final c in cats)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(c),
                  selected:
                      state.categoria != null &&
                      state.categoria!.toLowerCase() == c.toLowerCase(),
                  onSelected: (_) => notifier.setCategoria(c),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// «¿Qué cocino hoy?»: una receta al azar con «Otra» para pedir otra.
class _SuggestDialog extends StatefulWidget {
  final List<Recipe> recetas;

  const _SuggestDialog({required this.recetas});

  @override
  State<_SuggestDialog> createState() => _SuggestDialogState();
}

class _SuggestDialogState extends State<_SuggestDialog> {
  final _vistas = <int>{};
  late Recipe _receta;

  @override
  void initState() {
    super.initState();
    _receta = _siguiente()!;
  }

  Recipe? _siguiente() {
    final hoy = DateTime.now();
    var r = suggestRecipe(widget.recetas, hoy: hoy, excluir: _vistas);
    if (r == null) {
      // Ya salieron todas: se vuelve a empezar.
      _vistas.clear();
      r = suggestRecipe(widget.recetas, hoy: hoy);
    }
    if (r?.id != null) _vistas.add(r!.id!);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final r = _receta;
    final dias = daysSincePrepared(r, DateTime.now());
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('¿Qué tal esta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (r.favorita)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.star, color: Colors.amber),
                ),
              Expanded(
                child: Text(r.nombre, style: theme.textTheme.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if ((r.categoria ?? '').isNotEmpty)
            Text(r.categoria!, style: AppStyles.labelText),
          Text(
            dias == null
                ? 'Aún no la has marcado como preparada.'
                : 'La preparaste por última vez ${preparedAgo(dias)}.',
          ),
          if (r.tiempoMin != null)
            Text(
              'Tiempo: ${RecipeTextCodec.formatMinutes(r.tiempoMin!)}',
              style: AppStyles.labelText,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.recetas.length < 2
              ? null
              : () => setState(() => _receta = _siguiente() ?? _receta),
          child: const Text('Otra'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, r),
          child: const Text('Ver receta'),
        ),
      ],
    );
  }
}
