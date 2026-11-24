import '../entities/food.dart';
import '../entities/purchase.dart';
import '../repositories/food_repository.dart';
import '../repositories/scale_repository.dart';
import '../repositories/transaction_runner.dart';
import '../services/scale_barcode.dart';

/// Descripción de la presentación "al peso" de un alimento.
const String kPresentacionAlPeso = 'Al peso';

/// Lectura de una etiqueta de báscula con el formato de la tienda.
class ScaleReading {
  final ScaleLabel etiqueta;

  /// Importe del paquete (céntimos), si se conoce.
  final int? precioCent;

  /// Peso del paquete (g), si se conoce.
  final double? pesoG;

  /// €/kg usado para calcular el importe (formato peso).
  final int? precioKiloCent;

  const ScaleReading({
    required this.etiqueta,
    this.precioCent,
    this.pesoG,
    this.precioKiloCent,
  });
}

/// Interpreta el valor de la etiqueta: importe directo (formato precio) o
/// peso × €/kg conocido (formato peso; sin €/kg el importe queda por pedir).
ScaleReading readScaleLabel(
  ScaleLabel etiqueta,
  ScaleFormat formato, {
  int? precioKiloCent,
}) {
  switch (formato) {
    case ScaleFormat.precio:
      return ScaleReading(
        etiqueta: etiqueta,
        precioCent: etiqueta.comoPrecioCent,
      );
    case ScaleFormat.peso:
      final peso = etiqueta.comoPesoG;
      return ScaleReading(
        etiqueta: etiqueta,
        pesoG: peso,
        precioKiloCent: precioKiloCent,
        precioCent: precioKiloCent == null
            ? null
            : priceForWeight(peso, precioKiloCent),
      );
  }
}

/// Asocia la parte fija de una etiqueta de báscula de [tienda] a un
/// alimento (a su presentación "al peso", creada si no existe).
class LinkScaleCode {
  final FoodRepository foods;
  final ScaleRepository scale;
  final TransactionRunner tx;

  LinkScaleCode(this.foods, this.scale, this.tx);

  Future<ScaleMatch> call({
    required Store tienda,
    required String clave,
    required Food alimento,
  }) {
    return tx(() async {
      final packages = await foods.getPackages(alimento.id!);
      var pack = packages
          .where(
            (p) =>
                !p.archivado &&
                p.codigoBarras == null &&
                p.descripcion == kPresentacionAlPeso,
          )
          .firstOrNull;
      if (pack == null) {
        final id = await foods.savePackage(
          FoodPackage(
            alimentoId: alimento.id!,
            descripcion: kPresentacionAlPeso,
          ),
        );
        pack = await foods.getPackage(id);
      }
      await scale.saveCode(tienda.id!, clave, pack!.id!);
      return ScaleMatch(tienda, alimento, pack);
    });
  }
}
