import '../repositories/product_repository.dart';
import '../services/dates.dart';

/// Mantiene solo el historial de compras de los últimos 3 meses.
///
/// Borra las compras anteriores a [threeMonthsAgo] **excepto la última de cada
/// producto**, para no perder nunca su precio y fecha de última compra.
/// Devuelve cuántas compras se borraron.
class PurgeOldPurchases {
  final ProductRepository repository;

  PurgeOldPurchases(this.repository);

  Future<int> call({DateTime? now}) {
    return repository.purgePurchasesBefore(
      threeMonthsAgo(now ?? DateTime.now()),
    );
  }
}
