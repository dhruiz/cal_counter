import 'package:drift/drift.dart';

import '../../domain/entities/food.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/services/barcode.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Condición SQL (sobre el alias `a`) de un alimento pendiente de completar.
const String kPendienteSql =
    '(a.kcal IS NULL OR a.proteinas IS NULL OR a.grasas IS NULL '
    'OR a.carbohidratos IS NULL)';

/// Repertorio de alimentos sobre Drift.
class FoodRepositoryImpl implements FoodRepository {
  final AppDatabase db;

  FoodRepositoryImpl(this.db);

  // Búsqueda ------------------------------------------------------------------

  static String _filterSql(FoodFilter f) => switch (f) {
    FoodFilter.todos => 'a.archivado = 0',
    FoodFilter.pendientes => 'a.archivado = 0 AND $kPendienteSql',
    FoodFilter.envasados => "a.archivado = 0 AND a.tipo = 'envasado'",
    FoodFilter.genericos => "a.archivado = 0 AND a.tipo = 'generico'",
    FoodFilter.preparados => "a.archivado = 0 AND a.tipo = 'preparado'",
    FoodFilter.archivados => 'a.archivado = 1',
  };

  /// Expresión MATCH de FTS5: cada palabra por prefijo, con su singular y
  /// sus sinónimos ("papas fritas" → ("papas"* OR "papa"* OR "patata"*)
  /// AND ("fritas"* OR "frita"*)). Null si no queda ninguna palabra.
  static String? ftsQuery(String query) {
    final words = normalizeText(query).split(' ').where((w) => w.isNotEmpty);
    final parts = <String>[];
    for (final w in words) {
      final variants = searchVariants(w).where((v) => v.isNotEmpty).toList()
        ..sort();
      if (variants.isEmpty) continue;
      final ors = variants
          .map((v) => '"${v.replaceAll('"', '')}"*')
          .join(' OR ');
      parts.add(variants.length == 1 ? ors : '($ors)');
    }
    return parts.isEmpty ? null : parts.join(' AND ');
  }

  Selectable<Food> _searchQuery(String query, FoodFilter filter, int limit) {
    final where = _filterSql(filter);
    final q = query.trim();

    if (q.isEmpty) {
      return db
          .customSelect(
            'SELECT a.* FROM alimentos a WHERE $where '
            'ORDER BY a.uso_count DESC, a.nombre COLLATE NOCASE ASC LIMIT ?',
            variables: [Variable.withInt(limit)],
            readsFrom: {db.alimentos},
          )
          .map((r) => foodFromRow(db.alimentos.map(r.data)));
    }

    // Parece un código de barras: búsqueda exacta por presentación.
    final code = looksLikeBarcode(q) ? normalizeBarcode(q) : null;
    if (code != null) {
      return db
          .customSelect(
            'SELECT DISTINCT a.* FROM alimentos a '
            'JOIN presentaciones p ON p.alimento_id = a.id '
            'WHERE p.codigo_barras = ? AND $where LIMIT ?',
            variables: [Variable.withString(code), Variable.withInt(limit)],
            readsFrom: {db.alimentos, db.presentaciones},
          )
          .map((r) => foodFromRow(db.alimentos.map(r.data)));
    }

    final match = ftsQuery(q);
    if (match == null) {
      return db
          .customSelect(
            'SELECT * FROM alimentos WHERE 0',
            readsFrom: {db.alimentos},
          )
          .map((r) => foodFromRow(db.alimentos.map(r.data)));
    }
    // bm25: el nombre pesa más que la marca; a igualdad, lo más usado.
    return db
        .customSelect(
          'SELECT a.* FROM alimentos_fts '
          'JOIN alimentos a ON a.id = alimentos_fts.rowid '
          'WHERE alimentos_fts MATCH ? AND $where '
          'ORDER BY bm25(alimentos_fts, 10.0, 2.0), a.uso_count DESC, '
          'a.nombre COLLATE NOCASE LIMIT ?',
          variables: [Variable.withString(match), Variable.withInt(limit)],
          readsFrom: {db.alimentos},
        )
        .map((r) => foodFromRow(db.alimentos.map(r.data)));
  }

  @override
  Stream<List<Food>> watchSearch(
    String query, {
    FoodFilter filter = FoodFilter.todos,
    int limit = 200,
  }) => _searchQuery(query, filter, limit).watch();

  @override
  Future<List<Food>> search(
    String query, {
    FoodFilter filter = FoodFilter.todos,
    int limit = 200,
  }) => _searchQuery(query, filter, limit).get();

  // Lectura -------------------------------------------------------------------

  @override
  Future<Food?> getFood(int id) async {
    final row = await (db.select(
      db.alimentos,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    return row == null ? null : foodFromRow(row);
  }

  @override
  Stream<Food?> watchFood(int id) =>
      (db.select(db.alimentos)..where((a) => a.id.equals(id)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : foodFromRow(r));

  @override
  Future<Map<int, Food>> getFoodsByIds(Iterable<int> ids) async {
    final set = ids.toSet();
    if (set.isEmpty) return const {};
    final rows = await (db.select(
      db.alimentos,
    )..where((a) => a.id.isIn(set))).get();
    return {for (final r in rows) r.id: foodFromRow(r)};
  }

  @override
  Stream<FoodsWithPortions> watchFoodsWithPortions(Set<int> ids) {
    if (ids.isEmpty) return Stream.value(FoodsWithPortions.vacio);
    final marks = List.filled(ids.length, '?').join(', ');
    return db
        .customSelect(
          'SELECT * FROM alimentos WHERE id IN ($marks)',
          variables: [for (final id in ids) Variable.withInt(id)],
          readsFrom: {db.alimentos, db.porciones},
        )
        .watch()
        .asyncMap((rows) async {
          final foods = {
            for (final r in rows)
              r.read<int>('id'): foodFromRow(db.alimentos.map(r.data)),
          };
          return FoodsWithPortions(foods, await getPortionsFor(foods.keys));
        });
  }

  @override
  Future<List<Food>> getAllFoods({bool incluirArchivados = false}) async {
    final q = db.select(db.alimentos)
      ..orderBy([(a) => OrderingTerm.asc(a.nombre)]);
    if (!incluirArchivados) q.where((a) => a.archivado.equals(false));
    return (await q.get()).map(foodFromRow).toList();
  }

  @override
  Future<BarcodeMatch?> findByBarcode(String codigo) async {
    final code = normalizeBarcode(codigo);
    if (code == null) return null;
    final row =
        await (db.select(db.presentaciones).join([
                innerJoin(
                  db.alimentos,
                  db.alimentos.id.equalsExp(db.presentaciones.alimentoId),
                ),
              ])
              ..where(db.presentaciones.codigoBarras.equals(code))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return BarcodeMatch(
      foodFromRow(row.readTable(db.alimentos)),
      packageFromRow(row.readTable(db.presentaciones)),
    );
  }

  @override
  Future<List<Food>> findSimilar(String nombre, {String marca = ''}) async {
    final key = normalizeText(nombre);
    if (key.isEmpty) return const [];
    final marcaKey = normalizeText(marca);
    final tokens = keyTokens(nombre);
    final candidatos = await search(nombre, limit: 50);
    return candidatos.where((f) {
      final mk = normalizeText(f.marca);
      if (marcaKey.isNotEmpty && mk.isNotEmpty && mk != marcaKey) return false;
      final fk = normalizeText(f.nombre);
      if (fk == key) return true;
      final ft = keyTokens(f.nombre);
      return tokens.isNotEmpty &&
          ft.isNotEmpty &&
          tokens.length == ft.length &&
          tokens.containsAll(ft);
    }).toList();
  }

  // Escritura -----------------------------------------------------------------

  Future<Food?> _duplicado(Food food) async {
    final nombre = normalizeText(food.nombre);
    final marca = normalizeText(food.marca);
    final candidatos = await search(food.nombre, filter: FoodFilter.todos);
    final archivados = await search(food.nombre, filter: FoodFilter.archivados);
    for (final f in [...candidatos, ...archivados]) {
      if (f.id == food.id) continue;
      if (normalizeText(f.nombre) == nombre &&
          normalizeText(f.marca) == marca) {
        return f;
      }
    }
    // Coincidencia exacta sin FTS (nombres de una letra, signos...).
    final exacta =
        await (db.select(db.alimentos)..where(
              (a) =>
                  a.nombre.equals(food.nombre.trim()) &
                  a.marca.equals(food.marca.trim()),
            ))
            .getSingleOrNull();
    if (exacta != null && exacta.id != food.id) return foodFromRow(exacta);
    return null;
  }

  @override
  Future<int> saveFood(Food food) async {
    if (food.nombre.trim().isEmpty) {
      throw const ValidationException('El nombre no puede estar vacío.');
    }
    return db.transaction(() async {
      final dup = await _duplicado(food);
      if (dup != null) throw DuplicateFoodException(dup);
      final values = foodToCompanion(food);
      final now = nowIso();
      if (food.id == null) {
        return db
            .into(db.alimentos)
            .insert(
              values.copyWith(
                uuid: Value(food.uuid ?? newUuid()),
                usoCount: Value(food.usoCount),
                ultimoUso: Value(food.ultimoUso?.toIso8601String()),
                creado: Value(now),
                actualizado: Value(now),
              ),
            );
      }
      await (db.update(db.alimentos)..where((a) => a.id.equals(food.id!)))
          .write(values.copyWith(actualizado: Value(now)));
      return food.id!;
    });
  }

  Future<bool> _tieneCompras(int alimentoId) async {
    final res = await db
        .customSelect(
          'SELECT EXISTS(SELECT 1 FROM compras c JOIN presentaciones p '
          'ON p.id = c.presentacion_id WHERE p.alimento_id = ?) AS hay',
          variables: [Variable.withInt(alimentoId)],
        )
        .getSingle();
    return res.read<bool>('hay');
  }

  @override
  Future<FoodDeletion> deleteFood(int id) {
    return db.transaction(() async {
      if (await _tieneCompras(id)) {
        await setArchived(id, true);
        return FoodDeletion.archivado;
      }
      await (db.delete(db.alimentos)..where((a) => a.id.equals(id))).go();
      return FoodDeletion.borrado;
    });
  }

  @override
  Future<void> setArchived(int id, bool archivado) async {
    await (db.update(db.alimentos)..where((a) => a.id.equals(id))).write(
      AlimentosCompanion(
        archivado: Value(archivado),
        actualizado: Value(nowIso()),
      ),
    );
  }

  @override
  Future<void> incrementUsage(int id) async {
    await db.customUpdate(
      'UPDATE alimentos SET uso_count = uso_count + 1, ultimo_uso = ? '
      'WHERE id = ?',
      variables: [Variable.withString(nowIso()), Variable.withInt(id)],
      updates: {db.alimentos},
    );
  }

  @override
  Future<void> resetUsage(int id) async {
    await (db.update(db.alimentos)..where((a) => a.id.equals(id))).write(
      const AlimentosCompanion(usoCount: Value(0), ultimoUso: Value(null)),
    );
  }

  @override
  Stream<List<Food>> watchMostUsed({int limit = 20}) {
    final q = db.select(db.alimentos)
      ..where(
        (a) => a.usoCount.isBiggerThanValue(0) & a.archivado.equals(false),
      )
      ..orderBy([
        (a) => OrderingTerm.desc(a.usoCount),
        (a) => OrderingTerm.desc(a.ultimoUso),
      ])
      ..limit(limit);
    return q.watch().map((rows) => rows.map(foodFromRow).toList());
  }

  @override
  Stream<List<Food>> watchPending() {
    return db
        .customSelect(
          'SELECT a.*, '
          '(SELECT COUNT(*) FROM ingredientes_receta i '
          ' WHERE i.alimento_id = a.id) AS en_recetas, '
          '(SELECT MAX(c.fecha) FROM compras c JOIN presentaciones p '
          ' ON p.id = c.presentacion_id WHERE p.alimento_id = a.id) '
          ' AS ultima_compra '
          'FROM alimentos a WHERE a.archivado = 0 AND $kPendienteSql '
          'ORDER BY en_recetas > 0 DESC, ultima_compra IS NULL, '
          'ultima_compra DESC, a.actualizado DESC',
          readsFrom: {
            db.alimentos,
            db.ingredientesReceta,
            db.compras,
            db.presentaciones,
          },
        )
        .watch()
        .map(
          (rows) =>
              rows.map((r) => foodFromRow(db.alimentos.map(r.data))).toList(),
        );
  }

  @override
  Stream<int> watchPendingCount() => db
      .customSelect(
        'SELECT COUNT(*) AS n FROM alimentos a '
        'WHERE a.archivado = 0 AND $kPendienteSql',
        readsFrom: {db.alimentos},
      )
      .watchSingle()
      .map((r) => r.read<int>('n'));

  // Porciones -----------------------------------------------------------------

  @override
  Stream<List<FoodPortion>> watchPortions(int alimentoId) =>
      (db.select(db.porciones)
            ..where((p) => p.alimentoId.equals(alimentoId))
            ..orderBy([(p) => OrderingTerm.asc(p.gramos)]))
          .watch()
          .map((rows) => rows.map(portionFromRow).toList());

  @override
  Future<Map<int, List<FoodPortion>>> getPortionsFor(Iterable<int> ids) async {
    final set = ids.toSet();
    if (set.isEmpty) return const {};
    final rows = await (db.select(
      db.porciones,
    )..where((p) => p.alimentoId.isIn(set))).get();
    final out = <int, List<FoodPortion>>{};
    for (final r in rows) {
      out.putIfAbsent(r.alimentoId, () => []).add(portionFromRow(r));
    }
    return out;
  }

  @override
  Future<int> savePortion(FoodPortion portion) async {
    final nombre = portion.nombre.trim();
    if (nombre.isEmpty) {
      throw const ValidationException('Escribe el nombre de la porción.');
    }
    if (portion.gramos <= 0 || portion.gramos.isNaN) {
      throw const ValidationException('Los gramos deben ser mayores que 0.');
    }
    final alimentoId = portion.alimentoId;
    if (alimentoId == null) {
      throw const ValidationException('La porción no tiene alimento.');
    }
    final dup =
        await (db.select(db.porciones)..where(
              (p) => p.alimentoId.equals(alimentoId) & p.nombre.equals(nombre),
            ))
            .getSingleOrNull();
    if (dup != null && dup.id != portion.id) {
      throw ValidationException('Ya hay una porción "$nombre".');
    }
    final values = PorcionesCompanion(
      alimentoId: Value(alimentoId),
      nombre: Value(nombre),
      gramos: Value(portion.gramos),
    );
    if (portion.id == null) return db.into(db.porciones).insert(values);
    await (db.update(
      db.porciones,
    )..where((p) => p.id.equals(portion.id!))).write(values);
    return portion.id!;
  }

  @override
  Future<void> deletePortion(int id) async {
    await (db.delete(db.porciones)..where((p) => p.id.equals(id))).go();
  }

  // Presentaciones ------------------------------------------------------------

  @override
  Stream<List<FoodPackage>> watchPackages(int alimentoId) =>
      (db.select(db.presentaciones)
            ..where((p) => p.alimentoId.equals(alimentoId))
            ..orderBy([
              (p) => OrderingTerm.asc(p.archivado),
              (p) => OrderingTerm.asc(p.id),
            ]))
          .watch()
          .map((rows) => rows.map(packageFromRow).toList());

  @override
  Future<List<FoodPackage>> getPackages(int alimentoId) async {
    final rows =
        await (db.select(db.presentaciones)
              ..where((p) => p.alimentoId.equals(alimentoId))
              ..orderBy([(p) => OrderingTerm.asc(p.id)]))
            .get();
    return rows.map(packageFromRow).toList();
  }

  @override
  Future<FoodPackage?> getPackage(int id) async {
    final r = await (db.select(
      db.presentaciones,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    return r == null ? null : packageFromRow(r);
  }

  @override
  Future<int> savePackage(FoodPackage package) {
    return db.transaction(() async {
      final code = normalizeBarcode(package.codigoBarras);
      if (code != null) {
        final otro = await findByBarcode(code);
        if (otro != null && otro.package.id != package.id) {
          throw DuplicateBarcodeException(code, otro.food);
        }
      }
      final now = nowIso();
      final values = PresentacionesCompanion(
        alimentoId: Value(package.alimentoId),
        codigoBarras: Value(code),
        descripcion: Value(package.descripcion.trim()),
        contenido: Value(
          (package.contenido ?? 0) > 0 ? package.contenido : null,
        ),
        archivado: Value(package.archivado),
        actualizado: Value(now),
      );
      if (package.id == null) {
        return db
            .into(db.presentaciones)
            .insert(
              values.copyWith(
                uuid: Value(package.uuid ?? newUuid()),
                creado: Value(now),
              ),
            );
      }
      await (db.update(
        db.presentaciones,
      )..where((p) => p.id.equals(package.id!))).write(values);
      return package.id!;
    });
  }

  @override
  Future<void> deletePackage(int id) {
    return db.transaction(() async {
      final hay = await db
          .customSelect(
            'SELECT EXISTS(SELECT 1 FROM compras WHERE presentacion_id = ?) '
            'AS hay',
            variables: [Variable.withInt(id)],
          )
          .getSingle();
      if (hay.read<bool>('hay')) {
        // Conserva el historial; el código queda libre para otro alimento.
        await (db.update(
          db.presentaciones,
        )..where((p) => p.id.equals(id))).write(
          PresentacionesCompanion(
            archivado: const Value(true),
            codigoBarras: const Value(null),
            actualizado: Value(nowIso()),
          ),
        );
      } else {
        await (db.delete(
          db.presentaciones,
        )..where((p) => p.id.equals(id))).go();
      }
    });
  }

  @override
  Future<int> defaultPackageId(int alimentoId) {
    return db.transaction(() async {
      final existing =
          await (db.select(db.presentaciones)
                ..where(
                  (p) =>
                      p.alimentoId.equals(alimentoId) &
                      p.codigoBarras.isNull() &
                      p.descripcion.equals('') &
                      p.archivado.equals(false),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) return existing.id;
      final now = nowIso();
      return db
          .into(db.presentaciones)
          .insert(
            PresentacionesCompanion.insert(
              uuid: newUuid(),
              alimentoId: alimentoId,
              creado: now,
              actualizado: now,
            ),
          );
    });
  }
}
