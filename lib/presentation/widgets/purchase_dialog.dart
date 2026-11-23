import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/register_purchase.dart';
import '../providers/products_provider.dart';

/// Diálogo para registrar la compra de un producto: precio, establecimiento
/// (con autocompletado de los ya usados) y fecha. Precarga el último precio
/// y establecimiento conocidos. Devuelve true si se registró.
class PurchaseDialog extends ConsumerStatefulWidget {
  final Product product;

  const PurchaseDialog({super.key, required this.product});

  static Future<bool> show(BuildContext context, Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PurchaseDialog(product: product),
    );
    return ok == true;
  }

  @override
  ConsumerState<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends ConsumerState<PurchaseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceCtrl;
  TextEditingController? _storeCtrl;
  late String _initialStore;
  DateTime _fecha = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final last = widget.product.ultimaCompra;
    _priceCtrl = TextEditingController(
      text: last == null ? '' : AppUtils.formatPrecioEditable(last.precio),
    );
    _priceCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _priceCtrl.text.length,
    );
    _initialStore = last?.establecimiento ?? '';
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
      await ref
          .read(productsProvider.notifier)
          .registerPurchase(
            productoId: widget.product.id!,
            precio: RegisterPurchase.parsePrecio(_priceCtrl.text)!,
            establecimiento: _storeCtrl?.text ?? _initialStore,
            fecha: _fecha,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider).valueOrNull ?? const <String>[];
    return AlertDialog(
      title: Text('Compra de ${widget.product.nombre}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _priceCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Precio por unidad',
                  hintText: 'Ej: 2,35',
                  prefixIcon: Icon(Icons.sell_outlined),
                  suffixText: '€',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  final p = RegisterPurchase.parsePrecio(v ?? '');
                  if (p == null || p <= 0) return 'Escribe un precio válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _initialStore),
                optionsBuilder: (value) {
                  final q = value.text.toLowerCase().trim();
                  if (q.isEmpty) return stores;
                  return stores.where((s) => s.toLowerCase().contains(q));
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  _storeCtrl = controller;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Establecimiento',
                      hintText: 'Ej: Mercado central',
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
                leading: const Icon(Icons.event_outlined),
                title: Text(AppUtils.formatFecha(_fecha)),
                subtitle: const Text('Fecha de compra'),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
