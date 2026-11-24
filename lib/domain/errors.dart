/// Errores de dominio que la UI puede mostrar tal cual al usuario.
library;

/// Ya existe un alimento con ese nombre en `db_alimentos` (columna UNIQUE).
class DuplicateFoodNameException implements Exception {
  final String name;

  const DuplicateFoodNameException(this.name);

  @override
  String toString() => 'Ya existe un alimento llamado "$name".';
}
