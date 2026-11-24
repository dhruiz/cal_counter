import 'dart:io';

import 'package:cal_counter/data/backup/foods_tsv_codec.dart';
import 'package:cal_counter/data/backup/full_backup.dart';
import 'package:cal_counter/data/backup/legacy_db.dart';
import 'package:cal_counter/data/backup/repertoire_codec.dart';
import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/drift_transaction_runner.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/meal_repository_impl.dart';
import 'package:cal_counter/data/repositories/purchase_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/data/repositories/shopping_list_repository_impl.dart';
import 'package:cal_counter/domain/entities/food.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/purchase.dart';
import 'package:cal_counter/domain/entities/recipe.dart';
import 'package:cal_counter/domain/entities/repertoire.dart';
import 'package:cal_counter/domain/errors/domain_errors.dart';
import 'package:cal_counter/domain/repositories/food_repository.dart';
import 'package:cal_counter/domain/usecases/repertoire_exchange.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../helpers/test_db.dart';

/// Repositorios y casos de uso sobre una base de datos.
class _Env {
  final AppDatabase db;
  final FoodRepositoryImpl foods;
  final RecipeRepositoryImpl recipes;
  final PurchaseRepositoryImpl purchases;
  final ShoppingListRepositoryImpl shopping;
  final MealRepositoryImpl meals;
  final DriftTransactionRunner tx;

  _Env(this.db)
    : foods = FoodRepositoryImpl(db),
      recipes = RecipeRepositoryImpl(db),
      purchases = PurchaseRepositoryImpl(db),
      shopping = ShoppingListRepositoryImpl(db),
      meals = MealRepositoryImpl(db),
      tx = DriftTransactionRunner(db);

  ExportRepertoire get exportar => ExportRepertoire(foods, recipes);
  ImportRepertoire get importar => ImportRepertoire(foods, recipes, tx);
}

const _leche = NutritionFacts(
  kcal: 46,
  proteinas: 3.1,
  grasas: 1.6,
  grasasSaturadas: 1,
  carbohidratos: 4.7,
  azucares: 4.7,
  sal: 0.13,
);

