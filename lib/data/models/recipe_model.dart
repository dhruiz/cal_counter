import '../../domain/entities/recipe.dart';

/// Serializa filas de `recetas` ↔ [Recipe]. Los ingredientes viven en
/// `ingredientes_receta` y se pasan aparte.
class RecipeModel {
  static Recipe fromMap(Map<String, dynamic> m, List<String> ingredientes) {
    return Recipe(
      id: m['id'] as int?,
      nombre: m['nombre'] as String,
      categoria: m['categoria'] as String?,
      porciones: m['porciones'] as int?,
      tiempoMin: m['tiempo_min'] as int?,
      ingredientes: ingredientes,
      elaboracion: (m['elaboracion'] as String?) ?? '',
      notas: m['notas'] as String?,
      favorita: (m['favorita'] as int? ?? 0) == 1,
      alimentoId: m['alimento_id'] as int?,
      pesoPorcionG: (m['peso_porcion_g'] as num?)?.toDouble(),
    );
  }

  /// Columnas editables (sin id ni marcas de tiempo).
  static Map<String, dynamic> toMap(Recipe r) {
    return {
      'nombre': r.nombre.trim(),
      'categoria': _nullIfBlank(r.categoria),
      'porciones': r.porciones,
      'tiempo_min': r.tiempoMin,
      'elaboracion': r.elaboracion.trim(),
      'notas': _nullIfBlank(r.notas),
      'favorita': r.favorita ? 1 : 0,
      'alimento_id': r.alimentoId,
      'peso_porcion_g': r.alimentoId == null ? null : r.pesoPorcionG,
    };
  }
}

String? _nullIfBlank(String? s) =>
    (s == null || s.trim().isEmpty) ? null : s.trim();
