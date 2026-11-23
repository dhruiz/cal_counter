import 'package:intl/intl.dart';

class AppUtils {
  static final NumberFormat _precio = NumberFormat.currency(
    locale: 'es',
    symbol: '€',
    decimalDigits: 2,
  );
  static final NumberFormat _precioEditable = NumberFormat('0.00', 'es');
  static final DateFormat _fecha = DateFormat('dd/MM/yyyy', 'es');
  static final DateFormat _fechaCorta = DateFormat('dd/MM', 'es');

  /// Precio en euros para mostrar: "1,05 €", "1.234,50 €" (el espacio es no
  /// separable, así el símbolo no se parte de la cifra al saltar de línea).
  static String formatPrecio(double v) => _precio.format(v);

  /// Precio para precargar un campo editable: "1,05" (sin símbolo ni miles).
  static String formatPrecioEditable(double v) => _precioEditable.format(v);

  static String formatFecha(DateTime d) => _fecha.format(d);

  static String formatFechaCorta(DateTime d) => _fechaCorta.format(d);

  /// "1,5" o "150" sin decimales innecesarios.
  static String formatNumero(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