void main() {
  late _Env a;
  late _Env b;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kcal_target': 2100});
    a = _Env(memoryDb());
    b = _Env(memoryDb());

    final leche = await a.foods.saveFood(
      const Food(
        nombre: 'Leche semidesnatada',
        marca: 'Hacendado',
        tipo: FoodType.envasado,
        unidad: FoodUnit.ml,
        nutricion: _leche,
        origenNutricion: NutritionSource.etiquetaOcr,
      ),
    );
    await a.foods.savePackage(
      FoodPackage(
        alimentoId: leche,
        codigoBarras: '8480000123456',
        descripcion: 'Brick 1 L',
        contenido: 1000,
      ),
    );
    await a.foods.savePortion(
      FoodPortion(alimentoId: leche, nombre: 'vaso', gramos: 250),
    );
    final cacao = await a.foods.saveFood(
      const Food(
        nombre: 'Cacao puro',
        nutricion: NutritionFacts.basica(
          kcal: 380,
          proteinas: 20,
          grasas: 11,
          carbohidratos: 15,
        ),
      ),
    );
    await a.recipes.save(
      Recipe(
        nombre: 'Batido de cacao',
        porciones: 1,
        ingredientes: [
          RecipeIngredient(
            texto: '1 vaso de leche',
            alimentoId: leche,
            cantidad: 1,
            unidad: 'vaso',
          ),
          RecipeIngredient(
            texto: '10 g de cacao',
            alimentoId: cacao,
            cantidad: 10,
            unidad: 'g',
          ),
        ],
      ),
    );
  });

  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  group('repertorio', () {
    test('ida y vuelta: exportar → JSON → importar en vacío', () async {
      final rep = await a.exportar(incluirRecetas: true);
      final json = RepertoireCodec.encode(rep);
      final decoded = RepertoireCodec.decode(json);
      final report = await b.importar(decoded);
      expect(report.nuevos, 2);
      expect(report.recetasNuevas, 1);

      final leche = (await b.foods.findByBarcode('8480000123456'))!;
      final orig = (await a.foods.findByBarcode('8480000123456'))!;
      expect(leche.food.uuid, orig.food.uuid);
      expect(leche.food.nutricion, _leche);
      expect(leche.food.unidad, FoodUnit.ml);
      expect(leche.food.origenNutricion, NutritionSource.etiquetaOcr);
      expect(leche.package.contenido, 1000);
      expect(
        (await b.foods.getPortionsFor([
          leche.food.id!,
        ]))[leche.food.id]!.single.gramos,
        250,
      );
      final receta = (await b.recipes.getAll()).single;
      expect(receta.ingredientes.first.alimentoId, leche.food.id);
      expect(receta.ingredientes.first.unidad, 'vaso');
    });

    test('importar dos veces no duplica nada', () async {
      final rep = await a.exportar(incluirRecetas: true);
      await b.importar(rep);
      final second = await b.importar(rep);
      expect(second.nuevos, 0);
      expect(second.sinCambios, 2);
      expect(second.recetasOmitidas, 1);
      expect((await b.foods.getAllFoods()).length, 2);
      expect((await b.recipes.getAll()).length, 1);
    });

    test('rellena huecos y aplica la política en conflictos', () async {
      // En B: la leche existe por nombre, sin código y con datos parciales;
      // el cacao tiene otras kcal.
      await b.foods.saveFood(
        const Food(
          nombre: 'leche semidesnatada',
          marca: 'hacendado',
          nutricion: NutritionFacts(kcal: 46),
        ),
      );
      await b.foods.saveFood(
        const Food(
          nombre: 'Cacao puro',
          nutricion: NutritionFacts.basica(
            kcal: 400,
            proteinas: 20,
            grasas: 11,
            carbohidratos: 15,
          ),
        ),
      );
      final rep = await a.exportar();
      final preview = await b.importar(rep, dryRun: true);
      expect(preview.completados, 1);
      expect(preview.conflictos, 1);
      expect(preview.nombresEnConflicto, ['Cacao puro']);
      // La vista previa no escribe nada.
      expect(
        (await b.foods.findByNameAndBrand(
          'Leche semidesnatada',
          'Hacendado',
        ))!.pendiente,
        isTrue,
      );

      await b.importar(rep);
      final leche = (await b.foods.findByNameAndBrand(
        'Leche semidesnatada',
        'Hacendado',
      ))!;
      expect(leche.pendiente, isFalse);
      expect(leche.nutricion.sal, 0.13);
      expect((await b.foods.findByBarcode('8480000123456'))!.food.id, leche.id);
      var cacao = (await b.foods.findByNameAndBrand('Cacao puro', ''))!;
      expect(cacao.nutricion.kcal, 400); // conservar los míos

      await b.importar(rep, politica: ConflictPolicy.usarImportados);
      cacao = (await b.foods.findByNameAndBrand('Cacao puro', ''))!;
      expect(cacao.nutricion.kcal, 380);
    });

    test('empareja por código de barras aunque cambie el nombre', () async {
      final id = await b.foods.saveFood(
        const Food(nombre: 'Leche Hacendado 1L', tipo: FoodType.envasado),
      );
      await b.foods.savePackage(
        FoodPackage(alimentoId: id, codigoBarras: '8480000123456'),
      );
      final r = await b.importar(await a.exportar());
      expect(r.nuevos, 1); // solo el cacao
      expect((await b.foods.getFood(id))!.pendiente, isFalse);
    });

    test('rechaza versiones más nuevas y archivos que no son repertorio', () {
      expect(
        () => RepertoireCodec.decode(
          '{"formato":"cal_counter/repertorio","version":99,"alimentos":[]}',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => RepertoireCodec.decode('{"hola": 1}'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => RepertoireCodec.decode('no es json'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('TSV', () {
    test('ida y vuelta con códigos y nutrientes vacíos', () async {
      await a.foods.saveFood(const Food(nombre: 'Sin datos'));
      final tsv = FoodsTsvCodec.encode(await a.exportar());
      expect(tsv.split('\n').first, FoodsTsvCodec.columnas.join('\t'));
      final rep = FoodsTsvCodec.decode(tsv);
      expect(rep.alimentos.length, 3);
      final leche = rep.alimentos.firstWhere(
        (f) => f.alimento.nombre == 'Leche semidesnatada',
      );
      expect(leche.alimento.marca, 'Hacendado');
      expect(leche.alimento.nutricion.sal, 0.13);
      expect(leche.presentaciones.single.codigoBarras, '8480000123456');
      final vacio = rep.alimentos.firstWhere(
        (f) => f.alimento.nombre == 'Sin datos',
      );
      expect(vacio.alimento.pendiente, isTrue);
    });

    test('acepta la cabecera antigua de 6 columnas', () async {
      const legado =
          'id\talimento\tkCal\tgrasas\tcarbohidratos\tproteinas\n'
          '1\tArroz Blanco\t345\t0.7\t77.7\t8.1\n'
          '2\tMal\tabc\n';
      final rep = FoodsTsvCodec.decode(legado);
      expect(rep.alimentos.length, 1);
      final r = await b.importar(rep);
      expect(r.nuevos, 1);
      final arroz = (await b.foods.search('arroz')).single;
      expect(arroz.nutricion.carbohidratos, 77.7);
    });
  });

  group('respaldo completo', () {
    test('exportar → restaurar reemplaza todo y conserva relaciones', () async {
      final leche = (await a.foods.findByBarcode('8480000123456'))!;
      await a.purchases.addPurchase(
        Purchase(
          presentacionId: leche.package.id!,
          fecha: DateTime(2026, 11, 1),
          precioCent: 89,
          establecimiento: 'Súper',
        ),
      );
      await b.foods.saveFood(const Food(nombre: 'Se perderá'));

      final json = await FullBackupService(a.db).export();
      expect(FullBackupService.inspect(json)['alimentos'], 2);
      SharedPreferences.setMockInitialValues({});
      await FullBackupService(b.db).restore(json);

      expect(await b.foods.search('perdera'), isEmpty);
      final restored = (await b.foods.search('leche')).single; // FTS al día
      expect(restored.uuid, leche.food.uuid);
      final compras = await b.purchases.getPurchasesForFood(restored.id!);
      expect(compras.single.compra.precioCent, 89);
      expect((await b.recipes.getAll()).single.ingredientes.length, 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('kcal_target'), 2100);
      // Las claves foráneas siguen activas: con compras se archiva.
      expect(await b.foods.deleteFood(restored.id!), FoodDeletion.archivado);
    });

    test('rechaza un archivo que no es un respaldo', () {
      expect(
        () => FullBackupService.inspect('{"formato":"otro"}'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('versión anterior', () {
    test('lee la base de datos precargada de la v1.2', () {
      final data = LegacyData.read('test/fixtures/db_ctrl_calorias_v1_2.db');
      expect(data.alimentos.length, 678);
      expect(data.soloAlimentos, isTrue);
      expect(data.toRepertoire().alimentos.length, 678);
    });

    test('migra productos, compras, listas, recetas y comidas', () async {
      final dir = Directory.systemTemp.createTempSync('legacy');
      final path = '${dir.path}/db_ctrl_calorias.db';
      final old = sql.sqlite3.open(path);
      old.execute('''
        CREATE TABLE db_alimentos (id INTEGER PRIMARY KEY, alimento TEXT UNIQUE,
          kCal REAL, grasas REAL, carbohidratos REAL, proteinas REAL,
          uso_count INTEGER DEFAULT 0, ultimo_uso TEXT);
        CREATE TABLE comidas (id INTEGER PRIMARY KEY, nombre TEXT, fecha TEXT);
        CREATE TABLE items_comida (id INTEGER PRIMARY KEY, comida_id INTEGER,
          cantidad REAL, alimento TEXT, grasas REAL, carbohidratos REAL,
          proteinas REAL, kCal REAL);
        CREATE TABLE recetas (id INTEGER PRIMARY KEY, nombre TEXT, categoria TEXT,
          porciones INTEGER, tiempo_min INTEGER, elaboracion TEXT, notas TEXT,
          favorita INTEGER, alimento_id INTEGER, peso_porcion_g REAL,
          creada TEXT, actualizada TEXT);
        CREATE TABLE ingredientes_receta (id INTEGER PRIMARY KEY,
          receta_id INTEGER, orden INTEGER, texto TEXT);
        CREATE TABLE productos (id INTEGER PRIMARY KEY, codigo_barras TEXT,
          nombre TEXT, marca TEXT, presentacion TEXT, alimento_id INTEGER,
          creado TEXT);
        CREATE TABLE compras (id INTEGER PRIMARY KEY, producto_id INTEGER,
          fecha TEXT, precio REAL, establecimiento TEXT);
        CREATE TABLE listas_compra (id INTEGER PRIMARY KEY, nombre TEXT,
          creada TEXT);
        CREATE TABLE items_lista_compra (id INTEGER PRIMARY KEY,
          lista_id INTEGER, texto TEXT, cantidad TEXT, producto_id INTEGER,
          comprado INTEGER, orden INTEGER, unidades INTEGER,
          precio_pagado REAL, compra_id INTEGER);
        INSERT INTO db_alimentos VALUES
          (1, 'Leche entera', 64, 3.6, 4.7, 3.2, 5, '2026-11-01'),
          (2, 'Huevo', 143, 9.5, 0.7, 12.6, 0, NULL);
        INSERT INTO productos VALUES
          (1, '8410000000001', 'Leche entera', 'Vaca', '1 L', 1, 'x'),
          (2, NULL, 'Pan de barra', NULL, NULL, NULL, 'x');
        INSERT INTO compras VALUES
          (1, 1, '2026-11-02', 0.95, 'Mercado'),
          (2, 2, '2026-11-03', 1.1, 'Panadería');
        INSERT INTO listas_compra VALUES (1, 'Semana', 'x');
        INSERT INTO items_lista_compra VALUES
          (1, 1, 'Leche', NULL, 1, 1, 1, 3, 0.95, 1),
          (2, 1, 'Fruta', '1 kg', NULL, 0, 2, 1, NULL, NULL);
        INSERT INTO recetas VALUES
          (1, 'Tortilla', 'Plato', 4, 30, 'Batir', NULL, 1, NULL, NULL, 'x', 'x');
        INSERT INTO ingredientes_receta VALUES
          (1, 1, 1, '4 huevos'), (2, 1, 2, 'Sal');
        INSERT INTO comidas VALUES (1, 'Comida_1', '2026-11-20');
        INSERT INTO items_comida VALUES
          (1, 1, 200, 'Leche entera', 7.2, 9.4, 6.4, 128);
      ''');
      old.close();

      final data = LegacyData.read(path);
      final report = await MigrateLegacyData(
        foods: b.foods,
        purchases: b.purchases,
        shopping: b.shopping,
        recipes: b.recipes,
        meals: b.meals,
        tx: b.tx,
      )(data);
      expect(report.alimentos, 2);
      expect(report.productos, 2);
      expect(report.compras, 2);

      // Leche (genérico) conserva el uso; el producto es un envasado con la
      // tabla copiada y su código.
      final generico = (await b.foods.findByNameAndBrand('Leche entera', ''))!;
      expect(generico.usoCount, 5);
      final m = (await b.foods.findByBarcode('8410000000001'))!;
      expect(m.food.marca, 'Vaca');
      expect(m.food.tipo, FoodType.envasado);
      expect(m.food.nutricion.kcal, 64);
      expect(m.package.descripcion, '1 L');
      final compras = await b.purchases.getPurchasesForFood(m.food.id!);
      expect(compras.single.compra.precioCent, 95);
      // Pan sin vínculo: alimento pendiente con su compra.
      final pan = (await b.foods.findByNameAndBrand('Pan de barra', ''))!;
      expect(pan.pendiente, isTrue);

      // Lista con el carrito: unidades en la compra enlazada.
      final listas = await b.shopping.watchLists().first;
      final items = await b.shopping.getItems(listas.single.id!);
      final leche = items.firstWhere((i) => i.texto == 'Leche');
      expect(leche.alimentoId, m.food.id);
      expect(leche.unidades, 3);
      expect(leche.subtotalCent, 285);

      final receta = (await b.recipes.getAll()).single;
      expect(receta.lineas, ['4 huevos', 'Sal']);
      expect(receta.favorita, isTrue);
      final dia = await b.meals.watchDay(DateTime(2026, 11, 20)).first;
      expect(dia.single.items.single.alimentoId, generico.id);

      // Repetir la migración de alimentos no duplica.
      await b.importar(data.toRepertoire());
      expect((await b.foods.search('', filter: FoodFilter.todos)).length, 4);
      dir.deleteSync(recursive: true);
    });
  });
}
