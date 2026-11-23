import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/usecases/search_recipes_by_ingredients.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final search = SearchRecipesByIngredients();

  final tortilla = Recipe.desdeLineas(
    id: 1,
    nombre: 'Tortilla de patatas',
    lineas: [
      '4 huevos',
      '500 g de patatas',
      '1 cebolla (opcional)',
      'Sal',
      'Aceite de oliva',
    ],
  );
  final ensalada = Recipe.desdeLineas(
    id: 2,
    nombre: 'Ensalada',
    lineas: ['2 tomates', '1 pepino', '1 cebolla', 'Sal'],
  );
  final flan = Recipe.desdeLineas(
    id: 3,
    nombre: 'Flan',
    lineas: ['4 huevos', '500 ml de leche', '150 g de azúcar'],
  );
  final all = [ensalada, flan, tortilla];

  test('sin términos no devuelve nada', () {
    expect(search(all, []), isEmpty);
    expect(search(all, ['   ']), isEmpty);
  });

  test('ordena completas primero y calcula faltantes', () {
    final res = search(all, ['huevos', 'papas']);
    expect(res.map((m) => m.recipe.id), [1, 3]);
    final t = res.first;
    expect(t.completa, isTrue); // cebolla es opcional; sal y aceite básicos
    expect(t.faltantes, isEmpty);
    final f = res[1];
    expect(f.completa, isFalse);
    expect(f.faltantes, ['500 ml de leche', '150 g de azúcar']);
    expect(f.disponibles, ['4 huevos']);
  });

  test('sin básicos, sal y aceite cuentan como faltantes', () {
    final res = search(all, ['huevo', 'patata'], incluirBasicos: false);
    final t = res.firstWhere((m) => m.recipe.id == 1);
    expect(t.faltantes, ['Sal', 'Aceite de oliva']);
  });

  test('los básicos solos no bastan para incluir una receta', () {
    final res = search(all, ['tomate']);
    expect(res.map((m) => m.recipe.id), [2]);
  });

  test('soloCompletas filtra las parciales', () {
    final res = search(all, ['huevo', 'patata'], soloCompletas: true);
    expect(res.map((m) => m.recipe.id), [1]);
  });
}
