import 'dart:convert';

import '../../domain/entities/food.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/repertoire.dart';
import '../../domain/errors/domain_errors.dart';

/// Formato JSON de repertorio compartible (`*.json`).
///
/// ```json
/// {"formato": "cal_counter/repertorio", "version": 1, "exportado": "...",
///  "alimentos": [{"uuid", "nombre", "marca", "tipo", "unidad", "categoria",
///    "es_alimento" (solo si es false),
///    "nutricion": {"kcal", ..., "origen", "aproximada" (solo si true)},
///    "notas",
///    "porciones": [{"nombre", "gramos"}],
///    "presentaciones": [{"uuid", "codigo_barras", "descripcion",
///      "contenido"}]}],
///  "recetas": [{"uuid", "nombre", ..., "ingredientes": [{"texto",
///    "alimento_uuid", "cantidad", "unidad", "opcional", "nota"}]}]}
/// ```
///
/// Tolerante: ignora campos desconocidos y rechaza versiones mayores más
/// nuevas con un mensaje claro. Independiente del esquema interno.
class RepertoireCodec {
  RepertoireCodec._();

  static const String formato = 'cal_counter/repertorio';
  static const int version = 1;

  static const Map<Nutrient, String> _claves = {
    Nutrient.kcal: 'kcal',
    Nutrient.proteinas: 'proteinas',
    Nutrient.grasas: 'grasas',
    Nutrient.grasasSaturadas: 'grasas_saturadas',
    Nutrient.carbohidratos: 'carbohidratos',
    Nutrient.azucares: 'azucares',
    Nutrient.fibra: 'fibra',
    Nutrient.sal: 'sal',
  };

  // Codificar -----------------------------------------------------------------

