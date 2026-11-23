import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/services/barcode.dart';
import '../../domain/services/money.dart';
import '../providers/foods_provider.dart';
import '../widgets/add_to_shopping_list_dialog.dart';
import '../widgets/category_widgets.dart';
import '../widgets/dialog_controllers.dart';
import '../widgets/empty_state.dart';
import '../widgets/food_widgets.dart';
import '../widgets/purchase_dialog.dart';
import 'barcode_scanner_view.dart';
import 'food_flows.dart';
import 'food_form_view.dart';
import 'recipe_detail_view.dart';

/// Ficha de un alimento del repertorio: tabla nutricional, porciones,
/// presentaciones (códigos de barras), precios y recetas que lo usan.
class FoodDetailView extends ConsumerWidget {
  final int foodId;

  const FoodDetailView({super.key, required this.foodId});

  static Future<void> open(BuildContext context, int id) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => FoodDetailView(foodId: id)),
  );

  Future<void> _delete(BuildContext context, WidgetRef ref, Food f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar alimento'),
        content: Text(
          '¿Eliminar "${f.nombreCompleto}"? Si tiene compras se archivará '
          'para conservar el historial de precios. Las recetas y comidas que '
          'lo usan conservan su texto.',
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
    final res = await ref.read(foodRepositoryProvider).deleteFood(f.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res == FoodDeletion.borrado
              ? '"${f.nombre}" eliminado.'
              : '"${f.nombre}" archivado (tiene historial de compras).',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(foodProvider(foodId));
    final food = async.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(food?.nombre ?? 'Alimento'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          if (food != null) ...[
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () => FoodFormView.open(context, food: food),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                final repo = ref.read(foodRepositoryProvider);
                if (v == 'archive') await repo.setArchived(food.id!, true);
                if (v == 'unarchive') await repo.setArchived(food.id!, false);
                if (v == 'delete' && context.mounted) {
                  await _delete(context, ref, food);
                }
              },
              itemBuilder: (_) => [
                if (food.archivado)
                  const PopupMenuItem(
                    value: 'unarchive',
                    child: Text('Desarchivar'),
                  )
                else
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Archivar'),
                  ),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (f) => f == null
            ? const EmptyState(
                icon: Icons.no_food_outlined,
                title: 'Alimento no encontrado',
                message: 'Puede que se haya eliminado.',
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _Header(food: f),
                  _NutritionCard(food: f),
                  _Actions(food: f),
                  _PortionsCard(food: f),
                  _PackagesCard(food: f),
                  _PricesCard(food: f),
                  _RecipesCard(food: f),
                ],
              ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final Food food;

  const _Header({required this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cats = ref.watch(categoriesProvider(null)).valueOrNull ?? const [];
    final categoria = cats.where((c) => c.id == food.categoriaId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(food.nombre, style: theme.textTheme.headlineSmall),
          if (food.marca.isNotEmpty)
            Text(food.marca, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ActionChip(
                avatar: const Icon(Icons.category_outlined, size: 18),
                label: Text(categoria?.nombre ?? 'Sin categoría'),
                tooltip: 'Cambiar categoría',
                onPressed: () async {
                  final choice = await pickCategory(
                    context,
                    ref,
                    actual: food.categoriaId,
                  );
                  if (choice == null) return;
                  await ref.read(categoryRepositoryProvider).assignCategory([
                    food.id!,
                  ], choice.categoriaId);
                },
              ),
              Chip(label: Text(food.tipo.etiqueta)),
              if (food.pendiente) const PendingChip(dense: false),
              if (food.archivado)
                const Chip(
                  avatar: Icon(Icons.archive_outlined, size: 18),
                  label: Text('Archivado'),
                ),
            ],
          ),
          if ((food.notas ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(food.notas!),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

String _origen(NutritionSource? s) => switch (s) {
  NutritionSource.manual => 'Introducida a mano',
  NutritionSource.etiquetaOcr => 'Leída de la etiqueta',
  NutritionSource.importado => 'Importada de un repertorio',
  NutritionSource.calculado => 'Calculada a partir de sus ingredientes',
  null => '',
};

class _NutritionCard extends ConsumerWidget {
  final Food food;

  const _NutritionCard({required this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portions =
        ref.watch(foodPortionsProvider(food.id!)).valueOrNull ?? const [];
    final origen = _origen(food.origenNutricion);
    return _SectionCard(
      title: 'Tabla nutricional',
      trailing: TextButton.icon(
        onPressed: () =>
            FoodFormView.open(context, food: food, completar: food.pendiente),
        icon: Icon(food.pendiente ? Icons.edit_note : Icons.edit, size: 18),
        label: Text(food.pendiente ? 'Completar' : 'Editar'),
      ),
      children: [
        if (food.pendiente)
          InfoBanner(
            color: AppStyles.semaphOrange,
            icon: Icons.info_outline,
            text:
                'Pendiente: faltan '
                '${food.nutricion.faltantes.map((n) => n.etiqueta.toLowerCase()).join(', ')}. '
                'Hasta completarla no se puede contar en el día.',
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: NutritionTable(
            nutricion: food.nutricion,
            unidad: food.u,
            gramosPorcion: portions.isEmpty ? null : portions.first.gramos,
          ),
        ),
        if (portions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Última columna: 1 ${portions.first.nombre}.',
              style: AppStyles.labelText,
            ),
          ),
        if (origen.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(origen, style: AppStyles.labelText),
          ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  final Food food;

  const _Actions({required this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () async {
              final ok = await FoodFlows.registerIntake(context, ref, food);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${food.nombre} añadido al día')),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Añadir al día'),
          ),
          OutlinedButton.icon(
            onPressed: () => AddFoodToShoppingListDialog.show(context, food),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('A la lista'),
          ),
          OutlinedButton.icon(
            onPressed: () => PurchaseDialog.show(context, food: food),
            icon: const Icon(Icons.sell_outlined),
            label: const Text('Registrar compra'),
          ),
        ],
      ),
    );
  }
}

class _PortionsCard extends ConsumerWidget {
  final Food food;

  const _PortionsCard({required this.food});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    FoodPortion? p,
  ]) async {
    final res = await showDialog<List<String>>(
      context: context,
      builder: (_) => DialogControllers(
        iniciales: [
          p?.nombre ?? '',
          p == null ? '' : AppUtils.formatNumero(p.gramos),
        ],
        builder: (ctx, c) {
          final nameCtrl = c[0];
          final gramsCtrl = c[1];
          return AlertDialog(
            title: Text(p == null ? 'Nueva porción' : 'Editar porción'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'unidad, rebanada, diente, taza...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gramsCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Equivale a',
                    suffixText: food.u,
                  ),
                ),
              ],
            ),
            actions: [
              if (p != null)
                TextButton(
                  onPressed: () async {
                    await ref.read(foodRepositoryProvider).deletePortion(p.id!);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Eliminar'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(ctx, [nameCtrl.text, gramsCtrl.text]),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    if (res != null) {
      try {
        await ref
            .read(foodRepositoryProvider)
            .savePortion(
              FoodPortion(
                id: p?.id,
                alimentoId: food.id,
                nombre: res[0],
                gramos: parseDecimal(res[1]) ?? 0,
              ),
            );
      } on ValidationException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.mensaje)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portions =
        ref.watch(foodPortionsProvider(food.id!)).valueOrNull ?? const [];
    return _SectionCard(
      title: 'Porciones caseras',
      trailing: IconButton(
        tooltip: 'Añadir porción',
        icon: const Icon(Icons.add),
        onPressed: () => _edit(context, ref),
      ),
      children: [
        if (portions.isEmpty)
          const Text(
            'Ej.: 1 unidad = 60 g, 1 diente = 5 g. Sirven para registrar '
            'rápido y para calcular recetas con "2 dientes de ajo".',
            style: AppStyles.labelText,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in portions)
                ActionChip(
                  label: Text(
                    '1 ${p.nombre} = ${AppUtils.formatNumero(p.gramos)} ${food.u}',
                  ),
                  onPressed: () => _edit(context, ref, p),
                ),
            ],
          ),
      ],
    );
  }
}

class _PackagesCard extends ConsumerWidget {
  final Food food;

  const _PackagesCard({required this.food});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final how = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Escanear el código'),
              onTap: () => Navigator.pop(ctx, 'scan'),
            ),
            ListTile(
              leading: const Icon(Icons.keyboard),
              title: const Text('Escribir el código o sin código'),
              onTap: () => Navigator.pop(ctx, 'manual'),
            ),
          ],
        ),
      ),
    );
    if (how == null || !context.mounted) return;
    String? code;
    if (how == 'scan') {
      code = await BarcodeScannerView.scan(context);
      if (code == null || !context.mounted) return;
    }
    await _edit(
      context,
      ref,
      FoodPackage(alimentoId: food.id!, codigoBarras: normalizeBarcode(code)),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, FoodPackage p) async {
    final res = await showDialog<(String, List<String>)>(
      context: context,
      builder: (_) => DialogControllers(
        iniciales: [
          p.codigoBarras ?? '',
          p.descripcion,
          p.contenido == null ? '' : AppUtils.formatNumero(p.contenido!),
        ],
        builder: (ctx, c) {
          final codeCtrl = c[0];
          final descCtrl = c[1];
          final contCtrl = c[2];
          return AlertDialog(
            title: Text(p.id == null ? 'Nueva presentación' : 'Presentación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  autofocus: p.id == null,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Brick 1 L, pack 6 × 125 g, granel...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Contenido neto total',
                    suffixText: food.u,
                    helperText: 'Para comparar el precio por kg o litro',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Código de barras (opcional)',
                  ),
                ),
              ],
            ),
            actions: [
              if (p.id != null)
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, ('delete', const <String>[])),
                  child: const Text('Eliminar'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, (
                  'save',
                  [codeCtrl.text, descCtrl.text, contCtrl.text],
                )),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    if (res == null) return;
    final repo = ref.read(foodRepositoryProvider);
    final v = res.$2;
    try {
      if (res.$1 == 'delete') {
        await repo.deletePackage(p.id!);
      } else if (res.$1 == 'save') {
        await repo.savePackage(
          p.copyWith(
            codigoBarras: v[0],
            clearCodigo: normalizeBarcode(v[0]) == null,
            descripcion: v[1],
            contenido: parseDecimal(v[2]),
            clearContenido: parseDecimal(v[2]) == null,
          ),
        );
      }
    } on DuplicateBarcodeException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages =
        (ref.watch(foodPackagesProvider(food.id!)).valueOrNull ??
                const <FoodPackage>[])
            .where((p) => !p.archivado)
            .toList();
    final compras =
        ref.watch(foodPurchasesProvider(food.id!)).valueOrNull ?? const [];
    PurchaseRecord? last(int packageId) {
      for (final c in compras) {
        if (c.presentacion.id == packageId) return c;
      }
      return null;
    }

    return _SectionCard(
      title: 'Presentaciones y códigos',
      trailing: IconButton(
        tooltip: 'Añadir presentación',
        icon: const Icon(Icons.add),
        onPressed: () => _add(context, ref),
      ),
      children: [
        if (packages.isEmpty)
          const Text(
            'Sin presentaciones. Añade el código de barras para encontrarlo '
            'escaneando el envase.',
            style: AppStyles.labelText,
          ),
        for (final p in packages)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              p.codigoBarras == null
                  ? Icons.inventory_2_outlined
                  : Icons.qr_code,
            ),
            title: Text(
              p.descripcion.isEmpty
                  ? (p.codigoBarras == null ? 'Sin presentación' : 'Envase')
                  : p.descripcion,
            ),
            subtitle: Text(
              [
                if (p.codigoBarras != null) p.codigoBarras!,
                if (p.contenido != null)
                  '${AppUtils.formatNumero(p.contenido!)} ${food.u}',
              ].join(' · '),
            ),
            trailing: () {
              final l = last(p.id!);
              if (l == null) return null;
              final kilo = l.precioPorKiloCent;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppUtils.formatPrecioCent(l.compra.precioCent)),
                  if (kilo != null)
                    Text(
                      '${AppUtils.formatPrecioCent(kilo)}/${food.unidad == FoodUnit.ml ? 'L' : 'kg'}',
                      style: AppStyles.labelText,
                    ),
                ],
              );
            }(),
            onTap: () => _edit(context, ref, p),
          ),
      ],
    );
  }
}

