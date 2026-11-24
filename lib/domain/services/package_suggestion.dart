import '../entities/food.dart';

/// Envases que cubren una cantidad mínima: "1 × Paquete 1 kg".
class PackageSuggestion {
  final FoodPackage presentacion;
  final int unidades;

  const PackageSuggestion(this.presentacion, this.unidades);

  /// Cantidad total que se compra (g o ml).
  double get total => unidades * presentacion.contenido!;
}

/// Presentación (con contenido conocido) que cubre [minimo] con menos
/// sobrante; a igualdad, la que necesita menos unidades. Null si ninguna
/// tiene contenido.
PackageSuggestion? suggestPackage(
  double minimo,
  List<FoodPackage> presentaciones,
) {
  if (minimo <= 0) return null;
  PackageSuggestion? mejor;
  double? mejorSobra;
  for (final p in presentaciones) {
    final c = p.contenido;
    if (p.archivado || c == null || c <= 0) continue;
    var n = (minimo / c).ceil();
    if (n < 1) n = 1;
    final sobra = n * c - minimo;
    final s = PackageSuggestion(p, n);
    if (mejor == null ||
        sobra < mejorSobra! - 1e-9 ||
        ((sobra - mejorSobra).abs() < 1e-9 && n < mejor.unidades)) {
      mejor = s;
      mejorSobra = sobra;
    }
  }
  return mejor;
}
