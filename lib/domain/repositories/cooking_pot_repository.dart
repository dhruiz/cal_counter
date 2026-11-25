import '../entities/cooking_pot.dart';

/// Recipientes guardados (en los ajustes del dispositivo; viajan en el
/// respaldo completo).
abstract class CookingPotRepository {
  Future<List<CookingPot>> getAll();

  /// Guarda o sustituye (por nombre, sin distinguir mayúsculas).
  Future<List<CookingPot>> save(CookingPot pot);
  Future<List<CookingPot>> delete(String nombre);
}
