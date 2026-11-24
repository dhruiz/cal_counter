/// Utilidades puras para interpretar líneas de ingredientes escritas a mano
/// ("2 dientes de ajo", "Sal al gusto", "200 g de arroz (opcional)") y
/// compararlas con los ingredientes que el usuario dice tener.
///
/// La comparación trabaja con "tokens clave": palabras normalizadas (sin
/// tildes, minúsculas), en singular, sin cantidades, unidades ni palabras
/// vacías, y con sinónimos regionales unificados (papa = patata...).
library;

/// Ingredientes que casi todo el mundo tiene en casa. La búsqueda puede
/// asumirlos como disponibles.
const List<String> ingredientesBasicos = ['sal', 'pimienta', 'agua', 'aceite'];

// dart format off
const Set<String> _stopwords = {
  'de', 'del', 'la', 'el', 'lo', 'los', 'las', 'y', 'e', 'o', 'u', 'con',
  'en', 'a', 'al', 'para', 'por', 'sin', 'su', 'sus', 'mas', 'muy', 'bien',
  'cada', 'algo', 'poco', 'poca', 'unos', 'unas', 'algun', 'alguna',
};

const Set<String> _numberWords = {
  'un', 'una', 'uno', 'medio', 'media', 'dos', 'tres', 'cuatro', 'cinco',
  'seis', 'siete', 'ocho', 'nueve', 'diez', 'once', 'doce', 'docena',
  'cuarto', 'tercio', 'par',
};

/// Unidades de medida en forma normalizada y singular.
const Set<String> _units = {
  'g', 'gr', 'grs', 'gramo', 'kg', 'kilo', 'kilogramo', 'mg', 'ml',
  'mililitro', 'cc', 'l', 'lt', 'litro', 'cl', 'dl', 'taza', 'tazon',
  'vaso', 'copa', 'cucharada', 'cda', 'cdas', 'cucharadita', 'cdta', 'cdtas',
  'cdita', 'cucharon', 'pizca', 'pellizco', 'diente', 'unidad', 'ud', 'uds',
  'lata', 'bote', 'sobre', 'paquete', 'punado', 'rama', 'ramita', 'hoja',
  'rebanada', 'loncha', 'lonja', 'filete', 'trozo', 'chorro', 'chorrito',
  'onza', 'oz', 'lb', 'libra', 'manojo', 'atado', 'cabeza', 'tallo', 'gota',
  'tarro', 'frasco', 'bolsa', 'pieza', 'porcion', 'racion', 'cubito',
  'poco', 'poquito',
};

/// Palabras que no describen el ingrediente ("al gusto", "opcional"...).
const Set<String> _noise = {
  'gusto', 'opcional', 'cantidad', 'necesaria', 'necesario', 'cn', 'cs',
  'aprox', 'aproximadamente', 'suficiente',
};

// dart format on

/// Sinónimos regionales de una sola palabra → forma canónica.
const Map<String, String> _synonyms = {
  'papa': 'patata',
  'palta': 'aguacate',
  'choclo': 'maiz',
  'elote': 'maiz',
  'arveja': 'guisante',
  'chicharo': 'guisante',
  'durazno': 'melocoton',
  'banana': 'platano',
  'banano': 'platano',
  'mani': 'cacahuete',
  'cacahuate': 'cacahuete',
  'frutilla': 'fresa',
  'poroto': 'frijol',
  'frejol': 'frijol',
  'alubia': 'frijol',
  'jitomate': 'tomate',
  'zumo': 'jugo',
  'gamba': 'camaron',
  'zapallito': 'calabacin',
  'zucchini': 'calabacin',
  'morron': 'pimiento',
  'betabel': 'remolacha',
  'betarraga': 'remolacha',
  'anana': 'pina',
  'camote': 'batata',
  'boniato': 'batata',
  'repollo': 'col',
  'culantro': 'cilantro',
  'poro': 'puerro',
};

const String _accentFrom = 'áàäâãéèëêíìïîóòöôõúùüûñç';
const String _accentTo = 'aaaaaeeeeiiiiooooouuuunc';

/// Tabla rune → letra sin tilde (construida una vez).
final Map<int, int> _accentMap = {
  for (var i = 0; i < _accentFrom.length; i++)
    _accentFrom.codeUnitAt(i): _accentTo.codeUnitAt(i),
};

const int _a = 0x61, _z = 0x7a, _d0 = 0x30, _d9 = 0x39, _space = 0x20;

final RegExp _leadingDigit = RegExp(r'^\d');

/// Minúsculas, sin tildes, ñ→n, cualquier signo → espacio, espacios colapsados.
///
/// Se llama miles de veces por pulsación al buscar recetas por ingredientes:
/// trabaja con códigos de carácter en vez de crear un `RegExp` por carácter
/// (la versión anterior tardaba ~130 ms con 300 recetas).
String normalizeText(String input) {
  final out = <int>[];
  var pendingSpace = false;
  for (final rune in input.toLowerCase().runes) {
    final mapped = _accentMap[rune] ?? rune;
    final isWordChar =
        (mapped >= _a && mapped <= _z) || (mapped >= _d0 && mapped <= _d9);
    if (isWordChar) {
      if (pendingSpace && out.isNotEmpty) out.add(_space);
      pendingSpace = false;
      out.add(mapped);
    } else {
      pendingSpace = true;
    }
  }
  return String.fromCharCodes(out);
}

