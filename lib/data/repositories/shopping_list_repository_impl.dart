import 'package:drift/drift.dart';

import '../../domain/entities/shopping_list.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Listas de compra sobre Drift. Los datos del carrito (unidades, precio)
/// salen de la compra enlazada; el precio de referencia, de la última compra
/// de cualquier presentación del alimento.
class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final AppDatabase db;

  ShoppingListRepositoryImpl(this.db);

  @override
  Stream<List<ShoppingList>> watchLists() => db
      .customSelect(
        'SELECT l.*, COUNT(i.id) AS total, '
        'COALESCE(SUM(i.comprado), 0) AS comprados '
        'FROM listas_compra l LEFT JOIN items_lista i ON i.lista_id = l.id '
        'GROUP BY l.id ORDER BY l.creada DESC, l.id DESC',
        readsFrom: {db.listasCompra, db.itemsLista},
      )
      .watch()
      .map(
        (rows) => rows
            .map(
              (r) => ShoppingList(
                id: r.read<int>('id'),
                nombre: r.read<String>('nombre'),
                creada:
                    DateTime.tryParse(r.read<String>('creada')) ??
                    DateTime.now(),
                totalItems: r.read<int>('total'),
                comprados: r.read<int>('comprados'),
              ),
            )
            .toList(),
      );

  @override
  Future<int> createList(String nombre) => db
      .into(db.listasCompra)
      .insert(
        ListasCompraCompanion.insert(nombre: nombre.trim(), creada: nowIso()),
      );

  @override
  Future<void> renameList(int id, String nombre) async {
    await (db.update(db.listasCompra)..where((l) => l.id.equals(id))).write(
      ListasCompraCompanion(nombre: Value(nombre.trim())),
    );
  }

  @override
  Future<void> deleteList(int id) async {
    await (db.delete(db.listasCompra)..where((l) => l.id.equals(id))).go();
  }

  static const String _refSub =
      'FROM compras c2 '
      'JOIN presentaciones p2 ON p2.id = c2.presentacion_id '
      'JOIN establecimientos e2 ON e2.id = c2.establecimiento_id '
      'WHERE p2.alimento_id = i.alimento_id '
      'ORDER BY c2.fecha DESC, c2.id DESC LIMIT 1';

  Selectable<ShoppingItem> _items(int listaId) => db
      .customSelect(
        'SELECT i.*, c.presentacion_id AS c_presentacion, '
        'c.unidades AS c_unidades, c.precio_cent AS c_precio, '
        '(SELECT c2.precio_cent $_refSub) AS ref_precio, '
        '(SELECT e2.nombre $_refSub) AS ref_tienda '
        'FROM items_lista i LEFT JOIN compras c ON c.id = i.compra_id '
        'WHERE i.lista_id = ? '
        'ORDER BY i.comprado ASC, i.orden ASC, i.id ASC',
        variables: [Variable.withInt(listaId)],
        readsFrom: {
          db.itemsLista,
          db.compras,
          db.presentaciones,
          db.establecimientos,
        },
      )
      .map((r) {
        final row = db.itemsLista.map(r.data);
        return ShoppingItem(
          id: row.id,
          listaId: row.listaId,
          alimentoId: row.alimentoId,
          texto: row.texto,
          cantidad: row.cantidad,
          comprado: row.comprado,
          orden: row.orden,
          compraId: row.compraId,
          presentacionId: r.readNullable<int>('c_presentacion'),
          unidades: r.readNullable<int>('c_unidades') ?? 1,
          precioCent: r.readNullable<int>('c_precio'),
          precioReferenciaCent: r.readNullable<int>('ref_precio'),
          establecimientoReferencia: r.readNullable<String>('ref_tienda'),
        );
      });

  @override
  Stream<List<ShoppingItem>> watchItems(int listaId) => _items(listaId).watch();

  @override
  Future<List<ShoppingItem>> getItems(int listaId) => _items(listaId).get();

  @override
  Future<int> addItem(ShoppingItem item) {
    return db.transaction(() async {
      final res = await db
          .customSelect(
            'SELECT COALESCE(MAX(orden), 0) + 1 AS siguiente '
            'FROM items_lista WHERE lista_id = ?',
            variables: [Variable.withInt(item.listaId)],
          )
          .getSingle();
      return db
          .into(db.itemsLista)
          .insert(
            ItemsListaCompanion.insert(
              listaId: item.listaId,
              alimentoId: Value(item.alimentoId),
              texto: item.texto.trim(),
              cantidad: Value(emptyToNull(item.cantidad)),
              orden: res.read<int>('siguiente'),
              comprado: Value(item.comprado),
              compraId: Value(item.compraId),
            ),
          );
    });
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    final id = item.id;
    if (id == null) throw ArgumentError('El artículo no tiene id.');
    await (db.update(db.itemsLista)..where((i) => i.id.equals(id))).write(
      ItemsListaCompanion(
        alimentoId: Value(item.alimentoId),
        texto: Value(item.texto.trim()),
        cantidad: Value(emptyToNull(item.cantidad)),
        comprado: Value(item.comprado),
        compraId: Value(item.compraId),
      ),
    );
  }

  /// Desmarcar saca el artículo del carrito pero NO borra la compra:
  /// reutilizar una lista no debe perder historial de precios.
  static ItemsListaCompanion _bought(bool comprado) => comprado
      ? const ItemsListaCompanion(comprado: Value(true))
      : const ItemsListaCompanion(
          comprado: Value(false),
          compraId: Value(null),
        );

  @override
  Future<void> setItemBought(int itemId, bool comprado) async {
    await (db.update(
      db.itemsLista,
    )..where((i) => i.id.equals(itemId))).write(_bought(comprado));
  }

  @override
  Future<void> deleteItem(int itemId) async {
    await (db.delete(db.itemsLista)..where((i) => i.id.equals(itemId))).go();
  }

  @override
  Future<void> deleteBoughtItems(int listaId) async {
    await (db.delete(
      db.itemsLista,
    )..where((i) => i.listaId.equals(listaId) & i.comprado.equals(true))).go();
  }

  @override
  Future<void> setAllBought(int listaId, bool comprado) async {
    await (db.update(
      db.itemsLista,
    )..where((i) => i.listaId.equals(listaId))).write(_bought(comprado));
  }
}
