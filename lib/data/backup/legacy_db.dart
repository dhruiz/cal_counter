import 'package:sqlite3/sqlite3.dart';

import '../../domain/entities/food.dart';
import '../../domain/entities/meal_item.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/repertoire.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import '../../domain/repositories/transaction_runner.dart';
import '../../domain/services/barcode.dart';
import '../../domain/services/ingredient_matcher.dart';
import '../../domain/usecases/food_registration.dart';
import '../../domain/usecases/repertoire_exchange.dart';
import '../db/mappers.dart';

/// Nombre del archivo de la base de datos de las versiones anteriores.
const String kLegacyDatabaseName = 'db_ctrl_calorias.db';

/// Contenido de una base de datos de versiones anteriores (`db_alimentos`,
/// productos, compras, listas, recetas y comidas), leído sin modificarla.
class LegacyData {
  final List<Map<String, Object?>> alimentos;
  final List<Map<String, Object?>> productos;
  final List<Map<String, Object?>> compras;
  final List<Map<String, Object?>> listas;
  final List<Map<String, Object?>> itemsLista;
  final List<Map<String, Object?>> recetas;
  final List<Map<String, Object?>> ingredientes;
  final List<Map<String, Object?>> comidas;
  final List<Map<String, Object?>> itemsComida;

  const LegacyData({
    this.alimentos = const [],
    this.productos = const [],
    this.compras = const [],
    this.listas = const [],
    this.itemsLista = const [],
    this.recetas = const [],
    this.ingredientes = const [],
    this.comidas = const [],
    this.itemsComida = const [],
  });

  bool get soloAlimentos =>
      productos.isEmpty &&
      recetas.isEmpty &&
      listas.isEmpty &&
      comidas.isEmpty &&
      compras.isEmpty;

  int get total =>
      alimentos.length +
      productos.length +
      compras.length +
      listas.length +
      recetas.length +
      comidas.length;

  /// Lee el archivo en solo lectura. Lanza [ValidationException] si no es una
  /// base de datos de la versión anterior.
  static LegacyData read(String path) {
    final Database db;
    try {
      db = sqlite3.open(path, mode: OpenMode.readOnly);
    } catch (_) {
      throw const ValidationException('No se pudo abrir el archivo .db.');
    }
    try {
      final tablas = {
        for (final r in db.select(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        ))
          r['name'] as String,
      };
      if (!tablas.contains('db_alimentos')) {
        throw const ValidationException(
          'El archivo no es una base de datos de la versión anterior '
          '(no tiene la tabla db_alimentos).',
        );
      }
      List<Map<String, Object?>> all(String t, [String order = 'id']) =>
          tablas.contains(t)
          ? [
              for (final r in db.select('SELECT * FROM $t ORDER BY $order'))
                Map<String, Object?>.from(r),
            ]
          : const [];
      return LegacyData(
        alimentos: all('db_alimentos'),
        productos: all('productos'),
        compras: all('compras', 'fecha, id'),
        listas: all('listas_compra'),
        itemsLista: all('items_lista_compra', 'lista_id, orden, id'),
        recetas: all('recetas'),
        ingredientes: all('ingredientes_receta', 'receta_id, orden, id'),
        comidas: all('comidas'),
        itemsComida: all('items_comida'),
      );
    } on SqliteException {
      throw const ValidationException('El archivo .db está dañado.');
    } finally {
      db.close();
    }
  }

  /// Solo los alimentos, como repertorio (para fusionar).
  Repertoire toRepertoire() => Repertoire(
    alimentos: [
      for (final a in alimentos)
        if (_s(a['alimento']).isNotEmpty)
          RepertoireFood(
            alimento: Food(
              nombre: _s(a['alimento']),
              nutricion: NutritionFacts(
                kcal: _d(a['kCal']),
                grasas: _d(a['grasas']),
                carbohidratos: _d(a['carbohidratos']),
                proteinas: _d(a['proteinas']),
              ),
              origenNutricion: NutritionSource.importado,
            ),
          ),
    ],
  );

  static String _s(Object? v) => v == null ? '' : '$v'.trim();
  static double? _d(Object? v) => v is num ? v.toDouble() : null;
  static int? _i(Object? v) => v is num ? v.toInt() : null;
}

