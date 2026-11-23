import 'package:equatable/equatable.dart';

/// Receta personal del usuario.
///
/// [ingredientes] guarda cada línea tal cual la escribió el usuario
/// ("200 g de arroz"); el nombre normalizado para buscar se calcula al vuelo
/// con `ingredient_matcher.dart`, así que mejorar el parser no exige migrar
/// datos. [elaboracion] es texto libre: un paso por línea.
class Recipe extends Equatable {
  final int? id;
  final String nombre;
  final String? categoria;
  final int? porciones;
  final int? tiempoMin;
  final List<String> ingredientes;
  final String elaboracion;
  final String? notas;
  final bool favorita;

  /// Vínculo opcional a `db_alimentos` (p. ej. un alimento creado con
  /// "Guardar comida como alimento") para mostrar calorías y registrar porciones.
  final int? alimentoId;

  /// Gramos de una porción, para "Registrar porción" en el contador.
  final double? pesoPorcionG;

  const Recipe({
    this.id,
    required this.nombre,
    this.categoria,
    this.porciones,
    this.tiempoMin,
    this.ingredientes = const [],
    this.elaboracion = '',
    this.notas,
    this.favorita = false,
    this.alimentoId,
    this.pesoPorcionG,
  });

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
    List<String>? ingredientes,
    String? elaboracion,
    String? notas,
    bool? favorita,
    int? alimentoId,
    double? pesoPorcionG,
    bool clearAlimento = false,
  }) {
    return Recipe(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      porciones: porciones ?? this.porciones,
      tiempoMin: tiempoMin ?? this.tiempoMin,
      ingredientes: ingredientes ?? this.ingredientes,
      elaboracion: elaboracion ?? this.elaboracion,
      notas: notas ?? this.notas,
      favorita: favorita ?? this.favorita,
      alimentoId: clearAlimento ? null : (alimentoId ?? this.alimentoId),
      pesoPorcionG: clearAlimento ? null : (pesoPorcionG ?? this.pesoPorcionG),
    );
  }

  @override
  List<Object?> get props => [
    id,
    nombre,
    categoria,
    porciones,
    tiempoMin,
    ingredientes,
    elaboracion,
    notas,
    favorita,
    alimentoId,
    pesoPorcionG,
  ];
}
