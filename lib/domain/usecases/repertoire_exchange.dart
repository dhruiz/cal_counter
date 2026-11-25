import '../entities/category.dart';
import '../entities/food.dart';
import '../entities/nutrition_facts.dart';
import '../entities/recipe.dart';
import '../entities/repertoire.dart';
import '../errors/domain_errors.dart';
import '../repositories/category_repository.dart';
import '../repositories/food_repository.dart';
import '../repositories/recipe_repository.dart';
import '../repositories/transaction_runner.dart';
import '../services/barcode.dart';
import '../services/ingredient_matcher.dart';
import '../services/quantity_parser.dart';

/// Construye el repertorio compartible: alimentos no archivados con sus
/// porciones y presentaciones y, si se pide, las recetas.
class ExportRepertoire {
  final FoodRepository foods;
  final RecipeRepository recipes;
  final CategoryRepository? categories;

  ExportRepertoire(this.foods, this.recipes, [this.categories]);

  Future<Repertoire> call({bool incluirRecetas = false}) async {
    final all = await foods.getAllFoods();
    final nombreCategoria = {
      for (final c in await categories?.getCategories() ?? const <Category>[])
        c.id: c.nombre,
    };
    final ids = [for (final f in all) f.id!];
    final porciones = await foods.getPortionsFor(ids);
    final presentaciones = await foods.getPackagesFor(ids);
    final uuidPorId = {for (final f in all) f.id!: f.uuid};

    final recetas = <RepertoireRecipe>[];
    if (incluirRecetas) {
      for (final r in await recipes.getAll()) {
        recetas.add(
          RepertoireRecipe(
            receta: r,
            uuidsIngredientes: [
              for (final i in r.ingredientes)
                i.alimentoId == null ? null : uuidPorId[i.alimentoId],
            ],
          ),
        );
      }
    }
    return Repertoire(
      exportado: DateTime.now(),
      alimentos: [
        for (final f in all)
          RepertoireFood(
            alimento: f,
            categoria: nombreCategoria[f.categoriaId],
            porciones: porciones[f.id] ?? const [],
            presentaciones: [
              for (final p in presentaciones[f.id] ?? const <FoodPackage>[])
                if (!p.archivado) p,
            ],
          ),
      ],
      recetas: recetas,
    );
  }
}

/// Fusiona un repertorio con el local, en una sola transacción (o todo o
/// nada). Con [dryRun] solo calcula la vista previa, sin escribir.
///
/// Emparejamiento de cada alimento: mismo uuid → mismo código de barras →
/// mismo nombre y marca (sin tildes ni mayúsculas).
/// - Sin pareja: se crea conservando su uuid.
/// - Con pareja: se rellenan los huecos; si ambos tienen valores distintos
///   se aplica [ConflictPolicy]. Porciones y códigos nuevos se añaden; un
///   código que ya es de otro alimento se ignora (y se cuenta).
/// Las recetas se emparejan por uuid o nombre; las existentes se omiten.
class ImportRepertoire {
  final FoodRepository foods;
  final RecipeRepository recipes;
  final TransactionRunner tx;

  /// Para asignar la categoría por nombre (se crea si no existe).
  final CategoryRepository? categories;

  ImportRepertoire(this.foods, this.recipes, this.tx, [this.categories]);

  Future<ImportReport> call(
    Repertoire rep, {
    ConflictPolicy politica = ConflictPolicy.conservarMios,
    bool dryRun = false,
  }) async {
    if (dryRun) return _process(rep, politica, escribir: false);
    return tx(() => _process(rep, politica, escribir: true));
  }

  Future<Food?> _match(RepertoireFood rf) async {
    final a = rf.alimento;
    if (a.uuid != null) {
      final byUuid = await foods.findByUuid(a.uuid!);
      if (byUuid != null) return byUuid;
    }
    for (final p in rf.presentaciones) {
      final code = normalizeBarcode(p.codigoBarras);
      if (code == null) continue;
      final m = await foods.findByBarcode(code);
      if (m != null) return m.food;
    }
    return foods.findByNameAndBrand(a.nombre, a.marca);
  }

  static bool _distintos(NutritionFacts a, NutritionFacts b) {
    for (final n in Nutrient.values) {
      final x = a[n], y = b[n];
      if (x != null && y != null && (x - y).abs() > 0.01) return true;
    }
    return false;
  }

