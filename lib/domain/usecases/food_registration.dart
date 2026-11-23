import '../entities/food.dart';
import '../errors/domain_errors.dart';
import '../repositories/food_repository.dart';
import '../repositories/transaction_runner.dart';
import '../services/barcode.dart';

/// Datos de la presentación con la que se da de alta un alimento.
class PackageDraft {
  final String? codigoBarras;
  final String descripcion;
  final double? contenido;

  const PackageDraft({
    this.codigoBarras,
    this.descripcion = '',
    this.contenido,
  });

  bool get vacia =>
      normalizeBarcode(codigoBarras) == null &&
      descripcion.trim().isEmpty &&
      (contenido ?? 0) <= 0;
}

/// Alta mínima EN LA TIENDA: nombre, marca y presentación (con el código
/// escaneado). Nunca pide la tabla nutricional: el alimento queda pendiente
/// de completar en casa. Todo en una transacción.
///
/// - Con [alimentoExistenteId] el código se añade como otra presentación de
///   ese alimento ("es otra presentación de…").
/// - Si ya existe un alimento con el mismo nombre y marca, se reutiliza.
class RegisterFoodInStore {
  final FoodRepository foods;
  final TransactionRunner tx;

  RegisterFoodInStore(this.foods, this.tx);

  Future<BarcodeMatch> call({
    required String nombre,
    String marca = '',
    FoodUnit unidad = FoodUnit.g,
    PackageDraft presentacion = const PackageDraft(),
    int? alimentoExistenteId,
  }) {
    return tx(() async {
      int alimentoId;
      if (alimentoExistenteId != null) {
        alimentoId = alimentoExistenteId;
      } else {
        if (nombre.trim().isEmpty) {
          throw const ValidationException('Escribe el nombre del producto.');
        }
        final conCodigo = normalizeBarcode(presentacion.codigoBarras) != null;
        final food = Food(
          nombre: nombre.trim(),
          marca: marca.trim(),
          tipo: (conCodigo || marca.trim().isNotEmpty)
              ? FoodType.envasado
              : FoodType.generico,
          unidad: unidad,
        );
        try {
          alimentoId = await foods.saveFood(food);
        } on DuplicateFoodException catch (e) {
          alimentoId = e.existente.id!;
          if (e.existente.archivado) {
            await foods.setArchived(alimentoId, false);
          }
        }
      }
      final packageId = await foods.savePackage(
        FoodPackage(
          alimentoId: alimentoId,
          codigoBarras: presentacion.codigoBarras,
          descripcion: presentacion.descripcion,
          contenido: presentacion.contenido,
        ),
      );
      final food = await foods.getFood(alimentoId);
      final package = await foods.getPackage(packageId);
      return BarcodeMatch(food!, package!);
    });
  }
}

/// Alta o edición EN CASA de un alimento completo y, opcionalmente, de una
/// presentación con su código (en la misma transacción). Devuelve el id del
/// alimento.
class SaveFoodWithPackage {
  final FoodRepository foods;
  final TransactionRunner tx;

  SaveFoodWithPackage(this.foods, this.tx);

  Future<int> call(Food food, {PackageDraft? presentacion}) {
    return tx(() async {
      final id = await foods.saveFood(food);
      final p = presentacion;
      if (p != null && !p.vacia) {
        await foods.savePackage(
          FoodPackage(
            alimentoId: id,
            codigoBarras: p.codigoBarras,
            descripcion: p.descripcion,
            contenido: p.contenido,
          ),
        );
      }
      return id;
    });
  }
}
