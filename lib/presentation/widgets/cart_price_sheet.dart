import 'package:flutter/material.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/register_purchase.dart';

/// Resultado de [CartPriceSheet].
class CartPriceResult {
  final double precio;
  final int unidades;

  /// Solo en edición: el usuario pulsó «Quitar del carrito».
  final bool quitar;

  /// Solo si se pidió la tienda ([CartPriceSheet.tiendas] no nulo).
  final String? tienda;

  const CartPriceResult({
    required this.precio,
    required this.unidades,
    this.quitar = false,
    this.tienda,
  });
}

/// Tarjeta inferior del modo carrito: precio unitario + unidades.
///
/// Con precio conocido viene precargado y basta un toque en el botón (no
/// abre el teclado, para no tapar el botón). Sin precio guardado el campo
/// queda vacío y es obligatorio. Avisa si el producto no está en la lista.
class CartPriceSheet extends StatefulWidget {
  final String titulo;
  final String? detalle;
  final Purchase? ultima;
  final double? precioInicial;
  final int unidadesIniciales;

  /// Unidades que ya hay en el carrito (se sumarán las nuevas).
  final int yaEnCarrito;

  /// Texto del artículo de la lista que se marcará, si es distinto del nombre.
  final String? marcaraItem;
  final bool fueraDeLista;
  final bool edicion;

  /// Artículo sin producto vinculado: el precio no va al historial.
  final bool sinHistorial;

  /// Si no es null, se pide también la tienda (fuera del modo carrito).
  final List<String>? tiendas;
  final String? tiendaInicial;

  const CartPriceSheet({
    super.key,
    required this.titulo,
    this.detalle,
    this.ultima,
    this.precioInicial,
    this.unidadesIniciales = 1,
    this.yaEnCarrito = 0,
    this.marcaraItem,
    this.fueraDeLista = false,
    this.edicion = false,
    this.sinHistorial = false,
    this.tiendas,
    this.tiendaInicial,
  });

  static Future<CartPriceResult?> show(
    BuildContext context,
    CartPriceSheet sheet,
  ) {
    return showModalBottomSheet<CartPriceResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => sheet,
    );
  }

  @override
  State<CartPriceSheet> createState() => _CartPriceSheetState();
}

