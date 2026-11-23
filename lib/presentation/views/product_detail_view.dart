import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/price_stats.dart';
import '../../domain/entities/product.dart';
import '../providers/products_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/add_food_popup.dart';
import '../widgets/empty_state.dart';
import '../widgets/purchase_dialog.dart';
import 'food_picker_view.dart';
import 'product_form_view.dart';

/// Detalle de un producto: precios (último, mín/promedio/máx de 3 meses,
/// por establecimiento), historial de compras y vínculo con calorías.
class ProductDetailView extends ConsumerStatefulWidget {
  final int productId;

  /// Abre el diálogo de compra al entrar (tras escanear un producto conocido).
  final bool abrirCompra;

  const ProductDetailView({
    super.key,
    required this.productId,
    this.abrirCompra = false,
  });

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  bool _compraAbierta = false;

  Future<void> _registerPurchase(Product product) async {
    final ok = await PurchaseDialog.show(context, product);
    if (ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compra registrada')));
    }
  }

  Future<void> _edit(Product product) async {
    await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormView(product: product)),
    );
  }

  Future<void> _delete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${product.nombre}" y todo su historial de precios?',
        ),
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
    if (ok != true) return;
    await ref.read(productsProvider.notifier).deleteProduct(product.id!);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _linkFood(Product product) async {
    final food = await FoodPickerView.pick(
      context,
      initialQuery: product.nombre,
    );
    if (food == null) return;
    await ref
        .read(productsProvider.notifier)
        .saveProduct(product.copyWith(alimentoId: food.id));
  }

  Future<void> _deletePurchase(Purchase c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar compra'),
        content: Text(
          '¿Eliminar la compra del ${AppUtils.formatFecha(c.fecha)} '
          'en ${c.establecimiento}?',
        ),
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
      await ref.read(productsProvider.notifier).deletePurchase(c.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(widget.productId));
    final product = detail.valueOrNull?.product;

    if (widget.abrirCompra && !_compraAbierta && product != null) {
      _compraAbierta = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _registerPurchase(product);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product?.nombre ?? 'Producto'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          if (product != null) ...[
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () => _edit(product),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(product),
            ),
          ],
        ],
      ),
      floatingActionButton: product == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _registerPurchase(product),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Registrar compra'),
            ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (d) {
          final p = d.product;
          if (p == null) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Producto no encontrado',
              message: 'Puede que se haya eliminado.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              _HeaderCard(product: p),
              _PricesCard(stats: d.stats),
              _CaloriesCard(product: p, onLink: () => _linkFood(p)),
              SectionTitle(
                'Historial de compras',
                trailing: Text('últimos 3 meses', style: AppStyles.labelText),
              ),
              if (d.compras.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Aún no hay compras registradas.'),
                ),
              ...d.compras.map(
                (c) => ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(c.establecimiento),
                  subtitle: Text(AppUtils.formatFecha(c.fecha)),
                  trailing: Text(
                    AppUtils.formatPrecio(c.precio),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onLongPress: () => _deletePurchase(c),
                ),
              ),
              if (d.compras.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text(
                    'Mantén pulsada una compra para eliminarla.',
                    style: AppStyles.labelText,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Product product;

  const _HeaderCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final sub = [
      if ((product.marca ?? '').isNotEmpty) product.marca!,
      if ((product.presentacion ?? '').isNotEmpty) product.presentacion!,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.all(AppStyles.paddingMedium),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text(
          product.nombre,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sub.isNotEmpty) Text(sub),
            Row(
              children: [
                const Icon(Icons.qr_code, size: 16),
                const SizedBox(width: 4),
                Text(product.codigoBarras ?? 'Sin código de barras'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PricesCard extends StatelessWidget {
  final PriceStats stats;

  const _PricesCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final ultima = stats.ultima;
    if (ultima == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    String fmt(double? v) => v == null ? '—' : AppUtils.formatPrecio(v);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppStyles.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Último precio', style: AppStyles.labelText),
            Text(
              AppUtils.formatPrecio(ultima.precio),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${ultima.establecimiento} · ${AppUtils.formatFecha(ultima.fecha)}',
            ),
            if (stats.numCompras > 0) ...[
              const Divider(height: 24),
              Text(
                'Últimos 3 meses (${stats.numCompras} '
                '${stats.numCompras == 1 ? 'compra' : 'compras'})',
                style: AppStyles.labelText,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _stat('Mínimo', fmt(stats.minimo), AppStyles.semaphGreen),
                  _stat('Promedio', fmt(stats.promedio), null),
                  _stat('Máximo', fmt(stats.maximo), AppStyles.semaphRed),
                ],
              ),
            ],
            if (stats.ultimoPorEstablecimiento.length >= 2) ...[
              const Divider(height: 24),
              Text(
                'Último precio en cada establecimiento',
                style: AppStyles.labelText,
              ),
              ...stats.ultimoPorEstablecimiento.map(
                (c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        c == stats.masBarato
                            ? Icons.emoji_events
                            : Icons.storefront_outlined,
                        size: 18,
                        color: c == stats.masBarato ? Colors.amber[700] : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.establecimiento)),
                      Text(
                        '${AppUtils.formatPrecio(c.precio)}  '
                        '(${AppUtils.formatFechaCorta(c.fecha)})',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color? color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppStyles.labelText),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaloriesCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onLink;

  const _CaloriesCard({required this.product, required this.onLink});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = product.alimentoId;
    final food = id == null
        ? null
        : ref.watch(foodByIdProvider(id)).valueOrNull;
    return Card(
      margin: const EdgeInsets.all(AppStyles.paddingMedium),
      child: food == null
          ? ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text('Vincular al contador de calorías'),
              subtitle: const Text(
                'Así podrás registrar lo que comes escaneando este envase.',
              ),
              trailing: const Icon(Icons.link),
              onTap: onLink,
            )
          : Padding(
              padding: const EdgeInsets.all(AppStyles.paddingSmall),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.local_fire_department,
                      color: AppStyles.ringKcal,
                    ),
                    title: Text(food.name),
                    subtitle: Text(
                      '${food.kcalPer100} kcal · G ${food.grasasPer100} · '
                      'C ${food.carbsPer100} · P ${food.proteinsPer100} (por 100 g)',
                    ),
                    trailing: IconButton(
                      tooltip: 'Cambiar alimento',
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: onLink,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final added = await AddFoodPopup.showForToday(
                        context,
                        ref,
                        food,
                      );
                      if (added && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${food.name} añadido al día'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar ingesta'),
                  ),
                ],
              ),
            ),
    );
  }
}