  Future<ImportReport> _process(
    Repertoire rep,
    ConflictPolicy politica, {
    required bool escribir,
  }) async {
    final report = ImportReport();
    final idPorUuid = <String, int>{};
    final codigosUsados = <String>{};
    final categoriaPorNombre = {
      for (final c in await categories?.getCategories() ?? const <Category>[])
        normalizeText(c.nombre): c.id!,
    };
    Future<int?> categoriaDe(String? nombre) async {
      final key = normalizeText(nombre ?? '');
      if (key.isEmpty || categories == null) return null;
      final id = categoriaPorNombre[key];
      if (id != null || !escribir) return id;
      final nueva = await categories!.saveCategory(
        Category(nombre: nombre!.trim()),
      );
      categoriaPorNombre[key] = nueva;
      return nueva;
    }

    for (final rf in rep.alimentos) {
      final imp = rf.alimento;
      if (imp.nombre.trim().isEmpty) continue;
      final local = await _match(rf);
      int? id = local?.id;

      if (local == null) {
        report.nuevos++;
        if (escribir) {
          try {
            id = await foods.saveFood(
              Food(
                uuid: imp.uuid,
                nombre: imp.nombre,
                marca: imp.marca,
                tipo: imp.tipo,
                unidad: imp.unidad,
                categoriaId: await categoriaDe(rf.categoria),
                nutricion: imp.nutricion,
                origenNutricion: imp.nutricion.estaVacia
                    ? null
                    : (imp.origenNutricion ?? NutritionSource.importado),
                notas: imp.notas,
                aproximado: imp.aproximado,
                esAlimento: imp.esAlimento,
              ),
            );
          } on DuplicateFoodException catch (e) {
            id = e.existente.id; // repetido dentro del mismo archivo
          }
        }
      } else {
        final merged = politica == ConflictPolicy.conservarMios
            ? local.nutricion.completadaCon(imp.nutricion)
            : imp.nutricion.completadaCon(local.nutricion);
        final conflicto = _distintos(local.nutricion, imp.nutricion);
        final cambia = merged != local.nutricion;
        if (conflicto) {
          report.conflictos++;
          report.nombresEnConflicto.add(local.nombreCompleto);
        } else if (cambia) {
          report.completados++;
        } else {
          report.sinCambios++;
        }
        final notas = (local.notas ?? '').isEmpty ? imp.notas : local.notas;
        final categoria =
            local.categoriaId ??
            (escribir ? await categoriaDe(rf.categoria) : null);
        if (escribir &&
            (cambia ||
                notas != local.notas ||
                local.archivado ||
                categoria != local.categoriaId)) {
          await foods.saveFood(
            local.copyWith(
              categoriaId: categoria,
              nutricion: merged,
              origenNutricion: cambia
                  ? (local.origenNutricion ?? NutritionSource.importado)
                  : local.origenNutricion,
              notas: notas,
              archivado: false,
            ),
          );
        }
      }
      if (imp.uuid != null && id != null) idPorUuid[imp.uuid!] = id;

      // Porciones y presentaciones (solo al escribir y con alimento local).
      if (id == null) {
        for (final p in rf.presentaciones) {
          final code = normalizeBarcode(p.codigoBarras);
          if (code == null) continue;
          final m = await foods.findByBarcode(code);
          if (m != null && m.food.id != local?.id) report.codigosEnConflicto++;
        }
        continue;
      }
      final porcionesLocales =
          (await foods.getPortionsFor([id]))[id] ?? const <FoodPortion>[];
      final nombres = {
        for (final p in porcionesLocales) canonicalPortionName(p.nombre),
      };
      for (final p in rf.porciones) {
        if (!nombres.add(canonicalPortionName(p.nombre))) continue;
        if (escribir) {
          await foods.savePortion(
            FoodPortion(alimentoId: id, nombre: p.nombre, gramos: p.gramos),
          );
        }
      }
      final presentacionesLocales = await foods.getPackages(id);
      for (final p in rf.presentaciones) {
        final code = normalizeBarcode(p.codigoBarras);
        if (code != null) {
          if (!codigosUsados.add(code)) continue;
          final m = await foods.findByBarcode(code);
          if (m != null) {
            if (m.food.id != id) report.codigosEnConflicto++;
            continue;
          }
        } else {
          final misma = presentacionesLocales.any(
            (l) =>
                l.codigoBarras == null &&
                normalizeText(l.descripcion) == normalizeText(p.descripcion),
          );
          if (misma || p.descripcion.trim().isEmpty) continue;
        }
        if (escribir) {
          await foods.savePackage(
            FoodPackage(
              uuid: p.uuid,
              alimentoId: id,
              codigoBarras: code,
              descripcion: p.descripcion,
              contenido: p.contenido,
            ),
          );
        }
      }
    }

    // Recetas.
    if (rep.recetas.isNotEmpty) {
      final existentes = await recipes.getAll();
      final uuids = {for (final r in existentes) r.uuid};
      final nombres = {for (final r in existentes) normalizeText(r.nombre)};
      for (final rr in rep.recetas) {
        final r = rr.receta;
        final key = normalizeText(r.nombre);
        if (key.isEmpty) continue;
        if ((r.uuid != null && uuids.contains(r.uuid)) ||
            nombres.contains(key)) {
          report.recetasOmitidas++;
          continue;
        }
        report.recetasNuevas++;
        nombres.add(key);
        if (!escribir) continue;
        final ingredientes = <RecipeIngredient>[];
        for (var i = 0; i < r.ingredientes.length; i++) {
          final ing = r.ingredientes[i];
          final uuid = i < rr.uuidsIngredientes.length
              ? rr.uuidsIngredientes[i]
              : null;
          final alimentoId = uuid == null ? null : idPorUuid[uuid];
          ingredientes.add(
            alimentoId == null
                ? RecipeIngredient(
                    texto: ing.texto,
                    opcional: ing.opcional,
                    nota: ing.nota,
                  )
                : RecipeIngredient(
                    texto: ing.texto,
                    alimentoId: alimentoId,
                    cantidad: ing.cantidad,
                    unidad: ing.unidad,
                    opcional: ing.opcional,
                    nota: ing.nota,
                  ),
          );
        }
        await recipes.save(
          Recipe(
            uuid: r.uuid,
            nombre: r.nombre,
            categoria: r.categoria,
            porciones: r.porciones,
            tiempoMin: r.tiempoMin,
            ingredientes: ingredientes,
            elaboracion: r.elaboracion,
            notas: r.notas,
            pesoFinalG: r.pesoFinalG,
          ),
        );
      }
    }
    return report;
  }
}
