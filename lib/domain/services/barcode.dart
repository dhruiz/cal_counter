/// Normalización y validación de códigos de barras (GTIN: EAN-8, UPC-A,
/// EAN-13, GTIN-14).
///
/// Todos los códigos se guardan y se buscan normalizados para que el mismo
/// producto no quede duplicado según el lector: solo dígitos, y los UPC-A de
/// 12 dígitos se convierten a EAN-13 anteponiendo un 0 (algunos lectores ya
/// lo devuelven así).
library;

final RegExp _noDigits = RegExp(r'[^0-9]');

/// Código normalizado, o null si no queda ningún dígito.
String? normalizeBarcode(String? input) {
  if (input == null) return null;
  final digits = input.replaceAll(_noDigits, '');
  if (digits.isEmpty) return null;
  if (digits.length == 12) return '0$digits';
  return digits;
}

/// Dígito de control GS1 para [body] (el código sin su último dígito).
int gtinCheckDigit(String body) {
  var sum = 0;
  // Desde la derecha: posiciones impares ×3, pares ×1.
  for (var i = 0; i < body.length; i++) {
    final d = body.codeUnitAt(body.length - 1 - i) - 48;
    sum += i.isEven ? d * 3 : d;
  }
  return (10 - sum % 10) % 10;
}

/// Longitud de GTIN y dígito de control correctos.
bool isValidGtin(String code) {
  // Un UPC-A (12) ya llega normalizado a EAN-13 con el mismo dígito de control.
  final c = normalizeBarcode(code);
  if (c == null || !const {8, 13, 14}.contains(c.length)) return false;
  final body = c.substring(0, c.length - 1);
  return gtinCheckDigit(body) == c.codeUnitAt(c.length - 1) - 48;
}

/// Lo escrito en un buscador parece un código de barras (8 a 14 dígitos).
bool looksLikeBarcode(String query) {
  final q = query.trim();
  return RegExp(r'^\d{8,14}$').hasMatch(q);
}

/// Códigos de peso o precio variable (EAN-13 que empiezan por 2): los
/// imprimen las balanzas de frescos y llevan el importe o el peso incrustado,
/// así que cambian de un paquete a otro.
bool isVariableMeasure(String code) {
  final c = normalizeBarcode(code);
  return c != null && c.length == 13 && c.startsWith('2');
}
