import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppUtils {
  static final NumberFormat _precio = NumberFormat.currency(
    locale: 'es',
    symbol: '€',
    decimalDigits: 2,
  );
  static final NumberFormat _precioEditable = NumberFormat('0.00', 'es');
  static final NumberFormat _numero = NumberFormat('0.#', 'es');
  static final DateFormat _fecha = DateFormat('dd/MM/yyyy', 'es');
  static final DateFormat _fechaCorta = DateFormat('dd/MM', 'es');

  /// Precio en euros para mostrar: "1,05 €", "1.234,50 €" (el espacio es no
  /// separable, así el símbolo no se parte de la cifra al saltar de línea).
  static String formatPrecio(double v) => _precio.format(v);

  /// Precio para precargar un campo editable: "1,05" (sin símbolo ni miles).
  static String formatPrecioEditable(double v) => _precioEditable.format(v);

  static String formatFecha(DateTime d) => _fecha.format(d);

  static String formatFechaCorta(DateTime d) => _fechaCorta.format(d);

  /// "1,5" o "150" sin decimales innecesarios ni separador de miles (se usa
  /// también para precargar campos que se leen con [parseDecimal]).
  static String formatNumero(double v) => _numero.format(v);

  /// Número para precargar un campo editable: hasta 2 decimales con coma y
  /// sin ceros sobrantes ("1,25", "70", "0,5"); se vuelve a leer con
  /// [parseDecimal] sin perder precisión apreciable.
  static String formatDecimalEditable(double v) => v
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAll('.', ',');

  /// Lee un número escrito por el usuario con coma o punto decimal ("12,5",
  /// "12.5"). El teclado numérico en español escribe coma; antes estos campos
  /// solo aceptaban punto. Devuelve null si no es un número finito.
  static double? parseDecimal(String? input) {
    final s = (input ?? '').trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    final v = double.tryParse(s);
    return (v == null || !v.isFinite) ? null : v;
  }

  /// Filtro para campos decimales no negativos: dígitos y un único separador
  /// (coma o punto).
  static final TextInputFormatter decimalInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        return RegExp(r'^\d*[.,]?\d*$').hasMatch(newValue.text)
            ? newValue
            : oldValue;
      });
}
