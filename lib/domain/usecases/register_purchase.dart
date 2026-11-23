import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/dates.dart';

/// Registra la compra de un producto (precio unitario, establecimiento, fecha).
class RegisterPurchase {
  final ProductRepository repository;

  RegisterPurchase(this.repository);

  Future<int> call({
    required int productoId,
    required double precio,
    required String establecimiento,
    DateTime? fecha,
  }) async {
    if (precio <= 0 || precio.isNaN || precio.isInfinite) {
      throw ArgumentError('El precio debe ser mayor que 0.');
    }
    final store = establecimiento.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (store.isEmpty) {
      throw ArgumentError('Indica el establecimiento.');
    }
    return repository.addPurchase(
      Purchase(
        productoId: productoId,
        fecha: dateOnly(fecha ?? DateTime.now()),
        precio: (precio * 100).roundToDouble() / 100,
        establecimiento: store,
      ),
    );
  }

  /// Interpreta un precio escrito por el usuario: "2,35", "2.35", "1.234,50",
  /// "€ 3". Devuelve null si no es válido.
  static double? parsePrecio(String input) {
    var s = input.replaceAll(RegExp(r'[^\d.,]'), '');
    if (s.isEmpty) return null;
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    if (lastComma >= 0 && lastDot >= 0) {
      // El último separador es el decimal; el otro, de miles.
      if (lastComma > lastDot) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else {
      s = s.replaceAll(',', '.');
      // "1.234.5" no es válido; con un solo separador es decimal.
    }
    return double.tryParse(s);
  }
}