  static String encode(Repertoire rep) {
    final map = {
      'formato': formato,
      'version': version,
      'exportado': (rep.exportado ?? DateTime.now()).toUtc().toIso8601String(),
      'alimentos': [for (final f in rep.alimentos) _food(f)],
      if (rep.recetas.isNotEmpty)
        'recetas': [for (final r in rep.recetas) _recipe(r)],
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static Map<String, Object?> _food(RepertoireFood rf) {
    final f = rf.alimento;
    final n = f.nutricion;
    return {
      'uuid': f.uuid,
      'nombre': f.nombre,
      if (f.marca.isNotEmpty) 'marca': f.marca,
      'tipo': f.tipo.clave,
      'unidad': f.unidad.clave,
      if ((rf.categoria ?? '').isNotEmpty) 'categoria': rf.categoria,
      if (!f.esAlimento) 'es_alimento': false,
      if (!n.estaVacia)
        'nutricion': {
          for (final e in _claves.entries)
            if (n[e.key] != null) e.value: n[e.key],
          if (f.origenNutricion != null) 'origen': f.origenNutricion!.clave,
          if (f.aproximado) 'aproximada': true,
        },
      if ((f.notas ?? '').isNotEmpty) 'notas': f.notas,
      if (rf.porciones.isNotEmpty)
        'porciones': [
          for (final p in rf.porciones)
            {'nombre': p.nombre, 'gramos': p.gramos},
        ],
      if (rf.presentaciones.isNotEmpty)
        'presentaciones': [
          for (final p in rf.presentaciones)
            {
              if (p.uuid != null) 'uuid': p.uuid,
              if (p.codigoBarras != null) 'codigo_barras': p.codigoBarras,
              if (p.descripcion.isNotEmpty) 'descripcion': p.descripcion,
              if (p.contenido != null) 'contenido': p.contenido,
            },
        ],
    };
  }

  static Map<String, Object?> _recipe(RepertoireRecipe rr) {
    final r = rr.receta;
    return {
      if (r.uuid != null) 'uuid': r.uuid,
      'nombre': r.nombre,
      if ((r.categoria ?? '').isNotEmpty) 'categoria': r.categoria,
      if (r.porciones != null) 'porciones': r.porciones,
      if (r.tiempoMin != null) 'tiempo_min': r.tiempoMin,
      if (r.pesoFinalG != null) 'peso_final_g': r.pesoFinalG,
      'ingredientes': [
        for (var i = 0; i < r.ingredientes.length; i++)
          {
            'texto': r.ingredientes[i].texto,
            if (i < rr.uuidsIngredientes.length &&
                rr.uuidsIngredientes[i] != null)
              'alimento_uuid': rr.uuidsIngredientes[i],
            if (r.ingredientes[i].cantidad != null)
              'cantidad': r.ingredientes[i].cantidad,
            if (r.ingredientes[i].unidad != null)
              'unidad': r.ingredientes[i].unidad,
            if (r.ingredientes[i].opcional) 'opcional': true,
            if ((r.ingredientes[i].nota ?? '').isNotEmpty)
              'nota': r.ingredientes[i].nota,
          },
      ],
      if (r.elaboracion.isNotEmpty) 'elaboracion': r.elaboracion,
      if ((r.notas ?? '').isNotEmpty) 'notas': r.notas,
    };
  }

  // Decodificar ---------------------------------------------------------------

  static Repertoire decode(String content) {
    final Object? json;
    try {
      json = jsonDecode(content);
    } on FormatException {
      throw const ValidationException('El archivo no es un JSON válido.');
    }
    if (json is! Map) {
      throw const ValidationException('El archivo no es un repertorio.');
    }
    final fmt = json['formato'];
    if (fmt != formato) {
      throw const ValidationException(
        'El archivo no es un repertorio de alimentos de esta app.',
      );
    }
    final v = json['version'];
    if (v is int && v > version) {
      throw ValidationException(
        'El repertorio es de una versión más nueva de la app (formato v$v). '
        'Actualiza la app para importarlo.',
      );
    }
    final alimentos = <RepertoireFood>[];
    for (final a in (json['alimentos'] as List?) ?? const []) {
      if (a is! Map) continue;
      final f = _decodeFood(a);
      if (f != null) alimentos.add(f);
    }
    final recetas = <RepertoireRecipe>[];
    for (final r in (json['recetas'] as List?) ?? const []) {
      if (r is! Map) continue;
      final rr = _decodeRecipe(r);
      if (rr != null) recetas.add(rr);
    }
    return Repertoire(
      alimentos: alimentos,
      recetas: recetas,
      exportado: DateTime.tryParse('${json['exportado']}'),
    );
  }

  static double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static String _str(Object? v) => v == null ? '' : '$v'.trim();

  static RepertoireFood? _decodeFood(Map a) {
    final nombre = _str(a['nombre']);
    if (nombre.isEmpty) return null;
    final n = a['nutricion'];
    var nutricion = NutritionFacts.vacia;
    NutritionSource? origen;
    var aproximada = false;
    if (n is Map) {
      for (final e in _claves.entries) {
        final v = _num(n[e.value]);
        if (v != null && v >= 0) nutricion = nutricion.conValor(e.key, v);
      }
      origen = NutritionSource.fromClave(n['origen'] as String?);
      aproximada = n['aproximada'] == true;
    }
    final uuid = _str(a['uuid']);
    final categoria = _str(a['categoria']);
    return RepertoireFood(
      categoria: categoria.isEmpty ? null : categoria,
      alimento: Food(
        uuid: uuid.isEmpty ? null : uuid,
        nombre: nombre,
        marca: _str(a['marca']),
        tipo: FoodType.fromClave(a['tipo'] as String?),
        unidad: FoodUnit.fromClave(a['unidad'] as String?),
        nutricion: nutricion,
        origenNutricion: origen,
        notas: _str(a['notas']).isEmpty ? null : _str(a['notas']),
        aproximado: aproximada,
        esAlimento: a['es_alimento'] != false,
      ),
      porciones: [
        for (final p in (a['porciones'] as List?) ?? const [])
          if (p is Map &&
              _str(p['nombre']).isNotEmpty &&
              (_num(p['gramos']) ?? 0) > 0)
            FoodPortion(nombre: _str(p['nombre']), gramos: _num(p['gramos'])!),
      ],
      presentaciones: [
        for (final p in (a['presentaciones'] as List?) ?? const [])
          if (p is Map)
            FoodPackage(
              uuid: _str(p['uuid']).isEmpty ? null : _str(p['uuid']),
              alimentoId: 0,
              codigoBarras: _str(p['codigo_barras']).isEmpty
                  ? null
                  : _str(p['codigo_barras']),
              descripcion: _str(p['descripcion']),
              contenido: _num(p['contenido']),
            ),
      ],
    );
  }

  static RepertoireRecipe? _decodeRecipe(Map r) {
    final nombre = _str(r['nombre']);
    if (nombre.isEmpty) return null;
    final ingredientes = <RecipeIngredient>[];
    final uuids = <String?>[];
    for (final i in (r['ingredientes'] as List?) ?? const []) {
      if (i is String) {
        ingredientes.add(RecipeIngredient(texto: i));
        uuids.add(null);
      } else if (i is Map && _str(i['texto']).isNotEmpty) {
        ingredientes.add(
          RecipeIngredient(
            texto: _str(i['texto']),
            cantidad: _num(i['cantidad']),
            unidad: _str(i['unidad']).isEmpty ? null : _str(i['unidad']),
            opcional: i['opcional'] == true,
            nota: _str(i['nota']).isEmpty ? null : _str(i['nota']),
          ),
        );
        final u = _str(i['alimento_uuid']);
        uuids.add(u.isEmpty ? null : u);
      }
    }
    final uuid = _str(r['uuid']);
    return RepertoireRecipe(
      receta: Recipe(
        uuid: uuid.isEmpty ? null : uuid,
        nombre: nombre,
        categoria: _str(r['categoria']).isEmpty ? null : _str(r['categoria']),
        porciones: (r['porciones'] as num?)?.toInt(),
        tiempoMin: (r['tiempo_min'] as num?)?.toInt(),
        pesoFinalG: _num(r['peso_final_g']),
        ingredientes: ingredientes,
        elaboracion: _str(r['elaboracion']),
        notas: _str(r['notas']).isEmpty ? null : _str(r['notas']),
      ),
      uuidsIngredientes: uuids,
    );
  }
}
