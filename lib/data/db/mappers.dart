import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/food.dart';
import '../../domain/entities/meal_item.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/dates.dart';
import 'app_database.dart';

const Uuid _uuid = Uuid();

/// UUID v4 nuevo (identidad global de alimentos, presentaciones y recetas).
String newUuid() => _uuid.v4();

/// Marca de tiempo ISO 8601 para columnas `creado`/`actualizado`.
String nowIso() => DateTime.now().toIso8601String();

DateTime? parseIso(String? s) => s == null ? null : DateTime.tryParse(s);

/// Fecha `YYYY-MM-DD` → DateTime (medianoche local).
DateTime parseDay(String s) {
  final p = s.split('-');
  if (p.length != 3) return DateTime.parse(s);
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String dayKey(DateTime d) => dateKey(d);

// Alimentos ------------------------------------------------------------------

Food foodFromRow(AlimentoRow r) => Food(
  id: r.id,
  uuid: r.uuid,
  nombre: r.nombre,
  marca: r.marca,
  tipo: FoodType.fromClave(r.tipo),
  unidad: FoodUnit.fromClave(r.unidad),
  nutricion: NutritionFacts(
    kcal: r.kcal,
    proteinas: r.proteinas,
    grasas: r.grasas,
    grasasSaturadas: r.grasasSaturadas,
    carbohidratos: r.carbohidratos,
    azucares: r.azucares,
    fibra: r.fibra,
    sal: r.sal,
  ),
  origenNutricion: NutritionSource.fromClave(r.nutricionOrigen),
  notas: r.notas,
  usoCount: r.usoCount,
  ultimoUso: parseIso(r.ultimoUso),
  archivado: r.archivado,
  creado: parseIso(r.creado),
  actualizado: parseIso(r.actualizado),
);

/// Campos editables del alimento (sin uuid, uso ni fechas).
AlimentosCompanion foodToCompanion(Food f) {
  final n = f.nutricion;
  final notas = f.notas?.trim();
  return AlimentosCompanion(
    nombre: Value(f.nombre.trim()),
    marca: Value(f.marca.trim()),
    tipo: Value(f.tipo.clave),
    unidad: Value(f.unidad.clave),
    kcal: Value(n.kcal),
    proteinas: Value(n.proteinas),
    grasas: Value(n.grasas),
    grasasSaturadas: Value(n.grasasSaturadas),
    carbohidratos: Value(n.carbohidratos),
    azucares: Value(n.azucares),
    fibra: Value(n.fibra),
    sal: Value(n.sal),
    nutricionOrigen: Value(n.estaVacia ? null : f.origenNutricion?.clave),
    notas: Value((notas == null || notas.isEmpty) ? null : notas),
    archivado: Value(f.archivado),
  );
}

FoodPortion portionFromRow(PorcionRow r) => FoodPortion(
  id: r.id,
  alimentoId: r.alimentoId,
  nombre: r.nombre,
  gramos: r.gramos,
);

FoodPackage packageFromRow(PresentacionRow r) => FoodPackage(
  id: r.id,
  uuid: r.uuid,
  alimentoId: r.alimentoId,
  codigoBarras: r.codigoBarras,
  descripcion: r.descripcion,
  contenido: r.contenido,
  archivado: r.archivado,
);

// Compras --------------------------------------------------------------------

Purchase purchaseFromRows(CompraRow c, EstablecimientoRow e) => Purchase(
  id: c.id,
  presentacionId: c.presentacionId,
  fecha: parseDay(c.fecha),
  precioCent: c.precioCent,
  unidades: c.unidades,
  establecimiento: e.nombre,
);

// Recetas --------------------------------------------------------------------

RecipeIngredient ingredientFromRow(IngredienteRecetaRow r) => RecipeIngredient(
  id: r.id,
  texto: r.texto,
  alimentoId: r.alimentoId,
  cantidad: r.cantidad,
  unidad: r.unidad,
  opcional: r.opcional,
);

Recipe recipeFromRow(RecetaRow r, List<RecipeIngredient> ingredientes) =>
    Recipe(
      id: r.id,
      uuid: r.uuid,
      nombre: r.nombre,
      categoria: r.categoria,
      porciones: r.porciones,
      tiempoMin: r.tiempoMin,
      ingredientes: ingredientes,
      elaboracion: r.elaboracion,
      notas: r.notas,
      favorita: r.favorita,
      pesoFinalG: r.pesoFinalG,
      alimentoId: r.alimentoId,
    );

// Comidas --------------------------------------------------------------------

MealItem mealItemFromRow(ItemComidaRow r) => MealItem(
  id: r.id,
  mealId: r.comidaId,
  alimentoId: r.alimentoId,
  alimento: r.nombre,
  cantidad: r.cantidad,
  grasas: r.grasas,
  carbohidratos: r.carbohidratos,
  proteinas: r.proteinas,
  kcal: r.kcal,
);

/// Texto opcional: '' → null.
String? emptyToNull(String? s) {
  final t = s?.trim();
  return (t == null || t.isEmpty) ? null : t;
}