/// Resultado de la migración.
class LegacyMigrationReport {
  int alimentos = 0;
  int productos = 0;
  int compras = 0;
  int listas = 0;
  int recetas = 0;
  int comidas = 0;

  String get resumen => [
    '$alimentos alimentos',
    if (productos > 0) '$productos productos',
    if (compras > 0) '$compras compras',
    if (listas > 0) '$listas listas',
    if (recetas > 0) '$recetas recetas',
    if (comidas > 0) '$comidas comidas',
  ].join(' · ');
}

/// Pasa al esquema nuevo los datos de una instalación anterior (ver
/// Apéndice A de docs/PLAN_REDISENO_BD.md), en una transacción. El archivo
/// antiguo no se modifica nunca.
///
/// - `db_alimentos` → alimentos genéricos (fusionando con los existentes),
///   conservando el contador de uso.
/// - Cada producto → alimento envasado (nombre y marca) con la tabla del
///   alimento al que estaba vinculado (o pendiente) + su presentación.
/// - Compras → compras de esa presentación, en céntimos.
/// - Listas y artículos (con el carrito), recetas e ingredientes, comidas.
class MigrateLegacyData {
  final FoodRepository foods;
  final PurchaseRepository purchases;
  final ShoppingListRepository shopping;
  final RecipeRepository recipes;
  final MealRepository meals;
  final TransactionRunner tx;

  MigrateLegacyData({
    required this.foods,
    required this.purchases,
    required this.shopping,
    required this.recipes,
    required this.meals,
    required this.tx,
  });

