import 'package:drift/drift.dart';

import '../../domain/entities/category.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/services/category_guesser.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase db;

  CategoryRepositoryImpl(this.db);

  /// Orden de la tienda si tiene filas en `orden_pasillos`; las categorías
  /// que no están en su orden van después, en el orden general.
  Selectable<Category> _ordered(String? tienda) {
    final t = tienda?.trim() ?? '';
    return db
        .customSelect(
          'SELECT c.* FROM categorias c '
          'LEFT JOIN establecimientos e ON e.nombre = ? '
          'LEFT JOIN orden_pasillos o '
          '  ON o.categoria_id = c.id AND o.establecimiento_id = e.id '
          'ORDER BY o.orden IS NULL, o.orden, c.orden, c.id',
          variables: [Variable.withString(t)],
          readsFrom: {db.categorias, db.ordenPasillos, db.establecimientos},
        )
        .map((r) => categoryFromRow(db.categorias.map(r.data)));
  }

  @override
  Stream<List<Category>> watchCategories({String? tienda}) =>
      _ordered(tienda).watch();

  @override
  Future<List<Category>> getCategories({String? tienda}) =>
      _ordered(tienda).get();

  @override
  Future<int> saveCategory(Category categoria) async {
    final nombre = categoria.nombre.trim();
    if (nombre.isEmpty) {
      throw const ValidationException('Escribe el nombre de la categoría.');
    }
    final dup = await (db.select(
      db.categorias,
    )..where((c) => c.nombre.equals(nombre))).getSingleOrNull();
    if (dup != null && dup.id != categoria.id) {
      throw ValidationException('Ya existe la categoría "$nombre".');
    }
    if (categoria.id == null) {
      final max = await db
          .customSelect(
            'SELECT COALESCE(MAX(orden), -1) + 1 AS o FROM categorias',
          )
          .getSingle();
      return db
          .into(db.categorias)
          .insert(
            CategoriasCompanion.insert(
              nombre: nombre,
              orden: Value(max.read<int>('o')),
            ),
          );
    }
    await (db.update(db.categorias)..where((c) => c.id.equals(categoria.id!)))
        .write(CategoriasCompanion(nombre: Value(nombre)));
    return categoria.id!;
  }

  @override
  Future<void> deleteCategory(int id) async {
    await (db.delete(db.categorias)..where((c) => c.id.equals(id))).go();
  }

  Future<int?> _storeId(String tienda, {bool crear = false}) async {
    final n = tienda.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (n.isEmpty) return null;
    final row = await (db.select(
      db.establecimientos,
    )..where((e) => e.nombre.equals(n))).getSingleOrNull();
    if (row != null || !crear) return row?.id;
    return db
        .into(db.establecimientos)
        .insert(EstablecimientosCompanion.insert(nombre: n));
  }

  @override
  Future<void> reorder(List<int> idsEnOrden, {String? tienda}) {
    return db.transaction(() async {
      if (tienda == null) {
        for (var i = 0; i < idsEnOrden.length; i++) {
          await (db.update(db.categorias)
                ..where((c) => c.id.equals(idsEnOrden[i])))
              .write(CategoriasCompanion(orden: Value(i)));
        }
        return;
      }
      final storeId = await _storeId(tienda, crear: true);
      if (storeId == null) return;
      await (db.delete(
        db.ordenPasillos,
      )..where((o) => o.establecimientoId.equals(storeId))).go();
      for (var i = 0; i < idsEnOrden.length; i++) {
        await db
            .into(db.ordenPasillos)
            .insert(
              OrdenPasillosCompanion.insert(
                establecimientoId: storeId,
                categoriaId: idsEnOrden[i],
                orden: i,
              ),
            );
      }
    });
  }

  @override
  Future<void> resetStoreOrder(String tienda) async {
    final storeId = await _storeId(tienda);
    if (storeId == null) return;
    await (db.delete(
      db.ordenPasillos,
    )..where((o) => o.establecimientoId.equals(storeId))).go();
  }

  @override
  Stream<bool> watchHasStoreOrder(String tienda) => db
      .customSelect(
        'SELECT EXISTS(SELECT 1 FROM orden_pasillos o '
        'JOIN establecimientos e ON e.id = o.establecimiento_id '
        'WHERE e.nombre = ?) AS hay',
        variables: [Variable.withString(tienda.trim())],
        readsFrom: {db.ordenPasillos, db.establecimientos},
      )
      .watchSingle()
      .map((r) => r.read<bool>('hay'));

  @override
  Future<void> assignCategory(
    Iterable<int> alimentoIds,
    int? categoriaId,
  ) async {
    final ids = alimentoIds.toSet();
    if (ids.isEmpty) return;
    await (db.update(db.alimentos)..where((a) => a.id.isIn(ids))).write(
      AlimentosCompanion(
        categoriaId: Value(categoriaId),
        actualizado: Value(nowIso()),
      ),
    );
  }

  @override
  Future<Category?> suggestFor(String nombre) async {
    final guess = guessCategoryName(nombre);
    if (guess == null) return null;
    final row = await (db.select(
      db.categorias,
    )..where((c) => c.nombre.equals(guess))).getSingleOrNull();
    return row == null ? null : categoryFromRow(row);
  }
}