class _CartPriceSheetState extends State<CartPriceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceCtrl;
  TextEditingController? _storeCtrl;
  late int _unidades;

  @override
  void initState() {
    super.initState();
    final p = widget.precioInicial;
    _priceCtrl = TextEditingController(
      text: p == null ? '' : AppUtils.formatPrecioEditable(p),
    );
    _unidades = widget.unidadesIniciales < 1 ? 1 : widget.unidadesIniciales;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  double? get _precio => RegisterPurchase.parsePrecio(_priceCtrl.text);

  void _submit({bool quitar = false}) {
    if (quitar) {
      Navigator.pop(
        context,
        CartPriceResult(precio: 0, unidades: 0, quitar: true),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CartPriceResult(
        precio: _precio!,
        unidades: _unidades,
        tienda: widget.tiendas == null ? null : _storeCtrl?.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ultima = widget.ultima;
    final precio = _precio;
    final sinPrecioGuardado = widget.precioInicial == null;
    final String boton;
    if (widget.edicion) {
      boton = 'Guardar';
    } else if (widget.fueraDeLista) {
      boton = 'Añadir aunque no está en la lista';
    } else {
      boton = 'Añadir al carrito';
    }

    return Padding(
      padding: EdgeInsets.only(
        left: AppStyles.paddingMedium,
        right: AppStyles.paddingMedium,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppStyles.paddingMedium,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.titulo, style: theme.textTheme.titleLarge),
              if ((widget.detalle ?? '').isNotEmpty)
                Text(widget.detalle!, style: AppStyles.labelText),
              if (ultima != null)
                Text(
                  'Último: ${AppUtils.formatPrecio(ultima.precio)} en '
                  '${ultima.establecimiento} '
                  '(${AppUtils.formatFechaCorta(ultima.fecha)})',
                  style: AppStyles.labelText,
                ),
              if (widget.fueraDeLista)
                _Banner(
                  color: AppStyles.semaphOrange,
                  icon: Icons.playlist_add,
                  text: 'Este producto no está en tu lista de compra.',
                ),
              if (widget.marcaraItem != null)
                _Banner(
                  color: AppStyles.semaphGreen,
                  icon: Icons.checklist,
                  text: 'Marcará «${widget.marcaraItem}» de tu lista.',
                ),
              if (widget.yaEnCarrito > 0)
                _Banner(
                  color: AppStyles.semaphBlue,
                  icon: Icons.shopping_cart,
                  text:
                      'Ya llevas ${widget.yaEnCarrito} en el carrito; '
                      'se sumarán estas unidades.',
                ),
              if (sinPrecioGuardado && !widget.edicion)
                _Banner(
                  color: AppStyles.semaphBlue,
                  icon: Icons.sell_outlined,
                  text: widget.sinHistorial
                      ? 'Escribe el precio de la etiqueta.'
                      : 'No hay precio guardado: escribe el de la etiqueta y '
                            'quedará registrado.',
                ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      autofocus: sinPrecioGuardado,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio por unidad',
                        hintText: 'Ej: 2,35',
                        suffixText: '€',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final p = RegisterPurchase.parsePrecio(v ?? '');
                        return (p == null || p <= 0)
                            ? 'Escribe un precio válido'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _UnitsStepper(
                    value: _unidades,
                    onChanged: (v) => setState(() => _unidades = v),
                  ),
                ],
              ),
              if (widget.tiendas != null) ...[
                const SizedBox(height: 12),
                Autocomplete<String>(
                  initialValue: TextEditingValue(
                    text: widget.tiendaInicial ?? '',
                  ),
                  optionsBuilder: (value) {
                    final q = value.text.toLowerCase().trim();
                    final all = widget.tiendas!;
                    if (q.isEmpty) return all;
                    return all.where((s) => s.toLowerCase().contains(q));
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
              ],
              if (widget.sinHistorial)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Este artículo no está vinculado a un producto: el precio '
                    'cuenta para el total pero no se guarda en el historial.',
                    style: AppStyles.labelText,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                precio == null || precio <= 0
                    ? ' '
                    : 'Subtotal: $_unidades × ${AppUtils.formatPrecio(precio)}'
                          ' = ${AppUtils.formatPrecio(precio * _unidades)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _submit(),
                icon: Icon(
                  widget.edicion ? Icons.check : Icons.add_shopping_cart,
                ),
                label: Text(boton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: widget.fueraDeLista && !widget.edicion
                      ? AppStyles.semaphOrange
                      : null,
                ),
              ),
              if (widget.edicion)
                TextButton.icon(
                  onPressed: () => _submit(quitar: true),
                  icon: const Icon(Icons.remove_shopping_cart),
                  label: const Text('Quitar del carrito'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppStyles.semaphRed,
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resultado de [NewProductSheet].
class NewProductResult {
  final String nombre;
  final String? marca;
  final double precio;
  final int unidades;

  const NewProductResult({
    required this.nombre,
    this.marca,
    required this.precio,
    required this.unidades,
  });
}

/// Tarjeta para un código que no está registrado: crea el producto con su
/// precio y lo mete en el carrito.
class NewProductSheet extends StatefulWidget {
  final String codigo;

  const NewProductSheet({super.key, required this.codigo});

  static Future<NewProductResult?> show(BuildContext context, String codigo) {
    return showModalBottomSheet<NewProductResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NewProductSheet(codigo: codigo),
    );
  }

  @override
  State<NewProductSheet> createState() => _NewProductSheetState();
}

class _NewProductSheetState extends State<NewProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  int _unidades = 1;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final marca = _brandCtrl.text.trim();
    Navigator.pop(
      context,
      NewProductResult(
        nombre: _nameCtrl.text.trim(),
        marca: marca.isEmpty ? null : marca,
        precio: RegisterPurchase.parsePrecio(_priceCtrl.text)!,
        unidades: _unidades,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppStyles.paddingMedium,
        right: AppStyles.paddingMedium,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppStyles.paddingMedium,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Producto nuevo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('Código ${widget.codigo}', style: AppStyles.labelText),
              const _Banner(
                color: AppStyles.semaphOrange,
                icon: Icons.info_outline,
                text:
                    'No está registrado. Se guardará con su precio. Si coincide '
                    'con algo de tu lista se marcará; si no, se añadirá a la '
                    'lista como comprado.',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto *',
                  hintText: 'Ej: Leche entera',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Escribe un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Marca (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio por unidad *',
                        hintText: 'Ej: 2,35',
                        suffixText: '€',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      validator: (v) {
                        final p = RegisterPurchase.parsePrecio(v ?? '');
                        return (p == null || p <= 0)
                            ? 'Escribe un precio válido'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _UnitsStepper(
                    value: _unidades,
                    onChanged: (v) => setState(() => _unidades = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Guardar y añadir al carrito'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «¿En qué tienda estás?»: autocompletado con las tiendas ya usadas y
/// accesos rápidos a las más recientes. Devuelve null si se cancela.
Future<String?> askStore(
  BuildContext context, {
  required List<String> tiendas,
  String? inicial,
}) async {
  final formKey = GlobalKey<FormState>();
  TextEditingController? ctrl;
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿En qué tienda estás?'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se usará para guardar los precios de lo que escanees.',
              style: AppStyles.labelText,
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: inicial ?? ''),
              optionsBuilder: (value) {
                final q = value.text.toLowerCase().trim();
                if (q.isEmpty) return tiendas;
                return tiendas.where((s) => s.toLowerCase().contains(q));
              },
              fieldViewBuilder: (context, controller, focusNode, _) {
                ctrl = controller;
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
                      ? 'Escribe el nombre de la tienda'
                      : null,
                );
              },
            ),
            if (tiendas.length > 1) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tiendas
                    .take(4)
                    .map(
                      (t) => ActionChip(
                        label: Text(t),
                        onPressed: () => Navigator.pop(ctx, t),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx, ctrl!.text.trim());
            }
          },
          child: const Text('Empezar'),
        ),
      ],
    ),
  );
  return (result == null || result.trim().isEmpty) ? null : result.trim();
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _Banner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _UnitsStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _UnitsStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Unidades', style: AppStyles.labelText),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              tooltip: 'Una menos',
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.outlined(
              tooltip: 'Una más',
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
