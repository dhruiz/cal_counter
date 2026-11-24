import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/services/dates.dart';
import '../providers/purchases_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/food_widgets.dart';
import 'food_detail_view.dart';

/// Historial de precios: último precio de cada alimento comprado (3 meses +
/// la última compra de cada presentación), exportable a CSV (TAB).
class PriceHistoryView extends ConsumerWidget {
  const PriceHistoryView({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(purgeOldPurchasesProvider)();
      final tsv = await ref.read(exportPriceHistoryCsvProvider)();
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Exportar historial de precios',
        fileName: 'historial_precios_${dateKey(DateTime.now())}.csv',
        bytes: Uint8List.fromList(utf8.encode(tsv)),
      );
      if (saved == null) return; // Cancelado
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Historial exportado a: ${AppUtils.formatRutaGuardada(saved)}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lastPurchasePerFoodProvider);
    final records = async.valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de precios'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Exportar (CSV)',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: records.isEmpty ? null : () => _export(context, ref),
          ),
        ],
      ),
      body: async.isLoading && records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
          ? const EmptyState(
              icon: Icons.query_stats,
              title: 'Sin compras registradas',
              message:
                  'Los precios se guardan al usar el modo carrito, al poner '
                  'precio a un artículo de la lista o desde la ficha de un '
                  'alimento. Se conservan 3 meses y siempre el último de '
                  'cada presentación.',
            )
          : ListView.separated(
              itemCount: records.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 0),
              itemBuilder: (ctx, index) {
                if (index == 0) return const _SpendingCard();
                final r = records[index - 1];
                final kilo = r.precioPorKiloCent;
                return ListTile(
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          r.alimento.nombreCompleto,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (r.alimento.pendiente) ...[
                        const SizedBox(width: 6),
                        const PendingChip(),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    [
                      if (r.presentacion.descripcion.isNotEmpty)
                        r.presentacion.descripcion,
                      '${r.compra.establecimiento} · '
                          '${AppUtils.formatFecha(r.compra.fecha)}',
                    ].join('\n'),
                  ),
                  isThreeLine: r.presentacion.descripcion.isNotEmpty,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppUtils.formatPrecioCent(r.compra.precioCent),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (kilo != null)
                        Text(
                          '${AppUtils.formatPrecioCent(kilo)}/'
                          '${r.alimento.unidad == FoodUnit.ml ? 'L' : 'kg'}',
                          style: AppStyles.labelText,
                        ),
                    ],
                  ),
                  onTap: () => FoodDetailView.open(context, r.alimento.id!),
                );
              },
            ),
    );
  }
}

/// Gasto por categoría en los últimos 30 días o 3 meses.
class _SpendingCard extends ConsumerStatefulWidget {
  const _SpendingCard();

  @override
  ConsumerState<_SpendingCard> createState() => _SpendingCardState();
}

class _SpendingCardState extends ConsumerState<_SpendingCard> {
  int _dias = 30;

  @override
  Widget build(BuildContext context) {
    final gasto =
        ref.watch(spendingByCategoryProvider(_dias)).valueOrNull ?? const [];
    final total = gasto.fold<int>(0, (s, g) => s + g.totalCent);
    final maximo = gasto.isEmpty ? 1 : gasto.first.totalCent;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gasto por categoría',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 30, label: Text('30 días')),
                    ButtonSegment(value: 90, label: Text('3 meses')),
                  ],
                  selected: {_dias},
                  onSelectionChanged: (s) => setState(() => _dias = s.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (gasto.isEmpty)
              const Text(
                'Sin compras en este periodo.',
                style: AppStyles.labelText,
              )
            else ...[
              Text(
                'Total: ${AppUtils.formatPrecioCent(total)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final g in gasto)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(g.categoria?.nombre ?? 'Sin categoría'),
                          ),
                          Text(
                            '${AppUtils.formatPrecioCent(g.totalCent)} · '
                            '${(g.totalCent * 100 / (total == 0 ? 1 : total)).round()} %',
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: g.totalCent / maximo,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
