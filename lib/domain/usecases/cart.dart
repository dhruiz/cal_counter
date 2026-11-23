import '../entities/food.dart';
import '../entities/purchase.dart';
import '../entities/shopping_list.dart';
import '../errors/domain_errors.dart';
import '../repositories/food_repository.dart';
import '../repositories/purchase_repository.dart';
import '../repositories/shopping_list_repository.dart';
import '../repositories/transaction_runner.dart';
import '../services/cart_matching.dart';
import '../services/dates.dart';
import 'register_purchase.dart';

/// Modo carrito: mete un alimento en el carrito de una lista y registra la
/// compra en el historial, todo en una transacción.
///
/// - Si ya estaba en el carrito, suma [unidades] a la misma compra (y
///   corrige el precio si cambió); no crea otra fila en `compras`.
/// - Si no, registra la compra y marca como comprado el artículo
///   correspondiente ([findItemForFood], o [itemId] si se indica),
///   vinculándolo al alimento; si no estaba en la lista, lo añade ya
///   comprado. La UI pregunta antes de ese último caso.
///
/// Devuelve el id del artículo.
class AddToCart {
  final ShoppingListRepository shopping;
  final PurchaseRepository purchases;
  final FoodRepository foods;
  final TransactionRunner tx;

  AddToCart(this.shopping, this.purchases, this.foods, this.tx);

  Future<int> call({
    required int listaId,
    required Food alimento,
    int? presentacionId,
    int? itemId,
    required int precioCent,
    int unidades = 1,
    required String establecimiento,
    DateTime? fecha,
  }) {
    RegisterPurchase.validarPrecioCent(precioCent);
    if (unidades < 1) {
      throw const ValidationException('Las unidades deben ser al menos 1.');
    }
    final tienda = RegisterPurchase.normalizarEstablecimiento(establecimiento);
    final dia = dateOnly(fecha ?? DateTime.now());
    final alimentoId = alimento.id!;

    return tx(() async {
      final pid = presentacionId ?? await foods.defaultPackageId(alimentoId);
      Future<int> nuevaCompra() => purchases.addPurchase(
        Purchase(
          presentacionId: pid,
          fecha: dia,
          precioCent: precioCent,
          unidades: unidades,
          establecimiento: tienda,
        ),
      );

      final items = await shopping.getItems(listaId);
      ShoppingItem? target;
      if (itemId != null) {
        for (final i in items) {
          if (i.id == itemId) target = i;
        }
      }
      target ??= findItemForFood(items, alimento);

      // 1. Ya en el carrito: más unidades sobre la misma compra.
      if (target != null && target.comprado && target.compraId != null) {
        final compra = await purchases.getPurchase(target.compraId!);
        if (compra != null) {
          await purchases.updatePurchase(
            compra.copyWith(
              unidades: compra.unidades + unidades,
              precioCent: precioCent,
              presentacionId: pid,
            ),
          );
          return target.id!;
        }
      }

      final compraId = await nuevaCompra();

      // 2. Estaba en la lista (pendiente o marcado a mano sin compra).
      if (target != null) {
        await shopping.updateItem(
          target.copyWith(
            alimentoId: alimentoId,
            comprado: true,
            compraId: compraId,
          ),
        );
        return target.id!;
      }

      // 3. No estaba: se añade ya comprado.
      return shopping.addItem(
        ShoppingItem(
          listaId: listaId,
          alimentoId: alimentoId,
          texto: alimento.nombre,
          comprado: true,
          compraId: compraId,
        ),
      );
    });
  }
}

/// Corrige precio y unidades de un artículo que ya está en el carrito.
class UpdateCartItem {
  final ShoppingListRepository shopping;
  final PurchaseRepository purchases;
  final TransactionRunner tx;

  UpdateCartItem(this.shopping, this.purchases, this.tx);

  Future<void> call({
    required ShoppingItem item,
    required int precioCent,
    required int unidades,
  }) {
    RegisterPurchase.validarPrecioCent(precioCent);
    if (unidades < 1) {
      throw const ValidationException('Las unidades deben ser al menos 1.');
    }
    final compraId = item.compraId;
    if (compraId == null) {
      throw const ValidationException('El artículo no está en el carrito.');
    }
    return tx(() async {
      final compra = await purchases.getPurchase(compraId);
      if (compra == null) return;
      await purchases.updatePurchase(
        compra.copyWith(precioCent: precioCent, unidades: unidades),
      );
      if (!item.comprado) await shopping.setItemBought(item.id!, true);
    });
  }
}

/// Saca un artículo del carrito y borra la compra registrada desde él (el
/// artículo vuelve a pendiente).
class RemoveFromCart {
  final ShoppingListRepository shopping;
  final PurchaseRepository purchases;
  final TransactionRunner tx;

  RemoveFromCart(this.shopping, this.purchases, this.tx);

  Future<void> call(ShoppingItem item) {
    return tx(() async {
      if (item.id != null) await shopping.setItemBought(item.id!, false);
      if (item.compraId != null) {
        await purchases.deletePurchase(item.compraId!);
      }
    });
  }
}
