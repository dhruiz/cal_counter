import 'dart:convert';

import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_item.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/services/dates.dart';
import '../datasources/local_data_source.dart';

class MealRepositoryImpl implements MealRepository {
  final LocalDataSource localDataSource;

  MealRepositoryImpl(this.localDataSource);

  @override
  Future<int> createMeal(String name, DateTime date) async {
    return await localDataSource.createMeal(name, date);
  }

  @override
  Future<List<Meal>> getMealsByDate(DateTime date) async {
    final result = await localDataSource.getMealsByDate(date);
    return result
        .map(
          (e) => Meal(
            id: e['id'] as int,
            name: e['nombre'] as String,
            date: DateTime.parse(e['fecha'] as String),
          ),
        )
        .toList();
  }

  @override
  Future<DateTime?> getLastMealDate() async {
    final dateStr = await localDataSource.getLastMealDate();
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  @override
  Future<int> addItemToMeal(MealItem item) async {
    return await localDataSource.addItemToMeal(item);
  }

  @override
  Future<List<MealItem>> getMealItems(int mealId) async {
    final result = await localDataSource.getMealItems(mealId);
    // `num` → double: un REAL guardado como entero llega como int y el
    // acceso dinámico anterior fallaba en tiempo de ejecución.
    double d(Object? v) => (v as num).toDouble();
    return result
        .map(
          (e) => MealItem(
            id: e['id'] as int,
            mealId: e['comida_id'] as int,
            alimento: e['alimento'] as String,
            cantidad: d(e['cantidad']),
            grasas: d(e['grasas']),
            carbohidratos: d(e['carbohidratos']),
            proteinas: d(e['proteinas']),
            kcal: d(e['kCal']),
          ),
        )
        .toList();
  }

  @override
  Future<void> deleteMeal(int id) async {
    await localDataSource.deleteMeal(id);
  }

  @override
  Future<void> deleteMealItem(int id) async {
    await localDataSource.deleteMealItem(id);
  }

  @override
  Future<void> updateMealItem(int id, double newCantidad) async {
    await localDataSource.updateMealItem(id, newCantidad);
  }

  @override
  Future<void> updateMealName(int id, String name) async {
    await localDataSource.updateMealName(id, name);
  }

  @override
  Future<bool> hasMealItems() async {
    return await localDataSource.hasMealItems();
  }

  @override
  Future<void> clearMealsAndItems() async {
    await localDataSource.clearMealsAndItems();
  }

  @override
  Future<String> exportMealsByDateCSV(DateTime date) async {
    final meals = await getMealsByDate(date);
    List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'nombre_comida',
      'cantidad',
      'alimento',
      'grasas',
      'carbos',
      'proteinas',
      'kcal',
    ]);

    // Track daily totals
    double totalGrasas = 0;
    double totalCarbos = 0;
    double totalProteinas = 0;
    double totalKcal = 0;

    for (var meal in meals) {
      final items = await getMealItems(meal.id!);
      for (var item in items) {
        rows.add([
          meal.name,
          item.cantidad.toStringAsFixed(1),
          item.alimento,
          item.grasas.toStringAsFixed(1),
          item.carbohidratos.toStringAsFixed(1),
          item.proteinas.toStringAsFixed(1),
          item.kcal.toStringAsFixed(1),
        ]);

        // Accumulate totals
        totalGrasas += item.grasas;
        totalCarbos += item.carbohidratos;
        totalProteinas += item.proteinas;
        totalKcal += item.kcal;
      }
    }

    // Add totals row
    rows.add([
      '',
      '',
      'Total',
      totalGrasas.toStringAsFixed(1),
      totalCarbos.toStringAsFixed(1),
      totalProteinas.toStringAsFixed(1),
      totalKcal.toStringAsFixed(1),
    ]);

    String csv = const ListToCsvConverter(fieldDelimiter: '\t').convert(rows);

    final dateStr = dateKey(date);
    final fileName = 'comidas_$dateStr.csv';

    // Encode CSV string to bytes
    final bytes = Uint8List.fromList(utf8.encode(csv));

    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Guardar reporte de comidas',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: bytes,
    );

    if (outputFile != null) {
      // On Android/iOS, saveFile with bytes writes the file.
      // We don't need to write it again manually, which avoids permission issues.
      return outputFile;
    }

    return '';
  }
}
