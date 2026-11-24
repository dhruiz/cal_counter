import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/services/barcode.dart';
import '../../domain/services/category_guesser.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/services/money.dart';
import '../../domain/usecases/food_registration.dart';
import '../providers/foods_provider.dart';
import '../widgets/category_widgets.dart';
import '../widgets/food_widgets.dart';
import '../widgets/label_reader.dart';
import 'barcode_scanner_view.dart';

/// Alta o edición de un alimento EN CASA: datos básicos y tabla nutricional
/// por 100 g/ml (lo que se deje vacío queda como "desconocido"). Al crear se
/// puede indicar la presentación y su código de barras. Devuelve el id.
///
/// Con [completar] se abre centrado en la tabla nutricional (alimentos
/// pendientes dados de alta en la tienda).
///
/// También da de alta artículos que no son alimentos (limpieza, higiene...):
/// sin tabla nutricional, pero con sus compras y precios. Con [soloAlimento]
/// (ingredientes de recetas) no se ofrece esa opción.
class FoodFormView extends ConsumerStatefulWidget {
  final Food? food;
  final String? nombreInicial;
  final String? codigoBarras;
  final bool completar;
  final bool soloAlimento;

  const FoodFormView({
    super.key,
    this.food,
    this.nombreInicial,
    this.codigoBarras,
    this.completar = false,
    this.soloAlimento = false,
  });

  /// Abre el formulario y devuelve el id guardado (o null si se cancela).
  static Future<int?> open(
    BuildContext context, {
    Food? food,
    String? nombreInicial,
    String? codigoBarras,
    bool completar = false,
    bool soloAlimento = false,
  }) {
    return Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodFormView(
          food: food,
          nombreInicial: nombreInicial,
          codigoBarras: codigoBarras,
          completar: completar,
          soloAlimento: soloAlimento,
        ),
      ),
    );
  }

  @override
  ConsumerState<FoodFormView> createState() => _FoodFormViewState();
}

