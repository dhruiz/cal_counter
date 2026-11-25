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
      final candidatos = await foods.search(
        parsed.nombre,
        limit: 20,
        soloAlimentos: true,
      );
      final food = bestFoodMatch(parsed.nombre, [
        for (final f in candidatos)
          if (f.id != receta.alimentoId) f,
      ]);
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

/// Marca de los alimentos que representan una receta ("Lentejas · Receta").
/// Así no chocan con un alimento genérico del mismo nombre.
const String kMarcaReceta = 'Receta';

/// Nombre de la porción que equivale a una ración de la receta.
const String kPorcionReceta = 'porción';

/// Receta cuyo alimento no se pudo crear o renombrar porque ya existe otro
/// alimento (que no es de ninguna receta) con ese nombre.
class RecipeFoodConflict {
  final int recetaId;
  final String nombre;

  const RecipeFoodConflict(this.recetaId, this.nombre);
}

/// Resultado de sincronizar los alimentos de las recetas.
class RecipeFoodSync {
  final int creados;
  final int actualizados;
  final List<RecipeFoodConflict> conflictos;

  const RecipeFoodSync({
    this.creados = 0,
    this.actualizados = 0,
    this.conflictos = const [],
  });
}

/// Mantiene el alimento "preparado" de cada receta al día: nombre
/// ("Nombre · Receta"), tabla por 100 g calculada de los ingredientes (con
/// el peso final, o la suma en crudo si aún no se ha pesado), la marca de
/// aproximado y la porción de una ración.
///
/// - El alimento se crea en cuanto la receta se puede contar (kcal,
///   proteínas, grasas y carbohidratos conocidos); después se actualiza
///   siempre.
/// - Nunca sobrescribe un alimento ajeno: si el nombre ya es de otro
///   alimento, la receta queda sin el suyo y se informa del conflicto. Un
///   alimento "preparado" huérfano con ese nombre (de una receta borrada o
///   de un repertorio importado) se adopta.
/// - Un vínculo antiguo a un alimento que no es "preparado" (lo dejaba el
///   antiguo «Añadir a mis alimentos» al coincidir el nombre) se suelta sin
///   tocar ese alimento.
/// - Las recetas que usan el alimento de otra se calculan después de ella;
///   un bucle (A contiene B y B contiene A) se corta sin contar ese
///   ingrediente.
///
/// Solo escribe lo que cambia, así que se puede llamar siempre que cambie
/// algo (lo hace el vigilante de la app).
class SyncRecipeFoods {
  final RecipeRepository recipes;
  final FoodRepository foods;
  final TransactionRunner tx;

  SyncRecipeFoods(this.recipes, this.foods, this.tx);

