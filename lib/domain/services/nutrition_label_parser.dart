import '../entities/nutrition_facts.dart';
import 'ingredient_matcher.dart';

/// Línea de texto reconocida en una foto, con su caja (coordenadas en
/// píxeles de la imagen). Sin caja (`left`… nulos) se trata cada línea como
/// una fila.
class RecognizedLine {
  final String text;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const RecognizedLine(
    this.text, {
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  bool get tieneCaja =>
      left != null && top != null && right != null && bottom != null;
  double get centroY => (top! + bottom!) / 2;
  double get alto => bottom! - top!;
}

/// Resultado de interpretar una etiqueta nutricional.
class LabelParseResult {
  /// Valores por 100 g/ml (null = no encontrado).
  final NutritionFacts nutricion;

  /// Confianza 0..1 de cada valor encontrado (1 = con su unidad y coherente).
  final Map<Nutrient, double> confianza;

  /// 'g' o 'ml' si la etiqueta dice "por 100 ml".
  final String? unidad;

  /// Contenido neto del envase ("Peso neto: 500 g" → 500), en g o ml.
  final double? contenido;

  /// Peso de la ración si la etiqueta solo daba valores por ración.
  final double? porcion;

  /// Filas de texto usadas (para mostrar lo leído).
  final List<String> filas;

  const LabelParseResult({
    required this.nutricion,
    this.confianza = const {},
    this.unidad,
    this.contenido,
    this.porcion,
    this.filas = const [],
  });

  /// Nutrientes encontrados.
  int get encontrados =>
      Nutrient.values.where((n) => nutricion[n] != null).length;

  /// Valores que conviene revisar (dudosos o incoherentes).
  List<Nutrient> get dudosos => [
    for (final n in Nutrient.values)
      if (nutricion[n] != null && (confianza[n] ?? 0) < 0.8) n,
  ];

  /// Avisos de coherencia de la tabla leída.
  List<String> get avisos => nutricion.avisos;
}

/// Interpreta el texto de una etiqueta nutricional (Reglamento UE
/// 1169/2011) leído por OCR: valor energético (kJ/kcal), grasas, saturadas,
/// hidratos, azúcares, fibra, proteínas y sal, en varios idiomas.
///
/// - Agrupa en filas las líneas que están a la misma altura (las etiquetas
///   son tablas y el OCR suele devolver las columnas por separado).
/// - Toma el valor "por 100 g/ml" (la primera columna numérica de la fila;
///   se ignoran los % de ingesta de referencia).
/// - Energía: prefiere kcal; si solo hay kJ, kcal = kJ / 4,184.
/// - Corrige confusiones típicas del OCR (O→0, l→1, coma decimal) y entiende
///   "<0,5 g", "≤ 0,5 g", "menos de", "weniger als", "trazas" y "Spuren"
///   (→ 0). Con ">6 g", "≥ 6 g", "más de" o "mehr als" toma el mínimo (6) y
///   lo marca como dudoso.
/// - Si solo hay valores por ración y se lee su peso, los convierte a 100 g.
class NutritionLabelParser {
  NutritionLabelParser._();

  /// Confianza de un valor que la etiqueta da como mínimo (">6 g"): queda
  /// por debajo de 0,8 para que la revisión lo marque.
  static const double _confianzaMinimo = 0.7;

  // Palabras clave por nutriente (texto normalizado: minúsculas sin tildes).
  // El orden importa: las subcategorías se comprueban antes que su padre.
  static const List<(Nutrient, List<String>)> _claves = [
    (
      Nutrient.grasasSaturadas,
      ['saturad', 'saturat', 'satures', 'saturi', 'gesattigt', 'saturadas'],
    ),
    (
      Nutrient.azucares,
      ['azucar', 'sugar', 'sucre', 'zuccher', 'acucar', 'zucker'],
    ),
    (
      Nutrient.kcal,
      [
        'valor energetico',
        'energia',
        'energy',
        'energie',
        'valeur energetique',
        'valore energetico',
        'brennwert',
        'kcal',
        'kj',
      ],
    ),
    (
      Nutrient.grasas,
      [
        'grasa',
        'lipido',
        'materia grasa',
        'fat',
        'matieres grasses',
        'gordura',
        'grassi',
        'fett',
      ],
    ),
    (
      Nutrient.carbohidratos,
      [
        'hidratos de carbono',
        'hidratos',
        'carbohidrato',
        'glucido',
        'carbohydrate',
        'glucides',
        'carboidrati',
        'kohlenhydrat',
      ],
    ),
    (Nutrient.fibra, ['fibra', 'fibre', 'fiber', 'ballaststoff']),
    // "eiwei" cubre "Eiweiß" (la ß no es una letra a-z y la normalización la
    // quita), "Eiweiss" y "EiweiB" (el OCR confunde a menudo la ß con una B).
    (Nutrient.proteinas, ['proteina', 'protein', 'proteine', 'eiwei']),
    (Nutrient.sal, ['sal', 'salt', 'sel', 'sale', 'salz']),
  ];

  /// Número con su cota y su unidad. Grupos: 1 = "menor que" ("<", "≤",
  /// "menos de", "weniger als"), 2 = "mayor que" (">", "≥", "más de",
  /// "mehr als"), 3 = valor, 4 = unidad.
  static final RegExp _numero = RegExp(
    r'(?:(<\s*|≤\s*|\bmenos de\s*|\bweniger als\s*)|(>\s*|≥\s*|\bm[aá]s de\s*|\bmehr als\s*))?(\d+(?:[.,]\d+)?)\s*(kcal|kj|mg|g|%)?',
  );

  static _Cota? _cotaDe(RegExpMatch m) =>
      m[1] != null ? _Cota.menor : (m[2] != null ? _Cota.mayor : null);

  static final RegExp _sodioRe = RegExp(r'(^|[^a-z])(sodio|sodium|natrium)');

  /// "trazas", "traces", "Spuren": cantidad despreciable (→ 0).
  static final RegExp _trazasRe = RegExp(r'traza|trace|spur');

  /// Interpreta líneas con o sin caja.
  static LabelParseResult parse(List<RecognizedLine> lines) {
    final filas = _agruparFilas(lines);
    return _parseFilas(filas);
  }

  /// Interpreta texto plano (una fila por línea).
  static LabelParseResult parseText(String text) => _parseFilas(
    text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList(),
  );

  static List<String> _agruparFilas(List<RecognizedLine> lines) {
    final conCaja = lines
        .where((l) => l.tieneCaja && l.text.trim().isNotEmpty)
        .toList();
    if (conCaja.length < lines.length ~/ 2 || conCaja.isEmpty) {
      return [
        for (final l in lines)
          if (l.text.trim().isNotEmpty) l.text,
      ];
    }
    final altos = conCaja.map((l) => l.alto).toList()..sort();
    final mediana = altos[altos.length ~/ 2];
    conCaja.sort((a, b) => a.centroY.compareTo(b.centroY));
    final filas = <List<RecognizedLine>>[];
    for (final l in conCaja) {
      final ultima = filas.isEmpty ? null : filas.last;
      if (ultima != null) {
        final cy =
            ultima.map((x) => x.centroY).reduce((a, b) => a + b) /
            ultima.length;
        if ((l.centroY - cy).abs() <= mediana * 0.6) {
          ultima.add(l);
          continue;
        }
      }
      filas.add([l]);
    }
    return [
      for (final f in filas)
        (f..sort((a, b) => a.left!.compareTo(b.left!)))
            .map((l) => l.text.trim())
            .join(' '),
    ];
  }

  /// Arregla confusiones del OCR dentro de números: "1O,5" → "10,5",
  /// "l,2" → "1,2", "0.5g" se mantiene.
  static String _arreglarOcr(String s) {
    var t = s;
    // O/o entre dígitos o junto a coma/punto decimal → 0
    t = t.replaceAllMapped(
      RegExp(r'(?<=[\d.,])[Oo]|[Oo](?=[\d.,]\d)'),
      (_) => '0',
    );
    // l/I/| pegados a dígitos → 1
    t = t.replaceAllMapped(
      RegExp(r'(?<=\d[.,]?)[lI|]|[lI|](?=[.,]?\d)'),
      (_) => '1',
    );
    // "4 , 7" → "4,7"
    t = t.replaceAllMapped(
      RegExp(r'(\d)\s*([.,])\s*(\d)'),
      (m) => '${m[1]}${m[2]}${m[3]}',
    );
    return t;
  }

  static final RegExp _salRe = RegExp(
    r'(^|[^a-z])(sal|salt|sel|sale|salz)([^a-z]|$)',
  );

  static Nutrient? _nutrienteDe(String norm) {
    for (final (n, claves) in _claves) {
      if (n == Nutrient.sal) {
        if (_salRe.hasMatch(norm)) return n;
        continue;
      }
      for (final c in claves) {
        if (RegExp('(^|[^a-z])${RegExp.escape(c)}').hasMatch(norm)) return n;
      }
    }
    return null;
  }

  /// Minúsculas y sin tildes, conservando cifras, comas y puntos.
  static String _simple(String s) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString();
  }

  static double? _toDouble(String s) => double.tryParse(s.replaceAll(',', '.'));

  static LabelParseResult _parseFilas(List<String> filasOriginales) {
    final valores = <Nutrient, double>{};
    final confianza = <Nutrient, double>{};
    String? unidad;
    double? porcion;
    var hay100 = false;
    double? sodioG;

    // Un valor dado como mínimo (">6 g") se guarda, pero como dudoso.
    void guardar(Nutrient n, double v, double c, _Cota? cota) {
      valores[n] = v;
      confianza[n] = cota == _Cota.mayor && c > _confianzaMinimo
          ? _confianzaMinimo
          : c;
    }

    final textoTotal = _simple(filasOriginales.map(_arreglarOcr).join(' '));
    if (RegExp(r'100\s*ml').hasMatch(textoTotal)) unidad = 'ml';
    if (RegExp(r'100\s*(g|gr|ml)').hasMatch(textoTotal)) hay100 = true;
    final mPorcion = RegExp(
      r'(racion|porcion|serving|portion|porzione)[^0-9]{0,20}(\d+(?:[.,]\d+)?)\s*(g|ml)',
    ).firstMatch(textoTotal);
    if (mPorcion != null) porcion = _toDouble(mPorcion[2]!);

    for (final original in filasOriginales) {
      final fila = _arreglarOcr(original);
      final norm = normalizeText(fila);
      if (norm.isEmpty) continue;

      // Sodio (mg o g) → sal = sodio × 2,5 si no hay sal.
      if (_sodioRe.hasMatch(norm)) {
        final m = _numero.firstMatch(
          fila.toLowerCase().replaceFirst(RegExp(r'^[^\d<]*'), ''),
        );
        if (m != null) {
          final v = _toDouble(m[3]!);
          if (v != null) sodioG = m[4] == 'mg' ? v / 1000 : v;
        }
        continue;
      }

      final n = _nutrienteDe(norm);
      // Cada nutriente se toma una vez; la energía puede mejorarse si una
      // fila posterior trae las kcal explícitas.
      if (n == null) continue;
      if (valores.containsKey(n) &&
          !(n == Nutrient.kcal && (confianza[n] ?? 0) < 1)) {
        continue;
      }

      // Números de la fila (después de la etiqueta).
      final lower = fila.toLowerCase();
      final nums = <(double, String?, _Cota?)>[];
      for (final m in _numero.allMatches(lower)) {
        final v = _toDouble(m[3]!);
        if (v == null) continue;
        final u = m[4];
        if (u == '%') continue; // % de ingesta de referencia
        // El "100" de "por 100 g" en la misma fila no es un valor.
        final despues = lower.substring(m.end);
        if (v == 100 &&
            RegExp(r'^\s*(g|ml)\b').hasMatch(despues) &&
            u == null) {
          continue;
        }
        nums.add((v, u, _cotaDe(m)));
      }
      if (nums.isEmpty && _trazasRe.hasMatch(norm)) {
        valores[n] = 0;
        confianza[n] = 0.9;
        continue;
      }
      if (nums.isEmpty) continue;

      if (n == Nutrient.kcal) {
        final kcal = nums.where((x) => x.$2 == 'kcal').toList();
        final kj = nums.where((x) => x.$2 == 'kj').toList();
        if (kcal.isNotEmpty) {
          guardar(n, kcal.first.$1, 1, kcal.first.$3);
        } else if (valores.containsKey(n)) {
          continue; // ya había un valor y esta fila no trae kcal
        } else if (nums.length >= 2 &&
            (nums[0].$1 / (nums[1].$1 == 0 ? 1 : nums[1].$1) - 4.184).abs() <
                0.25) {
          // "1046 / 250" sin unidades: kJ / kcal.
          guardar(n, nums[1].$1, 0.85, nums[1].$3);
        } else if (kj.isNotEmpty) {
          final kcalDeKj = double.parse(
            (kj.first.$1 / 4.184).toStringAsFixed(0),
          );
          guardar(n, kcalDeKj, 0.8, kj.first.$3);
        } else {
          guardar(n, nums.first.$1, 0.6, nums.first.$3);
        }
        continue;
      }

      final primero = nums.firstWhere(
        (x) => x.$2 != 'kcal' && x.$2 != 'kj',
        orElse: () => nums.first,
      );
      var v = primero.$1;
      if (primero.$2 == 'mg') v = v / 1000;
      if (primero.$3 == _Cota.menor) v = 0; // "<0,5 g": despreciable
      guardar(n, v, primero.$2 == null ? 0.7 : 1, primero.$3);
    }

    if (!valores.containsKey(Nutrient.sal) && sodioG != null) {
      valores[Nutrient.sal] = double.parse((sodioG * 2.5).toStringAsFixed(2));
      confianza[Nutrient.sal] = 0.8;
    }

    // Solo por ración: convertir a 100 g.
    if (!hay100 && porcion != null && porcion > 0) {
      final f = 100 / porcion;
      valores.updateAll((_, v) => double.parse((v * f).toStringAsFixed(2)));
      confianza.updateAll((_, c) => c * 0.9);
    }

    var nutricion = NutritionFacts.desdeMapa(valores);

    // Coherencia: si una subcategoría supera a su padre, ambas son dudosas.
    void dudar(Nutrient n) {
      if (confianza.containsKey(n)) confianza[n] = confianza[n]!.clamp(0, 0.6);
    }

    if ((nutricion.grasasSaturadas ?? 0) >
        (nutricion.grasas ?? double.infinity)) {
      dudar(Nutrient.grasasSaturadas);
      dudar(Nutrient.grasas);
    }
    if ((nutricion.azucares ?? 0) >
        (nutricion.carbohidratos ?? double.infinity)) {
      dudar(Nutrient.azucares);
      dudar(Nutrient.carbohidratos);
    }
    final est = nutricion.kcalEstimadas;
    final k = nutricion.kcal;
    if (est != null && k != null && k > 20 && (k - est).abs() / k > 0.2) {
      dudar(Nutrient.kcal);
    }
    nutricion = nutricion.redondeada();

    return LabelParseResult(
      nutricion: nutricion,
      confianza: confianza,
      unidad: unidad,
      contenido: _contenidoNeto(textoTotal),
      porcion: hay100 ? null : porcion,
      filas: filasOriginales,
    );
  }

  /// "Peso neto 500 g", "Contenido neto: 1 L", "Nettofüllmenge 750 ml",
  /// "Inhalt: 1,5 kg" → g o ml.
  static final RegExp _contenidoNetoRe = RegExp(
    r'(peso neto|contenido neto|cont neto|net weight|poids net|peso netto|netto[a-z]*|fullmenge|\binhalt\b|net)\D{0,8}(\d+(?:[.,]\d+)?)\s*(kg|g|gr|cl|ml|l)\b',
  );

  static double? _contenidoNeto(String norm) {
    final m = _contenidoNetoRe.firstMatch(norm);
    if (m == null) return null;
    final v = _toDouble(m[2]!);
    if (v == null) return null;
    return switch (m[3]) {
      'kg' || 'l' => v * 1000,
      'cl' => v * 10,
      _ => v,
    };
  }
}

/// Cota que acompaña a un número de la etiqueta: "<0,5 g" o ">6 g".
enum _Cota { menor, mayor }
