import 'package:cal_counter/domain/entities/meal.dart';
import 'package:cal_counter/domain/services/meal_naming.dart';
import 'package:flutter_test/flutter_test.dart';

List<Meal> meals(List<String> names) => [
  for (var i = 0; i < names.length; i++)
    Meal(id: i + 1, name: names[i], date: DateTime(2024, 1, 1)),
];

void main() {
  test('sin comidas → Comida_1', () {
    expect(nextMealName(const []), 'Comida_1');
  });

  test('secuencia normal → siguiente número (igual que antes)', () {
    expect(nextMealName(meals(['Comida_1', 'Comida_2'])), 'Comida_3');
  });

  test('tras borrar una comida no reutiliza un nombre existente', () {
    // Antes: 2 comidas → "Comida_3", que ya existía, y el alimento se añadía
    // a esa comida en vez de crear una nueva.
    expect(nextMealName(meals(['Comida_1', 'Comida_3'])), 'Comida_4');
  });

  test('con nombres personalizados conserva la numeración por cantidad', () {
    expect(nextMealName(meals(['Desayuno', 'Cena'])), 'Comida_3');
    expect(nextMealName(meals(['Desayuno', 'Comida_3'])), 'Comida_4');
  });

  test('ignora nombres parecidos que no son automáticos', () {
    expect(nextMealName(meals(['Comida_extra', 'comida_9'])), 'Comida_3');
  });
}