  Future<RecipeFoodSync> call() => tx(() async {
    final todas = await recipes.getAll();
    if (todas.isEmpty) return const RecipeFoodSync();
    final ids = <int>{
      for (final r in todas) ...[
        if (r.alimentoId != null) r.alimentoId!,
        for (final i in r.ingredientes)
          if (i.alimentoId != null) i.alimentoId!,
      ],
    };
    final alimentos = Map<int, Food>.of(await foods.getFoodsByIds(ids));
    final porciones = <int, List<FoodPortion>>{
      for (final e in (await foods.getPortionsFor(ids)).entries)
        e.key: [...e.value],
    };

    // Alimento propio de cada receta: el "preparado" al que apunta.
    final propio = <int, int>{};
    final duenoDe = <int, Recipe>{};
    for (final r in todas) {
      final id = r.alimentoId;
      final f = id == null ? null : alimentos[id];
      if (f == null || f.tipo != FoodType.preparado) continue;
      if (duenoDe.containsKey(id)) continue;
      propio[r.id!] = id!;
      duenoDe[id] = r;
    }

    final porId = {for (final r in todas) r.id!: r};
    Set<int> deps(Recipe r) => {
      for (final i in r.ingredientes)
        if (duenoDe[i.alimentoId] != null && duenoDe[i.alimentoId]!.id != r.id)
          duenoDe[i.alimentoId]!.id!,
    };
    final cierre = <int, Set<int>>{};
    Set<int> usa(int id) => cierre.putIfAbsent(id, () {
      final out = <int>{};
      final pila = [...deps(porId[id]!)];
      while (pila.isNotEmpty) {
        final x = pila.removeLast();
        if (out.add(x)) pila.addAll(deps(porId[x]!));
      }
      return out;
    });
    Set<int> excluidos(Recipe r) => {
      if (propio[r.id] != null) propio[r.id]!,
      for (final i in r.ingredientes)
        if (duenoDe[i.alimentoId] != null &&
            duenoDe[i.alimentoId]!.id != r.id &&
            usa(duenoDe[i.alimentoId]!.id!).contains(r.id))
          i.alimentoId!,
    };

    // Primero las recetas cuyo alimento usan otras.
    final orden = <Recipe>[];
    final visto = <int>{};
    void visitar(Recipe r) {
      if (!visto.add(r.id!)) return;
      for (final d in deps(r)) {
        if (!usa(d).contains(r.id)) visitar(porId[d]!);
      }
      orden.add(r);
    }

    for (final r in todas) {
      visitar(r);
    }

    var creados = 0;
    var actualizados = 0;
    final conflictos = <RecipeFoodConflict>[];

    for (final r in orden) {
      final n = calculateRecipeNutrition(
        r,
        alimentos: alimentos,
        porciones: porciones,
        excluidos: excluidos(r),
      );
      final nutricion =
          (n.tieneDatos ? n.por100 : null) ?? NutritionFacts.vacia;
      final nombre = r.nombre.trim();
      var id = propio[r.id];
      var actual = id == null ? null : alimentos[id];

      if (actual == null) {
        if (r.alimentoId != null) await recipes.setFoodLink(r.id!, null);
        // Se crea cuando ya se puede contar en el día.
        if (!nutricion.estaCompleta) continue;
        final existente = await foods.findByNameAndBrand(nombre, kMarcaReceta);
        if (existente != null) {
          final libre =
              existente.tipo == FoodType.preparado &&
              !duenoDe.containsKey(existente.id);
          if (!libre) {
            conflictos.add(
              RecipeFoodConflict(r.id!, '$nombre · $kMarcaReceta'),
            );
            continue;
          }
          actual = existente;
          id = existente.id!;
        } else {
          try {
            id = await foods.saveFood(
              Food(
                nombre: nombre,
                marca: kMarcaReceta,
                tipo: FoodType.preparado,
                nutricion: nutricion,
                origenNutricion: NutritionSource.calculado,
                aproximado: !n.exacta,
              ),
              adivinarCategoria: false,
            );
          } on DuplicateFoodException {
            conflictos.add(
              RecipeFoodConflict(r.id!, '$nombre · $kMarcaReceta'),
            );
            continue;
          }
          creados++;
          actual = (await foods.getFood(id))!;
        }
        propio[r.id!] = id;
        duenoDe[id] = r;
      }

      var deseado = actual.copyWith(
        nombre: nombre,
        marca: kMarcaReceta,
        tipo: FoodType.preparado,
        unidad: FoodUnit.g,
        nutricion: nutricion,
        origenNutricion: NutritionSource.calculado,
        clearOrigen: nutricion.estaVacia,
        archivado: false,
        aproximado: !n.exacta,
        esAlimento: true,
      );
      if (_difiere(actual, deseado)) {
        try {
          await foods.saveFood(deseado);
        } on DuplicateFoodException {
          // El nombre nuevo es de otro alimento: se conserva el anterior.
          conflictos.add(RecipeFoodConflict(r.id!, '$nombre · $kMarcaReceta'));
          deseado = deseado.copyWith(
            nombre: actual.nombre,
            marca: actual.marca,
          );
          if (_difiere(actual, deseado)) await foods.saveFood(deseado);
        }
        actualizados++;
      }
      alimentos[id!] = deseado;
      if (await _sincronizarPorcion(id, n.pesoPorcion, porciones)) {
        actualizados++;
      }
      if (r.alimentoId != id) await recipes.setFoodLink(r.id!, id);
    }
    return RecipeFoodSync(
      creados: creados,
      actualizados: actualizados,
      conflictos: conflictos,
    );
  });

