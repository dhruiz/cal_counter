import 'ingredient_matcher.dart';

/// Cantidad numérica interpretada de una línea de ingrediente.
class ParsedQuantity {
  final double cantidad;

  /// 'g', 'ml' o el nombre normalizado (singular, sin tildes) de una porción:
  /// 'diente', 'taza', 'cucharada', 'unidad'...
  final String unidad;

  const ParsedQuantity(this.cantidad, this.unidad);

  bool get esMasa => unidad == 'g';
  bool get esVolumen => unidad == 'ml';

  @override
  String toString() => '$cantidad $unidad';
}

const Map<String, (String, double)> _conversiones = {
  'g': ('g', 1),
  'gr': ('g', 1),
  'grs': ('g', 1),
  'gramo': ('g', 1),
  'kg': ('g', 1000),
  'kilo': ('g', 1000),
  'kilogramo': ('g', 1000),
  'mg': ('g', 0.001),
  'ml': ('ml', 1),
  'mililitro': ('ml', 1),
  'cc': ('ml', 1),
  'l': ('ml', 1000),
  'lt': ('ml', 1000),
  'litro': ('ml', 1000),
  'cl': ('ml', 10),
  'dl': ('ml', 100),
};

/// Abreviaturas de porción → nombre canónico.
const Map<String, String> _alias = {
  'cda': 'cucharada',
  'cdas': 'cucharada',
  'cdta': 'cucharadita',
  'cdtas': 'cucharadita',
  'cdita': 'cucharadita',
  'ud': 'unidad',
  'uds': 'unidad',
  'u': 'unidad',
  'pieza': 'unidad',
};

const Map<String, double> _palabrasNumero = {
  'un': 1,
  'una': 1,
  'uno': 1,
  'medio': 0.5,
  'media': 0.5,
  'dos': 2,
  'tres': 3,
  'cuatro': 4,
  'cinco': 5,
  'seis': 6,
  'siete': 7,
  'ocho': 8,
  'nueve': 9,
  'diez': 10,
  'docena': 12,
  'cuarto': 0.25,
};

const Map<String, double> _fracciones = {
  '½': 0.5,
  '¼': 0.25,
  '¾': 0.75,
  '⅓': 1 / 3,
  '⅔': 2 / 3,
  '⅛': 0.125,
};

/// Interpreta la cantidad de una línea de ingrediente: "200 g de arroz" →
/// 200 g; "1/2 kg" → 500 g; "2 dientes de ajo" → 2 diente; "1 y 1/2 tazas"
/// → 1,5 taza; "3 huevos" → 3 unidad. Null si no hay cantidad numérica
/// ("sal al gusto", "una pizca" sí devuelve 1 pizca).
ParsedQuantity? parseQuantity(String linea) {
  final parsed = parseIngredientLine(linea);
  final texto = parsed.cantidad;
  if (texto == null || texto.trim().isEmpty) return null;

  // Separa número y unidad pegados ("200g", "1.5kg").
  final spaced = texto
      .replaceAllMapped(
        RegExp(r'(\d)([a-zA-Záéíóú])'),
        (m) => '${m[1]} ${m[2]}',
      )
      .trim();
  final words = spaced.split(RegExp(r'\s+'));

  double total = 0;
  var hayNumero = false;
  String? unidad;
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final n = normalizeText(w);
    final num = _numero(w);
    if (num != null) {
      // "2-3" o "2 a 3": se toma el primero; "1 y 1/2": se suman.
      if (hayNumero && i > 0 && const {'a', 'o', '-'}.contains(words[i - 1])) {
        continue;
      }
      total += num;
      hayNumero = true;
      continue;
    }
    if (const {'y', 'a', 'o', '-'}.contains(n)) continue;
    if (n.isEmpty) continue;
    unidad ??= n.replaceAll(' ', '');
  }
  if (!hayNumero || total <= 0) return null;

  if (unidad == null) return ParsedQuantity(total, 'unidad');
  final sing = singularize(unidad);
  final conv = _conversiones[unidad] ?? _conversiones[sing];
  if (conv != null) return ParsedQuantity(total * conv.$2, conv.$1);
  final alias = _alias[unidad] ?? _alias[sing] ?? sing;
  return ParsedQuantity(total, alias);
}

double? _numero(String w) {
  final n = normalizeText(w);
  if (_palabrasNumero.containsKey(n)) return _palabrasNumero[n];
  if (_fracciones.containsKey(w)) return _fracciones[w];
  // "1½"
  final mixed = RegExp(r'^(\d+)([½¼¾⅓⅔⅛])$').firstMatch(w);
  if (mixed != null) {
    return double.parse(mixed[1]!) + _fracciones[mixed[2]!]!;
  }
  final frac = RegExp(r'^(\d+)/(\d+)$').firstMatch(w);
  if (frac != null) {
    final d = double.parse(frac[2]!);
    return d == 0 ? null : double.parse(frac[1]!) / d;
  }
  // "2-3" → 2
  final range = RegExp(r'^(\d+(?:[.,]\d+)?)-\d').firstMatch(w);
  if (range != null) return double.tryParse(range[1]!.replaceAll(',', '.'));
  return double.tryParse(w.replaceAll(',', '.'));
}

/// Nombre canónico de una unidad de porción para comparar ("Dientes" →
/// "diente", "cdas" → "cucharada").
String canonicalPortionName(String nombre) {
  final n = normalizeText(nombre).replaceAll(' ', '');
  final s = singularize(n);
  return _alias[n] ?? _alias[s] ?? s;
}
