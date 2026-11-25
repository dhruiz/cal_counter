import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../domain/entities/cooking_pot.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/errors/domain_errors.dart';
import '../providers/recipes_provider.dart';

/// Resultado de la ventana del peso final: el peso neto o quitar el peso.
class FinalWeightResult {
  final double? neto;
  final bool quitar;

  const FinalWeightResult.neto(double this.neto) : quitar = false;
  const FinalWeightResult.quitar() : neto = null, quitar = true;
}

/// Pide el peso final de una preparación. Si se pesa en la olla, se elige
/// un recipiente guardado (o se escribe su peso) y se descuenta.
class FinalWeightDialog extends ConsumerStatefulWidget {
  final String receta;
  final double? pesoActual;

  /// Escala con la que se cocinó (×2 = el doble de todo).
  final double factor;

  const FinalWeightDialog({
    super.key,
    required this.receta,
    this.pesoActual,
    this.factor = 1,
  });

  static Future<FinalWeightResult?> show(
    BuildContext context, {
    required String receta,
    double? pesoActual,
    double factor = 1,
  }) => showDialog<FinalWeightResult>(
    context: context,
    builder: (_) => FinalWeightDialog(
      receta: receta,
      pesoActual: pesoActual,
      factor: factor,
    ),
  );

  /// Pide el peso de [receta] y lo guarda (pone al día su alimento).
  static Future<void> askAndSave(
    BuildContext context,
    WidgetRef ref,
    Recipe receta, {
    double factor = 1,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await show(
      context,
      receta: receta.nombre,
      pesoActual: receta.pesoFinalG,
      factor: factor,
    );
    if (res == null) return;
    try {
      await ref.read(setRecipeFinalWeightProvider)(
        recetaId: receta.id!,
        pesoNetoG: res.quitar ? null : res.neto,
        factor: factor,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res.quitar
                ? 'Peso final quitado: la tabla vuelve a ser aproximada.'
                : 'Peso final guardado: la tabla de «${receta.nombre}» '
                      'está al día.',
          ),
        ),
      );
    } on ValidationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  ConsumerState<FinalWeightDialog> createState() => _FinalWeightDialogState();
}

class _FinalWeightDialogState extends ConsumerState<FinalWeightDialog> {
  final _total = TextEditingController();
  final _tara = TextEditingController();
  final _neto = TextEditingController();
  bool _conRecipiente = true;
  List<CookingPot> _pots = const [];
  CookingPot? _pot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pots = await ref.read(cookingPotRepositoryProvider).getAll();
    if (mounted) setState(() => _pots = pots);
  }

  @override
  void dispose() {
    _total.dispose();
    _tara.dispose();
    _neto.dispose();
    super.dispose();
  }

  double? get _resultado => _conRecipiente
      ? netWeight(
          AppUtils.parseDecimal(_total.text),
          AppUtils.parseDecimal(_tara.text),
        )
      : () {
          final v = AppUtils.parseDecimal(_neto.text);
          return (v == null || v <= 0) ? null : v;
        }();

  void _choose(CookingPot p) {
    setState(() {
      _pot = p;
      _tara.text = AppUtils.formatDecimalEditable(p.gramos);
    });
  }

  Future<void> _newPot() async {
    final tara = AppUtils.parseDecimal(_tara.text);
    final res = await showDialog<CookingPot>(
      context: context,
      builder: (_) => _NewPotDialog(gramos: tara),
    );
    if (res == null) return;
    final pots = await ref.read(cookingPotRepositoryProvider).save(res);
    if (!mounted) return;
    setState(() => _pots = pots);
    _choose(res);
  }

  Future<void> _deletePot(CookingPot p) async {
    final pots = await ref.read(cookingPotRepositoryProvider).delete(p.nombre);
    if (!mounted) return;
    setState(() {
      _pots = pots;
      if (_pot == p) _pot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    final f = widget.factor;
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Peso final'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesa «${widget.receta}» ya terminada. Si la pesas en la olla, '
              'elige la olla para descontarla.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('En la olla')),
                ButtonSegment(value: false, label: Text('Sin olla')),
              ],
              selected: {_conRecipiente},
              onSelectionChanged: (v) =>
                  setState(() => _conRecipiente = v.first),
            ),
            const SizedBox(height: 8),
            if (_conRecipiente) ...[
              TextField(
                key: const Key('peso_total'),
                controller: _total,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AppUtils.decimalInputFormatter],
                decoration: const InputDecoration(
                  labelText: 'Peso total con la olla',
                  suffixText: 'g',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final p in _pots)
                    GestureDetector(
                      onLongPress: () => _deletePot(p),
                      child: ChoiceChip(
                        label: Text(
                          '${p.nombre} · ${AppUtils.formatNumero(p.gramos)} g',
                        ),
                        selected: _pot == p,
                        onSelected: (_) => _choose(p),
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Guardar olla'),
                    onPressed: _newPot,
                  ),
                ],
              ),
              if (_pots.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Mantén pulsada una olla para borrarla.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              TextField(
                key: const Key('peso_olla'),
                controller: _tara,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AppUtils.decimalInputFormatter],
                decoration: const InputDecoration(
                  labelText: 'Peso de la olla vacía',
                  suffixText: 'g',
                ),
                onChanged: (_) => setState(() => _pot = null),
              ),
            ] else
              TextField(
                key: const Key('peso_neto'),
                controller: _neto,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AppUtils.decimalInputFormatter],
                decoration: const InputDecoration(
                  labelText: 'Peso de la preparación',
                  suffixText: 'g',
                ),
                onChanged: (_) => setState(() {}),
              ),
            const SizedBox(height: 12),
            Text(
              r == null
                  ? 'Peso de la preparación: —'
                  : 'Peso de la preparación: ${AppUtils.formatNumero(r)} g',
              style: theme.textTheme.titleSmall,
            ),
            if (f != 1 && r != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'La cocinaste a ×${AppUtils.formatNumero(f)}: se guarda '
                  'como ${AppUtils.formatNumero(r / f)} g para la receta '
                  'original.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (widget.pesoActual != null)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const FinalWeightResult.quitar()),
            child: const Text('Quitar peso'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: r == null
              ? null
              : () => Navigator.pop(context, FinalWeightResult.neto(r)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _NewPotDialog extends StatefulWidget {
  final double? gramos;

  const _NewPotDialog({this.gramos});

  @override
  State<_NewPotDialog> createState() => _NewPotDialogState();
}

class _NewPotDialogState extends State<_NewPotDialog> {
  final _nombre = TextEditingController();
  late final _gramos = TextEditingController(
    text: widget.gramos == null
        ? ''
        : AppUtils.formatDecimalEditable(widget.gramos!),
  );

  @override
  void dispose() {
    _nombre.dispose();
    _gramos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = AppUtils.parseDecimal(_gramos.text);
    final ok = _nombre.text.trim().isNotEmpty && g != null && g > 0;
    return AlertDialog(
      title: const Text('Guardar olla'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nombre,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Olla grande',
            ),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _gramos,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AppUtils.decimalInputFormatter],
            decoration: const InputDecoration(
              labelText: 'Peso vacía',
              suffixText: 'g',
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
                  CookingPot(nombre: _nombre.text.trim(), gramos: g),
                )
              : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
