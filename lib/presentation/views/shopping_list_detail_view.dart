import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../providers/products_provider.dart';
import '../providers/shopping_provider.dart';
import '../widgets/cart_price_sheet.dart';
import 'cart_mode_view.dart';
import 'product_picker_view.dart';
import 'shopping_lists_view.dart';

/// Una lista de compra: añadir artículos (texto o productos), marcarlos como
/// comprados con su precio, total del carrito y acceso al «Modo carrito».
class ShoppingListDetailView extends ConsumerStatefulWidget {
  final int listaId;

  const ShoppingListDetailView({super.key, required this.listaId});

  @override
  ConsumerState<ShoppingListDetailView> createState() =>
      _ShoppingListDetailViewState();
}

class _ShoppingListDetailViewState
    extends ConsumerState<ShoppingListDetailView> {
  final _addCtrl = TextEditingController();
  final _addFocus = FocusNode();

  ShoppingItemsNotifier get _notifier =>
      ref.read(shoppingItemsProvider(widget.listaId).notifier);

  @override
  void dispose() {
    _addCtrl.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  Future<void> _addText() async {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    final parsed = parseIngredientLine(text);
    await _notifier.add(texto: parsed.nombre, cantidad: parsed.cantidad);
    _addCtrl.clear();
    _addFocus.requestFocus();
  }

  Future<void> _addProduct() async {
    final product = await ProductPickerView.pick(context);
    if (product == null) return;
    await _notifier.add(texto: product.nombre, productoId: product.id);
  }

  Future<Product?> _productOf(ShoppingItem item) async {
    if (item.productoId == null) return null;
    return ref.read(productRepositoryProvider).getProduct(item.productoId!);
  }

  /// Precio y unidades de un artículo marcado a mano (fuera del modo
  /// carrito). Con producto vinculado se pide también la tienda y se registra
  /// en el historial; sin producto, solo cuenta para el total del carrito.
  Future<void> _askPrice(ShoppingItem item) async {
    final product = await _productOf(item);
    if (!mounted) return;
    if (product == null) {
      final res = await CartPriceSheet.show(
        context,
        CartPriceSheet(
          titulo: item.texto,
          precioInicial: item.precioPagado,
          unidadesIniciales: item.unidades,
          sinHistorial: true,
          edicion: item.precioPagado != null,
        ),
      );
      if (res == null || !mounted) return;
      if (res.quitar) {
        await _notifier.removeFromCart(item);
      } else {
        await _notifier.updateCartItem(
          item,
          precio: res.precio,
          unidades: res.unidades,
        );
      }
      return;
    }

    if (item.compraId != null) {
      // Ya registrado: corregir precio/unidades o quitarlo del carrito.
      final res = await CartPriceSheet.show(
        context,
        CartPriceSheet(
          titulo: product.nombre,
          precioInicial: item.precioPagado,
          unidadesIniciales: item.unidades,
          edicion: true,
        ),
      );
      if (res == null || !mounted) return;
      if (res.quitar) {
        await _notifier.removeFromCart(item);
      } else {
        await _notifier.updateCartItem(
          item,
          precio: res.precio,
          unidades: res.unidades,
        );
      }
      return;
    }

    List<String> tiendas;
    try {
      tiendas = await ref.read(productRepositoryProvider).getStores();
    } catch (_) {
      tiendas = const [];
    }
    if (!mounted) return;
    final res = await CartPriceSheet.show(
      context,
      CartPriceSheet(
        titulo: product.nombre,
        ultima: product.ultimaCompra,
        precioInicial: product.ultimaCompra?.precio,
        tiendas: tiendas,
        tiendaInicial:
            product.ultimaCompra?.establecimiento ??
            (tiendas.isEmpty ? null : tiendas.first),
      ),
    );
    if (res == null || !mounted) return;
    await _notifier.addProductToCart(
      producto: product,
      precio: res.precio,
      unidades: res.unidades,
      establecimiento: res.tienda ?? '',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Precio de ${product.nombre} registrado')),
      );
    }
  }

  Future<void> _toggle(ShoppingItem item) async {
    final comprado = !item.comprado;
    await _notifier.setBought(item, comprado);
    if (!mounted || !comprado) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.texto} comprado'),
        action: SnackBarAction(
          label: 'Añadir precio',
          onPressed: () {
            // Relee el artículo: el estado ya cambió al marcarlo.
            final current = ref
                .read(shoppingItemsProvider(widget.listaId))
                .items
                .where((i) => i.id == item.id)
                .firstOrNull;
            if (current != null) _askPrice(current);
          },
        ),
      ),
    );
  }

  /// Modo carrito: escanear lo que se mete en el carrito con total en vivo.
  Future<void> _openCartMode() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CartModeView(listaId: widget.listaId)),
    );
  }

  Future<void> _edit(ShoppingItem item) async {
    final textCtrl = TextEditingController(text: item.texto);
    final qtyCtrl = TextEditingController(text: item.cantidad ?? '');
    var productoId = item.productoId;
    var productoNombre = productoId == null
        ? null
        : (await _productOf(item))?.nombre;
    if (!mounted) return;

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Editar artículo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Artículo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cantidad (opcional)',
                  hintText: 'Ej: 2 L, 1 kg, 3 unidades',
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(productoNombre ?? 'Sin producto vinculado'),
                subtitle: const Text('Para ver el precio de referencia'),
                trailing: productoId == null
                    ? TextButton(
                        onPressed: () async {
                          final p = await ProductPickerView.pick(ctx);
                          if (p != null) {
                            setLocal(() {
                              productoId = p.id;
                              productoNombre = p.nombre;
                            });
                          }
                        },
                        child: const Text('Vincular'),
                      )
                    : IconButton(
                        icon: const Icon(Icons.link_off),
                        onPressed: () => setLocal(() {
                          productoId = null;
                          productoNombre = null;
                        }),
                      ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (save == true && textCtrl.text.trim().isNotEmpty) {
      // Se conservan unidades, precio pagado y compra del carrito.
      await _notifier.update(
        ShoppingItem(
          id: item.id,
          listaId: item.listaId,
          texto: textCtrl.text.trim(),
          cantidad: qtyCtrl.text.trim(),
          productoId: productoId,
          comprado: item.comprado,
          orden: item.orden,
          unidades: item.unidades,
          precioPagado: item.precioPagado,
          compraId: productoId == item.productoId ? item.compraId : null,
        ),
      );
    }
    textCtrl.dispose();
    qtyCtrl.dispose();
  }

  Future<void> _copyAsText(String nombre, List<ShoppingItem> items) async {
    final b = StringBuffer('🛒 $nombre\n');
    for (final i in items) {
      final qty = (i.cantidad ?? '').isEmpty ? '' : ' (${i.cantidad})';
      b.writeln('${i.comprado ? '✅' : '⬜'} ${i.texto}$qty');
    }
    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista copiada. Pégala en WhatsApp, notas...'),
        ),
      );
    }
  }

  Future<void> _onMenu(String value, ShoppingList? list) async {
    final items = ref.read(shoppingItemsProvider(widget.listaId)).items;
    switch (value) {
      case 'copy':
        await _copyAsText(list?.nombre ?? 'Lista de compra', items);
      case 'uncheck':
        await _notifier.setAllBought(false);
      case 'clear':
        await _notifier.deleteBought();
      case 'rename':
        if (list == null) return;
        final name = await ShoppingListsView.askName(
          context,
          title: 'Renombrar lista',
          initial: list.nombre,
        );
        if (name != null) {
          await ref
              .read(shoppingListsProvider.notifier)
              .rename(widget.listaId, name);
        }
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar lista'),
            content: const Text('¿Eliminar esta lista y todos sus artículos?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await ref.read(shoppingListsProvider.notifier).delete(widget.listaId);
          if (mounted) Navigator.pop(context);
        }
    }
  }

  Widget _itemTile(ShoppingItem item) {
    final theme = Theme.of(context);
    final pagado = item.precioPagado;
    final info = [
      if ((item.cantidad ?? '').isNotEmpty) item.cantidad!,
      if (item.comprado && pagado != null)
        '${item.unidades} × ${AppUtils.formatPrecio(pagado)} = '
            '${AppUtils.formatPrecio(item.subtotal!)}'
      else if (item.precioReferencia != null)
        'Ref: ${AppUtils.formatPrecio(item.precioReferencia!)}'
            '${item.establecimientoReferencia == null ? '' : ' (${item.establecimientoReferencia})'}',
    ].join(' · ');
    return Dismissible(
      key: ValueKey('item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _notifier.delete(item),
      child: ListTile(
        leading: Checkbox(
          value: item.comprado,
          onChanged: (_) => _toggle(item),
        ),
        title: Text(
          item.texto,
          style: item.comprado
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: info.isEmpty ? null : Text(info),
        trailing: item.productoId == null && !item.comprado
            ? null
            : IconButton(
                tooltip: 'Precio',
                icon: const Icon(Icons.sell_outlined),
                onPressed: () => _askPrice(item),
              ),
        onTap: () => _toggle(item),
        onLongPress: () => _edit(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shoppingItemsProvider(widget.listaId));
    final lists = ref.watch(shoppingListsProvider).lists;
    final list = lists.where((l) => l.id == widget.listaId).firstOrNull;
    final pendientes = state.pendientes;
    final comprados = state.comprados;

    return Scaffold(
      appBar: AppBar(
        title: Text(list?.nombre ?? 'Lista de compra'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Modo carrito',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openCartMode,
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(v, list),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'copy', child: Text('Copiar como texto')),
              PopupMenuItem(value: 'uncheck', child: Text('Desmarcar todo')),
              PopupMenuItem(value: 'clear', child: Text('Quitar comprados')),
              PopupMenuItem(value: 'rename', child: Text('Renombrar lista')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar lista')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    focusNode: _addFocus,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Añadir artículo (ej: 2 L de leche)',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addText(),
                  ),
                ),
                IconButton(
                  tooltip: 'Añadir',
                  icon: const Icon(Icons.add_circle, color: AppStyles.primary),
                  onPressed: _addText,
                ),
                IconButton(
                  tooltip: 'Añadir desde mis productos',
                  icon: const Icon(Icons.inventory_2_outlined),
                  onPressed: _addProduct,
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppStyles.paddingLarge),
                      child: Text(
                        'Lista vacía. Escribe arriba lo que necesitas, '
                        'añade productos guardados o abre el modo carrito '
                        'en el súper.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      ...pendientes.map(_itemTile),
                      if (comprados.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            'Comprados (${comprados.length})',
                            style: AppStyles.labelText,
                          ),
                        ),
                      ...comprados.map(_itemTile),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 88),
                        child: Text(
                          'Toca para marcar · mantén pulsado para editar · '
                          'desliza a la izquierda para borrar',
                          style: AppStyles.labelText,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'modo_carrito',
        onPressed: _openCartMode,
        icon: const Icon(Icons.shopping_cart_checkout),
        label: const Text('Modo carrito'),
      ),
      bottomNavigationBar: _totalsBar(state),
    );
  }

  /// Barra inferior: total del carrito y estimación de lo que falta.
  Widget? _totalsBar(ShoppingItemsState state) {
    final hayCarrito = state.comprados.any((i) => i.precioPagado != null);
    final hayEstimado = state.estimadoPendiente > 0;
    if (!hayCarrito && !hayEstimado) return null;
    Widget row(String label, double value, {bool bold = false}) {
      return Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            AppUtils.formatPrecio(value),
            style: TextStyle(
              fontSize: bold ? 18 : 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return Material(
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row(
                'En el carrito (${state.articulosEnCarrito})'
                '${state.compradosSinPrecio > 0 ? ' · ${state.compradosSinPrecio} sin precio' : ''}',
                state.totalCarrito,
                bold: true,
              ),
              if (hayEstimado)
                row(
                  'Falta por comprar (estimado)'
                  '${state.pendientesSinPrecio > 0 ? ' · ${state.pendientesSinPrecio} sin precio' : ''}',
                  state.estimadoPendiente,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
