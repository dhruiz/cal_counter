import '../entities/food.dart';
import '../entities/nutrition_facts.dart';
import '../entities/recipe.dart';
import 'ingredient_matcher.dart';
import 'quantity_parser.dart';

/// Motivo por el que un ingrediente impide calcular la nutrición exacta.
enum IngredientIssueKind {
  /// La línea no está vinculada a ningún alimento del repertorio.
  sinVincular('Sin vincular a un alimento'),

  /// El alimento vinculado ya no existe (se borró).
  alimentoNoEncontrado('El alimento vinculado ya no existe'),

  /// Vinculado pero sin cantidad.
  sinCantidad('Falta la cantidad'),

  /// La unidad es una porción ("diente") sin equivalencia en gramos.
  unidadSinEquivalencia('Falta el peso de la porción'),

  /// El alimento no tiene la tabla nutricional completa.
  alimentoPendiente('Sin tabla nutricional');

  final String descripcion;

  const IngredientIssueKind(this.descripcion);
}

/// Problema de un ingrediente concreto, con lo necesario para resolverlo.
class IngredientIssue {
  final int indice;
  final RecipeIngredient ingrediente;
  final IngredientIssueKind tipo;
  final Food? alimento;

  const IngredientIssue({
    required this.indice,
    required this.ingrediente,
    required this.tipo,
    this.alimento,
  });

  String get descripcion => switch (tipo) {
    IngredientIssueKind.unidadSinEquivalencia =>
      'Falta el peso de 1 "${ingrediente.unidad}"',
    _ => tipo.descripcion,
  };
}

/// Resultado del cálculo nutricional de una receta.
class RecipeNutrition {
  /// Suma de lo que se pudo calcular. Si hay [issues] es un mínimo.
  final NutritionFacts total;

  /// Gramos de los ingredientes calculados.
  final double pesoIngredientes;

  /// Peso final indicado en la receta, o [pesoIngredientes].
  final double peso;
  final int? porciones;
  final List<IngredientIssue> issues;

  const RecipeNutrition({
    required this.total,
    required this.pesoIngredientes,
    required this.peso,
    required this.porciones,
    required this.issues,
  });

  /// Todos los ingredientes necesarios están vinculados, cuantificados y con
  /// su tabla completa.
  bool get completa => issues.isEmpty && pesoIngredientes > 0;

  /// Algo se pudo calcular.
  bool get tieneDatos => pesoIngredientes > 0;

  /// Por 100 g de preparación.
  NutritionFacts? get por100 =>
      peso > 0 ? total.escalada(100 / peso).redondeada() : null;

  /// Por porción, si se conocen las porciones.
  NutritionFacts? get porPorcion {
    final p = porciones;
    if (p == null || p <= 0) return null;
    return total.escalada(1 / p).redondeada();
  }

  /// Gramos de una porción.
  double? get pesoPorcion {
    final p = porciones;
    if (p == null || p <= 0 || peso <= 0) return null;
    return peso / p;
  }
}

/// Ingredientes que pueden ir "al gusto" sin cantidad porque no aportan
/// calorías apreciables.
const Set<String> _sinCalorias = {'sal', 'pimienta', 'agua'};

/// Calcula la nutrición de una receta con los alimentos vinculados.
///
/// [alimentos] contiene los alimentos de los ingredientes (por id) y
/// [porciones] sus equivalencias caseras (por id de alimento).
RecipeNutrition calculateRecipeNutrition(
  Recipe receta, {
  required Map<int, Food> alimentos,
  Map<int, List<FoodPortion>> porciones = const {},
}) {
  var total = NutritionFacts.vacia;
  var peso = 0.0;
  final issues = <IngredientIssue>[];

  for (var i = 0; i < receta.ingredientes.length; i++) {
    final ing = receta.ingredientes[i];
    if (ing.opcional || parseIngredientLine(ing.texto).opcional) continue;

    final id = ing.alimentoId;
    if (id == null) {
      if (_esDespreciable(ing)) continue;
      issues.add(
        IngredientIssue(
          indice: i,
          ingrediente: ing,
          tipo: IngredientIssueKind.sinVincular,
        ),
      );
      continue;
    }
    final food = alimentos[id];
    if (food == null) {
      issues.add(
        IngredientIssue(
          indice: i,
          ingrediente: ing,
          tipo: IngredientIssueKind.alimentoNoEncontrado,
        ),
      );
      continue;
    }
    final gramos = gramsForIngredient(ing, food, porciones[id] ?? const []);
    if (gramos == null) {
      final sinCantidad = ing.cantidad == null || ing.cantidad! <= 0;
      if (sinCantidad && _alimentoSinCalorias(food)) continue;
      issues.add(
        IngredientIssue(
          indice: i,
          ingrediente: ing,
          tipo: sinCantidad
              ? IngredientIssueKind.sinCantidad
              : IngredientIssueKind.unidadSinEquivalencia,
          alimento: food,
        ),
      );
      continue;
    }
    if (food.pendiente) {
      issues.add(
        IngredientIssue(
          indice: i,
          ingrediente: ing,
          tipo: IngredientIssueKind.alimentoPendiente,
          alimento: food,
        ),
      );
    }
    peso += gramos;
    total = total.sumar(
      food.nutricion.escalada(gramos / 100),
      ignorarDesconocidos: true,
    );
  }

  final pesoFinal = receta.pesoFinalG;
  return RecipeNutrition(
    total: total,
    pesoIngredientes: peso,
    peso: (pesoFinal != null && pesoFinal > 0) ? pesoFinal : peso,
    porciones: receta.porciones,
    issues: issues,
  );
}

/// Gramos (o ml) que aporta un ingrediente vinculado, o null si no se puede
/// saber (sin cantidad o porción sin equivalencia).
double? gramsForIngredient(
  RecipeIngredient ing,
  Food food,
  List<FoodPortion> porciones,
) {
  final cantidad = ing.cantidad;
  if (cantidad == null || cantidad <= 0) return null;
  final unidad = ing.unidad;
  if (unidad == null || unidad == 'g' || unidad == 'ml') return cantidad;
  final p = findPortion(porciones, unidad);
  return p == null ? null : cantidad * p.gramos;
}

/// Porción cuyo nombre equivale a [unidad] ("dientes" ↔ "diente").
FoodPortion? findPortion(List<FoodPortion> porciones, String unidad) {
  final key = canonicalPortionName(unidad);
  for (final p in porciones) {
    if (canonicalPortionName(p.nombre) == key) return p;
  }
  return null;
}

bool _esDespreciable(RecipeIngredient ing) {
  if (parseQuantity(ing.texto) != null) return false;
  final tokens = parseIngredientLine(ing.texto).tokens;
  return tokens.isNotEmpty && tokens.every(_sinCalorias.contains);
}

bool _alimentoSinCalorias(Food food) {
  final k = food.nutricion.kcal;
  if (k != null) return k < 1;
  return keyTokens(food.nombre).every(_sinCalorias.contains);
}
