import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/services/cart_matching.dart';
import '../providers/products_provider.dart';
import '../providers/shopping_provider.dart';
import '../widgets/cart_price_sheet.dart';
import 'barcode_scanner_view.dart';

/// Construye el lector de códigos; permite sustituir la cámara en tests.
typedef CartScannerBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onCode);

/// «Modo carrito»: cámara siempre abierta para ir escaneando lo que se mete
/// en el carrito. Cada producto se confirma con su precio (precargado si hay
/// historial; si no, se pide), suma al total, marca la lista y registra la
/// compra en el historial con la tienda elegida al entrar.
class CartModeView extends ConsumerStatefulWidget {
  final int listaId;
  final CartScannerBuilder? scannerBuilder;

  const CartModeView({super.key, required this.listaId, this.scannerBuilder});

  @override
  ConsumerState<CartModeView> createState() => _CartModeViewState();
}

class _CartModeViewState extends ConsumerState<CartModeView> {
  /// Espera antes de aceptar otra vez el mismo código (la cámara lo detecta
  /// en varios fotogramas seguidos). Escanearlo de nuevo = una unidad más.
  static const _esperaMismoCodigo = Duration(milliseconds: 2500);

  String? _tienda;
  bool _busy = false;
  String? _lastCode;
  DateTime? _lastAt;

  ShoppingItemsNotifier get _notifier =>
      ref.read(shoppingItemsProvider(widget.listaId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _chooseStore());
  }

  Future<void> _chooseStore() async {
    List<String> tiendas;
    try {
      tiendas = await ref.read(productRepositoryProvider).getStores();
    } catch (_) {
      tiendas = const [];
    }
    if (!mounted) return;
    final tienda = await askStore(
      context,
      tiendas: tiendas,
      inicial: _tienda ?? (tiendas.isEmpty ? null : tiendas.first),
    );
    if (!mounted) return;
    if (tienda == null) {
      // Sin tienda no se puede registrar nada: al entrar, cancelar = salir.
      if (_tienda == null) Navigator.pop(context);
      return;
    }
    setState(() => _tienda = tienda);
  }

