import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/product.dart';
import '../providers/products_provider.dart';
import '../widgets/empty_state.dart';
import 'barcode_scanner_view.dart';
import 'product_detail_view.dart';
import 'product_form_view.dart';

/// Pestaña "Productos": catálogo de productos con su último precio,
/// alta por código de barras e historial exportable.
class ProductsView extends ConsumerWidget {
  const ProductsView({super.key});

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final code = await BarcodeScannerView.scan(context);
    if (code == null || !context.mounted) return;
    final product = await ref
        .read(productRepositoryProvider)
        .getProductByBarcode(code);
    if (!context.mounted) return;
    if (product != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProductDetailView(productId: product.id!, abrirCompra: true),
        ),
      );
    } else {
      final id = await Navigator.push<int>(
        context,
        MaterialPageRoute(builder: (_) => ProductFormView(codigoBarras: code)),
      );
      if (id != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto guardado')));
      }
    }
  }

  Future<void> _addWithoutCode(BuildContext context) async {
    await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const ProductFormView()),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final tsv = await ref.read(productsProvider.notifier).exportHistory();
      final rows = tsv.trim().split('\n').length - 1;
      if (rows <= 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No hay compras en los últimos 3 meses.'),
          ),
        );
        return;
      }
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Exportar historial de precios',
        fileName: 'historial_precios_$date.csv',
        bytes: Uint8List.fromList(utf8.encode(tsv)),
      );
      if (saved == null) return; // Cancelado
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '$rows compras exportadas a: '
            '${AppUtils.formatRutaGuardada(saved)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Productos y precios'),
        content: const Text(
          '• Escanea el código de barras de un producto para registrarlo o '
          'anotar lo que pagaste y dónde.\n\n'
          '• Se guarda el historial de los últimos 3 meses. Las compras más '
          'antiguas se borran solas, pero la última compra de cada producto '
          'se conserva siempre.\n\n'
          '• Con "Exportar" obtienes un archivo .csv (separado por '
          'tabulaciones, precios en euros) para estudiar cómo varían los '
          'precios en una hoja de cálculo.\n\n'
          '• Si vinculas un producto a un alimento del contador, podrás '
          'registrar lo que comes escaneando el envase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider);
    final products = ref.watch(filteredProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos y precios'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Exportar historial (3 meses)',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _export(context, ref),
          ),
          IconButton(
            tooltip: 'Ayuda',
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'producto_sin_codigo',
            tooltip: 'Añadir producto sin código',
            onPressed: () => _addWithoutCode(context),
            child: const Icon(Icons.edit_note),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'escanear_producto',
            onPressed: () => _scan(context, ref),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.products.isEmpty
          ? EmptyState(
              icon: Icons.qr_code_scanner,
              title: 'Registra tus productos',
              message:
                  'Escanea el código de barras de lo que compras para llevar '
                  'la cuenta de precios, fechas y establecimientos.',
              actions: [
                ElevatedButton.icon(
                  onPressed: () => _scan(context, ref),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear un producto'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _addWithoutCode(context),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Añadir sin código'),
                ),
              ],
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nombre, marca o código',
                      isDense: true,
                    ),
                    onChanged: ref.read(productsProvider.notifier).setQuery,
                  ),
                ),
                Expanded(
                  child: products.isEmpty
                      ? const Center(child: Text('Sin resultados'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 140),
                          itemCount: products.length,
                          itemBuilder: (ctx, i) =>
                              _ProductTile(product: products[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final last = product.ultimaCompra;
    final details = [
      if ((product.marca ?? '').isNotEmpty) product.marca!,
      if ((product.presentacion ?? '').isNotEmpty) product.presentacion!,
    ].join(' · ');
    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          product.codigoBarras == null ? Icons.shopping_basket : Icons.qr_code,
        ),
      ),
      title: Text(product.nombre),
      subtitle: Text(
        [
          if (details.isNotEmpty) details,
          last == null
              ? 'Sin compras registradas'
              : 'Último: ${AppUtils.formatPrecio(last.precio)} · '
                    '${last.establecimiento} · ${AppUtils.formatFecha(last.fecha)}',
        ].join('\n'),
      ),
      isThreeLine: details.isNotEmpty,
      trailing: product.alimentoId != null
          ? const Tooltip(
              message: 'Vinculado al contador de calorías',
              child: Icon(
                Icons.local_fire_department,
                color: AppStyles.ringKcal,
              ),
            )
          : null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailView(productId: product.id!),
        ),
      ),
    );
  }
}
