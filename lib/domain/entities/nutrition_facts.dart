import 'package:equatable/equatable.dart';

/// Nutrientes de la tabla nutricional (orden de la etiqueta UE, Reglamento
/// 1169/2011). Los 4 primeros ([esencial]) son los que exige el contador.
enum Nutrient {
  kcal('Valor energético', 'kcal', esencial: true),
  grasas('Grasas', 'g', esencial: true),
  grasasSaturadas('de las cuales saturadas', 'g'),
  carbohidratos('Hidratos de carbono', 'g', esencial: true),
  azucares('de los cuales azúcares', 'g'),
  fibra('Fibra alimentaria', 'g'),
  proteinas('Proteínas', 'g', esencial: true),
  sal('Sal', 'g');

  final String etiqueta;
  final String unidad;
  final bool esencial;

  const Nutrient(this.etiqueta, this.unidad, {this.esencial = false});

  /// Subcategoría de otro nutriente (se muestra sangrada).
  bool get esSubcategoria =>
      this == grasasSaturadas || this == azucares;
}

/// De dónde salen los valores nutricionales de un alimento.
enum NutritionSource {
  manual('manual'),
  etiquetaOcr('etiqueta_ocr'),
  importado('importado'),
  calculado('calculado');

  /// Valor guardado en la columna `nutricion_origen`.
  final String clave;

  const NutritionSource(this.clave);

  static NutritionSource? fromClave(String? clave) {
    for (final s in values) {
      if (s.clave == clave) return s;
    }
    return null;
  }
}

/// Tabla nutricional por 100 g (o 100 ml). `null` = dato desconocido, que NO
/// es lo mismo que 0: un alimento con datos esenciales desconocidos está
/// "pendiente de completar".
class NutritionFacts extends Equatable {
  final double? kcal;
  final double? proteinas;
  final double? grasas;
  final double? grasasSaturadas;
  final double? carbohidratos;
  final double? azucares;
  final double? fibra;
  final double? sal;

  const NutritionFacts({
    this.kcal,
    this.proteinas,
    this.grasas,
    this.grasasSaturadas,
    this.carbohidratos,
    this.azucares,
    this.fibra,
    this.sal,
  });

  /// Sin ningún dato.
  static const NutritionFacts vacia = NutritionFacts();

  /// Con los 4 nutrientes esenciales.
  const NutritionFacts.basica({
    required double this.kcal,
    required double this.proteinas,
    required double this.grasas,
    required double this.carbohidratos,
  }) : grasasSaturadas = null,
       azucares = null,
       fibra = null,
       sal = null;

  double? operator [](Nutrient n) => switch (n) {
    Nutrient.kcal => kcal,
    Nutrient.proteinas => proteinas,
    Nutrient.grasas => grasas,
    Nutrient.grasasSaturadas => grasasSaturadas,
    Nutrient.carbohidratos => carbohidratos,
    Nutrient.azucares => azucares,
    Nutrient.fibra => fibra,
    Nutrient.sal => sal,
  };

  /// Copia con [n] = [valor] (puede ser null para borrarlo).
  NutritionFacts conValor(Nutrient n, double? valor) => NutritionFacts(
    kcal: n == Nutrient.kcal ? valor : kcal,
    proteinas: n == Nutrient.proteinas ? valor : proteinas,
    grasas: n == Nutrient.grasas ? valor : grasas,
    grasasSaturadas: n == Nutrient.grasasSaturadas ? valor : grasasSaturadas,
    carbohidratos: n == Nutrient.carbohidratos ? valor : carbohidratos,
    azucares: n == Nutrient.azucares ? valor : azucares,
    fibra: n == Nutrient.fibra ? valor : fibra,
    sal: n == Nutrient.sal ? valor : sal,
  );

  static NutritionFacts desdeMapa(Map<Nutrient, double?> valores) {
    var out = vacia;
    valores.forEach((k, v) => out = out.conValor(k, v));
    return out;
  }

  /// Tiene kcal, proteínas, grasas y carbohidratos.
  bool get estaCompleta => faltantes.isEmpty;

  /// Nutrientes esenciales que faltan.
  List<Nutrient> get faltantes => [
    for (final n in Nutrient.values)
      if (n.esencial && this[n] == null) n,
  ];

  /// Ningún dato conocido.
  bool get estaVacia => Nutrient.values.every((n) => this[n] == null);

