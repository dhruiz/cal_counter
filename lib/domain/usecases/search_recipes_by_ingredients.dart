import '../entities/recipe.dart';
import '../entities/recipe_match.dart';
import '../services/ingredient_matcher.dart';

/// Busca, entre las recetas dadas, las que se pueden preparar (total o
/// parcialmente) con los ingredientes que el usuario tiene.
///
/// Orden: primero las completas; luego mayor % de ingredientes cubiertos,
/// más coincidencias y nombre. Solo se incluyen recetas con al menos un
/// ingrediente indicado por el usuario (los básicos asumidos no bastan).
/// Los ingredientes marcados "(opcional)" no cuentan como faltantes.
class SearchRecipesByIngredients {
  List<RecipeMatch> call(
    List<Recipe> recipes,
    List<String> terminos, {
    bool incluirBasicos = true,
    bool soloCompletas = false,
  }) {
    final availability = IngredientAvailability(
      terminos,
      incluirBasicos: incluirBasicos,
    );
    if (availability.isEmpty) return const [];

    final matches = <RecipeMatch>[];
    for (final recipe in recipes) {
      final disponibles = <String>[];
      final faltantes = <String>[];
      var porUsuario = 0;

      for (final linea in recipe.ingredientes) {
        final parsed = parseIngredientLine(linea);
        if (parsed.opcional || parsed.tokens.isEmpty) continue;
        if (availability.coveredByUser(linea)) {
          porUsuario++;
          disponibles.add(linea);
        } else if (availability.covers(linea)) {
          disponibles.add(linea);
        } else {
          faltantes.add(linea);
        }
      }

      if (porUsuario == 0) continue;
      final match = RecipeMatch(
        recipe: recipe,
        disponibles: disponibles,
        faltantes: faltantes,
      );
      if (soloCompletas && !match.completa) continue;
      matches.add(match);
    }

    matches.sort((a, b) {
      if (a.completa != b.completa) return a.completa ? -1 : 1;
      final byCoverage = b.cobertura.compareTo(a.cobertura);
      if (byCoverage != 0) return byCoverage;
      final byCount = b.disponibles.length.compareTo(a.disponibles.length);
      if (byCount != 0) return byCount;
      return normalizeText(
        a.recipe.nombre,
      ).compareTo(normalizeText(b.recipe.nombre));
    });
    return matches;
  }
}
