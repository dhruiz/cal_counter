import 'package:sqflite/sqflite.dart';
import '../../domain/entities/shopping_list.dart';
import '../models/shopping_model.dart';
import 'local_data_source.dart';

abstract class ShoppingLocalDataSource {
  Future<List<ShoppingList>> getLists();
  Future<int> createList(String nombre);
  Future<void> renameList(int id, String nombre);
  Future<void> deleteList(int id);
  Future<List<ShoppingItem>> getItems(int listaId);
  Future<int> addItem(ShoppingItem item);
  Future<void> updateItem(ShoppingItem item);
  Future<void> setItemBought(int itemId, bool comprado);
  Future<void> deleteItem(int itemId);
  Future<void> deleteBoughtItems(int listaId);
  Future<void> setAllBought(int listaId, bool comprado);
}

/// Tablas `listas_compra` + `items_lista_compra` (DDL en module_tables.dart).
/// El precio de referencia sale de la última fila de `compras` del producto.
class ShoppingLocalDataSourceImpl implements ShoppingLocalDataSource {
  final LocalDataSource core;

  ShoppingLocalDataSourceImpl(this.core);

  @override
  Future<List<ShoppingList>> getLists() async {
    final db = await core.database;
    final rows = await db.rawQuery('''
      SELECT l.*, COUNT(i.id) AS total, COALESCE(SUM(i.comprado), 0) AS comprados
      FROM listas_compra l
      LEFT JOIN items_lista_compra i ON i.lista_id = l.id
      GROUP BY l.id
      ORDER BY l.creada DESC, l.id DESC
    ''');
    return rows.map(ShoppingListModel.fromMap).toList();
  }

  @override
  Future<int> createList(String nombre) async {
    final db = await core.database;
    return db.insert('listas_compra', {
      'nombre': nombre.trim(),
      'creada': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> renameList(int id, String nombre) async {
    final db = await core.database;
    await db.update(
      'listas_compra',
      {'nombre': nombre.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteList(int id) async {
    final db = await core.database;
    await db.transaction((txn) async {
      await txn.delete(
        'items_lista_compra',
        where: 'lista_id = ?',
        whereArgs: [id],
      );
      await txn.delete('listas_compra', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<List<ShoppingItem>> getItems(int listaId) async {
    final db = await core.database;
    final rows = await db.rawQuery(
      '''
      SELECT i.*, c.precio AS ref_precio, c.establecimiento AS ref_establecimiento
      FROM items_lista_compra i
      LEFT JOIN compras c ON c.id = (
        SELECT c2.id FROM compras c2
        WHERE c2.producto_id = i.producto_id
        ORDER BY c2.fecha DESC, c2.id DESC
        LIMIT 1
      )
      WHERE i.lista_id = ?
      ORDER BY i.comprado ASC, i.orden ASC, i.id ASC
      ''',
      [listaId],
    );
    return rows.map(ShoppingItemModel.fromMap).toList();
  }

  @override
  Future<int> addItem(ShoppingItem item) async {
    final db = await core.database;
    final res = await db.rawQuery(
      'SELECT COALESCE(MAX(orden), 0) + 1 AS siguiente '
      'FROM items_lista_compra WHERE lista_id = ?',
      [item.listaId],
    );
    final orden = Sqflite.firstIntValue(res) ?? 1;
    return db.insert(
      'items_lista_compra',
      ShoppingItemModel.toMap(item)..['orden'] = orden,
    );
  }

  @override
  Future<void> updateItem(ShoppingItem item) async {
    final db = await core.database;
    await db.update(
      'items_lista_compra',
      ShoppingItemModel.toMap(item)..remove('lista_id'),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Valores al marcar/desmarcar. Desmarcar saca el artículo del carrito
  /// (precio pagado y vínculo a la compra) pero NO borra la fila de `compras`:
  /// reutilizar una lista no debe perder historial de precios.
  static Map<String, Object?> _boughtValues(bool comprado) => comprado
      ? {'comprado': 1}
      : {
          'comprado': 0,
          'unidades': 1,
          'precio_pagado': null,
          'compra_id': null,
        };

  @override
  Future<void> setItemBought(int itemId, bool comprado) async {
    final db = await core.database;
    await db.update(
      'items_lista_compra',
      _boughtValues(comprado),
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  @override
  Future<void> deleteItem(int itemId) async {
    final db = await core.database;
    await db.delete('items_lista_compra', where: 'id = ?', whereArgs: [itemId]);
  }

  @override
  Future<void> deleteBoughtItems(int listaId) async {
    final db = await core.database;
    await db.delete(
      'items_lista_compra',
      where: 'lista_id = ? AND comprado = 1',
      whereArgs: [listaId],
    );
  }

  @override
  Future<void> setAllBought(int listaId, bool comprado) async {
    final db = await core.database;
    await db.update(
      'items_lista_compra',
      _boughtValues(comprado),
      where: 'lista_id = ?',
      whereArgs: [listaId],
    );
  }
}
