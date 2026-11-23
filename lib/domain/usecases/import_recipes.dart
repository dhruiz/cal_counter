import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../services/ingredient_matcher.dart';

/// Guarda recetas importadas omitiendo las que ya existen con el mismo nombre
/// (sin distinguir mayúsculas/tildes) o vienen repetidas en el lote.
/// Devuelve cuántas se guardaron.
class ImportRecipes {
  final RecipeRepository repository;

  ImportRecipes(this.repository);

  Future<int> call(List<Recipe> recipes) async {
    final existing = await repository.getAllRecipes();
    final names = existing.map((r) => normalizeText(r.nombre)).toSet();
    var saved = 0;
    for (final recipe in recipes) {
      final key = normalizeText(recipe.nombre);
      if (key.isEmpty || names.contains(key)) continue;
      await repository.saveRecipe(
        Recipe(
          nombre: recipe.nombre.trim(),
          categoria: recipe.categoria,
          porciones: recipe.porciones,
          tiempoMin: recipe.tiempoMin,
          ingredientes: recipe.ingredientes,
          elaboracion: recipe.elaboracion,
          notas: recipe.notas,
          favorita: recipe.favorita,
        ),
      );
      names.add(key);
      saved++;
    }
    return saved;
  }
}
