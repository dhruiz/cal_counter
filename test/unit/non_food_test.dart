import 'package:cal_counter/data/backup/foods_tsv_codec.dart';
import 'package:cal_counter/data/backup/full_backup.dart';
import 'package:cal_counter/data/backup/repertoire_codec.dart';
import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/drift_transaction_runner.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/services/category_guesser.dart';
import 'package:cal_counter/domain/usecases/food_registration.dart';
import 'package:cal_counter/domain/usecases/repertoire_exchange.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

/// Artículos que no son alimentos y campos nuevos (v3) en los formatos de
/// intercambio.
void main() {
  late AppDatabase db;
  late FoodRepositoryImpl foods;
  late RecipeRepositoryImpl recipes;
  late DriftTransactionRunner tx;

  setUp(() {
    db = memoryDb();
    foods = FoodRepositoryImpl(db);
    recipes = RecipeRepositoryImpl(db);
    tx = DriftTransactionRunner(db);
  });

  tearDown(() => db.close());

  test('el nombre propone si es un alimento', () {
    expect(pareceNoAlimentario('Detergente líquido'), isTrue);
    expect(pareceNoAlimentario('Papel higiénico'), isTrue);
    expect(pareceNoAlimentario('Champú anticaspa'), isTrue);
    expect(pareceNoAlimentario('Leche entera'), isFalse);
    expect(pareceNoAlimentario('Cosa rara'), isFalse);
  });

  test('alta en la tienda: lo propone el nombre y se puede elegir', () async {
    final alta = RegisterFoodInStore(foods, tx);
    final det = await alta(
      nombre: 'Detergente líquido',
      presentacion: const PackageDraft(codigoBarras: '8410000000002'),
    );
    expect(det.food.esAlimento, isFalse);
    expect(det.food.pendiente, isFalse);
    final leche = await alta(nombre: 'Leche entera');
    expect(leche.food.esAlimento, isTrue);
    expect(leche.food.pendiente, isTrue);
    final bolsa = await alta(
      nombre: 'Bolsas de congelación',
      esAlimento: false,
    );
    expect(bolsa.food.esAlimento, isFalse);
  });

  test(
    'repertorio y TSV llevan los campos nuevos (y aceptan los viejos)',
    () async {
      final det = await foods.saveFood(
        const Food(nombre: 'Detergente', esAlimento: false),
      );
      final arroz = await foods.saveFood(
        const Food(nombre: 'Arroz', nutricion: NutritionFacts(kcal: 350)),
      );
      await foods.saveFood(
        const Food(
          nombre: 'Paella',
          marca: 'Receta',
          tipo: FoodType.preparado,
          nutricion: NutritionFacts(
            kcal: 150,
            proteinas: 5,
            grasas: 4,
            carbohidratos: 22,
          ),
          aproximado: true,
        ),
      );
      await recipes.save(
        Recipe(
          nombre: 'Paella',
          ingredientes: [
            RecipeIngredient(
              texto: '200 g de arroz, lavado',
              alimentoId: arroz,
              cantidad: 200,
              unidad: 'g',
              nota: 'lavado',
            ),
          ],
        ),
      );
      final rep = await ExportRepertoire(foods, recipes)(incluirRecetas: true);
      final json = RepertoireCodec.encode(rep);
      expect(json, contains('"es_alimento": false'));
      expect(json, contains('"aproximada": true'));
      expect(json, contains('"nota": "lavado"'));

      // Otra instalación.
      final otra = memoryDb();
      final f2 = FoodRepositoryImpl(otra);
      final r2 = RecipeRepositoryImpl(otra);
      await ImportRepertoire(f2, r2, DriftTransactionRunner(otra))(
        RepertoireCodec.decode(json),
      );
      expect(
        (await f2.findByNameAndBrand('Detergente', ''))!.esAlimento,
        isFalse,
      );
      expect(
        (await f2.findByNameAndBrand('Paella', 'Receta'))!.aproximado,
        isTrue,
      );
      final paella = (await r2.getAll()).single;
      expect(paella.ingredientes.single.nota, 'lavado');
      await otra.close();

      // Un archivo anterior sin los campos: todo es alimento.
      final viejo = RepertoireCodec.decode(
        '{"formato": "cal_counter/repertorio", "version": 1, '
        '"alimentos": [{"nombre": "Sal", "nutricion": {"kcal": 0}}]}',
      );
      expect(viejo.alimentos.single.alimento.esAlimento, isTrue);
      expect(viejo.alimentos.single.alimento.aproximado, isFalse);

      final tsv = FoodsTsvCodec.encode(rep);
      final back = FoodsTsvCodec.decode(tsv).alimentos;
      expect(
        back
            .firstWhere((a) => a.alimento.nombre == 'Detergente')
            .alimento
            .esAlimento,
        isFalse,
      );
      expect(
        back
            .firstWhere((a) => a.alimento.nombre == 'Arroz')
            .alimento
            .esAlimento,
        isTrue,
      );
      expect(det, isPositive);
    },
  );

  test('el respaldo completo conserva las columnas nuevas', () async {
    SharedPreferences.setMockInitialValues({});
    await foods.saveFood(const Food(nombre: 'Lejía', esAlimento: false));
    final json = await FullBackupService(db).export();
    final otra = memoryDb();
    await FullBackupService(otra).restore(json);
    final lejia = await FoodRepositoryImpl(
      otra,
    ).findByNameAndBrand('Lejía', '');
    expect(lejia!.esAlimento, isFalse);
    await otra.close();
  });
}
