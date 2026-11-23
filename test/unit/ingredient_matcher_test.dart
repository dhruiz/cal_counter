import 'package:cal_counter/domain/services/ingredient_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeText / singularize', () {
    test('quita tildes, mayúsculas y signos', () {
      expect(normalizeText('  Champiñón, Limón!  '), 'champinon limon');
    });

    test('plural y singular coinciden', () {
      expect(singularize('tomates'), 'tomate');
      expect(singularize('limones'), 'limon');
      expect(singularize('nueces'), 'nuez');
      expect(singularize('huevos'), 'huevo');
      expect(singularize('frijoles'), 'frijol');
      expect(singularize('dulces'), 'dulce');
      expect(singularize('ajies'), 'aji');
      expect(singularize('sal'), 'sal');
    });
  });

  group('keyTokens', () {
    test('descarta cantidades, unidades y palabras vacías', () {
      expect(keyTokens('200 g de arroz blanco'), {'arroz', 'blanco'});
      expect(keyTokens('2 dientes de ajo'), {'ajo'});
      expect(keyTokens('Una pizca de sal'), {'sal'});
      expect(keyTokens('Sal al gusto'), {'sal'});
    });

    test('unifica sinónimos regionales', () {
      expect(keyTokens('papas'), keyTokens('patata'));
      expect(keyTokens('palta'), keyTokens('aguacate'));
      expect(keyTokens('jitomates'), keyTokens('tomate'));
    });
  });

  group('parseIngredientLine', () {
    test('cantidad con unidad y "de"', () {
      final p = parseIngredientLine('500 g de patatas');
      expect(p.cantidad, '500 g');
      expect(p.nombre, 'Patatas');
      expect(p.opcional, isFalse);
    });

    test('cantidades escritas y fraccionarias', () {
      expect(parseIngredientLine('Una pizca de sal').cantidad, 'Una pizca');
      expect(parseIngredientLine('Una pizca de sal').nombre, 'Sal');
      final p = parseIngredientLine('1 y 1/2 tazas de harina');
      expect(p.cantidad, '1 y 1/2 tazas');
      expect(p.nombre, 'Harina');
      expect(parseIngredientLine('1,5 kg de carne').cantidad, '1,5 kg');
      expect(parseIngredientLine('2-3 tomates').nombre, 'Tomates');
    });

    test('opcional y al gusto', () {
      final p = parseIngredientLine('1 cebolla (opcional)');
      expect(p.opcional, isTrue);
      expect(p.nombre, 'Cebolla');
      expect(parseIngredientLine('Sal al gusto').nombre, 'Sal');
    });

    test('cantidad al final o entre paréntesis', () {
      final a = parseIngredientLine('Harina: 200 g');
      expect(a.nombre, 'Harina');
      expect(a.cantidad, '200 g');
      final b = parseIngredientLine('Leche (250 ml)');
      expect(b.nombre, 'Leche');
      expect(b.cantidad, '250 ml');
    });

    test('sin cantidad', () {
      final p = parseIngredientLine('Aceite de oliva');
      expect(p.cantidad, isNull);
      expect(p.nombre, 'Aceite de oliva');
    });
  });

  group('IngredientAvailability', () {
    test('coincide en ambos sentidos', () {
      final a = IngredientAvailability(['pollo', 'aceite de oliva virgen']);
      expect(a.covers('2 pechugas de pollo'), isTrue);
      expect(a.covers('Aceite de oliva'), isTrue);
      expect(a.covers('3 huevos'), isFalse);
    });

    test('plurales y tildes', () {
      final a = IngredientAvailability(['Tomate', 'limon', 'champiñones']);
      expect(a.covers('4 tomates maduros'), isTrue);
      expect(a.covers('El zumo de 2 limones'), isTrue);
      expect(a.covers('200 g de champiñón'), isTrue);
    });

    test('básicos solo si se piden', () {
      expect(IngredientAvailability(['huevo']).covers('Sal'), isFalse);
      expect(
        IngredientAvailability(['huevo'], incluirBasicos: true).covers('Sal'),
        isTrue,
      );
      expect(IngredientAvailability.isBasic('Aceite de girasol'), isTrue);
      expect(IngredientAvailability.isBasic('Pimiento rojo'), isFalse);
    });
  });

  test('splitUserTerms separa por comas, punto y coma e "y"', () {
    expect(splitUserTerms('huevo, patata y cebolla; ajo, Huevo'), [
      'huevo',
      'patata',
      'cebolla',
      'ajo',
    ]);
  });
}
