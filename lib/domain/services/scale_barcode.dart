import 'barcode.dart';

/// Qué lleva incrustado una etiqueta de báscula.
enum ScaleFormat {
  /// Importe del paquete en céntimos ("01250" = 12,50 €).
  precio('precio'),

  /// Peso neto en gramos ("00850" = 0,850 kg).
  peso('peso');

  final String clave;

  const ScaleFormat(this.clave);

  static ScaleFormat? fromClave(String? clave) {
    for (final f in values) {
      if (f.clave == clave) return f;
    }
    return null;
  }
}

/// Etiqueta de báscula (EAN-13 de circulación restringida, prefijo 2): la
/// imprimen las balanzas de frescos con el importe o el peso del paquete.
///
/// Estructura habitual: `2X` + código de artículo + [dígito de control del
/// precio] + valor de 5 cifras + dígito de control. La parte fija que
/// identifica el producto ([clave]) son los primeros 7 dígitos, o los 6
/// primeros en las tiendas que usan dígito de control del precio en la
/// posición 7. El valor son siempre las cifras 8 a 12.
///
/// El formato no es igual en todos los supermercados y el mismo código
/// significa productos distintos en tiendas distintas: por eso el formato y
/// los productos se aprenden por tienda.
class ScaleLabel {
  final String codigo;

  /// Parte fija que identifica el producto en la tienda.
  final String clave;

  /// Cifras 8 a 12 (importe en céntimos o peso en gramos).
  final int valor;

  const ScaleLabel({
    required this.codigo,
    required this.clave,
    required this.valor,
  });

  /// Lectura del valor como importe (céntimos).
  int get comoPrecioCent => valor;

  /// Lectura del valor como peso (gramos).
  double get comoPesoG => valor.toDouble();

  /// Interpreta [code] con una clave de [longitudClave] dígitos (6 o 7).
  /// Null si no es una etiqueta de báscula válida.
  static ScaleLabel? parse(String code, {int longitudClave = 7}) {
    final c = normalizeBarcode(code);
    if (c == null || !isVariableMeasure(c) || !isValidGtin(c)) return null;
    final lon = (longitudClave == 6) ? 6 : 7;
    return ScaleLabel(
      codigo: c,
      clave: c.substring(0, lon),
      valor: int.parse(c.substring(7, 12)),
    );
  }

  /// Clave con la otra longitud (para detectar tiendas con dígito de control
  /// del precio: dos paquetes del mismo producto difieren en la cifra 7).
  String get claveCorta => codigo.substring(0, 6);
}

/// Importe en céntimos de un paquete pesado a [precioKiloCent] €/kg.
int priceForWeight(double pesoG, int precioKiloCent) =>
    (pesoG * precioKiloCent / 1000).round();

/// €/kg (céntimos) de un importe y un peso.
int? pricePerKilo(int precioCent, double? pesoG) {
  if (pesoG == null || pesoG <= 0) return null;
  return (precioCent * 1000 / pesoG).round();
}
