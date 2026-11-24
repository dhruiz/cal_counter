import 'package:drift/drift.dart';

import '../../domain/entities/recipe.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/services/dates.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Recetas e ingredientes sobre Drift.
class RecipeRepositoryImpl implements RecipeRepository {
  final AppDatabase db;

  RecipeRepositoryImpl(this.db);

  Future<List<Recipe>> _conIngredientes(List<RecetaRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();
    final ingRows =
        await (db.select(db.ingredientesReceta)
              ..where((i) => i.recetaId.isIn(ids))
              ..orderBy([
                (i) => OrderingTerm.asc(i.recetaId),
                (i) => OrderingTerm.asc(i.orden),
                (i) => OrderingTerm.asc(i.id),
              ]))
            .get();
    final byRecipe = <int, List<RecipeIngredient>>{};
    for (final r in ingRows) {
      byRecipe.putIfAbsent(r.recetaId, () => []).add(ingredientFromRow(r));
    }
    return [for (final r in rows) recipeFromRow(r, byRecipe[r.id] ?? const [])];
  }

  Selectable<RecetaRow> _all() => db
      .customSelect(
        'SELECT * FROM recetas '
        'ORDER BY favorita DESC, nombre COLLATE NOCASE ASC, id ASC',
        readsFrom: {db.recetas, db.ingredientesReceta},
      )
      .map((r) => db.recetas.map(r.data));

  @override
  Stream<List<Recipe>> watchAll() => _all().watch().asyncMap(_conIngredientes);

  @override
  Future<List<Recipe>> getAll() async => _conIngredientes(await _all().get());

  Selectable<RecetaRow> _one(int id) => db
      .customSelect(
        'SELECT * FROM recetas WHERE id = ?',
        variables: [Variable.withInt(id)],
        readsFrom: {db.recetas, db.ingredientesReceta},
      )
      .map((r) => db.recetas.map(r.data));

  @override
  Future<Recipe?> get(int id) async {
    final row = await _one(id).getSingleOrNull();
    if (row == null) return null;
    return (await _conIngredientes([row])).first;
  }

  @override
  Stream<Recipe?> watch(int id) => _one(id).watchSingleOrNull().asyncMap(
    (row) async => row == null ? null : (await _conIngredientes([row])).first,
  );

  @override
  Future<int> save(Recipe recipe) {
    final nombre = recipe.nombre.trim();
    if (nombre.isEmpty) {
      throw const ValidationException('La receta necesita un nombre.');
    }
    return db.transaction(() async {
      final now = nowIso();
      final values = RecetasCompanion(
        nombre: Value(nombre),
        categoria: Value(emptyToNull(recipe.categoria)),
        porciones: Value((recipe.porciones ?? 0) > 0 ? recipe.porciones : null),
        tiempoMin: Value(recipe.tiempoMin),
        elaboracion: Value(recipe.elaboracion.trim()),
        notas: Value(emptyToNull(recipe.notas)),
        favorita: Value(recipe.favorita),
        pesoFinalG: Value(
          (recipe.pesoFinalG ?? 0) > 0 ? recipe.pesoFinalG : null,
        ),
        alimentoId: Value(recipe.alimentoId),
        ultimaPreparacion: Value(
          recipe.ultimaPreparacion == null
              ? null
              : dateKey(recipe.ultimaPreparacion!),
        ),
        actualizada: Value(now),
      );
      final int id;
      if (recipe.id == null) {
        id = await db
            .into(db.recetas)
            .insert(
              values.copyWith(
                uuid: Value(recipe.uuid ?? newUuid()),
                creada: Value(now),
              ),
            );
      } else {
        id = recipe.id!;
        await (db.update(
          db.recetas,
        )..where((r) => r.id.equals(id))).write(values);
        await (db.delete(
          db.ingredientesReceta,
        )..where((i) => i.recetaId.equals(id))).go();
      }
      var orden = 0;
      for (final ing in recipe.ingredientes) {
        final texto = ing.texto.trim();
        if (texto.isEmpty) continue;
        orden++;
        await db
            .into(db.ingredientesReceta)
            .insert(
              IngredientesRecetaCompanion.insert(
                recetaId: id,
                orden: orden,
                texto: texto,
                alimentoId: Value(ing.alimentoId),
                cantidad: Value(
                  ing.alimentoId != null && (ing.cantidad ?? 0) > 0
                      ? ing.cantidad
                      : null,
                ),
                unidad: Value(
                  ing.alimentoId == null ? null : emptyToNull(ing.unidad),
                ),
                opcional: Value(ing.opcional),
                nota: Value(emptyToNull(ing.nota)),
              ),
            );
      }
      return id;
    });
  }

  @override
  Future<void> delete(int id) async {
    await (db.delete(db.recetas)..where((r) => r.id.equals(id))).go();
  }

  @override
  Future<void> setFavorite(int id, bool favorita) async {
    await (db.update(db.recetas)..where((r) => r.id.equals(id))).write(
      RecetasCompanion(favorita: Value(favorita)),
    );
  }

  @override
  Stream<List<Recipe>> watchUsingFood(int alimentoId) => db
      .customSelect(
        'SELECT * FROM recetas r WHERE r.alimento_id = ? OR EXISTS('
        'SELECT 1 FROM ingredientes_receta i '
        'WHERE i.receta_id = r.id AND i.alimento_id = ?) '
        'ORDER BY r.nombre COLLATE NOCASE',
        variables: [Variable.withInt(alimentoId), Variable.withInt(alimentoId)],
        readsFrom: {db.recetas, db.ingredientesReceta},
      )
      .map((r) => db.recetas.map(r.data))
      .watch()
      .asyncMap(_conIngredientes);
}
