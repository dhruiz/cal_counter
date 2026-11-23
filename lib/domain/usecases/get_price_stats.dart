import '../entities/price_stats.dart';
import '../entities/product.dart';
import '../services/dates.dart';

/// Calcula estadísticas de precio de un producto: última compra, mínimo,
/// máximo y promedio de los últimos 3 meses, y último precio por
/// establecimiento (del más barato al más caro).
class GetPriceStats {
  PriceStats call(List<Purchase> compras, {DateTime? now}) {
    if (compras.isEmpty) return const PriceStats();

    final sorted = [...compras]
      ..sort((a, b) {
        final byDate = b.fecha.compareTo(a.fecha);
        if (byDate != 0) return byDate;
        return (b.id ?? 0).compareTo(a.id ?? 0);
      });

    final desde = threeMonthsAgo(now ?? DateTime.now());
    final recientes = sorted.where((c) => !c.fecha.isBefore(desde)).toList();

    double? minimo, maximo, promedio;
    if (recientes.isNotEmpty) {
      final precios = recientes.map((c) => c.precio);
      minimo = precios.reduce((a, b) => a < b ? a : b);
      maximo = precios.reduce((a, b) => a > b ? a : b);
      promedio = precios.reduce((a, b) => a + b) / recientes.length;
    }

    // Última compra por establecimiento (sorted ya va de reciente a antigua).
    final porTienda = <String, Purchase>{};
    for (final c in sorted) {
      porTienda.putIfAbsent(c.establecimiento.toLowerCase(), () => c);
    }
    final ultimos = porTienda.values.toList()
      ..sort((a, b) => a.precio.compareTo(b.precio));

    return PriceStats(
      ultima: sorted.first,
      minimo: minimo,
      maximo: maximo,
      promedio: promedio,
      numCompras: recientes.length,
      ultimoPorEstablecimiento: ultimos,
    );
  }
}
