import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/dates.dart';

/// Genera el historial de precios de los últimos 3 meses como texto separado
/// por TAB (mismo criterio que el resto de exports; extensión `.csv`).
///
/// Columnas: fecha, codigo_barras, producto, marca, presentacion,
/// establecimiento, precio. Una fila por compra, ordenadas por producto y fecha.
class ExportPriceHistoryCsv {
  final ProductRepository repository;

  ExportPriceHistoryCsv(this.repository);

  static const String header =
      'fecha\tcodigo_barras\tproducto\tmarca\tpresentacion\testablecimiento\tprecio';

  Future<String> call({DateTime? now}) async {
    final rows = await repository.getPurchaseHistorySince(
      threeMonthsAgo(now ?? DateTime.now()),
    );
    return buildTsv(rows);
  }

  static String buildTsv(List<({Product producto, Purchase compra})> rows) {
    final buffer = StringBuffer()..writeln(header);
    for (final r in rows) {
      buffer.writeln(
        [
          dateKey(r.compra.fecha),
          r.producto.codigoBarras ?? '',
          r.producto.nombre,
          r.producto.marca ?? '',
          r.producto.presentacion ?? '',
          r.compra.establecimiento,
          r.compra.precio.toStringAsFixed(2),
        ].map(_clean).join('\t'),
      );
    }
    return buffer.toString();
  }

  static String _clean(String s) =>
      s.replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();
}
