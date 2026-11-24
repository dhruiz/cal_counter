import 'package:equatable/equatable.dart';

/// Categoría de alimentos (sección del supermercado). [orden] es el orden
/// general de los pasillos; cada tienda puede tener el suyo.
class Category extends Equatable {
  final int? id;
  final String nombre;
  final int orden;

  const Category({this.id, required this.nombre, this.orden = 0});

  Category copyWith({String? nombre, int? orden}) => Category(
    id: id,
    nombre: nombre ?? this.nombre,
    orden: orden ?? this.orden,
  );

  @override
  List<Object?> get props => [id, nombre, orden];
}

/// Gasto acumulado de una categoría en un periodo.
class CategorySpending extends Equatable {
  /// Null = sin categoría.
  final Category? categoria;
  final int totalCent;
  final int compras;

  const CategorySpending({
    required this.categoria,
    required this.totalCent,
    required this.compras,
  });

  @override
  List<Object?> get props => [categoria, totalCent, compras];
}
