/// Dinero en céntimos (enteros) para no acumular errores de redondeo.
library;

/// Euros → céntimos (redondeo al céntimo más cercano).
int toCents(double euros) => (euros * 100).round();

/// Céntimos → euros.
double fromCents(int cents) => cents / 100;

/// Interpreta un precio escrito por el usuario: "2,35", "2.35", "1.234,50",
/// "€ 3". Devuelve null si no es válido.
double? parsePrecio(String input) {
  var s = input.replaceAll(RegExp(r'[^\d.,]'), '');
  if (s.isEmpty) return null;
  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    // El último separador es el decimal; el otro, de miles.
    if (lastComma > lastDot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else {
    s = s.replaceAll(',', '.');
  }
  return double.tryParse(s);
}

/// Como [parsePrecio] pero en céntimos; null si no es válido o no es > 0.
int? parsePrecioCent(String input) {
  final p = parsePrecio(input);
  if (p == null || p <= 0 || p.isNaN || p.isInfinite) return null;
  final c = toCents(p);
  return c > 0 ? c : null;
}

/// Número decimal escrito con coma o punto ("1,5", "250"). Null si no es
/// válido.
double? parseDecimal(String input) {
  final s = input.trim().replaceAll(',', '.');
  if (s.isEmpty) return null;
  return double.tryParse(s);
}
