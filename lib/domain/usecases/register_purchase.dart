import '../entities/purchase.dart';
import '../errors/domain_errors.dart';
import '../repositories/food_repository.dart';
import '../repositories/purchase_repository.dart';
import '../services/dates.dart';
import '../services/money.dart' as money;

/// Registra la compra de un alimento: precio unitario (céntimos), unidades,
/// establecimiento y fecha. Si no se indica presentación se usa la
/// presentación sin código del alimento.
class RegisterPurchase {
  final FoodRepository foods;
  final PurchaseRepository purchases;

  RegisterPurchase(this.foods, this.purchases);

  Future<int> call({
    required int alimentoId,
    int? presentacionId,
    required int precioCent,
    int unidades = 1,
    required String establecimiento,
    DateTime? fecha,
  }) async {
    validarPrecioCent(precioCent);
    final tienda = normalizarEstablecimiento(establecimiento);
    final pid = presentacionId ?? await foods.defaultPackageId(alimentoId);
    return purchases.addPurchase(
      Purchase(
        presentacionId: pid,
        fecha: dateOnly(fecha ?? DateTime.now()),
        precioCent: precioCent,
        unidades: unidades,
        establecimiento: tienda,
      ),
    );
  }

  /// Lanza [ValidationException] si el precio no es mayor que 0.
  static void validarPrecioCent(int precioCent) {
    if (precioCent <= 0) {
      throw const ValidationException('El precio debe ser mayor que 0.');
    }
  }

  /// Espacios normalizados; lanza [ValidationException] si queda vacío.
  static String normalizarEstablecimiento(String establecimiento) {
    final store = establecimiento.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (store.isEmpty) {
      throw const ValidationException('Indica el establecimiento.');
    }
    return store;
  }

  /// Interpreta un precio escrito por el usuario ("2,35", "2.35",
  /// "1.234,50"). Devuelve null si no es válido.
  static double? parsePrecio(String input) => money.parsePrecio(input);

  /// Como [parsePrecio], en céntimos y solo si es mayor que 0.
  static int? parsePrecioCent(String input) => money.parsePrecioCent(input);
}
