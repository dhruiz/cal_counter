class AppConstants {
  /// Catálogo base de alimentos genéricos (formato repertorio).
  static const String seedCatalogAsset = 'assets/semilla/alimentos_base.json';

  /// Frutas, verduras y hortalizas con la tabla de CIQUAL 2025 o USDA SR Legacy
  /// (formato repertorio). Se genera con
  /// `tool/semilla/generar_frutas_verduras.py`.
  static const String produceCatalogAsset =
      'assets/semilla/frutas_verduras.json';
}
