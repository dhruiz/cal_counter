import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/services/money.dart';
import '../providers/foods_provider.dart';
import '../providers/purchases_provider.dart';

/// Registra la compra de un alimento: presentación, precio unitario,
/// unidades, establecimiento (autocompletado) y fecha. Precarga el último
/// precio y tienda conocidos. Devuelve true si se registró.
class PurchaseDialog extends ConsumerStatefulWidget {
  final Food food;

  const PurchaseDialog({super.key, required this.food});

  static Future<bool> show(BuildContext context, {required Food food}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PurchaseDialog(food: food),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compra de ${food.nombre} registrada')),
      );
    }
    return ok == true;
  }

  @override
  ConsumerState<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends ConsumerState<PurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  TextEditingController? _storeCtrl;
  String _initialStore = '';
  int? _packageId;
  int _unidades = 1;
  DateTime _fecha = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final last = await ref
        .read(purchaseRepositoryProvider)
        .lastPurchaseForFood(widget.food.id!);
    if (last == null || !mounted) return;
    setState(() {
      _priceCtrl.text = AppUtils.formatPrecioEditableCent(
        last.compra.precioCent,
      );
      _initialStore = last.compra.establecimiento;
      _storeCtrl?.text = _initialStore;
      _packageId = last.presentacion.archivado ? null : last.presentacion.id;
    });
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(registerPurchaseProvider)(
        alimentoId: widget.food.id!,
        presentacionId: _packageId,
        precioCent: parsePrecioCent(_priceCtrl.text)!,
        unidades: _unidades,
        establecimiento: _storeCtrl?.text ?? '',
        fecha: _fecha,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo registrar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final packages =
        (ref.watch(foodPackagesProvider(widget.food.id!)).valueOrNull ??
                const <FoodPackage>[])
            .where((p) => !p.archivado)
            .toList();
    final stores = ref.watch(storesProvider).valueOrNull ?? const <String>[];
    final validPackage = packages.any((p) => p.id == _packageId)
        ? _packageId
        : null;

    return AlertDialog(
      title: Text('Compra de ${widget.food.nombre}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (packages.isNotEmpty)
                DropdownButtonFormField<int?>(
                  initialValue: validPackage,
                  decoration: const InputDecoration(labelText: 'Presentación'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin especificar'),
                    ),
                    for (final p in packages)
                      DropdownMenuItem<int?>(
                        value: p.id,
                        child: Text(
                          p.descripcion.isNotEmpty
                              ? p.descripcion
                              : (p.codigoBarras ?? 'Sin descripción'),
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _packageId = v),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio por unidad',
                        suffixText: '€',
                      ),
                      validator: (v) => parsePrecioCent(v ?? '') == null
                          ? 'Precio no válido'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Una menos',
                    onPressed: _unidades > 1
                        ? () => setState(() => _unidades--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_unidades', style: const TextStyle(fontSize: 18)),
                  IconButton.outlined(
                    tooltip: 'Una más',
                    onPressed: () => setState(() => _unidades++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                key: ValueKey(_initialStore),
                initialValue: TextEditingValue(text: _initialStore),
                optionsBuilder: (value) {
                  final q = value.text.toLowerCase().trim();
                  if (q.isEmpty) return stores;
                  return stores.where((s) => s.toLowerCase().contains(q));
                },
                fieldViewBuilder: (context, controller, focusNode, _) {
                  _storeCtrl = controller;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Establecimiento',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? '¿Dónde lo compraste?'
                        : null,
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(AppUtils.formatFecha(_fecha)),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Cambiar'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
