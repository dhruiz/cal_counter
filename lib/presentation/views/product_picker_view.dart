import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../providers/products_provider.dart';
import 'product_form_view.dart';

/// Selector de un producto del catálogo (para añadirlo a una lista de compra).
/// Devuelve el [Product] elegido o null.
class ProductPickerView extends ConsumerStatefulWidget {
  const ProductPickerView({super.key});

  static Future<Product?> pick(BuildContext context) {
    return Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => const ProductPickerView()),
    );
  }

  @override
  ConsumerState<ProductPickerView> createState() => _ProductPickerViewState();
}

class _ProductPickerViewState extends ConsumerState<ProductPickerView> {
  String _query = '';

  Future<void> _create() async {
    final id = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormView(initialName: _query.trim()),
      ),
    );
    if (id == null || !mounted) return;
    final product = await ref.read(productRepositoryProvider).getProduct(id);
    if (mounted && product != null) Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(productsProvider).products;
    final q = normalizeText(_query);
    final products = q.isEmpty
        ? all
        : all
              .where(
                (p) =>
                    normalizeText(p.nombre).contains(q) ||
                    normalizeText(p.marca ?? '').contains(q),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        title: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Buscar en mis productos...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView(
        children: [
          ...products.map((p) {
            final last = p.ultimaCompra;
            return ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(p.nombre),
              subtitle: Text(
                [
                  if ((p.marca ?? '').isNotEmpty) p.marca!,
                  if ((p.presentacion ?? '').isNotEmpty) p.presentacion!,
                  if (last != null)
                    '${AppUtils.formatPrecio(last.precio)} en ${last.establecimiento}',
                ].join(' · '),
              ),
              onTap: () => Navigator.pop(context, p),
            );
          }),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Nuevo producto'),
            onTap: _create,
          ),
        ],
      ),
    );
  }
}
