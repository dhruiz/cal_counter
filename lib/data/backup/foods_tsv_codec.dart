import '../../domain/entities/food.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/entities/repertoire.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/services/barcode.dart';

/// Alimentos en TSV (separador TAB) para hojas de cálculo.
///
/// Cabecera actual:
/// `uuid	nombre	marca	tipo	unidad	codigos	kcal	grasas	grasas_saturadas	carbohidratos	azucares	fibra	proteinas	sal	categoria`
/// (`codigos`: códigos de barras separados por comas; celdas vacías =
/// desconocido). Al importar también se acepta la cabecera antigua de
/// 6 columnas `id	alimento	kCal	grasas	carbohidratos	proteinas` (el id se
/// ignora).
class FoodsTsvCodec {
  FoodsTsvCodec._();

  static const List<String> columnas = [
    'uuid',
    'nombre',
    'marca',
    'tipo',
    'unidad',
    'codigos',
    'kcal',
    'grasas',
    'grasas_saturadas',
    'carbohidratos',
    'azucares',
    'fibra',
    'proteinas',
    'sal',
    'categoria',
  ];

  static const List<String> columnasLegado = [
    'id',
    'alimento',
    'kCal',
    'grasas',
    'carbohidratos',
    'proteinas',
  ];

  static const Map<String, Nutrient> _nutrientes = {
    'kcal': Nutrient.kcal,
    'grasas': Nutrient.grasas,
    'grasas_saturadas': Nutrient.grasasSaturadas,
    'carbohidratos': Nutrient.carbohidratos,
    'azucares': Nutrient.azucares,
    'fibra': Nutrient.fibra,
    'proteinas': Nutrient.proteinas,
    'sal': Nutrient.sal,
  };

  static String _clean(String s) =>
      s.replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();

  static String _num(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';
  }

  static String encode(Repertoire rep) {
    final b = StringBuffer()..writeln(columnas.join('\t'));
    for (final rf in rep.alimentos) {
      final f = rf.alimento;
      final codigos = [
        for (final p in rf.presentaciones)
          if (p.codigoBarras != null) p.codigoBarras!,
      ].join(',');
      b.writeln(
        [
          f.uuid ?? '',
          _clean(f.nombre),
          _clean(f.marca),
          f.tipo.clave,
          f.unidad.clave,
          codigos,
          for (final c in columnas.skip(6).take(8))
            _num(f.nutricion[_nutrientes[c]!]),
          _clean(rf.categoria ?? ''),
        ].join('\t'),
      );
    }
    return b.toString();
  }

  static double? _parse(String s) {
    final t = s.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return (v == null || v < 0) ? null : v;
  }

  static Repertoire decode(String content) {
    final lines = content
        .replaceFirst('﻿', '')
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) throw const ValidationException('Archivo TSV vacío.');
    final header = lines.first.split('\t').map((h) => h.trim()).toList();
    final legado = _sameColumns(header, columnasLegado);
    if (!legado && !header.contains('nombre')) {
      throw ValidationException(
        'Cabecera TSV no reconocida. Esperado: ${columnas.join(r'\t')}',
      );
    }
    final idx = {for (var i = 0; i < header.length; i++) header[i]: i};
    String cell(List<String> cols, String name) {
      final i = idx[name];
      return (i == null || i >= cols.length) ? '' : cols[i].trim();
    }

    final out = <RepertoireFood>[];
    for (final line in lines.skip(1)) {
      final cols = line.split('\t');
      if (legado) {
        if (cols.length != 6) continue;
        final nombre = cols[1].trim();
        if (nombre.isEmpty) continue;
        out.add(
          RepertoireFood(
            alimento: Food(
              nombre: nombre,
              nutricion: NutritionFacts(
                kcal: _parse(cols[2]),
                grasas: _parse(cols[3]),
                carbohidratos: _parse(cols[4]),
                proteinas: _parse(cols[5]),
              ),
              origenNutricion: NutritionSource.importado,
            ),
          ),
        );
        continue;
      }
      final nombre = cell(cols, 'nombre');
      if (nombre.isEmpty) continue;
      var n = NutritionFacts.vacia;
      _nutrientes.forEach((col, nut) {
        n = n.conValor(nut, _parse(cell(cols, col)));
      });
      final uuid = cell(cols, 'uuid');
      final categoria = cell(cols, 'categoria');
      out.add(
        RepertoireFood(
          categoria: categoria.isEmpty ? null : categoria,
          alimento: Food(
            uuid: uuid.isEmpty ? null : uuid,
            nombre: nombre,
            marca: cell(cols, 'marca'),
            tipo: FoodType.fromClave(cell(cols, 'tipo')),
            unidad: FoodUnit.fromClave(cell(cols, 'unidad')),
            nutricion: n,
            origenNutricion: n.estaVacia ? null : NutritionSource.importado,
          ),
          presentaciones: [
            for (final c in cell(cols, 'codigos').split(','))
              if (normalizeBarcode(c) != null)
                FoodPackage(alimentoId: 0, codigoBarras: normalizeBarcode(c)),
          ],
        ),
      );
    }
    return Repertoire(alimentos: out);
  }

  static bool _sameColumns(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