class _FoodFormViewState extends ConsumerState<FoodFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _packCtrl;
  late final TextEditingController _contentCtrl;
  late final Map<Nutrient, TextEditingController> _nutrientCtrls;
  late FoodType _tipo;
  late FoodUnit _unidad;
  int? _categoriaId;

  /// El usuario eligió la categoría a mano (si no, al crear se propone la
  /// que sugiere el nombre).
  bool _categoriaElegida = false;
  NutritionSource? _origen;
  bool _saving = false;

  /// Elección del usuario sobre «Es un alimento» (null = la propuesta).
  bool? _esAlimentoElegido;

  bool get _isNew => widget.food == null;

  /// Es un alimento: lo elegido, lo que ya era o lo que sugiere el nombre.
  bool get _esAlimento {
    if (widget.soloAlimento) return true;
    final elegido = _esAlimentoElegido;
    if (elegido != null) return elegido;
    final f = widget.food;
    if (f != null) return f.esAlimento;
    return !pareceNoAlimentario(_nameCtrl.text);
  }

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    _nameCtrl = TextEditingController(
      text: f?.nombre ?? widget.nombreInicial ?? '',
    );
    _brandCtrl = TextEditingController(text: f?.marca ?? '');
    _notesCtrl = TextEditingController(text: f?.notas ?? '');
    _codeCtrl = TextEditingController(text: widget.codigoBarras ?? '');
    _packCtrl = TextEditingController();
    _contentCtrl = TextEditingController();
    _nutrientCtrls = {
      for (final n in Nutrient.values)
        n: TextEditingController(text: _fmt(f?.nutricion[n])),
    };
    _tipo =
        f?.tipo ??
        (widget.codigoBarras != null ? FoodType.envasado : FoodType.generico);
    _unidad = f?.unidad ?? FoodUnit.g;
    _categoriaId = f?.categoriaId;
    _categoriaElegida = f != null;
    _origen = f?.origenNutricion;
  }

  /// Categoría efectiva: la elegida, o la que sugiere el nombre al crear.
  int? _categoria(List<Category> cats) {
    if (_categoriaElegida) return _categoriaId;
    final guess = guessCategoryName(_nameCtrl.text);
    if (guess == null) return null;
    return cats
        .where((c) => normalizeText(c.nombre) == normalizeText(guess))
        .firstOrNull
        ?.id;
  }

  static String _fmt(double? v) =>
      v == null ? '' : AppUtils.formatNumero(v).replaceAll('.', ',');

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _brandCtrl,
      _notesCtrl,
      _codeCtrl,
      _packCtrl,
      _contentCtrl,
      ..._nutrientCtrls.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  NutritionFacts get _nutricion => NutritionFacts.desdeMapa({
    for (final e in _nutrientCtrls.entries) e.key: parseDecimal(e.value.text),
  });

  Future<void> _scanCode() async {
    final code = await BarcodeScannerView.scan(context);
    if (code != null && mounted) {
      setState(() => _codeCtrl.text = normalizeBarcode(code) ?? code);
    }
  }

  /// Rellena la tabla con lo leído de la etiqueta (OCR). El usuario revisa
  /// antes de guardar.
  Future<void> _readLabel() async {
    final res = await LabelReader.read(context, unidad: _unidad.clave);
    if (res == null || !mounted) return;
    setState(() {
      for (final n in Nutrient.values) {
        final v = res.nutricion[n];
        if (v != null) _nutrientCtrls[n]!.text = _fmt(v);
      }
      if (res.contenido != null && _contentCtrl.text.trim().isEmpty) {
        _contentCtrl.text = _fmt(res.contenido);
      }
      if (res.unidad != null) _unidad = FoodUnit.fromClave(res.unidad);
      _origen = NutritionSource.etiquetaOcr;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Revisa los valores leídos antes de guardar.'),
      ),
    );
  }

  Future<bool> _confirmAvisos(List<String> avisos) async {
    if (avisos.isEmpty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revisa la tabla nutricional'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final a in avisos)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $a'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Corregir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar igualmente'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final esAlimento = _esAlimento;
    final nutricion = esAlimento ? _nutricion : NutritionFacts.vacia;
    if (esAlimento && !await _confirmAvisos(nutricion.avisos)) return;

    final base = widget.food ?? const Food(nombre: '');
    final cambioTabla = nutricion != (widget.food?.nutricion);
    final categoria = _categoria(
      ref.read(categoriesProvider(null)).valueOrNull ?? const [],
    );
    final food = base.copyWith(
      nombre: _nameCtrl.text.trim(),
      marca: _brandCtrl.text.trim(),
      tipo: _tipo,
      unidad: _unidad,
      categoriaId: categoria,
      clearCategoria: categoria == null,
      nutricion: nutricion,
      origenNutricion: cambioTabla && _origen != NutritionSource.etiquetaOcr
          ? NutritionSource.manual
          : (_origen ?? NutritionSource.manual),
      notas: _notesCtrl.text.trim(),
      esAlimento: esAlimento,
    );

    setState(() => _saving = true);
    try {
      final int id;
      if (_isNew) {
        id = await ref.read(saveFoodWithPackageProvider)(
          food,
          adivinarCategoria: false,
          presentacion: PackageDraft(
            codigoBarras: _codeCtrl.text,
            descripcion: _packCtrl.text,
            contenido: parseDecimal(_contentCtrl.text),
          ),
        );
      } else {
        id = await ref.read(foodRepositoryProvider).saveFood(food);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            food.pendiente
                ? '"${food.nombre}" guardado (pendiente de completar).'
                : '"${food.nombre}" guardado.',
          ),
        ),
      );
      Navigator.pop(context, id);
    } on DuplicateFoodException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final abrir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ya existe'),
          content: Text(
            'Ya tienes "${e.existente.nombreCompleto}"'
            '${e.existente.archivado ? ' (archivado)' : ''}. '
            'Cambia el nombre o la marca, o usa el que ya existe.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cambiar nombre'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Usar el existente'),
            ),
          ],
        ),
      );
      if (abrir == true && mounted) {
        if (e.existente.archivado) {
          await ref
              .read(foodRepositoryProvider)
              .setArchived(e.existente.id!, false);
        }
        if (mounted) Navigator.pop(context, e.existente.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  Widget _nutrientField(Nutrient n) {
    return Padding(
      padding: EdgeInsets.only(left: n.esSubcategoria ? 24 : 0, bottom: 8),
      child: TextFormField(
        controller: _nutrientCtrls[n],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: n.etiqueta + (n.esencial ? ' *' : ''),
          suffixText: n.unidad,
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final d = parseDecimal(v);
          if (d == null || d < 0) return 'Número no válido';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faltan = _nutricion.faltantes;
    final esAlimento = _esAlimento;
    final title = widget.completar
        ? 'Completar tabla nutricional'
        : (_isNew
              ? (esAlimento ? 'Nuevo alimento' : 'Nuevo artículo')
              : (esAlimento ? 'Editar alimento' : 'Editar artículo'));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
              autofocus: _isNew && _nameCtrl.text.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              onChanged: (_) {
                if (!_categoriaElegida || _esAlimentoElegido == null) {
                  setState(() {});
                }
              },
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Marca (vacío = genérico)',
              ),
            ),
            if (!widget.soloAlimento && !widget.completar)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Es un alimento'),
                subtitle: Text(
                  esAlimento
                      ? 'Tiene tabla nutricional y se cuenta en el día.'
                      : 'Limpieza, higiene, hogar...: se compra y guarda su '
                            'historial de precios, sin tabla nutricional.',
                ),
                value: esAlimento,
                onChanged: (v) => setState(() => _esAlimentoElegido = v),
              ),
            const SizedBox(height: 12),
            SegmentedButton<FoodType>(
              segments: [
                for (final t in FoodType.values)
                  ButtonSegment(value: t, label: Text(t.etiqueta)),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 12),
            CategoryDropdown(
              value: _categoria(
                ref.watch(categoriesProvider(null)).valueOrNull ?? const [],
              ),
              helperText: _categoriaElegida ? null : 'Sugerida por el nombre',
              onChanged: (v) => setState(() {
                _categoriaId = v;
                _categoriaElegida = true;
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    esAlimento ? 'Tabla nutricional' : 'Se mide en',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SegmentedButton<FoodUnit>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: FoodUnit.g, label: Text('100 g')),
                    ButtonSegment(value: FoodUnit.ml, label: Text('100 ml')),
                  ],
                  selected: {_unidad},
                  onSelectionChanged: (s) => setState(() => _unidad = s.first),
                ),
              ],
            ),
            if (esAlimento) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _readLabel,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Leer la etiqueta con la cámara'),
              ),
              if (faltan.isNotEmpty)
                InfoBanner(
                  color: AppStyles.semaphOrange,
                  icon: Icons.info_outline,
                  text:
                      'Faltan: ${faltan.map((n) => n.etiqueta.toLowerCase()).join(', ')}. '
                      'Puedes guardar igualmente: quedará pendiente y no se '
                      'podrá registrar en el contador hasta completarlo.',
                ),
              const SizedBox(height: 12),
              for (final n in Nutrient.values) _nutrientField(n),
            ],
            if (_isNew) ...[
              const SizedBox(height: 12),
              Text(
                'Presentación y código de barras (opcional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Código de barras',
                  suffixIcon: IconButton(
                    tooltip: 'Escanear',
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanCode,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (normalizeBarcode(_codeCtrl.text) != null &&
                  !isValidGtin(_codeCtrl.text))
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'El dígito de control no cuadra: revisa el código '
                    '(se permite guardarlo por si es un código de tienda).',
                    style: TextStyle(color: AppStyles.semaphOrange),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _packCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Presentación',
                        hintText: 'Brick 1 L, pack 6...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _contentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Contenido',
                        suffixText: _unidad.clave,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
