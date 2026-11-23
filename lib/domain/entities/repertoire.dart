import 'food.dart';
import 'recipe.dart';

/// Alimento de un repertorio compartible, con sus porciones y presentaciones.
/// [alimento.uuid] es obligatorio: es lo que permite fusionar sin duplicar.
class RepertoireFood {
  final Food alimento;
  final List<FoodPortion> porciones;
  final List<FoodPackage> presentaciones;

  const RepertoireFood({
    required this.alimento,
    this.porciones = const [],
    this.presentaciones = const [],
  });
}

/// Receta de un repertorio. Los ingredientes vinculados apuntan al alimento
/// por su uuid ([uuidsIngredientes], alineado con `receta.ingredientes`),
/// porque los ids locales no significan nada en otro móvil.
class RepertoireRecipe {
  final Recipe receta;
  final List<String?> uuidsIngredientes;

  const RepertoireRecipe({
    required this.receta,
    this.uuidsIngredientes = const [],
  });
}

/// Repertorio para compartir entre usuarios: alimentos (con códigos y
/// porciones) y, opcionalmente, recetas. Nunca lleva datos personales
/// (comidas, compras, precios, contadores de uso ni ajustes).
class Repertoire {
  final List<RepertoireFood> alimentos;
  final List<RepertoireRecipe> recetas;
  final DateTime? exportado;

  const Repertoire({
    this.alimentos = const [],
    this.recetas = const [],
    this.exportado,
  });

  bool get vacio => alimentos.isEmpty && recetas.isEmpty;
}

/// Qué hacer cuando un alimento importado y el local tienen valores
/// distintos para el mismo nutriente (los huecos siempre se rellenan).
enum ConflictPolicy {
  conservarMios('Conservar los míos'),
  usarImportados('Usar los importados');

  final String etiqueta;

  const ConflictPolicy(this.etiqueta);
}

/// Resultado (o vista previa) de importar un repertorio.
class ImportReport {
  int nuevos = 0;
  int completados = 0;
  int conflictos = 0;
  int sinCambios = 0;
  int codigosEnConflicto = 0;
  int recetasNuevas = 0;
  int recetasOmitidas = 0;

  /// Nombres de los alimentos con valores distintos (para mostrar).
  final List<String> nombresEnConflicto = [];

  int get totalAlimentos => nuevos + completados + conflictos + sinCambios;

  String get resumen {
    final partes = <String>[
      if (nuevos > 0) '$nuevos nuevos',
      if (completados > 0) '$completados completados',
      if (conflictos > 0) '$conflictos con valores distintos',
      if (sinCambios > 0) '$sinCambios ya estaban',
      if (recetasNuevas > 0) '$recetasNuevas recetas nuevas',
      if (recetasOmitidas > 0) '$recetasOmitidas recetas ya existían',
      if (codigosEnConflicto > 0)
        '$codigosEnConflicto códigos de barras en uso por otro alimento',
    ];
    return partes.isEmpty ? 'Nada que importar' : partes.join(' · ');
  }
}
