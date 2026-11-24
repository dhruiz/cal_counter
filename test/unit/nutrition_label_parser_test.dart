import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/services/nutrition_label_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Textos como los devuelve el OCR de etiquetas reales (con su ruido).
void main() {
  void expectFacts(
    LabelParseResult r, {
    double? kcal,
    double? grasas,
    double? saturadas,
    double? hidratos,
    double? azucares,
    double? fibra,
    double? proteinas,
    double? sal,
  }) {
    final n = r.nutricion;
    if (kcal != null) expect(n.kcal, closeTo(kcal, 0.01), reason: 'kcal');
    if (grasas != null) {
      expect(n.grasas, closeTo(grasas, 0.01), reason: 'grasas');
    }
    if (saturadas != null) {
      expect(n.grasasSaturadas, closeTo(saturadas, 0.01), reason: 'saturadas');
    }
    if (hidratos != null) {
      expect(n.carbohidratos, closeTo(hidratos, 0.01), reason: 'hidratos');
    }
    if (azucares != null) {
      expect(n.azucares, closeTo(azucares, 0.01), reason: 'azúcares');
    }
    if (fibra != null) expect(n.fibra, closeTo(fibra, 0.01), reason: 'fibra');
    if (proteinas != null) {
      expect(n.proteinas, closeTo(proteinas, 0.01), reason: 'proteínas');
    }
    if (sal != null) expect(n.sal, closeTo(sal, 0.01), reason: 'sal');
  }

  test('leche: etiqueta española típica por 100 ml', () {
    final r = NutritionLabelParser.parseText('''
INFORMACIÓN NUTRICIONAL
Valores medios por 100 ml
Valor energético 194 kJ / 46 kcal
Grasas 1,6 g
de las cuales saturadas 1,0 g
Hidratos de carbono 4,7 g
de los cuales azúcares 4,7 g
Proteínas 3,1 g
Sal 0,13 g
Contenido neto: 1 L
''');
    expectFacts(
      r,
      kcal: 46,
      grasas: 1.6,
      saturadas: 1.0,
      hidratos: 4.7,
      azucares: 4.7,
      proteinas: 3.1,
      sal: 0.13,
    );
    expect(r.unidad, 'ml');
    expect(r.contenido, 1000);
    expect(r.nutricion.estaCompleta, isTrue);
    expect(r.dudosos, isEmpty);
  });

  test('dos columnas (100 g y ración) con % IR: toma la de 100 g', () {
    final r = NutritionLabelParser.parseText('''
Información nutricional  Por 100 g  Por ración (30 g)  %IR*
Valor energético  1569 kJ  471 kJ
375 kcal  113 kcal  6%
Grasas  2,0 g  0,6 g  1%
de las cuales saturadas  0,4 g  0,1 g  1%
Hidratos de carbono  77 g  23 g  9%
de los cuales azúcares  17 g  5,1 g  6%
Fibra alimentaria  5,5 g  1,7 g
Proteínas  8,0 g  2,4 g  5%
Sal  0,75 g  0,23 g  4%
''');
    expectFacts(
      r,
      kcal: 375,
      grasas: 2,
      saturadas: 0.4,
      hidratos: 77,
      azucares: 17,
      fibra: 5.5,
      proteinas: 8,
      sal: 0.75,
    );
    expect(r.porcion, isNull); // hay columna de 100 g
  });

  test('ruido de OCR: O por 0, l por 1 y comas separadas', () {
    final r = NutritionLabelParser.parseText('''
Valor energetico 2O92 kJ/5OO kcal
Grasas 25 , 5 g
de las cuales saturadas l5,2 g
Hidratos de carbono 6O,O g
de los cuales azucares 5l,3 g
Proteinas 6,l g
Sal O,24 g
''');
    expectFacts(
      r,
      kcal: 500,
      grasas: 25.5,
      saturadas: 15.2,
      hidratos: 60,
      azucares: 51.3,
      proteinas: 6.1,
      sal: 0.24,
    );
  });

  test('solo kJ: convierte a kcal', () {
    final r = NutritionLabelParser.parseText('''
Energía 1046 kJ
Grasas 10 g
Hidratos de carbono 30 g
Proteínas 5 g
''');
    expectFacts(r, kcal: 250, grasas: 10, hidratos: 30, proteinas: 5);
  });

  test('kJ/kcal sin unidades en la fila', () {
    final r = NutritionLabelParser.parseText('''
Valor energético (kJ/kcal) 1046/250
Grasas (g) 10
Hidratos de carbono (g) 30
Proteínas (g) 5
''');
    expectFacts(r, kcal: 250, grasas: 10, hidratos: 30, proteinas: 5);
    // Sin unidad junto al número: se marcan para revisar.
    expect(r.dudosos, contains(Nutrient.grasas));
  });

  test('menor que y trazas cuentan como 0', () {
    final r = NutritionLabelParser.parseText('''
Valor energético 15 kJ / 4 kcal
Grasas <0,5 g
de las cuales saturadas <0,1 g
Hidratos de carbono 0,9 g
de los cuales azúcares 0,9 g
Proteínas <0,5 g
Sal trazas
''');
    expectFacts(
      r,
      kcal: 4,
      grasas: 0,
      saturadas: 0,
      hidratos: 0.9,
      proteinas: 0,
      sal: 0,
    );
  });

  test('etiqueta multilingüe (ES/PT/FR/EN): toma la primera de cada', () {
    final r = NutritionLabelParser.parseText('''
Valor energético/Energia/Énergie/Energy 1640 kJ/392 kcal
Grasas/Lípidos/Matières grasses/Fat 15 g
de las cuales saturadas/dos quais saturados/dont acides gras saturés/of which saturates 9,0 g
Hidratos de carbono/Glúcidos/Carbohydrate 56 g
de los cuales azúcares/dos quais açúcares/dont sucres/of which sugars 31 g
Proteínas/Protéines/Protein 6,5 g
Sal/Sel/Salt 0,40 g
''');
    expectFacts(
      r,
      kcal: 392,
      grasas: 15,
      saturadas: 9,
      hidratos: 56,
      azucares: 31,
      proteinas: 6.5,
      sal: 0.4,
    );
  });

  test('etiqueta alemana típica: Brennwert, Eiweiß y Nettofüllmenge', () {
    final r = NutritionLabelParser.parseText('''
Nettofüllmenge: 500 g
Nährwerte pro 100 g
Brennwert 1046 kJ / 250 kcal
Fett 9,0 g
davon gesättigte Fettsäuren 3,2 g
einfach ungesättigte Fettsäuren 4,1 g
Kohlenhydrate 30 g
davon Zucker 12 g
Ballaststoffe 2,1 g
Eiweiß 8,5 g
Salz 0,9 g
''');
    expectFacts(
      r,
      kcal: 250,
      grasas: 9,
      saturadas: 3.2,
      hidratos: 30,
      azucares: 12,
      fibra: 2.1,
      proteinas: 8.5,
      sal: 0.9,
    );
    expect(r.nutricion.estaCompleta, isTrue);
    expect(r.contenido, 500);
    expect(r.dudosos, isEmpty);
  });

  test('Eiweiß también con ss o con la ß leída como B', () {
    for (final palabra in ['Eiweiß', 'EIWEISS', 'Eiweiss', 'EiweiB']) {
      final r = NutritionLabelParser.parseText('$palabra 8,5 g');
      expect(r.nutricion.proteinas, 8.5, reason: palabra);
    }
  });

  test('alemán: Brennwert en dos filas y sin unidades', () {
    expectFacts(
      NutritionLabelParser.parseText('Brennwert 2255 kJ\n539 kcal\nFett 30 g'),
      kcal: 539,
    );
    expectFacts(
      NutritionLabelParser.parseText('Brennwert 1046 / 250\nFett 9 g'),
      kcal: 250,
    );
  });

  test('alemán: "weniger als" y "Spuren" cuentan como 0', () {
    final r = NutritionLabelParser.parseText('''
Energie 15 kJ / 4 kcal
Fett weniger als 0,5 g
davon gesättigte Fettsäuren Spuren
Kohlenhydrate 0,9 g
Eiweiß < 0,5 g
Salz Spuren
''');
    expectFacts(r, kcal: 4, grasas: 0, saturadas: 0, hidratos: 0.9);
    expectFacts(r, proteinas: 0, sal: 0);
  });

  test('alemán: Natrium en mg → sal', () {
    final r = NutritionLabelParser.parseText('''
Energie 120 kcal
Fett 3 g
Kohlenhydrate 20 g
Eiweiß 2 g
Natrium 400 mg
''');
    expectFacts(r, sal: 1.0);
  });

  test('alemán: por ración (Portion)', () {
    final r = NutritionLabelParser.parseText('''
Nährwerte pro Portion (25 g)
Energie 100 kcal
Fett 5 g
Kohlenhydrate 12 g
Eiweiß 2 g
''');
    expectFacts(r, kcal: 400, grasas: 20, hidratos: 48, proteinas: 8);
    expect(r.porcion, 25);
  });

  test('solo por ración: convierte a 100 g', () {
    final r = NutritionLabelParser.parseText('''
Información nutricional por ración (25 g)
Energía 100 kcal
Grasas 5 g
Hidratos de carbono 12 g
Proteínas 2 g
''');
    expectFacts(r, kcal: 400, grasas: 20, hidratos: 48, proteinas: 8);
    expect(r.porcion, 25);
  });

  test('sodio en mg → sal', () {
    final r = NutritionLabelParser.parseText('''
Energía 120 kcal
Grasas 3 g
Hidratos de carbono 20 g
Proteínas 2 g
Sodio 400 mg
''');
    expectFacts(r, sal: 1.0);
  });

  test('energía partida en dos filas (kJ y kcal)', () {
    final r = NutritionLabelParser.parseText('''
Valor energético 2255 kJ
539 kcal
Grasas 30,9 g
Hidratos de carbono 57,5 g
Proteínas 6,3 g
''');
    expectFacts(r, kcal: 539, grasas: 30.9, hidratos: 57.5, proteinas: 6.3);
    expect(r.dudosos, isNot(contains(Nutrient.kcal)));
  });

  test('"sal" no se confunde con otras palabras', () {
    final r = NutritionLabelParser.parseText('''
Salsa de tomate - Valores por 100 g
Energía 80 kcal
Grasas 3 g
Hidratos de carbono 11 g
Proteínas 1,6 g
Sal 1,2 g
''');
    expectFacts(r, sal: 1.2);
  });

  test('incoherencias se marcan como dudosas', () {
    final r = NutritionLabelParser.parseText('''
Energía 900 kcal
Grasas 2 g
de las cuales saturadas 5 g
Hidratos de carbono 10 g
Proteínas 3 g
''');
    expect(r.dudosos, containsAll([Nutrient.grasas, Nutrient.grasasSaturadas]));
    expect(r.dudosos, contains(Nutrient.kcal));
    expect(r.avisos, isNotEmpty);
  });

  test('agrupa en filas las columnas que el OCR devuelve por separado', () {
    // Columna de etiquetas a la izquierda y de valores a la derecha.
    final lines = [
      const RecognizedLine(
        'Valor energético',
        left: 10,
        top: 100,
        right: 200,
        bottom: 120,
      ),
      const RecognizedLine(
        'Grasas',
        left: 10,
        top: 130,
        right: 80,
        bottom: 150,
      ),
      const RecognizedLine(
        'Hidratos de carbono',
        left: 10,
        top: 160,
        right: 220,
        bottom: 180,
      ),
      const RecognizedLine(
        'Proteínas',
        left: 10,
        top: 190,
        right: 120,
        bottom: 210,
      ),
      const RecognizedLine(
        '1046 kJ / 250 kcal',
        left: 300,
        top: 102,
        right: 480,
        bottom: 121,
      ),
      const RecognizedLine(
        '9,8 g',
        left: 300,
        top: 131,
        right: 360,
        bottom: 151,
      ),
      const RecognizedLine(
        '32 g',
        left: 300,
        top: 161,
        right: 350,
        bottom: 181,
      ),
      const RecognizedLine(
        '7,4 g',
        left: 300,
        top: 189,
        right: 360,
        bottom: 209,
      ),
    ];
    final r = NutritionLabelParser.parse(lines);
    expectFacts(r, kcal: 250, grasas: 9.8, hidratos: 32, proteinas: 7.4);
    expect(r.filas.first, 'Valor energético 1046 kJ / 250 kcal');
  });

  test('peso neto en g y en kg', () {
    expect(
      NutritionLabelParser.parseText('Peso neto: 500 g\nGrasas 1 g').contenido,
      500,
    );
    expect(
      NutritionLabelParser.parseText('Peso neto 1,5 kg\nGrasas 1 g').contenido,
      1500,
    );
    expect(NutritionLabelParser.parseText('Grasas 1 g').contenido, isNull);
  });

  test('contenido neto en alemán', () {
    double? contenido(String t) =>
        NutritionLabelParser.parseText('$t\nFett 1 g').contenido;
    expect(contenido('Nettofüllmenge: 500 g'), 500);
    expect(contenido('Füllmenge 750 ml'), 750);
    expect(contenido('Nettogewicht 1,5 kg'), 1500);
    expect(contenido('Nettoinhalt: 33 cl'), 330);
    expect(contenido('Inhalt: 1 l'), 1000);
    // "Inhaltsstoffe" (ingredientes) no es el contenido neto.
    expect(contenido('Inhaltsstoffe: 2 g Vitamin C'), isNull);
  });
}
