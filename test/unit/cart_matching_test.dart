import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/shopping_list.dart';
import 'package:cal_counter/domain/services/cart_matching.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const leche = Food(id: 1, nombre: 'Leche entera', marca: 'Vaca');
  const cafe = Food(id: 2, nombre: 'Café molido');

  ShoppingItem item(
    int id,
    String texto, {
    int? alimentoId,
    bool comprado = false,
  }) => ShoppingItem(
    id: id,
    listaId: 1,
    texto: texto,
    alimentoId: alimentoId,
    comprado: comprado,
  );

  test('prefiere el que ya está en el carrito con ese alimento', () {
    final items = [
      item(1, 'Leche entera', alimentoId: 1),
      item(2, 'Leche entera', alimentoId: 1, comprado: true),
    ];
    expect(findItemForFood(items, leche)?.id, 2);
  });

  test('luego el pendiente vinculado al alimento', () {
    final items = [
      item(1, 'Leche', alimentoId: null),
      item(2, 'Otra cosa', alimentoId: 1),
    ];
    expect(findItemForFood(items, leche)?.id, 2);
  });

  test('luego un pendiente sin vincular que coincide por texto', () {
    final items = [
      item(1, 'Pan'),
      item(2, 'leches'), // plural y minúsculas
    ];
    expect(findItemForFood(items, leche)?.id, 2);
  });

  test('no empareja comprados sin vincular ni textos distintos', () {
    final items = [
      item(1, 'Leche', comprado: true),
      item(2, 'Galletas'),
      item(3, 'Leche', alimentoId: 9), // vinculado a otro alimento
    ];
    expect(findItemForFood(items, leche), isNull);
    expect(findItemForFood(items, cafe), isNull);
  });
}
