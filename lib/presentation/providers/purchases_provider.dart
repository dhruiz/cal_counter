import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/usecases/export_price_history_csv.dart';
import 'core_providers.dart';

export 'core_providers.dart';

/// Establecimientos usados (para autocompletar), del más reciente.
final storesProvider = StreamProvider.autoDispose<List<String>>(
  (ref) => ref.watch(purchaseRepositoryProvider).watchStoreNames(),
);

/// Última compra de cada alimento (historial de precios), recientes primero.
final lastPurchasePerFoodProvider =
    StreamProvider.autoDispose<List<PurchaseRecord>>(
      (ref) => ref.watch(purchaseRepositoryProvider).watchLastPurchasePerFood(),
    );

final exportPriceHistoryCsvProvider = Provider<ExportPriceHistoryCsv>(
  (ref) => ExportPriceHistoryCsv(ref.watch(purchaseRepositoryProvider)),
);

/// Purga el historial de más de 3 meses (conservando la última compra de
/// cada presentación). Se lanza al abrir la app y antes de exportar.
final purgeOnStartupProvider = FutureProvider<int>(
  (ref) => ref.watch(purgeOldPurchasesProvider)(),
);

/// Gasto por categoría en los últimos [dias] días. Se recalcula cuando
/// cambian las compras.
final spendingByCategoryProvider = FutureProvider.autoDispose
    .family<List<CategorySpending>, int>((ref, dias) {
      ref.watch(lastPurchasePerFoodProvider); // dependencia: cambios en compras
      final desde = DateTime.now().subtract(Duration(days: dias));
      return ref.watch(purchaseRepositoryProvider).spendingByCategory(desde);
    });