/// Singular aproximado en español. No es perfecto, pero es consistente:
/// como se aplica igual a recetas y búsqueda, "tomates" y "tomate" coinciden.
String singularize(String w) {
  if (w.length <= 3) return w;
  if (w.endsWith('ces') && w.length > 4 && 'aeiou'.contains(w[w.length - 4])) {
    return '${w.substring(0, w.length - 3)}z'; // nueces → nuez
  }
  if (w.endsWith('ies')) return w.substring(0, w.length - 2); // ajies → aji
  if (w.endsWith('es')) {
    final c = w[w.length - 3];
    if ('lnrdjy'.contains(c)) return w.substring(0, w.length - 2); // limones
    return w.substring(0, w.length - 1); // tomates → tomate
  }
  if (w.endsWith('s') && !w.endsWith('ss')) return w.substring(0, w.length - 1);
  return w;
}

/// Tokens clave de un texto (ingrediente de receta o término de búsqueda).
Set<String> keyTokens(String text) {
  final out = <String>{};
  for (final raw in normalizeText(text).split(' ')) {
    if (raw.length < 2) continue;
    if (_leadingDigit.hasMatch(raw)) continue; // "200", "200g", "1"
    if (_stopwords.contains(raw) || _numberWords.contains(raw)) continue;
    final s = singularize(raw);
    if (_units.contains(raw) || _units.contains(s)) continue;
    if (_noise.contains(raw) || _noise.contains(s)) continue;
    out.add(_synonyms[s] ?? s);
  }
  return out;
}

/// Dos ingredientes coinciden si los tokens de uno contienen a los del otro:
/// "pollo" ↔ "pechuga de pollo", "aceite" ↔ "aceite de oliva".
bool tokensMatch(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return false;
  return a.containsAll(b) || b.containsAll(a);
}

/// Separa lo que escribe el usuario ("huevo, patata y cebolla") en términos.
List<String> splitUserTerms(String input) {
  final seen = <String>{};
  final out = <String>[];
  for (final part in input.split(RegExp(r'[,;\n]|\s+y\s+'))) {
    final t = part.trim();
    if (t.isEmpty) continue;
    final key = normalizeText(t);
    if (key.isEmpty || !seen.add(key)) continue;
    out.add(t);
  }
  return out;
}

/// Línea de ingrediente interpretada.
class ParsedIngredient {
  /// Cantidad tal cual se escribió ("200 g", "2 dientes", "Una pizca") o null.
  final String? cantidad;

  /// Nombre limpio para mostrar o llevar a la lista de compra ("Arroz").
  final String nombre;

  /// Marcado como "(opcional)": no cuenta como faltante.
  final bool opcional;

  ParsedIngredient({
    this.cantidad,
    required this.nombre,
    this.opcional = false,
  });

  /// Tokens clave del nombre (calculados una vez; conjunto inmodificable
  /// porque la instancia se comparte desde la caché de [parseIngredientLine]).
  late final Set<String> tokens = Set.unmodifiable(keyTokens(nombre));
}

/// Caché de líneas ya interpretadas. [parseIngredientLine] es una función
/// pura y las líneas de las recetas casi nunca cambian, pero la búsqueda por
/// ingredientes las reinterpreta en cada pulsación.
final Map<String, ParsedIngredient> _parseCache = {};
const int _parseCacheMax = 4096;

final RegExp _numberToken = RegExp(
  r'^(\d+([.,/\-]\d+)*[a-zA-Z.]*|[½¼¾⅓⅔⅛]|\d+[½¼¾⅓⅔⅛])$',
);
final RegExp _optionalRe = RegExp(
  r'[\(\[]?\s*\bopcional\b\s*[\)\]]?',
  caseSensitive: false,
);
final RegExp _toTasteRe = RegExp(
  r'(\bal gusto\b|\ba gusto\b|\bc/n\b|\bc\.n\.?|\bc/s\b|\bcantidad necesaria\b)',
  caseSensitive: false,
);
final RegExp _parensRe = RegExp(r'\(([^)]*)\)');
final RegExp _trailingQtyRe = RegExp(
  r'^(.*?\S)\s*[:\-–,]?\s+(\d+(?:[.,/]\d+)?\s*[a-zA-Záéíóú.]*)$',
);
final RegExp _bulletPrefixRe = RegExp(r'^[-•*·▪►✓✔]+\s*');
final RegExp _whitespaceRe = RegExp(r'\s+');
final RegExp _leadingQtyNumberRe = RegExp(r'^[\d.,/]+\s*');
final RegExp _edgePunctuationRe = RegExp(r'^[\s,;:.\-–]+|[\s,;:.\-–]+$');