class _PricesCard extends ConsumerWidget {
  final Food food;

  const _PricesCard({required this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compras =
        ref.watch(foodPurchasesProvider(food.id!)).valueOrNull ?? const [];
    if (compras.isEmpty) return const SizedBox.shrink();
    final stats = ref.watch(foodPriceStatsProvider(food.id!));
    final u = stats.ultima!;
    return _SectionCard(
      title: 'Precios',
      children: [
        const SizedBox(height: 4),
        Text(
          'Último: ${AppUtils.formatPrecioCent(u.precioCent)} en '
          '${u.establecimiento} (${AppUtils.formatFecha(u.fecha)})',
        ),
        if (stats.numCompras > 1)
          Text(
            'Últimos 3 meses: mín. ${AppUtils.formatPrecioCent(stats.minimoCent!)} · '
            'máx. ${AppUtils.formatPrecioCent(stats.maximoCent!)} · '
            'media ${AppUtils.formatPrecioCent(stats.promedioCent!)}',
            style: AppStyles.labelText,
          ),
        if (stats.ultimoPorEstablecimiento.length > 1) ...[
          const SizedBox(height: 8),
          const Text('Último precio por tienda'),
          for (final c in stats.ultimoPorEstablecimiento)
            Row(
              children: [
                Icon(
                  c == stats.masBarato
                      ? Icons.emoji_events_outlined
                      : Icons.storefront_outlined,
                  size: 16,
                  color: c == stats.masBarato ? AppStyles.semaphGreen : null,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(c.establecimiento)),
                Text(AppUtils.formatPrecioCent(c.precioCent)),
              ],
            ),
        ],
        const Divider(),
        for (final c in compras.take(8))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${AppUtils.formatFecha(c.compra.fecha)} · ${c.compra.establecimiento}',
            ),
            subtitle: c.presentacion.descripcion.isEmpty
                ? null
                : Text(c.presentacion.descripcion),
            trailing: Text(
              c.compra.unidades > 1
                  ? '${c.compra.unidades} × ${AppUtils.formatPrecioCent(c.compra.precioCent)}'
                  : AppUtils.formatPrecioCent(c.compra.precioCent),
            ),
            onLongPress: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar compra'),
                  content: Text(
                    '¿Eliminar la compra del '
                    '${AppUtils.formatFecha(c.compra.fecha)} en '
                    '${c.compra.establecimiento}?',
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
                await ref
                    .read(purchaseRepositoryProvider)
                    .deletePurchase(c.compra.id!);
              }
            },
          ),
        if (compras.length > 8)
          Text(
            'Y ${compras.length - 8} compras más (últimos 3 meses).',
            style: AppStyles.labelText,
          ),
      ],
    );
  }
}

class _RecipesCard extends ConsumerWidget {
  final Food food;

  const _RecipesCard({required this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes =
        ref.watch(recipesUsingFoodProvider(food.id!)).valueOrNull ?? const [];
    if (recipes.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Usado en recetas',
      children: [
        for (final r in recipes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(r.nombre),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailView(recipeId: r.id!),
              ),
            ),
          ),
      ],
    );
  }
}
