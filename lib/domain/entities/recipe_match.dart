import 'package:equatable/equatable.dart';
import 'recipe.dart';

/// Resultado de buscar recetas por ingredientes disponibles.
class RecipeMatch extends Equatable {
  final Recipe recipe;

  /// Líneas de ingredientes (no opcionales) que el usuario tiene.
  final List<String> disponibles;

  /// Líneas de ingredientes (no opcionales) que le faltan.
  final List<String> faltantes;

  const RecipeMatch({
    required this.recipe,
    required this.disponibles,
    required this.faltantes,
  });

  int get totalRequeridos => disponibles.length + faltantes.length;

  /// Se puede preparar con lo que hay (todos los no opcionales cubiertos).
  bool get completa => faltantes.isEmpty && disponibles.isNotEmpty;

  double get cobertura =>
      totalRequeridos == 0 ? 0 : disponibles.length / totalRequeridos;

  @override
  List<Object?> get props => [recipe, disponibles, faltantes];
}
