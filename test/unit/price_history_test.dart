import 'package:cal_counter/core/utils.dart';
import 'package:cal_counter/domain/entities/product.dart';
import 'package:cal_counter/domain/services/dates.dart';
import 'package:cal_counter/domain/usecases/export_price_history_csv.dart';
import 'package:cal_counter/domain/usecases/get_price_stats.dart';
import 'package:cal_counter/domain/usecases/register_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('threeMonthsAgo', () {
    test('mismo día 3 meses antes', () {
      expect(
        threeMonthsAgo(DateTime(2026, 11, 23, 18, 5)),
        DateTime(2026, 8, 23),
      );
    });
    test('cruza el año', () {
      expect(threeMonthsAgo(DateTime(2026, 2, 10)), DateTime(2025, 11, 10));
    });
    test('ajusta a fin de mes', () {
      expect(threeMonthsAgo(DateTime(2026, 5, 31)), DateTime(2026, 2, 28));
      expect(threeMonthsAgo(DateTime(2028, 5, 31)), DateTime(2028, 2, 29));
    });
  });

  test('dateKey', () {
    expect(dateKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });

  group('GetPriceStats', () {
    final now = DateTime(2026, 11, 23);
    Purchase p(int id, DateTime f, double precio, String tienda) => Purchase(
      id: id,
      productoId: 1,
      fecha: f,
      precio: precio,
      establecimiento: tienda,
    );

    test('vacío', () {
      final s = GetPriceStats()([], now: now);
      expect(s.ultima, isNull);
      expect(s.numCompras, 0);
    });

    test('última, min/max/promedio de 3 meses y más barato por tienda', () {
      final compras = [
        p(1, DateTime(2026, 5, 1), 0.50, 'Antigua'), // fuera de 3 meses
        p(2, DateTime(2026, 10, 1), 1.20, 'Mercado'),
        p(3, DateTime(2026, 11, 1), 1.50, 'Súper'),
        p(4, DateTime(2026, 11, 20), 1.00, 'mercado'),
      ];
      final s = GetPriceStats()(compras, now: now);
      expect(s.ultima!.id, 4);
      expect(s.numCompras, 3);
      expect(s.minimo, 1.00);
      expect(s.maximo, 1.50);
      expect(s.promedio, closeTo(1.2333, 0.001));
      // Último precio por tienda (sin distinguir mayúsculas), del más barato.
      expect(s.ultimoPorEstablecimiento.map((c) => c.id), [1, 4, 3]);
      expect(s.masBarato!.establecimiento, 'Antigua');
    });
  });

  test('parsePrecio acepta coma, punto y miles', () {
    expect(RegisterPurchase.parsePrecio('2,35'), 2.35);
    expect(RegisterPurchase.parsePrecio('2.35'), 2.35);
    expect(RegisterPurchase.parsePrecio('€ 3'), 3);
    expect(RegisterPurchase.parsePrecio('1.234,50'), 1234.50);
    expect(RegisterPurchase.parsePrecio('1,234.50'), 1234.50);
    expect(RegisterPurchase.parsePrecio('abc'), isNull);
  });

  test('formatPrecio muestra euros; formatPrecioEditable solo la cifra', () {
    // Espacio no separable entre la cifra y el símbolo.
    expect(AppUtils.formatPrecio(1.05), '1,05\u00A0€');
    expect(AppUtils.formatPrecio(1234.5), '1.234,50\u00A0€');
    expect(AppUtils.formatPrecioEditable(1234.5), '1234,50');
    // Lo que se precarga en el campo se vuelve a leer igual.
    expect(
      RegisterPurchase.parsePrecio(AppUtils.formatPrecioEditable(2.35)),
      2.35,
    );
  });

  test('ExportPriceHistoryCsv.buildTsv', () {
    final tsv = ExportPriceHistoryCsv.buildTsv([
      (
        producto: const Product(
          id: 1,
          codigoBarras: '8410000000001',
          nombre: 'Leche\tentera',
          marca: 'Marca',
          presentacion: '1 L',
        ),
        compra: Purchase(
          productoId: 1,
          fecha: DateTime(2026, 11, 2),
          precio: 0.9,
          establecimiento: 'Súper',
        ),
      ),
    ]);
    final lines = tsv.trim().split('\n');
    expect(lines.first, ExportPriceHistoryCsv.header);
    expect(
      lines[1],
      '2026-11-02\t8410000000001\tLeche entera\tMarca\t1 L\tSúper\t0.90',
    );
  });
}
