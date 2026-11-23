import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/register_purchase.dart';
import '../providers/products_provider.dart';
import '../providers/search_provider.dart';
import 'barcode_scanner_view.dart';
import 'food_picker_view.dart';

/// Alta o edición de un producto. Al crear, permite registrar también la
/// primera compra. Devuelve el id del producto guardado
/// (`Navigator.pop(context, id)`).
class ProductFormView extends ConsumerStatefulWidget {
  final Product? product;
  final String? codigoBarras;
  final String? initialName;

  const ProductFormView({
    super.key,
    this.product,
    this.codigoBarras,
    this.initialName,
  });

  @override
  ConsumerState<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends ConsumerState<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _sizeCtrl;
  final _priceCtrl = TextEditingController();
  TextEditingController? _storeCtrl;
  DateTime _fecha = DateTime.now();
  int? _alimentoId;
  bool _saving = false;

  bool get _isNew => widget.product == null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _codeCtrl = TextEditingController(
      text: p?.codigoBarras ?? widget.codigoBarras ?? '',
    );
    _nameCtrl = TextEditingController(
      text: p?.nombre ?? widget.initialName ?? '',
    );
    _brandCtrl = TextEditingController(text: p?.marca ?? '');
    _sizeCtrl = TextEditingController(text: p?.presentacion ?? '');
    _alimentoId = p?.alimentoId;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _sizeCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await BarcodeScannerView.scan(context);
    if (code != null) setState(() => _codeCtrl.text = code);
  }

  Future<void> _pickFood() async {
    final food = await FoodPickerView.pick(
      context,
      initialQuery: _nameCtrl.text.trim(),
    );
    if (food != null) setState(() => _alimentoId = food.id);
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
    final notifier = ref.read(productsProvider.notifier);
    try {
      final id = await notifier.saveProduct(
        Product(
          id: widget.product?.id,
          codigoBarras: _codeCtrl.text.trim(),
          nombre: _nameCtrl.text.trim(),
          marca: _brandCtrl.text.trim(),
          presentacion: _sizeCtrl.text.trim(),
          alimentoId: _alimentoId,
        ),
      );
      final precio = RegisterPurchase.parsePrecio(_priceCtrl.text);
      final store = _storeCtrl?.text.trim() ?? '';
      if (_isNew && precio != null && precio > 0 && store.isNotEmpty) {
        await notifier.registerPurchase(
          productoId: id,
          precio: precio,
          establecimiento: store,
          fecha: _fecha,
        );
      }
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final msg = e is StateError ? e.message : '$e';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider).valueOrNull ?? const <String>[];
    final Food? linked = _alimentoId == null
        ? null
        : ref.watch(foodByIdProvider(_alimentoId!)).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Nuevo producto' : 'Editar producto'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          children: [
            TextFormField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Código de barras (opcional)',
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  tooltip: 'Escanear',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scan,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              autofocus: _isNew && _nameCtrl.text.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto *',
                hintText: 'Ej: Leche entera',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Marca (opcional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sizeCtrl,
              decoration: const InputDecoration(
                labelText: 'Presentación (opcional)',
                hintText: 'Ej: 1 L, 500 g, pack de 6',
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_fire_department_outlined),
                title: Text(
                  linked == null
                      ? 'Sin vincular al contador de calorías'
                      : 'Calorías: ${linked.name}',
                ),
                subtitle: Text(
                  linked == null
                      ? 'Vincúlalo para registrar lo que comes escaneando el envase.'
                      : '${linked.kcalPer100} kcal por 100 g',
                ),
                trailing: _alimentoId == null
                    ? TextButton(
                        onPressed: _pickFood,
                        child: const Text('Vincular'),
                      )
                    : IconButton(
                        tooltip: 'Quitar vínculo',
                        icon: const Icon(Icons.link_off),
                        onPressed: () => setState(() => _alimentoId = null),
                      ),
                onTap: _pickFood,
              ),
            ),
            if (_isNew) ...[
              const SizedBox(height: 24),
              Text(
                'Primera compra (opcional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio por unidad',
                  hintText: 'Ej: 2,35',
                  prefixIcon: Icon(Icons.sell_outlined),
                  suffixText: '€',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final p = RegisterPurchase.parsePrecio(v);
                  return (p == null || p <= 0) ? 'Precio no válido' : null;
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
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
                    validator: (v) {
                      final hasPrice = _priceCtrl.text.trim().isNotEmpty;
                      if (hasPrice && (v == null || v.trim().isEmpty)) {
                        return '¿Dónde lo compraste?';
                      }
                      return null;
                    },
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(AppUtils.formatFecha(_fecha)),
                subtitle: const Text('Fecha de compra'),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickDate,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