bool _isQuantityWord(String word) {
  if (_numberToken.hasMatch(word)) return true;
  return _numberWords.contains(normalizeText(word));
}

bool _isUnitWord(String word) {
  final n = normalizeText(word).replaceAll(' ', '');
  return _units.contains(n) || _units.contains(singularize(n));
}

/// Interpreta una línea de ingrediente escrita libremente.
ParsedIngredient parseIngredientLine(String line) {
  final cached = _parseCache[line];
  if (cached != null) return cached;
  final parsed = _parseIngredientLine(line);
  if (_parseCache.length >= _parseCacheMax) _parseCache.clear();
  _parseCache[line] = parsed;
  return parsed;
}

ParsedIngredient _parseIngredientLine(String line) {
  // Línea vacía: antes `nombre[0]` lanzaba RangeError.
  if (line.trim().isEmpty) return ParsedIngredient(nombre: '');
  var text = line.trim().replaceFirst(_bulletPrefixRe, '');

  final opcional = _optionalRe.hasMatch(text);
  text = text.replaceAll(_optionalRe, ' ');
  text = text.replaceAll(_toTasteRe, ' ');

  // Paréntesis: "(200 g)" se usa como cantidad; el resto se descarta del nombre.
  String? parenQty;
  text = text.replaceAllMapped(_parensRe, (m) {
    final inner = m.group(1)!.trim();
    if (parenQty == null && _leadingDigit.hasMatch(inner)) parenQty = inner;
    return ' ';
  });
  text = text.replaceAll(_whitespaceRe, ' ').trim();

  final words = text.split(' ').where((w) => w.isNotEmpty).toList();
  var i = 0;
  // Cantidad inicial: "2", "1/2", "1 y 1/2", "2-3", "2 a 3", "una", "200g".
  while (i < words.length) {
    final w = words[i];
    if (_isQuantityWord(w)) {
      i++;
    } else if (i > 0 &&
        i + 1 < words.length &&
        const {'y', 'a', '-', 'o'}.contains(w.toLowerCase()) &&
        _isQuantityWord(words[i + 1])) {
      i++;
    } else {
      break;
    }
  }
  if (i > 0 && i < words.length && _isUnitWord(words[i])) i++;
  final qtyWords = words.sublist(0, i);
  var rest = words.sublist(i);
  if (rest.isNotEmpty &&
      const {'de', 'del'}.contains(rest.first.toLowerCase())) {
    rest = rest.sublist(1);
  }

  String? cantidad = qtyWords.isEmpty ? null : qtyWords.join(' ');
  var nombre = rest.join(' ');

  // Cantidad al final: "Harina 200 g", "Harina: 200 g".
  if (cantidad == null) {
    final m = _trailingQtyRe.firstMatch(nombre);
    if (m != null) {
      final qty = m.group(2)!;
      final unitPart = qty.replaceFirst(_leadingQtyNumberRe, '');
      if (unitPart.isEmpty || _isUnitWord(unitPart)) {
        cantidad = qty;
        nombre = m.group(1)!;
      }
    }
  }
  cantidad ??= parenQty;

  nombre = nombre.replaceAll(_edgePunctuationRe, '');
  if (nombre.isEmpty) nombre = line.trim();
  nombre = nombre[0].toUpperCase() + nombre.substring(1);

  return ParsedIngredient(
    cantidad: cantidad,
    nombre: nombre,
    opcional: opcional,
  );
}

/// Conjunto de ingredientes que el usuario tiene, listo para comparar.
class IngredientAvailability {
  final List<Set<String>> _userSets;
  final List<Set<String>> _basicSets;

  IngredientAvailability(List<String> terminos, {bool incluirBasicos = false})
    : _userSets = terminos.map(keyTokens).where((s) => s.isNotEmpty).toList(),
      _basicSets = incluirBasicos
          ? ingredientesBasicos.map(keyTokens).toList()
          : const [];

  /// Hay al menos un término útil (sin contar los básicos).
  bool get isEmpty => _userSets.isEmpty;

  /// El usuario indicó explícitamente este ingrediente.
  bool coveredByUser(String ingredientLine) =>
      coveredByUserTokens(parseIngredientLine(ingredientLine).tokens);

  /// El usuario lo tiene (indicado o asumido como básico).
  bool covers(String ingredientLine) =>
      coversTokens(parseIngredientLine(ingredientLine).tokens);

  /// Como [coveredByUser] con los tokens ya calculados (evita reinterpretar
  /// la línea varias veces en bucles).
  bool coveredByUserTokens(Set<String> tokens) =>
      _userSets.any((u) => tokensMatch(tokens, u));

  /// Como [covers] con los tokens ya calculados.
  bool coversTokens(Set<String> tokens) =>
      coveredByUserTokens(tokens) ||
      _basicSets.any((b) => tokensMatch(tokens, b));

  /// Es uno de los básicos (sal, pimienta, agua, aceite).
  static bool isBasic(String ingredientLine) {
    final tokens = parseIngredientLine(ingredientLine).tokens;
    return ingredientesBasicos.any((b) => tokensMatch(tokens, keyTokens(b)));
  }
}
