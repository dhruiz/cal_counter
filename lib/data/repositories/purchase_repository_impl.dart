import 'package:drift/drift.dart';

import '../../domain/entities/purchase.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Historial de compras y establecimientos sobre Drift.
class PurchaseRepositoryImpl implements PurchaseRepository {
  final AppDatabase db;

  PurchaseRepositoryImpl(this.db);

  /// Espacios normalizados del nombre de una tienda.
  static String normalizarEstablecimiento(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');

  Selectable<String> _storeNames() => db
      .customSelect(
        'SELECT e.nombre, MAX(c.fecha) AS f, MAX(c.id) AS i '
        'FROM establecimientos e '
        'LEFT JOIN compras c ON c.establecimiento_id = e.id '
        'GROUP BY e.id ORDER BY f DESC NULLS LAST, i DESC, e.nombre',
        readsFrom: {db.establecimientos, db.compras},
      )
      .map((r) => r.read<String>('nombre'));

  @override
  Future<List<String>> getStoreNames() => _storeNames().get();

  @override
  Stream<List<String>> watchStoreNames() => _storeNames().watch();

  /// Id del establecimiento (sin distinguir mayúsculas), creado si no existe.
  Future<int> _storeId(String nombre) async {
    final n = normalizarEstablecimiento(nombre);
    if (n.isEmpty) throw const ValidationException('Indica el establecimiento.');
    final existing = await (db.select(
      db.establecimientos,
    )..where((e) => e.nombre.equals(n))).getSingleOrNull();
    if (existing != null) return existing.id;
    return db
        .into(db.establecimientos)
        .insert(EstablecimientosCompanion.insert(nombre: n));
  }

  static void _validar(Purchase c) {
    if (c.precioCent <= 0) {
      throw const ValidationException('El precio debe ser mayor que 0.');
    }
    if (c.unidades < 1) {
      throw const ValidationException('Las unidades deben ser al menos 1.');
    }
  }

  Future<CompraRow?> _row(int id) =>
      (db.select(db.compras)..where((c) => c.id.equals(id))).getSingleOrNull();

  @override
  Future<Purchase?> getPurchase(int id) async {
    final row =
        await (db.select(db.compras).join([
              innerJoin(
                db.establecimientos,
                db.establecimientos.id.equalsExp(db.compras.establecimientoId),
              ),
            ])..where(db.compras.id.equals(id)))
            .getSingleOrNull();
    if (row == null) return null;
    return purchaseFromRows(
      row.readTable(db.compras),
      row.readTable(db.establecimientos),
    );
  }

  @override
  Future<int> addPurchase(Purchase compra) {
    _validar(compra);
    return db.transaction(() async {
      final storeId = await _storeId(compra.establecimiento);
      return db
          .into(db.compras)
          .insert(
            ComprasCompanion.insert(
              presentacionId: compra.presentacionId,
              establecimientoId: storeId,
              fecha: dayKey(compra.fecha),
              precioCent: compra.precioCent,
              unidades: Value(compra.unidades),
            ),
          );
    });
  }

  @override
  Future<void> updatePurchase(Purchase compra) {
    _validar(compra);
    final id = compra.id;
    if (id == null) throw ArgumentError('La compra no tiene id.');
    return db.transaction(() async {
      final storeId = await _storeId(compra.establecimiento);
      await (db.update(db.compras)..where((c) => c.id.equals(id))).write(
        ComprasCompanion(
          presentacionId: Value(compra.presentacionId),
          establecimientoId: Value(storeId),
          fecha: Value(dayKey(compra.fecha)),
          precioCent: Value(compra.precioCent),
          unidades: Value(compra.unidades),
        ),
      );
    });
  }

  @override
  Future<void> deletePurchase(int id) async {
    if (await _row(id) == null) return;
    await (db.delete(db.compras)..where((c) => c.id.equals(id))).go();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _recordsQuery() =>
      db.select(db.compras).join([
        innerJoin(
          db.presentaciones,
          db.presentaciones.id.equalsExp(db.compras.presentacionId),
        ),
        innerJoin(
          db.alimentos,
          db.alimentos.id.equalsExp(db.presentaciones.alimentoId),
        ),
        innerJoin(
          db.establecimientos,
          db.establecimientos.id.equalsExp(db.compras.establecimientoId),
        ),
      ]);

  PurchaseRecord _record(TypedResult r) => PurchaseRecord(
    compra: purchaseFromRows(
      r.readTable(db.compras),
      r.readTable(db.establecimientos),
    ),
    presentacion: packageFromRow(r.readTable(db.presentaciones)),
    alimento: foodFromRow(r.readTable(db.alimentos)),
  );

  JoinedSelectStatement<HasResultSet, dynamic> _forFood(int alimentoId) =>
      _recordsQuery()
        ..where(db.presentaciones.alimentoId.equals(alimentoId))
        ..orderBy([
          OrderingTerm.desc(db.compras.fecha),
          OrderingTerm.desc(db.compras.id),
        ]);

  @override
  Stream<List<PurchaseRecord>> watchPurchasesForFood(int alimentoId) =>
      _forFood(alimentoId).watch().map((rows) => rows.map(_record).toList());

  @override
  Future<List<PurchaseRecord>> getPurchasesForFood(int alimentoId) async =>
      (await _forFood(alimentoId).get()).map(_record).toList();

  @override
  Future<PurchaseRecord?> lastPurchaseForFood(
    int alimentoId, {
    String? establecimiento,
  }) async {
    final tienda = establecimiento == null
        ? null
        : normalizarEstablecimiento(establecimiento);
    if (tienda != null && tienda.isNotEmpty) {
      final q = _forFood(alimentoId)
        ..where(db.establecimientos.nombre.equals(tienda))
        ..limit(1);
      final r = await q.getSingleOrNull();
      if (r != null) return _record(r);
    }
    final r = await (_forFood(alimentoId)..limit(1)).getSingleOrNull();
    return r == null ? null : _record(r);
  }

  @override
  Stream<List<PurchaseRecord>> watchLastPurchasePerFood() {
    final q = _recordsQuery()
      ..orderBy([
        OrderingTerm.desc(db.compras.fecha),
        OrderingTerm.desc(db.compras.id),
      ]);
    return q.watch().map((rows) {
      final seen = <int>{};
      final out = <PurchaseRecord>[];
      for (final r in rows) {
        final rec = _record(r);
        if (seen.add(rec.alimento.id!)) out.add(rec);
      }
      return out;
    });
  }

  @override
  Future<int> purgeBefore(DateTime fecha) {
    return db.customUpdate(
      '''
      DELETE FROM compras
      WHERE fecha < ?
        AND id NOT IN (
          SELECT (
            SELECT c2.id FROM compras c2
            WHERE c2.presentacion_id = p.presentacion_id
            ORDER BY c2.fecha DESC, c2.id DESC
            LIMIT 1
          )
          FROM (SELECT DISTINCT presentacion_id FROM compras) p
        )
      ''',
      variables: [Variable.withString(dayKey(fecha))],
      updates: {db.compras, db.itemsLista},
      updateKind: UpdateKind.delete,
    );
  }

  @override
  Future<List<PurchaseRecord>> historySince(DateTime fecha) async {
    final q = _recordsQuery()
      ..where(db.compras.fecha.isBiggerOrEqualValue(dayKey(fecha)))
      ..orderBy([
        OrderingTerm.asc(db.alimentos.nombre),
        OrderingTerm.asc(db.alimentos.id),
        OrderingTerm.asc(db.compras.fecha),
        OrderingTerm.asc(db.compras.id),
      ]);
    return (await q.get()).map(_record).toList();
  }
}
