import '../../domain/entities/product.dart';
import '../../domain/services/dates.dart';
import '../models/product_model.dart';
import 'local_data_source.dart';

abstract class ProductLocalDataSource {
  Future<List<Product>> getProducts();
  Future<Product?> getProduct(int id);
  Future<Product?> getProductByBarcode(String codigoBarras);
  Future<int> saveProduct(Product product);
  Future<void> deleteProduct(int id);
  Future<List<Purchase>> getPurchases(int productoId);
  Future<int> addPurchase(Purchase purchase);
  Future<void> deletePurchase(int id);
  Future<List<String>> getStores();
  Future<int> purgePurchasesBefore(DateTime fecha);
  Future<List<({Product producto, Purchase compra})>> getPurchaseHistorySince(
    DateTime fecha,
  );
}

/// Tablas `productos` + `compras` (DDL en module_tables.dart).
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final LocalDataSource core;

  ProductLocalDataSourceImpl(this.core);

  /// SELECT de productos con su última compra (prefijo `c_`).
  static const String _selectWithLast = '''
    SELECT p.*, c.id AS c_id, c.fecha AS c_fecha, c.precio AS c_precio,
           c.establecimiento AS c_establecimiento
    FROM productos p
    LEFT JOIN compras c ON c.id = (
      SELECT c2.id FROM compras c2
      WHERE c2.producto_id = p.id
      ORDER BY c2.fecha DESC, c2.id DESC
      LIMIT 1
    )
  ''';

  @override
  Future<List<Product>> getProducts() async {
    final db = await core.database;
    final rows = await db.rawQuery(
      '$_selectWithLast ORDER BY p.nombre COLLATE NOCASE ASC',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  @override
  Future<Product?> getProduct(int id) async {
    final db = await core.database;
    final rows = await db.rawQuery('$_selectWithLast WHERE p.id = ?', [id]);
    return rows.isEmpty ? null : ProductModel.fromMap(rows.first);
  }

  @override
  Future<Product?> getProductByBarcode(String codigoBarras) async {
    final code = codigoBarras.trim();
    if (code.isEmpty) return null;
    final db = await core.database;
    final rows = await db.rawQuery(
      '$_selectWithLast WHERE p.codigo_barras = ?',
      [code],
    );
    return rows.isEmpty ? null : ProductModel.fromMap(rows.first);
  }

  @override
  Future<int> saveProduct(Product product) async {
    final db = await core.database;
    final values = ProductModel.toMap(product);
    final code = values['codigo_barras'] as String?;
    if (code != null) {
      final dup = await db.query(
        'productos',
        columns: ['id', 'nombre'],
        where: product.id == null
            ? 'codigo_barras = ?'
            : 'codigo_barras = ? AND id <> ?',
        whereArgs: product.id == null ? [code] : [code, product.id],
        limit: 1,
      );
      if (dup.isNotEmpty) {
        throw StateError(
          'El código $code ya pertenece a "${dup.first['nombre']}".',
        );
      }
    }
    if (product.id == null) {
      values['creado'] = DateTime.now().toIso8601String();
      return db.insert('productos', values);
    }
    await db.update(
      'productos',
      values,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    return product.id!;
  }

  @override
  Future<void> deleteProduct(int id) async {
    final db = await core.database;
    await db.transaction((txn) async {
      await txn.delete('compras', where: 'producto_id = ?', whereArgs: [id]);
      await txn.update(
        'items_lista_compra',
        {'producto_id': null},
        where: 'producto_id = ?',
        whereArgs: [id],
      );
      await txn.delete('productos', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<List<Purchase>> getPurchases(int productoId) async {
    final db = await core.database;
    final rows = await db.query(
      'compras',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'fecha DESC, id DESC',
    );
    return rows.map(PurchaseModel.fromMap).toList();
  }

  @override
  Future<int> addPurchase(Purchase purchase) async {
    final db = await core.database;
    return db.insert('compras', PurchaseModel.toMap(purchase));
  }

  @override
  Future<void> deletePurchase(int id) async {
    final db = await core.database;
    await db.delete('compras', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<String>> getStores() async {
    final db = await core.database;
    final rows = await db.rawQuery('''
      SELECT establecimiento, MAX(fecha) AS f, MAX(id) AS i
      FROM compras
      WHERE TRIM(establecimiento) <> ''
      GROUP BY LOWER(establecimiento)
      ORDER BY f DESC, i DESC
    ''');
    return rows.map((r) => r['establecimiento'] as String).toList();
  }

  @override
  Future<int> purgePurchasesBefore(DateTime fecha) async {
    final db = await core.database;
    return db.rawDelete(
      '''
      DELETE FROM compras
      WHERE fecha < ?
        AND id NOT IN (
          SELECT (
            SELECT c2.id FROM compras c2
            WHERE c2.producto_id = p.producto_id
            ORDER BY c2.fecha DESC, c2.id DESC
            LIMIT 1
          )
          FROM (SELECT DISTINCT producto_id FROM compras) p
        )
      ''',
      [dateKey(fecha)],
    );
  }

  @override
  Future<List<({Product producto, Purchase compra})>> getPurchaseHistorySince(
    DateTime fecha,
  ) async {
    final db = await core.database;
    final rows = await db.rawQuery(
      '''
      SELECT p.*, c.id AS c_id, c.fecha AS c_fecha, c.precio AS c_precio,
             c.establecimiento AS c_establecimiento
      FROM compras c
      JOIN productos p ON p.id = c.producto_id
      WHERE c.fecha >= ?
      ORDER BY p.nombre COLLATE NOCASE ASC, p.id ASC, c.fecha ASC, c.id ASC
      ''',
      [dateKey(fecha)],
    );
    return rows.map((r) {
      final p = ProductModel.fromMap(r);
      return (producto: p, compra: p.ultimaCompra!);
    }).toList();
  }
}