  void _toast(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onCode(String code) async {
    if (_busy || _tienda == null) return;
    final now = DateTime.now();
    if (code == _lastCode &&
        _lastAt != null &&
        now.difference(_lastAt!) < _esperaMismoCodigo) {
      return;
    }
    _busy = true;
    try {
      final product = await ref
          .read(productRepositoryProvider)
          .getProductByBarcode(code);
      if (!mounted) return;
      if (product == null) {
        await _addNewProduct(code);
      } else {
        await _addKnownProduct(product);
      }
    } catch (e) {
      if (mounted) _toast('No se pudo añadir: $e');
    } finally {
      // La espera cuenta desde que se cierra la tarjeta.
      _lastCode = code;
      _lastAt = DateTime.now();
      _busy = false;
    }
  }

  Future<void> _addKnownProduct(Product product) async {
    final items = ref.read(shoppingItemsProvider(widget.listaId)).items;
    final target = findItemForProduct(items, product);
    final enCarrito =
        target != null &&
        target.comprado &&
        (target.precioPagado != null || target.compraId != null);
    final detalle = [
      if ((product.marca ?? '').isNotEmpty) product.marca!,
      if ((product.presentacion ?? '').isNotEmpty) product.presentacion!,
    ].join(' · ');

    final res = await CartPriceSheet.show(
      context,
      CartPriceSheet(
        titulo: product.nombre,
        detalle: detalle,
        ultima: product.ultimaCompra,
        precioInicial: enCarrito
            ? target.precioPagado
            : product.ultimaCompra?.precio,
        yaEnCarrito: enCarrito ? target.unidades : 0,
        marcaraItem:
            target != null && !target.comprado && target.texto != product.nombre
            ? target.texto
            : null,
        fueraDeLista: target == null,
      ),
    );
    if (res == null || !mounted) return;
    await _notifier.addProductToCart(
      producto: product,
      precio: res.precio,
      unidades: res.unidades,
      establecimiento: _tienda!,
    );
    HapticFeedback.lightImpact();
    if (mounted) {
      _toast(
        '✓ ${product.nombre} · '
        '${AppUtils.formatPrecio(res.precio * res.unidades)}',
      );
    }
  }

  Future<void> _addNewProduct(String code) async {
    final res = await NewProductSheet.show(context, code);
    if (res == null || !mounted) return;
    final productsNotifier = ref.read(productsProvider.notifier);
    final id = await productsNotifier.saveProduct(
      Product(codigoBarras: code, nombre: res.nombre, marca: res.marca),
    );
    final product = await ref.read(productRepositoryProvider).getProduct(id);
    if (product == null || !mounted) return;
    // saveProduct recrea los providers de la lista: se relee el notifier.
    await _notifier.addProductToCart(
      producto: product,
      precio: res.precio,
      unidades: res.unidades,
      establecimiento: _tienda!,
    );
    HapticFeedback.lightImpact();
    if (mounted) {
      _toast(
        '✓ ${product.nombre} · '
        '${AppUtils.formatPrecio(res.precio * res.unidades)}',
      );
    }
  }

  /// Tocar un artículo del carrito: corregir precio/unidades o quitarlo.
  Future<void> _editCartItem(ShoppingItem item) async {
    _busy = true;
    try {
      final res = await CartPriceSheet.show(
        context,
        CartPriceSheet(
          titulo: item.texto,
          precioInicial: item.precioPagado,
          unidadesIniciales: item.unidades,
          edicion: true,
          sinHistorial: item.productoId == null,
        ),
      );
      if (res == null || !mounted) return;
      if (res.quitar) {
        await _notifier.removeFromCart(item);
        if (mounted) _toast('${item.texto} quitado del carrito');
      } else {
        await _notifier.updateCartItem(
          item,
          precio: res.precio,
          unidades: res.unidades,
        );
      }
    } finally {
      _busy = false;
    }
  }

  /// Tocar un pendiente: meterlo en el carrito sin escanear (fruta a granel,
  /// productos sin código...).
  Future<void> _addPendingItem(ShoppingItem item) async {
    _busy = true;
    try {
      if (item.productoId != null) {
        final product = await ref
            .read(productRepositoryProvider)
            .getProduct(item.productoId!);
        if (product != null && mounted) {
          await _addKnownProduct(product);
          return;
        }
      }
      if (!mounted) return;
      final res = await CartPriceSheet.show(
        context,
        CartPriceSheet(titulo: item.texto, sinHistorial: true),
      );
      if (res == null || !mounted) return;
      await _notifier.updateCartItem(
        item,
        precio: res.precio,
        unidades: res.unidades,
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> _finish(ShoppingItemsState state) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppUtils.formatPrecio(state.totalCarrito),
              style: Theme.of(
                ctx,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${state.articulosEnCarrito} '
              '${state.articulosEnCarrito == 1 ? 'artículo' : 'artículos'} '
              'en $_tienda',
            ),
            if (state.compradosSinPrecio > 0)
              Text(
                '${state.compradosSinPrecio} sin precio (no suman)',
                style: const TextStyle(color: AppStyles.semaphOrange),
              ),
            if (state.pendientes.isNotEmpty)
              Text('Quedan ${state.pendientes.length} pendientes en la lista.'),
            const SizedBox(height: 8),
            const Text(
              'Los precios de los productos ya están guardados en el '
              'historial.',
              style: AppStyles.labelText,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Seguir comprando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'mantener'),
            child: const Text('Mantener la lista'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'quitar'),
            child: const Text('Quitar comprados'),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'quitar') await _notifier.deleteBought();
    if (mounted) Navigator.pop(context);
  }

  Widget _cartTile(ShoppingItem item) {
    final precio = item.precioPagado;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppStyles.primary.withValues(alpha: 0.12),
        child: Text(
          '${item.unidades}×',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(item.texto, style: const TextStyle(fontSize: 16)),
      subtitle: precio == null
          ? const Text(
              'Sin precio · toca para añadirlo',
              style: TextStyle(color: AppStyles.semaphOrange),
            )
          : Text('${AppUtils.formatPrecio(precio)} / ud.'),
      trailing: Text(
        precio == null ? '—' : AppUtils.formatPrecio(item.subtotal!),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onTap: () => _editCartItem(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shoppingItemsProvider(widget.listaId));
    final comprados = state.comprados;
    final pendientes = state.pendientes;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo carrito'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_tienda != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.storefront_outlined, size: 18),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(_tienda!, overflow: TextOverflow.ellipsis),
                ),
                tooltip: 'Cambiar de tienda',
                onPressed: _chooseStore,
              ),
            ),
        ],
      ),
      body: _tienda == null
          ? Center(
              child: TextButton.icon(
                onPressed: _chooseStore,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Elige la tienda para empezar'),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 210,
                  child:
                      widget.scannerBuilder?.call(context, _onCode) ??
                      BarcodeScannerPanel(
                        onCode: _onCode,
                        compacto: true,
                        instrucciones: 'Escanea cada producto al meterlo',
                      ),
                ),
                Material(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_cart, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'En el carrito · ${state.articulosEnCarrito} '
                                '${state.articulosEnCarrito == 1 ? 'artículo' : 'artículos'}',
                              ),
                              if (pendientes.isNotEmpty)
                                Text(
                                  'Te faltan ${pendientes.length}'
                                  '${state.estimadoPendiente > 0 ? ' (≈ ${AppUtils.formatPrecio(state.estimadoPendiente)})' : ''}',
                                  style: AppStyles.labelText,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          AppUtils.formatPrecio(state.totalCarrito),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (comprados.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppStyles.paddingLarge),
                          child: Text(
                            'Escanea el código de barras de cada producto al '
                            'meterlo en el carrito. Lo que no tenga código '
                            '(fruta a granel...) añádelo tocándolo en '
                            '«Te falta».',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ...comprados.map(_cartTile),
                      if (pendientes.isNotEmpty)
                        ExpansionTile(
                          initiallyExpanded: comprados.isEmpty,
                          leading: const Icon(Icons.checklist),
                          title: Text('Te falta (${pendientes.length})'),
                          children: pendientes
                              .map(
                                (i) => ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.check_box_outline_blank,
                                  ),
                                  title: Text(i.texto),
                                  subtitle: (i.cantidad ?? '').isEmpty
                                      ? null
                                      : Text(i.cantidad!),
                                  trailing: const Icon(Icons.add_shopping_cart),
                                  onTap: () => _addPendingItem(i),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: FilledButton.icon(
                      onPressed: () => _finish(state),
                      icon: const Icon(Icons.check),
                      label: const Text('Terminar compra'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
