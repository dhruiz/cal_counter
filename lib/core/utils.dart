import 'package:intl/intl.dart';

class AppUtils {
  static final NumberFormat _precio = NumberFormat('#,##0.00', 'es');
  static final DateFormat _fecha = DateFormat('dd/MM/yyyy', 'es');
  static final DateFormat _fechaCorta = DateFormat('dd/MM', 'es');

  /// Precio con 2 decimales y separadores locales ("1.234,50"). Sin símbolo
  /// de moneda: la app no sabe en qué país se usa.
  static String formatPrecio(double v) => _precio.format(v);

  static String formatFecha(DateTime d) => _fecha.format(d);

  static String formatFechaCorta(DateTime d) => _fechaCorta.format(d);

  /// "1,5" o "150" sin decimales innecesarios.
  static String formatNumero(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