  static bool _difiere(Food a, Food b) =>
      a.nombre != b.nombre ||
      a.marca != b.marca ||
      a.tipo != b.tipo ||
      a.unidad != b.unidad ||
      a.nutricion != b.nutricion ||
      a.origenNutricion != b.origenNutricion ||
      a.archivado != b.archivado ||
      a.aproximado != b.aproximado ||
      a.esAlimento != b.esAlimento;

  /// Porción "porción" = peso de una ración. Devuelve true si cambió.
  Future<bool> _sincronizarPorcion(
    int alimentoId,
    double? pesoPorcion,
    Map<int, List<FoodPortion>> porciones,
  ) async {
    final lista = porciones.putIfAbsent(alimentoId, () => []);
    final actual = findPortion(lista, kPorcionReceta);
    if (pesoPorcion == null || pesoPorcion <= 0) {
      if (actual == null) return false;
      await foods.deletePortion(actual.id!);
      lista.remove(actual);
      return true;
    }
    final gramos = (pesoPorcion * 10).roundToDouble() / 10;
    if (actual != null && actual.gramos == gramos) return false;
    final pid = await foods.savePortion(
      FoodPortion(
        id: actual?.id,
        alimentoId: alimentoId,
        nombre: kPorcionReceta,
        gramos: gramos,
      ),
    );
    if (actual != null) lista.remove(actual);
    lista.add(
      FoodPortion(
        id: pid,
        alimentoId: alimentoId,
        nombre: kPorcionReceta,
        gramos: gramos,
      ),
    );
    return true;
  }
}

/// Guarda una receta (nombre único, sin distinguir tildes ni mayúsculas) y
/// pone al día su alimento. Devuelve el id.
class SaveRecipe {
  final RecipeRepository recipes;
  final SyncRecipeFoods sync;
  final TransactionRunner tx;

  SaveRecipe(this.recipes, this.sync, this.tx);

  Future<int> call(Recipe receta) async {
    final nombre = receta.nombre.trim();
    if (nombre.isEmpty) {
      throw const ValidationException('La receta necesita un nombre.');
    }
    final id = await tx(() async {
      final key = normalizeText(nombre);
      for (final r in await recipes.getAll()) {
        if (r.id != receta.id && normalizeText(r.nombre) == key) {
          throw ValidationException(
            'Ya tienes una receta llamada «${r.nombre}».',
          );
        }
      }
      return recipes.save(receta.copyWith(nombre: nombre));
    });
    await sync();
    return id;
  }
}

/// Peso final de la preparación, ya descontado el recipiente. [factor] es
/// la escala con la que se cocinó (×2 = el doble de todo): el peso se guarda
/// referido a la receta tal cual, así la tabla por 100 g sale bien. Con
/// [pesoNetoG] null se quita el peso. Marca la receta como preparada ese día.
class SetRecipeFinalWeight {
  final RecipeRepository recipes;
  final SyncRecipeFoods sync;

  SetRecipeFinalWeight(this.recipes, this.sync);

  Future<void> call({
    required int recetaId,
    required double? pesoNetoG,
    double factor = 1,
    DateTime? fecha,
  }) async {
    if (pesoNetoG == null) {
      await recipes.setFinalWeight(recetaId, null);
    } else {
      if (pesoNetoG <= 0 || pesoNetoG.isNaN) {
        throw const ValidationException(
          'El peso final debe ser mayor que 0 (¿descontaste bien el '
          'recipiente?).',
        );
      }
      final f = factor > 0 ? factor : 1;
      final base = ((pesoNetoG / f) * 10).roundToDouble() / 10;
      final d = fecha ?? DateTime.now();
      await recipes.setFinalWeight(
        recetaId,
        base,
        preparadaEl: DateTime(d.year, d.month, d.day),
      );
    }
    await sync();
  }
}
