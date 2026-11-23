import '../entities/food.dart';
import '../entities/purchase.dart';
import '../services/scale_barcode.dart';

/// Producto de báscula reconocido en una tienda.
class ScaleMatch {
  final Store tienda;
  final Food alimento;
  final FoodPackage presentacion;

  const ScaleMatch(this.tienda, this.alimento, this.presentacion);
}

/// Etiquetas de báscula (frescos al peso): formato aprendido por tienda y
/// productos asociados a la parte fija de sus códigos.
abstract class ScaleRepository {
  /// Tienda por nombre (sin distinguir mayúsculas), creada si no existe.
  Future<Store> ensureStore(String nombre);
  Future<Store?> getStore(String nombre);

  Future<void> setScaleFormat(
    int storeId,
    ScaleFormat formato, {
    int? longitudClave,
  });

  /// Producto de la tienda con esa clave.
  Future<ScaleMatch?> findCode(int storeId, String clave);

  /// Productos de la tienda cuya clave empieza por [clave6] (sirve para
  /// detectar tiendas que usan 6 dígitos fijos).
  Future<List<ScaleMatch>> findByShortKey(int storeId, String clave6);

  /// En casa: busca el código en todas las tiendas, con la longitud de clave
  /// de cada una.
  Future<List<ScaleMatch>> findAnyStore(String codigo);

  /// La tienda pasa a usar claves de 6 dígitos (dígito de control del
  /// precio en la posición 7): recorta las claves ya aprendidas.
  Future<void> useShortKeys(int storeId);

  /// Asocia la clave a una presentación (reemplaza si ya existía).
  Future<void> saveCode(int storeId, String clave, int presentacionId);

  /// €/kg (céntimos) de la última compra pesada de la presentación,
  /// preferentemente en la tienda indicada.
  Future<int?> lastPricePerKiloCent(int presentacionId, {int? storeId});
}
