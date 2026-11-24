import 'package:cal_counter/core/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('parseDecimal', () {
    test('acepta coma y punto (teclado numérico en español)', () {
      expect(AppUtils.parseDecimal('12,5'), 12.5);
      expect(AppUtils.parseDecimal('12.5'), 12.5);
      expect(AppUtils.parseDecimal(' 150 '), 150);
    });

    test('vacío, basura o no finito → null', () {
      expect(AppUtils.parseDecimal(''), isNull);
      expect(AppUtils.parseDecimal(null), isNull);
      expect(AppUtils.parseDecimal(','), isNull);
      expect(AppUtils.parseDecimal('abc'), isNull);
      expect(AppUtils.parseDecimal('Infinity'), isNull);
      expect(AppUtils.parseDecimal('NaN'), isNull);
    });
  });

  test('formatNumero usa coma decimal y omite decimales innecesarios', () {
    expect(AppUtils.formatNumero(1.5), '1,5');
    expect(AppUtils.formatNumero(150), '150');
    expect(AppUtils.formatNumero(1234.5), '1234,5'); // sin miles: editable
  });

  test('formatDecimalEditable conserva 2 decimales y se relee igual', () {
    for (final v in [1.25, 70.0, 0.5, 100.0, 0.0, 12.34]) {
      final text = AppUtils.formatDecimalEditable(v);
      expect(AppUtils.parseDecimal(text), v, reason: text);
    }
    expect(AppUtils.formatDecimalEditable(1.25), '1,25');
    expect(AppUtils.formatDecimalEditable(70), '70');
  });

  test('decimalInputFormatter admite un solo separador', () {
    final f = AppUtils.decimalInputFormatter;
    TextEditingValue apply(String old, String next) => f.formatEditUpdate(
      TextEditingValue(text: old),
      TextEditingValue(text: next),
    );
    expect(apply('12', '12,').text, '12,');
    expect(apply('12,', '12,5').text, '12,5');
    expect(apply('12,5', '12,5,').text, '12,5');
    expect(apply('12', '12a').text, '12');
    expect(apply('', '-3').text, '');
  });

  test('formatRutaGuardada muestra la ruta legible del Uri de saveFile', () {
    // Android: file_picker convierte la ruta del documento SAF en Uri, lo que
    // codifica espacios y tildes.
    final saf = Uri.tryParse('/document/primary:Download/comidas día 1.csv')!;
    expect(
      AppUtils.formatRutaGuardada(saf),
      '/document/primary:Download/comidas día 1.csv',
    );
    // Escritorio/tests: Uri file: → ruta local de la plataforma.
    final local = Uri.file('/tmp/export.csv', windows: false);
    expect(AppUtils.formatRutaGuardada(local), local.toFilePath());
  });
}