  /// Valores multiplicados por [factor] (p. ej. cantidad/100). Los
  /// desconocidos siguen siendo desconocidos.
  NutritionFacts escalada(double factor) => NutritionFacts(
    kcal: _mul(kcal, factor),
    proteinas: _mul(proteinas, factor),
    grasas: _mul(grasas, factor),
    grasasSaturadas: _mul(grasasSaturadas, factor),
    carbohidratos: _mul(carbohidratos, factor),
    azucares: _mul(azucares, factor),
    fibra: _mul(fibra, factor),
    sal: _mul(sal, factor),
  );

  /// Suma nutriente a nutriente. Si en alguno de los dos falta un dato, la
  /// suma de ese nutriente se toma como la parte conocida solo si
  /// [ignorarDesconocidos]; si no, queda desconocida.
  NutritionFacts sumar(NutritionFacts o, {bool ignorarDesconocidos = false}) {
    double? add(double? a, double? b) {
      if (a == null && b == null) return null;
      if (a == null || b == null) {
        return ignorarDesconocidos ? (a ?? 0) + (b ?? 0) : null;
      }
      return a + b;
    }

    return NutritionFacts(
      kcal: add(kcal, o.kcal),
      proteinas: add(proteinas, o.proteinas),
      grasas: add(grasas, o.grasas),
      grasasSaturadas: add(grasasSaturadas, o.grasasSaturadas),
      carbohidratos: add(carbohidratos, o.carbohidratos),
      azucares: add(azucares, o.azucares),
      fibra: add(fibra, o.fibra),
      sal: add(sal, o.sal),
    );
  }

  /// Rellena los huecos (null) con los valores de [otra]; lo conocido se
  /// conserva. Es la regla de fusión al importar repertorios.
  NutritionFacts completadaCon(NutritionFacts otra) => NutritionFacts(
    kcal: kcal ?? otra.kcal,
    proteinas: proteinas ?? otra.proteinas,
    grasas: grasas ?? otra.grasas,
    grasasSaturadas: grasasSaturadas ?? otra.grasasSaturadas,
    carbohidratos: carbohidratos ?? otra.carbohidratos,
    azucares: azucares ?? otra.azucares,
    fibra: fibra ?? otra.fibra,
    sal: sal ?? otra.sal,
  );

  /// Redondeo a [decimales] (por defecto 2) para no guardar precisión irreal.
  NutritionFacts redondeada([int decimales = 2]) {
    double? r(double? v) {
      if (v == null) return null;
      final f = _pow10(decimales);
      return (v * f).roundToDouble() / f;
    }

    return NutritionFacts(
      kcal: r(kcal),
      proteinas: r(proteinas),
      grasas: r(grasas),
      grasasSaturadas: r(grasasSaturadas),
      carbohidratos: r(carbohidratos),
      azucares: r(azucares),
      fibra: r(fibra),
      sal: r(sal),
    );
  }

  /// Kcal esperadas por los macros: 4·P + 4·C + 9·G (+ 2·fibra). Null si
  /// falta alguno de los tres macros.
  double? get kcalEstimadas {
    final p = proteinas, c = carbohidratos, g = grasas;
    if (p == null || c == null || g == null) return null;
    return 4 * p + 4 * c + 9 * g + 2 * (fibra ?? 0);
  }

  /// Avisos de coherencia (no bloquean el guardado).
  List<String> get avisos {
    final out = <String>[];
    final est = kcalEstimadas;
    final k = kcal;
    if (est != null && k != null && (k > 5 || est > 5)) {
      final ref = k > est ? k : est;
      if ((k - est).abs() / ref > 0.15) {
        out.add(
          'Las calorías (${k.toStringAsFixed(0)} kcal) no cuadran con los '
          'macros (≈ ${est.toStringAsFixed(0)} kcal).',
        );
      }
    }
    if (grasasSaturadas != null &&
        grasas != null &&
        grasasSaturadas! > grasas! + 0.05) {
      out.add('Las grasas saturadas superan a las grasas totales.');
    }
    if (azucares != null &&
        carbohidratos != null &&
        azucares! > carbohidratos! + 0.05) {
      out.add('Los azúcares superan a los hidratos de carbono.');
    }
    final suma =
        (proteinas ?? 0) + (grasas ?? 0) + (carbohidratos ?? 0) + (sal ?? 0);
    if (suma > 100.5) {
      out.add('Los macronutrientes suman más de 100 g por cada 100 g.');
    }
    return out;
  }

  static double? _mul(double? v, double f) => v == null ? null : v * f;

  static double _pow10(int n) {
    var f = 1.0;
    for (var i = 0; i < n; i++) {
      f *= 10;
    }
    return f;
  }

  @override
  List<Object?> get props => [
    kcal,
    proteinas,
    grasas,
    grasasSaturadas,
    carbohidratos,
    azucares,
    fibra,
    sal,
  ];
}
