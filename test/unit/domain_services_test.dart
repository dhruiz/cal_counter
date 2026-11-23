import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/services/barcode.dart';
import 'package:cal_counter/domain/services/money.dart';
import 'package:cal_counter/domain/services/nutrition_calculator.dart';
import 'package:cal_counter/domain/services/quantity_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('códigos de barras', () {
    test('normaliza: solo dígitos y UPC-A → EAN-13', () {
      expect(normalizeBarcode(' 8410 0000 00001 '), '8410000000001');
      expect(normalizeBarcode('012345678905'), '0012345678905');
      expect(normalizeBarcode('abc'), isNull);
      expect(normalizeBarcode(null), isNull);
    });

    test('dígito de control GS1', () {
      expect(isValidGtin('4006381333931'), isTrue); // EAN-13
      expect(isValidGtin('4006381333932'), isFalse);
      expect(isValidGtin('96385074'), isTrue); // EAN-8
      expect(isValidGtin('036000291452'), isTrue); // UPC-A
      expect(isValidGtin('123'), isFalse);
    });

    test('parece código / peso variable', () {
      expect(looksLikeBarcode('8410000000001'), isTrue);
      expect(looksLikeBarcode('7up'), isFalse);
      expect(looksLikeBarcode('1234567'), isFalse);
      expect(isVariableMeasure('2123450012347'), isTrue);
      expect(isVariableMeasure('8410000000001'), isFalse);
    });
  });

  group('dinero', () {
    test('parsePrecioCent', () {
      expect(parsePrecioCent('2,35'), 235);
      expect(parsePrecioCent('0.1'), 10);
      expect(parsePrecioCent('1.234,50'), 123450);
      expect(parsePrecioCent('0'), isNull);
      expect(parsePrecioCent('abc'), isNull);
    });
  });

  group('cantidades de ingredientes', () {
    void q(String linea, double cantidad, String unidad) {
      final p = parseQuantity(linea);
      expect(p, isNotNull, reason: linea);
      expect(p!.cantidad, closeTo(cantidad, 1e-9), reason: linea);
      expect(p.unidad, unidad, reason: linea);
    }

    test('masa y volumen con conversión', () {
      q('200 g de arroz', 200, 'g');
      q('200g de arroz', 200, 'g');
      q('1/2 kg de patatas', 500, 'g');
      q('1,5 kg de harina', 1500, 'g');
      q('250 ml de leche', 250, 'ml');
      q('1 L de caldo', 1000, 'ml');
      q('Harina 300 g', 300, 'g');
    });

    test('porciones caseras y unidades', () {
      q('2 dientes de ajo', 2, 'diente');
      q('1 y 1/2 tazas de azúcar', 1.5, 'taza');
      q('3 huevos', 3, 'unidad');
      q('2 cdas de aceite', 2, 'cucharada');
      q('Una pizca de comino', 1, 'pizca');
      q('½ cebolla', 0.5, 'unidad');
      q('2-3 tomates', 2, 'unidad');
    });

    test('sin cantidad', () {
      expect(parseQuantity('Sal al gusto'), isNull);
      expect(parseQuantity('Perejil'), isNull);
    });

    test('nombre canónico de porción', () {
      expect(canonicalPortionName('Dientes'), 'diente');
      expect(canonicalPortionName('cdas'), 'cucharada');
    });
  });

  group('NutritionFacts', () {
    test('completa, faltantes y escalado conservando desconocidos', () {
      const n = NutritionFacts(kcal: 100, proteinas: 10);
      expect(n.estaCompleta, isFalse);
      expect(n.faltantes, [Nutrient.grasas, Nutrient.carbohidratos]);
      final e = n.escalada(2);
      expect(e.kcal, 200);
      expect(e.grasas, isNull);
    });

    test('completadaCon rellena huecos sin pisar lo conocido', () {
      const a = NutritionFacts(kcal: 100, grasas: 1);
      const b = NutritionFacts(kcal: 999, proteinas: 5, grasas: 9);
      final c = a.completadaCon(b);
      expect(c.kcal, 100);
      expect(c.grasas, 1);
      expect(c.proteinas, 5);
    });

    test('avisos de coherencia', () {
      const ok = NutritionFacts.basica(
        kcal: 46,
        proteinas: 3.1,
        grasas: 1.6,
        carbohidratos: 4.7,
      );
      expect(ok.avisos, isEmpty);
      const mal = NutritionFacts(
        kcal: 500,
        proteinas: 3,
        grasas: 1,
        grasasSaturadas: 2,
        carbohidratos: 5,
      );
      expect(mal.avisos.length, 2);
    });
  });

  group('nutrición de recetas', () {
    const arroz = Food(
      id: 1,
      nombre: 'Arroz',
      nutricion: NutritionFacts.basica(
        kcal: 350,
        proteinas: 7,
        grasas: 1,
        carbohidratos: 78,
      ),
    );
    const ajo = Food(
      id: 2,
      nombre: 'Ajo',
      nutricion: NutritionFacts.basica(
        kcal: 150,
        proteinas: 6,
        grasas: 0.5,
        carbohidratos: 33,
      ),
    );
    const tomate = Food(id: 3, nombre: 'Tomate triturado'); // pendiente
    const alimentos = {1: arroz, 2: ajo, 3: tomate};

    test('completa: suma, por porción y por 100 g', () {
      const r = Recipe(
        nombre: 'Arroz con ajo',
        porciones: 2,
        ingredientes: [
          RecipeIngredient(
            texto: '200 g de arroz',
            alimentoId: 1,
            cantidad: 200,
            unidad: 'g',
          ),
          RecipeIngredient(
            texto: '2 dientes de ajo',
            alimentoId: 2,
            cantidad: 2,
            unidad: 'dientes',
          ),
          RecipeIngredient(texto: 'Sal al gusto'),
          RecipeIngredient(texto: 'Perejil (opcional)'),
        ],
      );
      final n = calculateRecipeNutrition(
        r,
        alimentos: alimentos,
        porciones: {
          2: [const FoodPortion(alimentoId: 2, nombre: 'diente', gramos: 5)],
        },
      );
      expect(n.completa, isTrue);
      expect(n.pesoIngredientes, 210);
      expect(n.total.kcal, closeTo(700 + 15, 1e-9));
      expect(n.porPorcion!.kcal, closeTo(357.5, 0.01));
      expect(n.pesoPorcion, 105);
      expect(n.por100!.kcal, closeTo(715 / 210 * 100, 0.01));
    });

    test('lista lo que falta con su motivo', () {
      const r = Recipe(
        nombre: 'Salsa',
        ingredientes: [
          RecipeIngredient(
            texto: '400 g de tomate triturado',
            alimentoId: 3,
            cantidad: 400,
            unidad: 'g',
          ),
          RecipeIngredient(
            texto: '2 dientes de ajo',
            alimentoId: 2,
            cantidad: 2,
            unidad: 'diente',
          ),
          RecipeIngredient(texto: 'Una pizca de comino'),
          RecipeIngredient(texto: 'Arroz', alimentoId: 1),
        ],
      );
      final n = calculateRecipeNutrition(r, alimentos: alimentos);
      expect(n.completa, isFalse);
      expect(n.issues.map((i) => i.tipo), [
        IngredientIssueKind.alimentoPendiente,
        IngredientIssueKind.unidadSinEquivalencia,
        IngredientIssueKind.sinVincular,
        IngredientIssueKind.sinCantidad,
      ]);
      expect(n.issues[1].descripcion, 'Falta el peso de 1 "diente"');
    });

    test('peso final cocinado cambia el valor por 100 g', () {
      const r = Recipe(
        nombre: 'Arroz cocido',
        pesoFinalG: 600,
        ingredientes: [
          RecipeIngredient(
            texto: '200 g arroz',
            alimentoId: 1,
            cantidad: 200,
            unidad: 'g',
          ),
        ],
      );
      final n = calculateRecipeNutrition(r, alimentos: alimentos);
      expect(n.por100!.kcal, closeTo(700 / 6, 0.01));
    });
  });
}
