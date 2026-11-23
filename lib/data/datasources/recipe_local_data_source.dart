import '../../domain/entities/recipe.dart';
import '../models/recipe_model.dart';
import 'local_data_source.dart';

abstract class RecipeLocalDataSource {
  Future<List<Recipe>> getAllRecipes();
  Future<Recipe?> getRecipe(int id);
  Future<int> saveRecipe(Recipe recipe);
  Future<void> deleteRecipe(int id);
  Future<void> setFavorite(int id, bool favorita);
}

/// Tablas `recetas` + `ingredientes_receta` (DDL en module_tables.dart).
class RecipeLocalDataSourceImpl implements RecipeLocalDataSource {
  final LocalDataSource core;

  RecipeLocalDataSourceImpl(this.core);

  @override
  Future<List<Recipe>> getAllRecipes() async {
    final db = await core.database;
    final rows = await db.query(
      'recetas',
      orderBy: 'favorita DESC, nombre COLLATE NOCASE ASC',
    );
    final ingRows = await db.query(
      'ingredientes_receta',
      orderBy: 'receta_id ASC, orden ASC, id ASC',
    );
    final byRecipe = <int, List<String>>{};
    for (final r in ingRows) {
      byRecipe
          .putIfAbsent(r['receta_id'] as int, () => [])
          .add(r['texto'] as String);
    }
    return rows
        .map((m) => RecipeModel.fromMap(m, byRecipe[m['id']] ?? const []))
        .toList();
  }

  @override
  Future<Recipe?> getRecipe(int id) async {
    final db = await core.database;
    final rows = await db.query(
      'recetas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ingRows = await db.query(
      'ingredientes_receta',
      where: 'receta_id = ?',
      whereArgs: [id],
      orderBy: 'orden ASC, id ASC',
    );
    return RecipeModel.fromMap(
      rows.first,
      ingRows.map((r) => r['texto'] as String).toList(),
    );
  }

  @override
  Future<int> saveRecipe(Recipe recipe) async {
    final db = await core.database;
    final now = DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      final values = RecipeModel.toMap(recipe)..['actualizada'] = now;
      int id;
      if (recipe.id == null) {
        values['creada'] = now;
        id = await txn.insert('recetas', values);
      } else {
        id = recipe.id!;
        await txn.update('recetas', values, where: 'id = ?', whereArgs: [id]);
        await txn.delete(
          'ingredientes_receta',
          where: 'receta_id = ?',
          whereArgs: [id],
        );
      }
      final lines = recipe.ingredientes
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      final batch = txn.batch();
      for (var i = 0; i < lines.length; i++) {
        batch.insert('ingredientes_receta', {
          'receta_id': id,
          'orden': i,
          'texto': lines[i],
        });
      }
      await batch.commit(noResult: true);
      return id;
    });
  }

  @override
  Future<void> deleteRecipe(int id) async {
    final db = await core.database;
    await db.transaction((txn) async {
      await txn.delete(
        'ingredientes_receta',
        where: 'receta_id = ?',
        whereArgs: [id],
      );
      await txn.delete('recetas', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> setFavorite(int id, bool favorita) async {
    final db = await core.database;
    await db.update(
      'recetas',
      {'favorita': favorita ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
