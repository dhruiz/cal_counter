import 'package:cal_counter/domain/entities/product.dart';
import 'package:cal_counter/domain/entities/shopping_list.dart';
import 'package:cal_counter/domain/services/cart_matching.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const leche = Product(id: 1, nombre: 'Leche entera', marca: 'Vaca');
  const cafe = Product(id: 2, nombre: 'Café molido');

  ShoppingItem item(
    int id,
    String texto, {
    int? productoId,
    bool comprado = false,
  }) => ShoppingItem(
    id: id,
    listaId: 1,
    texto: texto,
    productoId: productoId,
    comprado: comprado,
  );

  test('prefiere el que ya está en el carrito con ese producto', () {
    final items = [
      item(1, 'Leche entera', productoId: 1),
      item(2, 'Leche entera', productoId: 1, comprado: true),
    ];
    expect(findItemForProduct(items, leche)?.id, 2);
  });

  test('luego el pendiente vinculado al producto', () {
    final items = [
      item(1, 'Leche', productoId: null),
      item(2, 'Otra cosa', productoId: 1),
    ];
    expect(findItemForProduct(items, leche)?.id, 2);
  });

  test('luego un pendiente sin vincular que coincide por texto', () {
    final items = [
      item(1, 'Pan'),
      item(2, 'leches'), // plural y minúsculas
    ];
    expect(findItemForProduct(items, leche)?.id, 2);
  });

  test('no empareja comprados sin vincular ni textos distintos', () {
    final items = [
      item(1, 'Leche', comprado: true),
      item(2, 'Galletas'),
      item(3, 'Leche', productoId: 9), // vinculado a otro producto
    ];
    expect(findItemForProduct(items, leche), isNull);
    expect(findItemForProduct(items, cafe), isNull);
  });
}
