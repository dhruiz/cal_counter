import 'dart:math';

import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/services/recipe_ideas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoy = DateTime(2026, 11, 24, 20);
  final lentejas = Recipe(
    id: 1,
    nombre: 'Lentejas',
    categoria: 'Plato principal',
    ultimaPreparacion: DateTime(2026, 9, 1),
  );
  final tortilla = Recipe(
    id: 2,
    nombre: 'Tortilla',
    favorita: true,
    ultimaPreparacion: DateTime(2026, 11, 23),
  );
  const flan = Recipe(id: 3, nombre: 'Flan', categoria: 'postre');
  final arroz = Recipe(
    id: 4,
    nombre: 'Arroz',
    categoria: 'Plato Principal',
    ultimaPreparacion: DateTime(2026, 11, 1),
  );
  final todas = [lentejas, tortilla, flan, arroz];

  test('órdenes', () {
    expect(sortRecipes(todas, RecipeOrder.favoritas).map((r) => r.id), [
      2,
      4,
      3,
      1,
    ]);
    // Las nunca preparadas, al final.
    expect(sortRecipes(todas, RecipeOrder.haceTiempo).map((r) => r.id), [
      1,
      4,
      2,
      3,
    ]);
    expect(sortRecipes(todas, RecipeOrder.recientes).map((r) => r.id), [
      2,
      4,
      1,
      3,
    ]);
  });

  test('categorías sin repetir y filtro sin mayúsculas', () {
    expect(recipeCategories(todas), ['Plato principal', 'postre']);
    expect(isInCategory(arroz, 'plato principal'), isTrue);
    expect(isInCategory(flan, 'Plato principal'), isFalse);
  });

  test('cuánto hace', () {
    expect(daysSincePrepared(tortilla, hoy), 1);
    expect(daysSincePrepared(flan, hoy), isNull);
    expect(preparedAgo(0), 'hoy');
    expect(preparedAgo(1), 'ayer');
    expect(preparedAgo(5), 'hace 5 días');
    expect(preparedAgo(21), 'hace 3 semanas');
    expect(preparedAgo(84), 'hace 2 meses');
  });

  test('sugerencias: pesan las favoritas y lo que hace tiempo', () {
    // Preparada ayer: casi nunca, aunque sea favorita.
    expect(ideaWeight(tortilla, hoy), lessThan(ideaWeight(flan, hoy)));
    // Hace casi 3 meses: más que una nunca preparada.
    expect(ideaWeight(lentejas, hoy), greaterThan(ideaWeight(flan, hoy)));

    final rnd = Random(7);
    final cuenta = <int, int>{};
    for (var i = 0; i < 2000; i++) {
      final r = suggestRecipe(todas, hoy: hoy, random: rnd)!;
      cuenta[r.id!] = (cuenta[r.id!] ?? 0) + 1;
    }
    expect(cuenta[1]!, greaterThan(cuenta[2]!));
    expect(cuenta[1]!, greaterThan(cuenta[3]!));

    // «Otra»: no repite las ya propuestas.
    final otra = suggestRecipe(todas, hoy: hoy, excluir: {1, 2, 4});
    expect(otra!.id, 3);
    expect(suggestRecipe(todas, hoy: hoy, excluir: {1, 2, 3, 4}), isNull);
  });
}
