import 'package:flutter/material.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/services/money.dart';
import 'food_widgets.dart';

/// Resultado de [CartPriceSheet].
class CartPriceResult {
  /// Precio unitario en céntimos.
  final int precioCent;
  final int unidades;

  /// Solo en edición: el usuario pulsó «Quitar del carrito».
  final bool quitar;

  /// Solo si se pidió la tienda ([CartPriceSheet.tiendas] no nulo).
  final String? tienda;

  const CartPriceResult({
    required this.precioCent,
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
  final int? precioInicialCent;
  final int unidadesIniciales;

  /// Unidades que ya hay en el carrito (se sumarán las nuevas).
  final int yaEnCarrito;

  /// Texto del artículo de la lista que se marcará, si es distinto del nombre.
  final String? marcaraItem;
  final bool fueraDeLista;
  final bool edicion;

  /// Si no es null, se pide también la tienda (fuera del modo carrito).
  final List<String>? tiendas;
  final String? tiendaInicial;

  /// Producto al peso (etiqueta de báscula): se pide el importe del paquete
  /// y no hay unidades.
  final bool alPeso;

  const CartPriceSheet({
    super.key,
    required this.titulo,
    this.detalle,
    this.ultima,
    this.precioInicialCent,
    this.unidadesIniciales = 1,
    this.yaEnCarrito = 0,
    this.marcaraItem,
    this.fueraDeLista = false,
    this.edicion = false,
    this.tiendas,
    this.tiendaInicial,
    this.alPeso = false,
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
    final p = widget.precioInicialCent;
    _priceCtrl = TextEditingController(
      text: p == null ? '' : AppUtils.formatPrecioEditableCent(p),
    );
    _unidades = widget.unidadesIniciales < 1 ? 1 : widget.unidadesIniciales;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  int? get _precioCent => parsePrecioCent(_priceCtrl.text);

  void _submit({bool quitar = false}) {
    if (quitar) {
      Navigator.pop(
        context,
        const CartPriceResult(precioCent: 0, unidades: 0, quitar: true),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CartPriceResult(
        precioCent: _precioCent!,
        unidades: _unidades,
        tienda: widget.tiendas == null ? null : _storeCtrl?.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ultima = widget.ultima;
    final precio = _precioCent;
    final sinPrecioGuardado = widget.precioInicialCent == null;
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
                  'Último: ${AppUtils.formatPrecioCent(ultima.precioCent)} en '
                  '${ultima.establecimiento} '
                  '(${AppUtils.formatFechaCorta(ultima.fecha)})',
                  style: AppStyles.labelText,
                ),
              if (widget.fueraDeLista)
                const InfoBanner(
                  color: AppStyles.semaphOrange,
                  icon: Icons.playlist_add,
                  text: 'Este producto no está en tu lista de compra.',
                ),
              if (widget.marcaraItem != null)
                InfoBanner(
                  color: AppStyles.semaphGreen,
                  icon: Icons.checklist,
                  text: 'Marcará «${widget.marcaraItem}» de tu lista.',
                ),
              if (widget.yaEnCarrito > 0)
                InfoBanner(
                  color: AppStyles.semaphBlue,
                  icon: Icons.shopping_cart,
                  text: widget.alPeso
                      ? 'Ya llevas este producto en el carrito; se sumará '
                            'este paquete.'
                      : 'Ya llevas ${widget.yaEnCarrito} en el carrito; '
                            'se sumarán estas unidades.',
                ),
              if (sinPrecioGuardado && !widget.edicion)
                InfoBanner(
                  color: AppStyles.semaphBlue,
                  icon: Icons.sell_outlined,
                  text: widget.alPeso
                      ? 'Escribe el importe que marca la etiqueta: la próxima '
                            'vez se calculará solo con el peso.'
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
                      decoration: InputDecoration(
                        labelText: widget.alPeso
                            ? 'Importe del paquete'
                            : 'Precio por unidad',
                        hintText: 'Ej: 2,35',
                        suffixText: '€',
                        prefixIcon: const Icon(Icons.sell_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => parsePrecioCent(v ?? '') == null
                          ? 'Escribe un precio válido'
                          : null,
                    ),
                  ),
                  if (!widget.alPeso) ...[
                    const SizedBox(width: 8),
                    _UnitsStepper(
                      value: _unidades,
                      onChanged: (v) => setState(() => _unidades = v),
                    ),
                  ],
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
              const SizedBox(height: 12),
              Text(
                precio == null || widget.alPeso
                    ? ' '
                    : 'Subtotal: $_unidades × ${AppUtils.formatPrecioCent(precio)}'
                          ' = ${AppUtils.formatPrecioCent(precio * _unidades)}',
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
  final String marca;
  final String presentacion;
  final double? contenido;
  final String unidad;
  final int precioCent;
  final int unidades;

  /// El usuario indicó que es otra presentación de un alimento que ya tiene:
  /// hay que elegirlo (nombre y marca se ignoran).
  final bool otraPresentacion;

  const NewProductResult({
    required this.nombre,
    this.marca = '',
    this.presentacion = '',
    this.contenido,
    this.unidad = 'g',
    required this.precioCent,
    required this.unidades,
    this.otraPresentacion = false,
  });
}

/// Alta mínima EN LA TIENDA para un código que no está registrado: avisa de
/// que no existe y pide solo lo básico (nombre, marca, presentación y
/// precio). Nunca la tabla nutricional: queda pendiente para casa.
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
  final _packCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _unidad = 'g';
  int _unidades = 1;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _brandCtrl,
      _packCtrl,
      _contentCtrl,
      _priceCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit({bool otraPresentacion = false}) {
    final precio = parsePrecioCent(_priceCtrl.text);
    if (otraPresentacion) {
      // Solo hace falta el precio para registrar la compra.
      if (precio == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe primero el precio.')),
        );
        return;
      }
      Navigator.pop(
        context,
        NewProductResult(
          nombre: '',
          presentacion: _packCtrl.text.trim(),
          contenido: parseDecimal(_contentCtrl.text),
          unidad: _unidad,
          precioCent: precio,
          unidades: _unidades,
          otraPresentacion: true,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      NewProductResult(
        nombre: _nameCtrl.text.trim(),
        marca: _brandCtrl.text.trim(),
        presentacion: _packCtrl.text.trim(),
        contenido: parseDecimal(_contentCtrl.text),
        unidad: _unidad,
        precioCent: precio!,
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
                'Producto no registrado',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('Código ${widget.codigo}', style: AppStyles.labelText),
              const InfoBanner(
                color: AppStyles.semaphOrange,
                icon: Icons.info_outline,
                text:
                    'Este código no está en tus alimentos. Indica lo básico y '
                    'el precio; la tabla nutricional se completa luego en '
                    'casa.',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Leche semidesnatada',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Escribe un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      decoration: const InputDecoration(labelText: 'Contenido'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: DropdownButton<String>(
                      value: _unidad,
                      items: const [
                        DropdownMenuItem(value: 'g', child: Text('g')),
                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                      ],
                      onChanged: (v) => setState(() => _unidad = v ?? 'g'),
                    ),
                  ),
                ],
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
                      validator: (v) => parsePrecioCent(v ?? '') == null
                          ? 'Escribe un precio válido'
                          : null,
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
              TextButton.icon(
                onPressed: () => _submit(otraPresentacion: true),
                icon: const Icon(Icons.link),
                label: const Text('Es otra presentación de uno que ya tengo'),
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
