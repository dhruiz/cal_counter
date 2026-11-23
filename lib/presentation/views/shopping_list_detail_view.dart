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
import '../widgets/purchase_dialog.dart';
import 'barcode_scanner_view.dart';
import 'product_form_view.dart';
import 'product_picker_view.dart';
import 'shopping_lists_view.dart';

/// Una lista de compra: añadir artículos (texto o productos), marcarlos como
/// comprados, precio estimado y modo "escanear en el súper".
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

  Future<void> _askPrice(ShoppingItem item) async {
    final product = await _productOf(item);
    if (product == null || !mounted) return;
    final ok = await PurchaseDialog.show(context, product);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Precio de ${product.nombre} registrado')),
      );
    }
  }

  Future<void> _toggle(ShoppingItem item) async {
    final comprado = !item.comprado;
    await _notifier.setBought(item, comprado);
    if (!mounted || !comprado || item.productoId == null) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.texto} comprado'),
        action: SnackBarAction(
          label: 'Registrar precio',
          onPressed: () => _askPrice(item),
        ),
      ),
    );
  }

  /// Escanear en el súper: marca el artículo (o lo añade) y pide el precio.
  Future<void> _scan() async {
    final code = await BarcodeScannerView.scan(
      context,
      title: 'Escanear en el súper',
    );
    if (code == null || !mounted) return;
    final product = await ref
        .read(productRepositoryProvider)
        .getProductByBarcode(code);
    if (!mounted) return;

    if (product == null) {
      final create = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Producto nuevo'),
          content: Text(
            'El código $code no está registrado. ¿Quieres registrarlo ahora? '
            'Se añadirá a la lista como comprado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      );
      if (create != true || !mounted) return;
      final id = await Navigator.push<int>(
        context,
        MaterialPageRoute(builder: (_) => ProductFormView(codigoBarras: code)),
      );
      if (id == null || !mounted) return;
      final created = await ref.read(productRepositoryProvider).getProduct(id);
      if (created == null) return;
      await _notifier.add(
        texto: created.nombre,
        productoId: created.id,
        comprado: true,
      );
      return;
    }

    final items = ref.read(shoppingItemsProvider(widget.listaId)).items;
    final match = items.where((i) => i.productoId == product.id && !i.comprado);
    if (match.isNotEmpty) {
      await _notifier.setBought(match.first, true);
    } else {
      await _notifier.add(
        texto: product.nombre,
        productoId: product.id,
        comprado: true,
      );
    }
    if (!mounted) return;
    await PurchaseDialog.show(context, product);
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
      await _notifier.update(
        ShoppingItem(
          id: item.id,
          listaId: item.listaId,
          texto: textCtrl.text.trim(),
          cantidad: qtyCtrl.text.trim(),
          productoId: productoId,
          comprado: item.comprado,
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
    final info = [
      if ((item.cantidad ?? '').isNotEmpty) item.cantidad!,
      if (item.precioReferencia != null)
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
        trailing: item.productoId == null
            ? null
            : IconButton(
                tooltip: 'Registrar precio',
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
            tooltip: 'Escanear en el súper',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scan,
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
                        'añade productos guardados o escanea en el súper.',
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
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Text(
                          'Toca para marcar · mantén pulsado para editar · '
                          'desliza a la izquierda para borrar',
                          style: AppStyles.labelText,
                        ),
                      ),
                    ],
                  ),
          ),
          if (state.items.any((i) => i.precioReferencia != null))
            Material(
              elevation: 4,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.sinPrecio == 0
                              ? 'Total estimado'
                              : 'Total estimado (${state.sinPrecio} sin precio)',
                        ),
                      ),
                      Text(
                        AppUtils.formatPrecio(state.totalEstimado),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
