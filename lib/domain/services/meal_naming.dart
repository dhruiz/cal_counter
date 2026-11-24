/// Nombre automático de las comidas nuevas (`Comida_N`).
library;

import '../entities/meal.dart';

final RegExp _autoName = RegExp(r'^Comida_(\d+)$');

/// Siguiente `Comida_N` libre para el día: el mayor N existente + 1.
///
/// Antes se usaba `comidas.length + 1`: tras borrar o renombrar una comida
/// ese nombre podía existir ya, y `CreateMealIfNotExists` devolvía la comida
/// existente, así que "Nueva comida" añadía el alimento a otra en silencio.
String nextMealName(List<Meal> meals) {
  var max = 0;
  for (final m in meals) {
    final match = _autoName.firstMatch(m.name.trim());
    final n = match == null ? null : int.tryParse(match.group(1)!);
    if (n != null && n > max) max = n;
  }
  // Con nombres no automáticos, el número no debe quedar por debajo de la
  // cantidad de comidas (Comida_1 junto a "Desayuno" y "Cena" → Comida_3).
  final next = max + 1 > meals.length + 1 ? max + 1 : meals.length + 1;
  final names = meals.map((m) => m.name.trim()).toSet();
  var candidate = next;
  while (names.contains('Comida_$candidate')) {
    candidate++;
  }
  return 'Comida_$candidate';
}
