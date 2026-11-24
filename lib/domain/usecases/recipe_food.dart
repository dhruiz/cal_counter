import '../entities/food.dart';
import '../entities/nutrition_facts.dart';
import '../entities/recipe.dart';
import '../errors/domain_errors.dart';
import '../repositories/food_repository.dart';
import '../repositories/recipe_repository.dart';
import '../repositories/transaction_runner.dart';
import '../services/ingredient_matcher.dart';
import '../services/nutrition_calculator.dart';
import '../services/quantity_parser.dart';

/// Propuesta de vínculo para una línea de ingrediente.
class IngredientLinkSuggestion {
  final int indice;
  final Food alimento;
  final double? cantidad;
  final String? unidad;

  const IngredientLinkSuggestion({
    required this.indice,
    required this.alimento,
    this.cantidad,
    this.unidad,
  });
}

/// Propone, para cada ingrediente sin vincular, el alimento del repertorio
/// que mejor encaja con su nombre ("200 g de arroz" → Arroz blanco, 200 g),
/// con la misma normalización que la búsqueda de recetas (tildes, plurales,
/// sinónimos). El usuario confirma antes de guardar.
class SuggestIngredientLinks {
  final FoodRepository foods;

  SuggestIngredientLinks(this.foods);

  Future<List<IngredientLinkSuggestion>> call(Recipe receta) async {
    final out = <IngredientLinkSuggestion>[];
    for (var i = 0; i < receta.ingredientes.length; i++) {
      final ing = receta.ingredientes[i];
      if (ing.vinculado) continue;
      final parsed = parseIngredientLine(ing.texto);
      final tokens = parsed.tokens;
      if (tokens.isEmpty) continue;
      final candidatos = await foods.search(parsed.nombre, limit: 20);
      final food = bestFoodMatch(parsed.nombre, candidatos);
      if (food == null) continue;
      final q = parseQuantity(ing.texto);
      out.add(
        IngredientLinkSuggestion(
          indice: i,
          alimento: food,
          cantidad: q?.cantidad,
          unidad: q == null ? null : _unidadPara(q, food),
        ),
      );
    }
    return out;
  }

  /// 'g'/'ml' se adaptan a la unidad del alimento; el resto es una porción.
  static String _unidadPara(ParsedQuantity q, Food food) {
    if (q.esMasa || q.esVolumen) return food.unidad.clave;
    return q.unidad;
  }
}

/// Mejor candidato para un nombre de ingrediente: nombre normalizado igual;
/// si no, el que comparte todos los tokens clave (el más corto, que suele ser
/// el genérico); a igualdad, el que tiene la tabla completa y más uso.
Food? bestFoodMatch(String nombre, List<Food> candidatos) {
  final key = normalizeText(nombre);
  final tokens = keyTokens(nombre);
  int score(Food f) {
    final fk = normalizeText(f.nombre);
    if (fk == key) return 1000;
    final ft = keyTokens(f.nombre);
    if (!tokensMatch(ft, tokens)) return -1;
    // Menos palabras sobrantes = mejor.
    final extra = (ft.length - tokens.length).abs();
    return 500 - extra * 10;
  }

  Food? best;
  var bestScore = -1;
  for (final f in candidatos) {
    var s = score(f);
    if (s < 0) continue;
    if (!f.pendiente) s += 5;
    if (f.usoCount > 0) s += 1;
    if (s > bestScore) {
      best = f;
      bestScore = s;
    }
  }
  return best;
}

/// Crea o actualiza el alimento "preparado" que representa una receta en el
/// repertorio, con su nutrición por 100 g calculada de los ingredientes y la
/// porción de la receta como equivalencia casera. Vincula la receta a él.
class SaveRecipeAsFood {
  final FoodRepository foods;
  final RecipeRepository recipes;
  final TransactionRunner tx;

  SaveRecipeAsFood(this.foods, this.recipes, this.tx);

  Future<int> call(Recipe receta, RecipeNutrition nutricion) {
    final por100 = nutricion.por100;
    if (por100 == null || !nutricion.tieneDatos) {
      throw const ValidationException(
        'Vincula los ingredientes con su cantidad para calcular la receta.',
      );
    }
    return tx(() async {
      final existente = receta.alimentoId == null
          ? null
          : await foods.getFood(receta.alimentoId!);
      final base =
          existente ??
          Food(nombre: receta.nombre.trim(), tipo: FoodType.preparado);
      final food = base.copyWith(
        nombre: existente?.nombre ?? receta.nombre.trim(),
        nutricion: por100,
        origenNutricion: NutritionSource.calculado,
        archivado: false,
      );
      int id;
      try {
        id = await foods.saveFood(food);
      } on DuplicateFoodException catch (e) {
        // Ya hay un alimento con ese nombre: se actualiza ese.
        id = await foods.saveFood(
          e.existente.copyWith(
            nutricion: por100,
            origenNutricion: NutritionSource.calculado,
            archivado: false,
          ),
        );
      }
      final pesoPorcion = nutricion.pesoPorcion;
      if (pesoPorcion != null && pesoPorcion > 0) {
        final porciones = (await foods.getPortionsFor([id]))[id] ?? const [];
        final actual = findPortion(porciones, 'porción');
        await foods.savePortion(
          FoodPortion(
            id: actual?.id,
            alimentoId: id,
            nombre: 'porción',
            gramos: (pesoPorcion * 10).roundToDouble() / 10,
          ),
        );
      }
      if (receta.alimentoId != id) {
        await recipes.save(receta.copyWith(alimentoId: id));
      }
      return id;
    });
  }
}
