import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/utils.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_item.dart';
import '../../domain/repositories/meal_repository.dart';
import '../db/app_database.dart';
import '../db/mappers.dart';

/// Comidas del día sobre Drift.
class MealRepositoryImpl implements MealRepository {
  final AppDatabase db;

  MealRepositoryImpl(this.db);

  Meal _meal(ComidaRow r) =>
      Meal(id: r.id, name: r.nombre, date: parseDay(r.fecha));

  @override
  Future<int> createMeal(String name, DateTime date) => db
      .into(db.comidas)
      .insert(ComidasCompanion.insert(nombre: name, fecha: dayKey(date)));

  @override
  Future<List<Meal>> getMealsByDate(DateTime date) async {
    final rows =
        await (db.select(db.comidas)
              ..where((c) => c.fecha.equals(dayKey(date)))
              ..orderBy([(c) => OrderingTerm.asc(c.id)]))
            .get();
    return rows.map(_meal).toList();
  }

  @override
  Stream<List<MealWithItems>> watchDay(DateTime date) => db
      .customSelect(
        'SELECT * FROM comidas WHERE fecha = ? ORDER BY id',
        variables: [Variable.withString(dayKey(date))],
        readsFrom: {db.comidas, db.itemsComida},
      )
      .map((r) => db.comidas.map(r.data))
      .watch()
      .asyncMap((meals) async {
        if (meals.isEmpty) return const <MealWithItems>[];
        final ids = meals.map((m) => m.id).toList();
        final items =
            await (db.select(db.itemsComida)
                  ..where((i) => i.comidaId.isIn(ids))
                  ..orderBy([(i) => OrderingTerm.asc(i.id)]))
                .get();
        final byMeal = <int, List<MealItem>>{};
        for (final i in items) {
          byMeal.putIfAbsent(i.comidaId, () => []).add(mealItemFromRow(i));
        }
        return [
          for (final m in meals) MealWithItems(_meal(m), byMeal[m.id] ?? []),
        ];
      });

  @override
  Future<DateTime?> getLastMealDate() async {
    final row =
        await (db.select(db.comidas)
              ..orderBy([(c) => OrderingTerm.desc(c.fecha)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : parseDay(row.fecha);
  }

  @override
  Future<int> addItemToMeal(MealItem item) => db
      .into(db.itemsComida)
      .insert(
        ItemsComidaCompanion.insert(
          comidaId: item.mealId,
          alimentoId: Value(item.alimentoId),
          nombre: item.alimento,
          cantidad: item.cantidad,
          kcal: item.kcal,
          proteinas: item.proteinas,
          grasas: item.grasas,
          carbohidratos: item.carbohidratos,
        ),
      );

  @override
  Future<List<MealItem>> getMealItems(int mealId) async {
    final rows =
        await (db.select(db.itemsComida)
              ..where((i) => i.comidaId.equals(mealId))
              ..orderBy([(i) => OrderingTerm.asc(i.id)]))
            .get();
    return rows.map(mealItemFromRow).toList();
  }

  @override
  Future<void> deleteMeal(int id) async {
    // Las claves foráneas están activas: sus items se borran en cascada.
    await (db.delete(db.comidas)..where((c) => c.id.equals(id))).go();
  }

  @override
  Future<void> deleteMealItem(int id) async {
    await (db.delete(db.itemsComida)..where((i) => i.id.equals(id))).go();
  }

  @override
  Future<void> updateMealItem(int id, double newCantidad) {
    return db.transaction(() async {
      final item = await (db.select(
        db.itemsComida,
      )..where((i) => i.id.equals(id))).getSingleOrNull();
      if (item == null || newCantidad <= 0) return;
      // Proporción sobre lo ya guardado: NO se re-consulta el alimento base.
      final ratio = newCantidad / item.cantidad;
      await (db.update(db.itemsComida)..where((i) => i.id.equals(id))).write(
        ItemsComidaCompanion(
          cantidad: Value(newCantidad),
          kcal: Value(item.kcal * ratio),
          grasas: Value(item.grasas * ratio),
          carbohidratos: Value(item.carbohidratos * ratio),
          proteinas: Value(item.proteinas * ratio),
        ),
      );
    });
  }

  @override
  Future<void> updateMealName(int id, String name) async {
    await (db.update(db.comidas)..where((c) => c.id.equals(id))).write(
      ComidasCompanion(nombre: Value(name)),
    );
  }

  @override
  Future<bool> hasMealItems() async {
    final res = await db
        .customSelect('SELECT EXISTS(SELECT 1 FROM items_comida) AS hay')
        .getSingle();
    return res.read<bool>('hay');
  }

  @override
  Future<void> clearMealsAndItems() async {
    await db.transaction(() async {
      await db.delete(db.itemsComida).go();
      await db.delete(db.comidas).go();
    });
  }

  /// Contenido del CSV diario (separador TAB).
  Future<String> buildDayCsv(DateTime date) async {
    final meals = await getMealsByDate(date);
    final rows = <List<dynamic>>[
      [
        'nombre_comida',
        'cantidad',
        'alimento',
        'grasas',
        'carbos',
        'proteinas',
        'kcal',
      ],
    ];
    double g = 0, c = 0, p = 0, k = 0;
    for (final meal in meals) {
      for (final item in await getMealItems(meal.id!)) {
        rows.add([
          meal.name,
          item.cantidad.toStringAsFixed(1),
          item.alimento,
          item.grasas.toStringAsFixed(1),
          item.carbohidratos.toStringAsFixed(1),
          item.proteinas.toStringAsFixed(1),
          item.kcal.toStringAsFixed(1),
        ]);
        g += item.grasas;
        c += item.carbohidratos;
        p += item.proteinas;
        k += item.kcal;
      }
    }
    rows.add([
      '',
      '',
      'Total',
      g.toStringAsFixed(1),
      c.toStringAsFixed(1),
      p.toStringAsFixed(1),
      k.toStringAsFixed(1),
    ]);
    return const ListToCsvConverter(fieldDelimiter: '\t').convert(rows);
  }

  @override
  Future<String> exportMealsByDateCSV(DateTime date) async {
    final csv = await buildDayCsv(date);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    // saveFile con bytes escribe el archivo vía SAF (no hace falta escribirlo
    // a mano ni pedir permisos). En Android el tipo MIME sale de la extensión.
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Guardar reporte de comidas',
      fileName: 'comidas_${dayKey(date)}.csv',
      bytes: bytes,
    );
    // Ruta vacía = cancelado: ExportDayToCsv solo vacía el día si no lo está.
    return saved == null ? '' : AppUtils.formatRutaGuardada(saved);
  }
}
