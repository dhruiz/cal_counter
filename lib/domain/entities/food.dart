import 'package:equatable/equatable.dart';
import 'nutrition_facts.dart';

/// Clase de alimento del repertorio.
enum FoodType {
  /// Alimento sin marca ("Plátano", "Arroz blanco").
  generico('generico', 'Genérico'),

  /// Producto envasado de una marca, normalmente con código de barras.
  envasado('envasado', 'Envasado'),

  /// Preparación casera (receta o comida guardada como alimento).
  preparado('preparado', 'Preparado');

  final String clave;
  final String etiqueta;

  const FoodType(this.clave, this.etiqueta);

  static FoodType fromClave(String? clave) => values.firstWhere(
    (t) => t.clave == clave,
    orElse: () => FoodType.generico,
  );
}

/// Unidad base del alimento: la tabla nutricional es por 100 de esta unidad
/// y las cantidades se escriben en ella.
enum FoodUnit {
  g('g'),
  ml('ml');

  final String clave;

  const FoodUnit(this.clave);

  static FoodUnit fromClave(String? clave) =>
      clave == 'ml' ? FoodUnit.ml : FoodUnit.g;
}

/// Alimento del repertorio: el núcleo de la app. Recetas, compras, listas y
/// comidas apuntan a él.
class Food extends Equatable {
  final int? id;

  /// Identificador global para fusionar repertorios entre usuarios. Null en
  /// un alimento aún no guardado (el repositorio lo genera).
  final String? uuid;
  final String nombre;

  /// '' = genérico (sin marca).
  final String marca;
  final FoodType tipo;
  final FoodUnit unidad;

  /// Sección del súper (null = sin categoría).
  final int? categoriaId;

  /// Por 100 g/ml. Los valores desconocidos son null.
  final NutritionFacts nutricion;
  final NutritionSource? origenNutricion;
  final String? notas;
  final int usoCount;
  final DateTime? ultimoUso;
  final bool archivado;
  final DateTime? creado;
  final DateTime? actualizado;

  /// La tabla es una aproximación: es el alimento de una receta sin peso
  /// final o con ingredientes sin datos.
  final bool aproximado;

  /// false = artículo que no es un alimento (limpieza, higiene...): se compra
  /// y tiene historial de precios, pero no tabla nutricional ni contador.
  final bool esAlimento;

  const Food({
    this.id,
    this.uuid,
    required this.nombre,
    this.marca = '',
    this.tipo = FoodType.generico,
    this.unidad = FoodUnit.g,
    this.categoriaId,
    this.nutricion = NutritionFacts.vacia,
    this.origenNutricion,
    this.notas,
    this.usoCount = 0,
    this.ultimoUso,
    this.archivado = false,
    this.creado,
    this.actualizado,
    this.aproximado = false,
    this.esAlimento = true,
  });

  /// Le faltan datos nutricionales esenciales: no se puede registrar en el
  /// contador hasta completarlo. Un artículo que no es un alimento nunca
  /// está pendiente (no tiene tabla).
  bool get pendiente => esAlimento && !nutricion.estaCompleta;

  /// "Leche semidesnatada · Hacendado" (o solo el nombre si es genérico).
  String get nombreCompleto =>
      marca.trim().isEmpty ? nombre : '$nombre · ${marca.trim()}';

  /// "g" o "ml".
  String get u => unidad.clave;

  Food copyWith({
    int? id,
    String? uuid,
    String? nombre,
    String? marca,
    FoodType? tipo,
    FoodUnit? unidad,
    int? categoriaId,
    bool clearCategoria = false,
    NutritionFacts? nutricion,
    NutritionSource? origenNutricion,
    bool clearOrigen = false,
    String? notas,
    int? usoCount,
    DateTime? ultimoUso,
    bool? archivado,
    bool? aproximado,
    bool? esAlimento,
  }) {
    return Food(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      nombre: nombre ?? this.nombre,
      marca: marca ?? this.marca,
      tipo: tipo ?? this.tipo,
      unidad: unidad ?? this.unidad,
      categoriaId: clearCategoria ? null : (categoriaId ?? this.categoriaId),
      nutricion: nutricion ?? this.nutricion,
      origenNutricion: clearOrigen
          ? null
          : (origenNutricion ?? this.origenNutricion),
      notas: notas ?? this.notas,
      usoCount: usoCount ?? this.usoCount,
      ultimoUso: ultimoUso ?? this.ultimoUso,
      archivado: archivado ?? this.archivado,
      creado: creado,
      actualizado: actualizado,
      aproximado: aproximado ?? this.aproximado,
      esAlimento: esAlimento ?? this.esAlimento,
    );
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    nombre,
    marca,
    tipo,
    unidad,
    categoriaId,
    nutricion,
    origenNutricion,
    notas,
    usoCount,
    ultimoUso,
    archivado,
    aproximado,
    esAlimento,
  ];
}

/// Equivalencia casera: "1 huevo = 60 g", "1 diente = 5 g".
class FoodPortion extends Equatable {
  final int? id;
  final int? alimentoId;
  final String nombre;
  final double gramos;

  const FoodPortion({
    this.id,
    this.alimentoId,
    required this.nombre,
    required this.gramos,
  });

  @override
  List<Object?> get props => [id, alimentoId, nombre, gramos];
}

/// Presentación comercial de un alimento ("Brick 1 L", "Pack 6 × 125 g").
/// Aquí viven el código de barras y, a través de las compras, el precio.
class FoodPackage extends Equatable {
  final int? id;
  final String? uuid;
  final int alimentoId;

  /// GTIN normalizado (ver `barcode.dart`). Null = granel o sin código.
  final String? codigoBarras;
  final String descripcion;

  /// Contenido neto total en la unidad del alimento (g o ml).
  final double? contenido;
  final bool archivado;

  const FoodPackage({
    this.id,
    this.uuid,
    required this.alimentoId,
    this.codigoBarras,
    this.descripcion = '',
    this.contenido,
    this.archivado = false,
  });

  FoodPackage copyWith({
    int? id,
    int? alimentoId,
    String? codigoBarras,
    bool clearCodigo = false,
    String? descripcion,
    double? contenido,
    bool clearContenido = false,
    bool? archivado,
  }) {
    return FoodPackage(
      id: id ?? this.id,
      uuid: uuid,
      alimentoId: alimentoId ?? this.alimentoId,
      codigoBarras: clearCodigo ? null : (codigoBarras ?? this.codigoBarras),
      descripcion: descripcion ?? this.descripcion,
      contenido: clearContenido ? null : (contenido ?? this.contenido),
      archivado: archivado ?? this.archivado,
    );
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    alimentoId,
    codigoBarras,
    descripcion,
    contenido,
    archivado,
  ];
}

/// Resultado de buscar por código de barras.
class BarcodeMatch extends Equatable {
  final Food food;
  final FoodPackage package;

  const BarcodeMatch(this.food, this.package);

  @override
  List<Object?> get props => [food, package];
}