  Future<LegacyMigrationReport> call(LegacyData data) {
    return tx(() async {
      final report = LegacyMigrationReport();
      final s = LegacyData._s, d = LegacyData._d, i = LegacyData._i;

      // 1. Alimentos.
      await ImportRepertoire(foods, recipes, _NoTx())(data.toRepertoire());
      final idPorNombre = <String, int>{};
      final idPorViejo = <int, int>{};
      for (final a in data.alimentos) {
        final nombre = s(a['alimento']);
        final f = await foods.findByNameAndBrand(nombre, '');
        if (f == null) continue;
        idPorNombre[normalizeText(nombre)] = f.id!;
        final viejo = i(a['id']);
        if (viejo != null) idPorViejo[viejo] = f.id!;
        final uso = i(a['uso_count']) ?? 0;
        if (uso > 0 && f.usoCount == 0) {
          await foods.setUsage(
            f.id!,
            uso,
            DateTime.tryParse(s(a['ultimo_uso'])),
          );
        }
        report.alimentos++;
      }

      // 2. Productos → alimento envasado + presentación.
      final presentacionPorProducto = <int, int>{};
      final alimentoPorProducto = <int, int>{};
      final register = RegisterFoodInStore(foods, _NoTx());
      for (final p in data.productos) {
        final nombre = s(p['nombre']);
        if (nombre.isEmpty) continue;
        final vinculado = idPorViejo[i(p['alimento_id']) ?? -1];
        final base = vinculado == null ? null : await foods.getFood(vinculado);
        var code = normalizeBarcode(p['codigo_barras'] as String?);
        if (code != null && await foods.findByBarcode(code) != null) {
          code = null; // ya es de otro alimento: se conserva sin código
        }
        final m = await register(
          nombre: nombre,
          marca: s(p['marca']),
          presentacion: PackageDraft(
            codigoBarras: code,
            descripcion: s(p['presentacion']),
          ),
        );
        if (base != null && m.food.pendiente) {
          await foods.saveFood(
            m.food.copyWith(
              nutricion: base.nutricion,
              origenNutricion: base.origenNutricion,
              tipo: s(p['marca']).isEmpty && code == null
                  ? FoodType.generico
                  : FoodType.envasado,
            ),
          );
        }
        final id = i(p['id']);
        if (id != null) {
          presentacionPorProducto[id] = m.package.id!;
          alimentoPorProducto[id] = m.food.id!;
        }
        report.productos++;
      }

      // 3. Compras.
      final compraNueva = <int, int>{};
      for (final c in data.compras) {
        final pid = presentacionPorProducto[i(c['producto_id']) ?? -1];
        final precio = d(c['precio']);
        final tienda = s(c['establecimiento']);
        if (pid == null || precio == null || precio <= 0 || tienda.isEmpty) {
          continue;
        }
        final nuevo = await purchases.addPurchase(
          Purchase(
            presentacionId: pid,
            fecha: parseDay(s(c['fecha'])),
            precioCent: (precio * 100).round(),
            establecimiento: tienda,
          ),
        );
        final viejo = i(c['id']);
        if (viejo != null) compraNueva[viejo] = nuevo;
        report.compras++;
      }

      // 4. Listas y artículos (con los datos del carrito).
      final listaNueva = <int, int>{};
      for (final l in data.listas) {
        final id = await shopping.createList(
          s(l['nombre']).isEmpty ? 'Lista' : s(l['nombre']),
        );
        listaNueva[i(l['id']) ?? -1] = id;
        report.listas++;
      }
      for (final it in data.itemsLista) {
        final lista = listaNueva[i(it['lista_id']) ?? -1];
        final texto = s(it['texto']);
        if (lista == null || texto.isEmpty) continue;
        final compraId = compraNueva[i(it['compra_id']) ?? -1];
        final comprado = (i(it['comprado']) ?? 0) == 1;
        if (compraId != null) {
          final unidades = i(it['unidades']) ?? 1;
          final compra = await purchases.getPurchase(compraId);
          if (compra != null && unidades > 1) {
            await purchases.updatePurchase(compra.copyWith(unidades: unidades));
          }
        }
        await shopping.addItem(
          ShoppingItem(
            listaId: lista,
            alimentoId: alimentoPorProducto[i(it['producto_id']) ?? -1],
            texto: texto,
            cantidad: s(it['cantidad']),
            comprado: comprado,
            compraId: comprado ? compraId : null,
          ),
        );
      }

      // 5. Recetas.
      final porReceta = <int, List<String>>{};
      for (final ing in data.ingredientes) {
        porReceta
            .putIfAbsent(i(ing['receta_id']) ?? -1, () => [])
            .add(s(ing['texto']));
      }
      final existentes = {
        for (final r in await recipes.getAll()) normalizeText(r.nombre),
      };
      for (final r in data.recetas) {
        final nombre = s(r['nombre']);
        if (nombre.isEmpty || !existentes.add(normalizeText(nombre))) continue;
        final receta = Recipe.desdeLineas(
          nombre: nombre,
          categoria: s(r['categoria']),
          porciones: i(r['porciones']),
          tiempoMin: i(r['tiempo_min']),
          lineas: porReceta[i(r['id']) ?? -1] ?? const [],
          elaboracion: s(r['elaboracion']),
          notas: s(r['notas']),
          favorita: (i(r['favorita']) ?? 0) == 1,
        );
        await recipes.save(
          receta.copyWith(alimentoId: idPorViejo[i(r['alimento_id']) ?? -1]),
        );
        report.recetas++;
      }

      // 6. Comidas.
      final porComida = <int, List<Map<String, Object?>>>{};
      for (final it in data.itemsComida) {
        porComida.putIfAbsent(i(it['comida_id']) ?? -1, () => []).add(it);
      }
      for (final c in data.comidas) {
        final items = porComida[i(c['id']) ?? -1] ?? const [];
        if (items.isEmpty) continue;
        final mealId = await meals.createMeal(
          s(c['nombre']).isEmpty ? 'Comida' : s(c['nombre']),
          parseDay(s(c['fecha'])),
        );
        for (final it in items) {
          final cantidad = d(it['cantidad']) ?? 0;
          if (cantidad <= 0) continue;
          await meals.addItemToMeal(
            MealItem(
              mealId: mealId,
              alimentoId: idPorNombre[normalizeText(s(it['alimento']))],
              alimento: s(it['alimento']),
              cantidad: cantidad,
              grasas: d(it['grasas']) ?? 0,
              carbohidratos: d(it['carbohidratos']) ?? 0,
              proteinas: d(it['proteinas']) ?? 0,
              kcal: d(it['kCal']) ?? 0,
            ),
          );
        }
        report.comidas++;
      }
      return report;
    });
  }
}

/// Ya estamos dentro de una transacción: se ejecuta tal cual.
class _NoTx implements TransactionRunner {
  @override
  Future<T> call<T>(Future<T> Function() action) => action();
}
