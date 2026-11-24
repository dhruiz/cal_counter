import 'package:equatable/equatable.dart';

/// Línea de ingrediente de una receta.
///
/// [texto] es la línea tal cual la escribió el usuario ("2 dientes de ajo") y
/// siempre se conserva. Opcionalmente se vincula a un alimento del repertorio
/// con una cantidad y unidad (`g`, `ml` o el nombre de una porción del
/// alimento, p. ej. "diente"), lo que permite calcular la nutrición.
class RecipeIngredient extends Equatable {
  final int? id;
  final String texto;
  final int? alimentoId;
  final double? cantidad;
  final String? unidad;
  final bool opcional;

  /// Nota de la línea ("picada", "en dados"); forma parte de [texto].
  final String? nota;

  const RecipeIngredient({
    this.id,
    required this.texto,
    this.alimentoId,
    this.cantidad,
    this.unidad,
    this.opcional = false,
    this.nota,
  });

  bool get vinculado => alimentoId != null;

  RecipeIngredient copyWith({
    String? texto,
    int? alimentoId,
    double? cantidad,
    String? unidad,
    bool? opcional,
    String? nota,
    bool clearCantidad = false,
    bool desvincular = false,
  }) {
    return RecipeIngredient(
      id: id,
      texto: texto ?? this.texto,
      alimentoId: desvincular ? null : (alimentoId ?? this.alimentoId),
      cantidad: (desvincular || clearCantidad)
          ? null
          : (cantidad ?? this.cantidad),
      unidad: desvincular ? null : (unidad ?? this.unidad),
      opcional: opcional ?? this.opcional,
      nota: nota ?? this.nota,
    );
  }

  @override
  List<Object?> get props => [
    id,
    texto,
    alimentoId,
    cantidad,
    unidad,
    opcional,
    nota,
  ];
}

/// Receta personal del usuario.
///
/// El nombre normalizado de cada ingrediente para buscar se calcula al vuelo
/// con `ingredient_matcher.dart`. [elaboracion] es texto libre: un paso por
/// línea.
class Recipe extends Equatable {
  final int? id;
  final String? uuid;
  final String nombre;
  final String? categoria;
  final int? porciones;
  final int? tiempoMin;
  final List<RecipeIngredient> ingredientes;
  final String elaboracion;
  final String? notas;
  final bool favorita;

  /// Peso de la preparación ya cocinada (opcional; si falta se usa la suma de
  /// los ingredientes).
  final double? pesoFinalG;

  /// Alimento "preparado" que representa la receta en el repertorio. Se
  /// crea y actualiza solo (`SyncRecipeFoods`).
  final int? alimentoId;

  /// Último día en que se preparó (al introducir el peso final).
  final DateTime? ultimaPreparacion;

  const Recipe({
    this.id,
    this.uuid,
    required this.nombre,
    this.categoria,
    this.porciones,
    this.tiempoMin,
    this.ingredientes = const [],
    this.elaboracion = '',
    this.notas,
    this.favorita = false,
    this.pesoFinalG,
    this.alimentoId,
    this.ultimaPreparacion,
  });

  /// Crea una receta a partir de líneas de texto (formularios, importación).
  factory Recipe.desdeLineas({
    int? id,
    required String nombre,
    String? categoria,
    int? porciones,
    int? tiempoMin,
    List<String> lineas = const [],
    String elaboracion = '',
    String? notas,
    bool favorita = false,
  }) {
    return Recipe(
      id: id,
      nombre: nombre,
      categoria: categoria,
      porciones: porciones,
      tiempoMin: tiempoMin,
      ingredientes: [for (final l in lineas) RecipeIngredient(texto: l)],
      elaboracion: elaboracion,
      notas: notas,
      favorita: favorita,
    );
  }

  /// Las líneas de ingredientes tal cual se escribieron.
  List<String> get lineas => [for (final i in ingredientes) i.texto];

  /// Pasos de la elaboración (líneas no vacías).
  List<String> get pasos => elaboracion
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  Recipe copyWith({
    int? id,
    String? nombre,
    String? categoria,
    int? porciones,
    int? tiempoMin,
    List<RecipeIngredient>? ingredientes,
    String? elaboracion,
    String? notas,
    bool? favorita,
    double? pesoFinalG,
    bool clearPesoFinal = false,
    int? alimentoId,
    bool clearAlimento = false,
    DateTime? ultimaPreparacion,
  }) {
    return Recipe(
      id: id ?? this.id,
      uuid: uuid,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      porciones: porciones ?? this.porciones,
      tiempoMin: tiempoMin ?? this.tiempoMin,
      ingredientes: ingredientes ?? this.ingredientes,
      elaboracion: elaboracion ?? this.elaboracion,
      notas: notas ?? this.notas,
      favorita: favorita ?? this.favorita,
      pesoFinalG: clearPesoFinal ? null : (pesoFinalG ?? this.pesoFinalG),
      alimentoId: clearAlimento ? null : (alimentoId ?? this.alimentoId),
      ultimaPreparacion: ultimaPreparacion ?? this.ultimaPreparacion,
    );
  }

  @override
  List<Object?> get props => [
    id,
    uuid,
    nombre,
    categoria,
    porciones,
    tiempoMin,
    ingredientes,
    elaboracion,
    notas,
    favorita,
    pesoFinalG,
    alimentoId,
    ultimaPreparacion,
  ];
}
