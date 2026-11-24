import '../entities/purchase.dart';
import '../repositories/purchase_repository.dart';
import '../services/dates.dart';

/// Genera el historial de precios de los últimos 3 meses como texto separado
/// por TAB (mismo criterio que el resto de exports; extensión `.csv`).
///
/// Columnas: fecha, codigo_barras, producto, marca, presentacion,
/// establecimiento, precio_eur, unidades, precio_kg_l_eur. Una fila por
/// compra, ordenadas por alimento y fecha. Los precios van como número sin
/// símbolo ("0.90") para que la hoja de cálculo pueda operar con ellos;
/// `precio_kg_l_eur` queda vacío si no se conoce el contenido neto.
class ExportPriceHistoryCsv {
  final PurchaseRepository repository;

  ExportPriceHistoryCsv(this.repository);

  static const String header =
      'fecha\tcodigo_barras\tproducto\tmarca\tpresentacion\testablecimiento'
      '\tprecio_eur\tunidades\tprecio_kg_l_eur';

  Future<String> call({DateTime? now}) async {
    final rows = await repository.historySince(
      threeMonthsAgo(now ?? DateTime.now()),
    );
    return buildTsv(rows);
  }

  static String buildTsv(List<PurchaseRecord> rows) {
    final buffer = StringBuffer()..writeln(header);
    for (final r in rows) {
      final kilo = r.precioPorKiloCent;
      buffer.writeln(
        [
          dateKey(r.compra.fecha),
          r.presentacion.codigoBarras ?? '',
          r.alimento.nombre,
          r.alimento.marca,
          r.presentacion.descripcion,
          r.compra.establecimiento,
          (r.compra.precioCent / 100).toStringAsFixed(2),
          '${r.compra.unidades}',
          kilo == null ? '' : (kilo / 100).toStringAsFixed(2),
        ].map(_clean).join('\t'),
      );
    }
    return buffer.toString();
  }

  static String _clean(String s) =>
      s.replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();
}
