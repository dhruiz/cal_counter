import '../repositories/purchase_repository.dart';
import '../services/dates.dart';

/// Mantiene solo el historial de compras de los últimos 3 meses.
///
/// Borra las compras anteriores a [threeMonthsAgo] **excepto la última de cada
/// presentación**, para no perder nunca su último precio y fecha.
/// Devuelve cuántas compras se borraron.
class PurgeOldPurchases {
  final PurchaseRepository repository;

  PurgeOldPurchases(this.repository);

  Future<int> call({DateTime? now}) =>
      repository.purgeBefore(threeMonthsAgo(now ?? DateTime.now()));
}
