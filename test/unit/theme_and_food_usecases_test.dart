import 'dart:typed_data';

import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
import 'package:cal_counter/domain/repositories/food_repository.dart';
import 'package:cal_counter/domain/usecases/save_meal_as_food.dart';
import 'package:cal_counter/presentation/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FoodRepo implements FoodRepository {
  final List<Food> saved = [];
  bool insertCalled = false;

  @override
  Future<int> saveFoodByName(Food food) async {
    saved.add(food);
    return 42;
  }

  @override
  Future<int> insertFood(Food food) async {
    insertCalled = true;
    return 1;
  }

  @override
  Future<Uint8List> exportDatabase() async => Uint8List(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ThemeNotifier.isDarkFor', () {
    test('con "sistema" refleja el brillo del sistema (antes el interruptor '
        'mostraba "claro" con el tema oscuro)', () {
      expect(
        ThemeNotifier.isDarkFor(ThemeMode.system, Brightness.dark),
        isTrue,
      );
      expect(
        ThemeNotifier.isDarkFor(ThemeMode.system, Brightness.light),
        isFalse,
      );
    });

    test('modos explícitos ignoran el sistema', () {
      expect(ThemeNotifier.isDarkFor(ThemeMode.dark, Brightness.light), isTrue);
      expect(
        ThemeNotifier.isDarkFor(ThemeMode.light, Brightness.dark),
        isFalse,
      );
    });
  });

  test('SaveMealAsFood prorratea a 100 g y sobrescribe en su sitio '
      '(saveFoodByName, conserva id y vínculos)', () async {
    final repo = _FoodRepo();
    final id = await SaveMealAsFood(repo)(
      name: 'Guiso',
      items: const [
        MealItem(
          mealId: 1,
          alimento: 'Arroz',
          cantidad: 100,
          grasas: 1,
          carbohidratos: 28,
          proteinas: 3,
          kcal: 130,
        ),
        MealItem(
          mealId: 1,
          alimento: 'Pollo',
          cantidad: 100,
          grasas: 4,
          carbohidratos: 0,
          proteinas: 31,
          kcal: 165,
        ),
      ],
      totalGrams: 250,
    );
    expect(id, 42);
    expect(repo.insertCalled, isFalse);
    final f = repo.saved.single;
    expect(f.name, 'Guiso');
    expect(f.kcalPer100, 118); // 295 / 250 * 100
    expect(f.grasasPer100, 2);
    expect(f.carbsPer100, 11.2);
    expect(f.proteinsPer100, 13.6);
  });
}
