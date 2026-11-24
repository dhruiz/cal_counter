import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/drift_transaction_runner.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/errors/domain_errors.dart';
import 'package:cal_counter/domain/repositories/food_repository.dart';
import 'package:cal_counter/domain/usecases/recipe_food.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

NutritionFacts _n(double kcal, double p, double g, double c) =>
    NutritionFacts(kcal: kcal, proteinas: p, grasas: g, carbohidratos: c);

void main() {
  late AppDatabase db;
  late FoodRepositoryImpl foods;
  late RecipeRepositoryImpl recipes;
  late SyncRecipeFoods sync;
  late SaveRecipe save;
  late SetRecipeFinalWeight setWeight;

  setUp(() {
    db = memoryDb();
    foods = FoodRepositoryImpl(db);
    recipes = RecipeRepositoryImpl(db);
    final tx = DriftTransactionRunner(db);
    sync = SyncRecipeFoods(recipes, foods, tx);
    save = SaveRecipe(recipes, sync, tx);
    setWeight = SetRecipeFinalWeight(recipes, sync);
  });

  tearDown(() => db.close());

  Future<int> food(String nombre, [NutritionFacts n = NutritionFacts.vacia]) =>
      foods.saveFood(Food(nombre: nombre, nutricion: n));

  RecipeIngredient ing(int alimentoId, double g, [String texto = 'x']) =>
      RecipeIngredient(
        texto: texto,
        alimentoId: alimentoId,
        cantidad: g,
        unidad: 'g',
      );

  Future<Food> recipeFood(int recetaId) async {
    final r = (await recipes.get(recetaId))!;
    expect(r.alimentoId, isNotNull, reason: 'la receta debería tener alimento');
    return (await foods.getFood(r.alimentoId!))!;
  }

  group('alimento de la receta', () {
    test('se crea al guardar, aproximado sin peso final', () async {
      final arroz = await food('Arroz', _n(350, 7, 1, 78));
      final aceite = await food('Aceite', _n(900, 0, 100, 0));
      final id = await save(
        Recipe(
          nombre: 'Arroz blanco',
          porciones: 2,
          ingredientes: [ing(arroz, 200), ing(aceite, 10)],
        ),
      );
      final f = await recipeFood(id);
      expect(f.nombre, 'Arroz blanco');
      expect(f.marca, kMarcaReceta);
      expect(f.nombreCompleto, 'Arroz blanco · Receta');
      expect(f.tipo, FoodType.preparado);
      expect(f.origenNutricion, NutritionSource.calculado);
      expect(f.aproximado, isTrue);
      // 700 + 90 kcal en 210 g crudos.
      expect(f.nutricion.kcal, closeTo(790 / 210 * 100, 0.01));
      final porcion = (await foods.getPortionsFor([f.id!]))[f.id]!.single;
      expect(porcion.nombre, kPorcionReceta);
      expect(porcion.gramos, 105);
      // Idempotente: una segunda pasada no escribe nada.
      final again = await sync();
      expect(again.creados, 0);
      expect(again.actualizados, 0);
    });

    test('peso final (con escala) la hace exacta y marca el día', () async {
      final arroz = await food('Arroz', _n(350, 7, 1, 78));
      final id = await save(
        Recipe(
          nombre: 'Arroz cocido',
          porciones: 2,
          ingredientes: [ing(arroz, 200)],
        ),
      );
      // Se cocinó el doble (400 g crudos) y pesó 1000 g sin la olla.
      await setWeight(
        recetaId: id,
        pesoNetoG: 1000,
        factor: 2,
        fecha: DateTime(2026, 11, 24, 21, 30),
      );
      final r = (await recipes.get(id))!;
      expect(r.pesoFinalG, 500);
      expect(r.ultimaPreparacion, DateTime(2026, 11, 24));
      final f = await recipeFood(id);
      expect(f.aproximado, isFalse);
      expect(f.nutricion.kcal, 140); // 700 kcal en 500 g
      final porcion = (await foods.getPortionsFor([f.id!]))[f.id]!.single;
      expect(porcion.gramos, 250);

      await setWeight(recetaId: id, pesoNetoG: null);
      expect((await recipes.get(id))!.pesoFinalG, isNull);
      expect((await recipeFood(id)).aproximado, isTrue);
      expect(
        () => setWeight(recetaId: id, pesoNetoG: -5),
        throwsA(isA<ValidationException>()),
      );
    });

    test('se calcula con los datos que hay y se completa después', () async {
      final pollo = await food('Pollo', _n(120, 22, 3, 0));
      final salsa = await food('Salsa'); // pendiente
      final id = await save(
        Recipe(
          nombre: 'Pollo en salsa',
          ingredientes: [
            ing(pollo, 300),
            ing(salsa, 100),
            const RecipeIngredient(texto: '1 hoja de laurel'),
          ],
        ),
      );
      var f = await recipeFood(id);
      expect(f.aproximado, isTrue);
      expect(f.pendiente, isFalse);
      expect(f.nutricion.kcal, closeTo(360 / 400 * 100, 0.01));

      // Completar la salsa actualiza el alimento de la receta.
      final s = (await foods.getFood(salsa))!;
      await foods.saveFood(s.copyWith(nutricion: _n(100, 1, 5, 10)));
      await sync();
      f = await recipeFood(id);
      expect(f.nutricion.kcal, closeTo(460 / 400 * 100, 0.01));
      // Sigue aproximado: falta el peso final y queda una línea sin vincular.
      expect(f.aproximado, isTrue);
    });

    test('sin datos esenciales no se crea; renombrar y borrar', () async {
      final tomate = await food('Tomate');
      final id = await save(
        Recipe(nombre: 'Salmorejo', ingredientes: [ing(tomate, 500)]),
      );
      expect((await recipes.get(id))!.alimentoId, isNull);

      final pan = await food('Pan', _n(270, 9, 1.5, 55));
      final r = (await recipes.get(id))!;
      await save(r.copyWith(ingredientes: [...r.ingredientes, ing(pan, 100)]));
      final f = await recipeFood(id);
      expect(f.nombre, 'Salmorejo');

      await save(
        (await recipes.get(id))!.copyWith(nombre: 'Salmorejo cordobés'),
      );
      final renombrado = await recipeFood(id);
      expect(renombrado.id, f.id);
      expect(renombrado.nombre, 'Salmorejo cordobés');

      // Borrar la receta conserva su alimento (se sigue pudiendo registrar).
      await recipes.delete(id);
      final queda = (await foods.getFood(f.id!))!;
      expect(queda.archivado, isFalse);
      expect(queda.pendiente, isFalse);
    });

    test('nunca sobrescribe otro alimento con el mismo nombre', () async {
      final garbanzo = await food('Garbanzo', _n(360, 19, 6, 60));
      final hummusGenerico = await food('Hummus', _n(170, 8, 10, 14));
      // Un alimento que no es de ninguna receta con la marca «Receta».
      final ajeno = await foods.saveFood(
        const Food(
          nombre: 'Falafel',
          marca: 'Receta',
          nutricion: NutritionFacts(kcal: 1),
        ),
      );

      final hummus = await save(
        Recipe(nombre: 'Hummus', ingredientes: [ing(garbanzo, 250)]),
      );
      final f = await recipeFood(hummus);
      expect(f.id, isNot(hummusGenerico));
      expect(f.nombreCompleto, 'Hummus · Receta');
      expect((await foods.getFood(hummusGenerico))!.nutricion.kcal, 170);

      final falafel = await save(
        Recipe(nombre: 'Falafel', ingredientes: [ing(garbanzo, 250)]),
      );
      expect((await recipes.get(falafel))!.alimentoId, isNull);
      final res = await sync();
      expect(res.conflictos.single.recetaId, falafel);
      expect((await foods.getFood(ajeno))!.nutricion.kcal, 1);
    });

    test('adopta su alimento huérfano y suelta vínculos antiguos', () async {
      final lenteja = await food('Lenteja', _n(330, 24, 1.5, 50));
      final id = await save(
        Recipe(nombre: 'Lentejas', ingredientes: [ing(lenteja, 300)]),
      );
      final antes = await recipeFood(id);
      await recipes.delete(id);
      final otra = await save(
        Recipe(nombre: 'Lentejas', ingredientes: [ing(lenteja, 300)]),
      );
      expect((await recipeFood(otra)).id, antes.id);

      // Vínculo antiguo a un alimento que no es "preparado" (el antiguo
      // «Añadir a mis alimentos» sobrescribía el genérico del mismo nombre).
      final generico = await food('Gazpacho', _n(40, 1, 2, 4));
      final tomate = await food('Tomate', _n(20, 1, 0, 4));
      final gid = await recipes.save(
        Recipe(
          nombre: 'Gazpacho',
          alimentoId: generico,
          ingredientes: [ing(tomate, 500)],
        ),
      );
      await sync();
      final nuevo = await recipeFood(gid);
      expect(nuevo.id, isNot(generico));
      expect(nuevo.nombreCompleto, 'Gazpacho · Receta');
      final intacto = (await foods.getFood(generico))!;
      expect(intacto.nutricion.kcal, 40);
      expect(intacto.marca, '');

      // Un "preparado" antiguo sin marca pasa a «Nombre · Receta».
      final prep = await foods.saveFood(
        Food(
          nombre: 'Crema',
          tipo: FoodType.preparado,
          nutricion: _n(1, 1, 1, 1),
        ),
      );
      final cid = await recipes.save(
        Recipe(
          nombre: 'Crema',
          alimentoId: prep,
          ingredientes: [ing(tomate, 100)],
        ),
      );
      await sync();
      final crema = await recipeFood(cid);
      expect(crema.id, prep);
      expect(crema.nombreCompleto, 'Crema · Receta');
    });

    test('recetas dentro de recetas y bucles', () async {
      final harina = await food('Harina', _n(350, 10, 1, 75));
      final masa = await save(
        Recipe(nombre: 'Masa', ingredientes: [ing(harina, 100)]),
      );
      final masaFood = await recipeFood(masa);
      final pizza = await save(
        Recipe(nombre: 'Pizza', ingredientes: [ing(masaFood.id!, 100)]),
      );
      expect((await recipeFood(pizza)).nutricion.kcal, 350);

      // Cambiar la masa cambia la pizza en la misma pasada.
      final r = (await recipes.get(masa))!;
      await recipes.save(
        r.copyWith(ingredientes: [ing(harina, 100), ing(harina, 100)]),
      );
      await setWeight(recetaId: masa, pesoNetoG: 100);
      expect((await recipeFood(masa)).nutricion.kcal, 700);
      expect((await recipeFood(pizza)).nutricion.kcal, 700);

      // Bucle: la masa usa la pizza. No se cuenta y se estabiliza.
      final m = (await recipes.get(masa))!;
      await recipes.save(
        m.copyWith(
          ingredientes: [
            ...m.ingredientes,
            ing((await recipeFood(pizza)).id!, 50),
          ],
        ),
      );
      await sync();
      final res = await sync();
      expect(res.actualizados, 0);
      expect((await recipeFood(masa)).nutricion.kcal, 700);
    });

    test('nombre de receta único sin tildes ni mayúsculas', () async {
      await save(const Recipe(nombre: 'Crema de calabacín'));
      expect(
        () => save(const Recipe(nombre: 'crema de CALABACIN')),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('artículos que no son alimentos', () {
    test('fuera del contador, de los ingredientes y de pendientes', () async {
      await foods.saveFood(
        const Food(nombre: 'Detergente líquido', esAlimento: false),
      );
      await food('Leche');
      expect((await foods.search('detergente', soloAlimentos: true)), isEmpty);
      expect((await foods.search('detergente')).single.esAlimento, isFalse);
      expect(
        (await foods.search(
          '',
          filter: FoodFilter.otrosProductos,
        )).single.nombre,
        'Detergente líquido',
      );
      final pendientes = await foods.watchPending().first;
      expect(pendientes.map((f) => f.nombre), ['Leche']);
      expect(await foods.watchPendingCount().first, 1);

      final sug = await SuggestIngredientLinks(foods)(
        Recipe.desdeLineas(nombre: 'X', lineas: ['1 detergente líquido']),
      );
      expect(sug, isEmpty);
    });
  });
}
