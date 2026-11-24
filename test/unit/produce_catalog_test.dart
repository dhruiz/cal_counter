import 'dart:io';

import 'package:cal_counter/data/backup/repertoire_codec.dart';
import 'package:cal_counter/data/db/app_database.dart';
import 'package:cal_counter/data/repositories/category_repository_impl.dart';
import 'package:cal_counter/data/repositories/drift_transaction_runner.dart';
import 'package:cal_counter/data/repositories/food_repository_impl.dart';
import 'package:cal_counter/data/repositories/recipe_repository_impl.dart';
import 'package:cal_counter/domain/entities/nutrition_facts.dart';
import 'package:cal_counter/domain/entities/repertoire.dart';
import 'package:cal_counter/domain/services/ingredient_matcher.dart';
import 'package:cal_counter/domain/usecases/repertoire_exchange.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

Repertoire _leer(String ruta) =>
    RepertoireCodec.decode(File(ruta).readAsStringSync());

void main() {
  final frutas = _leer('assets/semilla/frutas_verduras_usda.json');
  final base = _leer('assets/semilla/alimentos_base.json');

  RepertoireFood buscar(String nombre) =>
      frutas.alimentos.firstWhere((f) => f.alimento.nombre == nombre);

  group('catálogo de frutas y verduras (USDA SR28)', () {
    test('222 alimentos completos, con uuid, categoría y fuente', () {
      expect(frutas.alimentos.length, 222);
      for (final rf in frutas.alimentos) {
        final f = rf.alimento;
        expect(f.uuid, isNotNull, reason: f.nombre);
        expect(f.pendiente, isFalse, reason: f.nombre);
        expect(f.origenNutricion, NutritionSource.importado);
        expect(rf.categoria, anyOf('Frutas y verduras', 'Despensa'));
        expect(f.notas, startsWith('Fuente: USDA SR28, NDB '));
        for (final p in rf.porciones) {
          expect(p.gramos, greaterThan(0), reason: '${f.nombre}: ${p.nombre}');
        }
      }
    });

    test('uuid y nombres únicos, sin chocar con el catálogo base', () {
      final uuids = frutas.alimentos.map((f) => f.alimento.uuid).toSet();
      expect(uuids.length, 222);
      final nombres = {
        for (final f in frutas.alimentos) normalizeText(f.alimento.nombre),
      };
      expect(nombres.length, 222);
      for (final f in base.alimentos) {
        expect(uuids.contains(f.alimento.uuid), isFalse);
        expect(nombres.contains(normalizeText(f.alimento.nombre)), isFalse);
      }
    });

    test('valores de control idénticos a la fuente', () {
      // USDA SR28, NDB 09040 «Bananas, raw».
      final cambur = buscar('Cambur (banano, banana), crudo / Banane, roh');
      expect(cambur.alimento.nutricion.kcal, 89);
      expect(cambur.alimento.nutricion.proteinas, 1.09);
      expect(cambur.alimento.nutricion.grasas, 0.33);
      expect(cambur.alimento.nutricion.carbohidratos, 22.84);
      expect(cambur.alimento.nutricion.fibra, 2.6);
      expect(cambur.alimento.nutricion.azucares, 12.23);
      expect(cambur.alimento.nutricion.sal, 0.0025); // 1 mg de sodio × 2,5
      expect(
        cambur.porciones.map((p) => p.gramos),
        containsAll([118.0, 101.0, 136.0]),
      );
      // NDB 09037 «Avocados, raw, all commercial varieties».
      final aguacate = buscar(
        'Aguacate (palta), crudo, promedio de variedades comerciales / '
        'Avocado, roh, Durchschnitt der Handelssorten',
      );
      expect(aguacate.alimento.nutricion.kcal, 160);
      expect(aguacate.alimento.nutricion.grasas, 14.66);
      expect(aguacate.alimento.nutricion.grasasSaturadas, 2.126);
    });

    test('nombre en español y en alemán', () {
      for (final rf in frutas.alimentos) {
        final partes = rf.alimento.nombre.split(' / ');
        expect(partes, hasLength(2), reason: rf.alimento.nombre);
        expect(partes.every((p) => p.trim().isNotEmpty), isTrue);
      }
    });

    test('un dato ausente en la fuente queda vacío, nunca en 0', () {
      // NDB 09138: USDA no publica fibra, azúcares, saturadas ni sodio.
      final uchuva = buscar(
        'Uchuva (aguaymanto, physalis), cruda / Physalis (Kapstachelbeere), roh',
      );
      final n = uchuva.alimento.nutricion;
      expect(n.fibra, isNull);
      expect(n.azucares, isNull);
      expect(n.grasasSaturadas, isNull);
      expect(n.sal, isNull);
      expect(uchuva.alimento.notas, contains('Sin dato en la fuente'));
    });

    test('se importa junto al catálogo base y sin duplicar', () async {
      final AppDatabase db = memoryDb();
      try {
        final foods = FoodRepositoryImpl(db);
        final cats = CategoryRepositoryImpl(db);
        final importar = ImportRepertoire(
          foods,
          RecipeRepositoryImpl(db),
          DriftTransactionRunner(db),
          cats,
        );
        expect((await importar(base)).nuevos, 678);
        expect((await importar(frutas)).nuevos, 222);
        expect((await importar(frutas)).nuevos, 0);
        expect((await foods.search('', limit: 2000)).length, 900);

        final kale = (await foods.search('grünkohl')).firstWhere(
          (f) => f.nombre == 'Col rizada (kale), cruda / Grünkohl, roh',
        );
        expect((await foods.getPortionsFor([kale.id!]))[kale.id!], isNull);
        final cambur = (await foods.search('cambur')).firstWhere(
          (f) => f.nombre == 'Cambur (banano, banana), crudo / Banane, roh',
        );
        expect(
          (await foods.getPortionsFor([cambur.id!]))[cambur.id!],
          hasLength(3),
        );
        final cat = (await cats.getCategories()).firstWhere(
          (c) => c.id == kale.categoriaId,
        );
        expect(cat.nombre, 'Frutas y verduras');

        // Se encuentra en los dos idiomas, con o sin tildes, diéresis o ß.
        Future<List<String>> nombres(String q) async => [
          for (final f in await foods.search(q, limit: 50)) f.nombre,
        ];
        const weisskohl = 'Repollo blanco (col), crudo / Weißkohl, roh';
        for (final q in ['repollo blanco', 'weißkohl', 'Weisskohl', 'weiß']) {
          expect(await nombres(q), contains(weisskohl), reason: q);
        }
        const batata = 'Batata (boniato, camote), cruda / Süßkartoffel, roh';
        for (final q in ['batata', 'camote', 'süßkartoffel', 'Susskartoffel']) {
          expect(await nombres(q), contains(batata), reason: q);
        }
        for (final q in ['grünkohl', 'grunkohl', 'col rizada']) {
          expect(
            await nombres(q),
            contains('Col rizada (kale), cruda / Grünkohl, roh'),
            reason: q,
          );
        }
        expect(
          await nombres('lechoza'),
          contains('Lechoza (papaya), cruda / Papaya, roh'),
        );
      } finally {
        await db.close();
      }
    });
  });
}
