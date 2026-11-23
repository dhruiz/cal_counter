import '../entities/food.dart';

/// Ya existe un alimento con el mismo nombre y marca.
class DuplicateFoodException implements Exception {
  final Food existente;

  const DuplicateFoodException(this.existente);

  @override
  String toString() =>
      'Ya existe un alimento llamado "${existente.nombreCompleto}".';
}

/// El código de barras ya pertenece a otro alimento.
class DuplicateBarcodeException implements Exception {
  final String codigo;
  final Food propietario;

  const DuplicateBarcodeException(this.codigo, this.propietario);

  @override
  String toString() =>
      'El código $codigo ya pertenece a "${propietario.nombreCompleto}".';
}

/// Datos no válidos para una operación (mensaje para mostrar al usuario).
class ValidationException implements Exception {
  final String mensaje;

  const ValidationException(this.mensaje);

  @override
  String toString() => mensaje;
}
