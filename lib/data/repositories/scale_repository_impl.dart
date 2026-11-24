import 'package:drift/drift.dart';

import '../../domain/entities/purchase.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/repositories/scale_repository.dart';
import '../../domain/services/barcode.dart';
import '../../domain/services/scale_barcode.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

class ScaleRepositoryImpl implements ScaleRepository {
  final AppDatabase db;

  ScaleRepositoryImpl(this.db);

  static String _norm(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

  @override
  Future<Store?> getStore(String nombre) async {
    final row = await (db.select(
      db.establecimientos,
    )..where((e) => e.nombre.equals(_norm(nombre)))).getSingleOrNull();
    return row == null ? null : storeFromRow(row);
  }

  @override
  Future<Store> ensureStore(String nombre) async {
    final n = _norm(nombre);
    if (n.isEmpty) {
      throw const ValidationException('Indica el establecimiento.');
    }
    final existing = await getStore(n);
    if (existing != null) return existing;
    final id = await db
        .into(db.establecimientos)
        .insert(EstablecimientosCompanion.insert(nombre: n));
    return Store(id: id, nombre: n);
  }

  @override
  Future<void> setScaleFormat(
    int storeId,
    ScaleFormat formato, {
    int? longitudClave,
  }) async {
    await (db.update(
      db.establecimientos,
    )..where((e) => e.id.equals(storeId))).write(
      EstablecimientosCompanion(
        formatoBascula: Value(formato.clave),
        longitudClave: longitudClave == null
            ? const Value.absent()
            : Value(longitudClave),
      ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _query() =>
      db.select(db.codigosBascula).join([
        innerJoin(
          db.presentaciones,
          db.presentaciones.id.equalsExp(db.codigosBascula.presentacionId),
        ),
        innerJoin(
          db.alimentos,
          db.alimentos.id.equalsExp(db.presentaciones.alimentoId),
        ),
        innerJoin(
          db.establecimientos,
          db.establecimientos.id.equalsExp(db.codigosBascula.establecimientoId),
        ),
      ]);

  ScaleMatch _match(TypedResult r) => ScaleMatch(
    storeFromRow(r.readTable(db.establecimientos)),
    foodFromRow(r.readTable(db.alimentos)),
    packageFromRow(r.readTable(db.presentaciones)),
  );

  @override
  Future<ScaleMatch?> findCode(int storeId, String clave) async {
    final r =
        await (_query()..where(
              db.codigosBascula.establecimientoId.equals(storeId) &
                  db.codigosBascula.clave.equals(clave),
            ))
            .getSingleOrNull();
    return r == null ? null : _match(r);
  }

  @override
  Future<List<ScaleMatch>> findByShortKey(int storeId, String clave6) async {
    final rows =
        await (_query()..where(
              db.codigosBascula.establecimientoId.equals(storeId) &
                  db.codigosBascula.clave.like('$clave6%'),
            ))
            .get();
    final out = <int, ScaleMatch>{};
    for (final r in rows) {
      final m = _match(r);
      out[m.presentacion.id!] = m;
    }
    return out.values.toList();
  }

  @override
  Future<List<ScaleMatch>> findAnyStore(String codigo) async {
    final c = normalizeBarcode(codigo);
    if (c == null || c.length != 13) return const [];
    final rows =
        await (_query()..where(
              db.codigosBascula.clave.isIn([
                c.substring(0, 6),
                c.substring(0, 7),
              ]),
            ))
            .get();
    final out = <ScaleMatch>[];
    for (final r in rows) {
      final m = _match(r);
      final clave = r.readTable(db.codigosBascula).clave;
      if (m.tienda.longitudClave == clave.length) out.add(m);
    }
    return out;
  }

  @override
  Future<void> useShortKeys(int storeId) {
    return db.transaction(() async {
      final vars = [Variable.withInt(storeId)];
      await db.customUpdate(
        'UPDATE OR IGNORE codigos_bascula SET clave = substr(clave, 1, 6) '
        'WHERE establecimiento_id = ? AND length(clave) = 7',
        variables: vars,
        updates: {db.codigosBascula},
      );
      await db.customUpdate(
        'DELETE FROM codigos_bascula '
        'WHERE establecimiento_id = ? AND length(clave) = 7',
        variables: vars,
        updates: {db.codigosBascula},
        updateKind: UpdateKind.delete,
      );
      await (db.update(db.establecimientos)..where((e) => e.id.equals(storeId)))
          .write(const EstablecimientosCompanion(longitudClave: Value(6)));
    });
  }

  @override
  Future<void> saveCode(int storeId, String clave, int presentacionId) async {
    await db
        .into(db.codigosBascula)
        .insert(
          CodigosBasculaCompanion.insert(
            establecimientoId: storeId,
            clave: clave,
            presentacionId: presentacionId,
          ),
          onConflict: DoUpdate(
            (_) =>
                CodigosBasculaCompanion(presentacionId: Value(presentacionId)),
            target: [
              db.codigosBascula.establecimientoId,
              db.codigosBascula.clave,
            ],
          ),
        );
  }

  @override
  Future<int?> lastPricePerKiloCent(int presentacionId, {int? storeId}) async {
    Future<int?> buscar(int? tienda) async {
      final r = await db
          .customSelect(
            'SELECT precio_cent * unidades AS total, peso_g FROM compras '
            'WHERE presentacion_id = ? AND peso_g IS NOT NULL '
            '${tienda == null ? '' : 'AND establecimiento_id = ? '}'
            'ORDER BY fecha DESC, id DESC LIMIT 1',
            variables: [
              Variable.withInt(presentacionId),
              if (tienda != null) Variable.withInt(tienda),
            ],
          )
          .getSingleOrNull();
      if (r == null) return null;
      return pricePerKilo(r.read<int>('total'), r.read<double>('peso_g'));
    }

    if (storeId != null) {
      final enTienda = await buscar(storeId);
      if (enTienda != null) return enTienda;
    }
    return buscar(null);
  }
}
