import 'dart:convert';

import 'package:csv/csv.dart';

import '../../domain/entities/recipe.dart';
import '../../domain/services/ingredient_matcher.dart';

/// Importa y exporta recetas en formatos pensados para usuarios sin
/// conocimientos técnicos.
///
/// **Texto (formato principal, `.txt` o texto pegado)**:
/// ```
/// RECETA: Tortilla de patatas
/// CATEGORÍA: Plato principal
/// PORCIONES: 4
/// TIEMPO: 40 min
/// INGREDIENTES:
/// - 4 huevos
/// - 500 g de patatas
/// PREPARACIÓN:
/// 1. Pelar y cortar...
/// NOTAS:
/// ...
/// ---
/// ```
/// Encabezados sin distinguir mayúsculas ni tildes y con sinónimos
/// (NOMBRE/TÍTULO, ELABORACIÓN/PASOS/INSTRUCCIONES, RACIONES/PERSONAS...).
/// Líneas `#` = comentarios. Recetas separadas por `---` o por un nuevo
/// `RECETA:`. Un texto pegado sin encabezados también se acepta: la primera
/// línea es el nombre y las líneas con cantidad o viñeta, ingredientes.
///
/// **JSON**: lista de objetos, `{"recetas": [...]}` o un objeto suelto.
/// **CSV**: con cabecera; delimitador `;`, `,` o TAB autodetectado.
class RecipeTextCodec {
  RecipeTextCodec._();

  /// Interpreta [content] eligiendo el formato por la extensión de
  /// [fileName] o, si no la hay, por el contenido.
  static List<Recipe> parse(String content, {String? fileName}) {
    final text = _cleanInput(content);
    final ext = (fileName ?? '').toLowerCase().split('.').last;
    if (ext == 'json') return parseJson(text);
    if (ext == 'csv' || ext == 'tsv') return parseCsv(text);
    if (ext == 'txt') return parseText(text);
    final trimmed = text.trimLeft();
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      try {
        return parseJson(trimmed);
      } on FormatException {
        // No era JSON: se trata como texto.
      }
    }
    return parseText(text);
  }

  static String _cleanInput(String content) => content
      .replaceFirst('﻿', '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  // ---------------------------------------------------------------------------
  // Texto
  // ---------------------------------------------------------------------------

  static const Map<String, String> _headerKeys = {
    'receta': 'nombre',
    'nombre': 'nombre',
    'titulo': 'nombre',
    'nombre de la receta': 'nombre',
    'categoria': 'categoria',
    'tipo': 'categoria',
    'tipo de plato': 'categoria',
    'porciones': 'porciones',
    'raciones': 'porciones',
    'personas': 'porciones',
    'comensales': 'porciones',
    'rinde': 'porciones',
    'tiempo': 'tiempo',
    'tiempo de preparacion': 'tiempo',
    'tiempo total': 'tiempo',
    'duracion': 'tiempo',
    'ingredientes': 'ingredientes',
    'preparacion': 'preparacion',
    'elaboracion': 'preparacion',
    'pasos': 'preparacion',
    'instrucciones': 'preparacion',
    'procedimiento': 'preparacion',
    'modo de preparacion': 'preparacion',
    'metodo': 'preparacion',
    'notas': 'notas',
    'nota': 'notas',
    'observaciones': 'notas',
    'consejos': 'notas',
    'trucos': 'notas',
  };

  static const Set<String> _sectionKinds = {
    'ingredientes',
    'preparacion',
    'notas',
  };

  static final RegExp _headerRe = RegExp(
    r'^\s*([A-Za-zÁÉÍÓÚÜÑáéíóúüñ][A-Za-zÁÉÍÓÚÜÑáéíóúüñ ]{1,30}?)\s*:\s*(.*)$',
  );
  static final RegExp _separatorRe = RegExp(r'^\s*([-=*_~])\1{2,}\s*$');
  static final RegExp _bulletRe = RegExp(r'^\s*[-•*·▪►✓✔–—]+\s*');
  static final RegExp _ingredientNumberRe = RegExp(r'^\s*\d{1,2}[.)]\s+');
  static final RegExp _stepNumberRe = RegExp(
    r'^\s*((paso\s*)?\d{1,2}\s*[.):\-]\s*|paso\s*\d{1,2}\s+)',
    caseSensitive: false,
  );

  static List<Recipe> parseText(String content) {
    final recipes = <Recipe>[];
    var current = _RecipeDraft();
    var section = '';

    void finish() {
      final recipe = current.build(recipes.length + 1);
      if (recipe != null) recipes.add(recipe);
      current = _RecipeDraft();
      section = '';
    }

    for (final rawLine in _cleanInput(content).split('\n')) {
      final line = _unwrapBold(rawLine.trim());
      if (line.startsWith('#')) continue;
      if (_separatorRe.hasMatch(line)) {
        finish();
        continue;
      }
      if (line.isEmpty) continue;

      // Encabezado "CLAVE: valor".
      final m = _headerRe.firstMatch(line);
      final kind = m == null ? null : _headerKeys[normalizeText(m.group(1)!)];
      final value = m?.group(2)?.trim() ?? '';
      if (kind != null) {
        if (kind == 'nombre') {
          if (current.hasContent) finish();
          current.nombre = value;
          continue;
        }
        if (_sectionKinds.contains(kind)) {
          section = kind;
          if (value.isNotEmpty) {
            _addToSection(current, section, value, inline: true);
          }
          continue;
        }
        // Metadatos: antes de cualquier sección, o valor corto fuera de notas
        // (para no confundir "Tiempo: 10 minutos en el horno" en los pasos).
        if (section.isEmpty || (section != 'notas' && value.length <= 15)) {
          switch (kind) {
            case 'categoria':
              current.categoria = value;
            case 'porciones':
              current.porciones = _firstInt(value);
            case 'tiempo':
              current.tiempoMin = parseMinutes(value);
          }
          continue;
        }
      }

      // Encabezado de sección sin dos puntos: "Ingredientes", "Preparación",
      // "Ingredientes para 4 personas".
      final norm = normalizeText(line);
      final bare = _bareSection(norm);
      if (bare != null) {
        section = bare;
        continue;
      }

      if (current.nombre == null && section.isEmpty) {
        current.nombre = line.replaceFirst(_bulletRe, '');
        continue;
      }

      if (section.isEmpty) {
        // Texto pegado sin secciones: viñeta o cantidad → ingrediente.
        final looksIngredient =
            _bulletRe.hasMatch(line) ||
            (line.length < 80 && parseIngredientLine(line).cantidad != null);
        _addToSection(
          current,
          looksIngredient ? 'ingredientes' : 'preparacion',
          line,
        );
      } else {
        _addToSection(current, section, line);
      }
    }
    finish();
    return recipes;
  }

  static String? _bareSection(String norm) {
    for (final entry in _headerKeys.entries) {
      if (!_sectionKinds.contains(entry.value)) continue;
      if (norm == entry.key || norm.startsWith('${entry.key} para ')) {
        return entry.value;
      }
    }
    return null;
  }

  static String _unwrapBold(String line) {
    var s = line.replaceAll('**', '').replaceAll('__', '');
    final m = RegExp(r'^\*([^*\s].*?)\*$').firstMatch(s);
    if (m != null) s = m.group(1)!;
    return s.trim();
  }

  static void _addToSection(
    _RecipeDraft d,
    String section,
    String line, {
    bool inline = false,
  }) {
    switch (section) {
      case 'ingredientes':
        final parts = inline ? splitList(line) : [line];
        for (final p in parts) {
          final clean = p
              .replaceFirst(_bulletRe, '')
              .replaceFirst(_ingredientNumberRe, '')
              .trim();
          if (clean.isNotEmpty) d.ingredientes.add(clean);
        }
      case 'preparacion':
        final clean = line
            .replaceFirst(_bulletRe, '')
            .replaceFirst(_stepNumberRe, '')
            .trim();
        if (clean.isNotEmpty) d.pasos.add(clean);
      case 'notas':
        d.notas.add(line);
    }
  }

  // ---------------------------------------------------------------------------
  // JSON
  // ---------------------------------------------------------------------------

  static List<Recipe> parseJson(String content) {
    final data = jsonDecode(_cleanInput(content));
    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      final listKey = data.keys.cast<String>().where((k) {
        final n = normalizeText(k);
        return n == 'recetas' || n == 'recipes';
      });
      items = listKey.isNotEmpty ? data[listKey.first] as List : [data];
    } else {
      throw const FormatException('El JSON no contiene recetas.');
    }
    final out = <Recipe>[];
    for (final item in items) {
      if (item is! Map) continue;
      final r = _fromFields(
        item.map((k, v) => MapEntry(normalizeText(k.toString()), v)),
        out.length + 1,
      );
      if (r != null) out.add(r);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // CSV
  // ---------------------------------------------------------------------------

  static List<Recipe> parseCsv(String content) {
    final text = _cleanInput(content);
    final firstLine = text
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) return const [];
    final delimiter = _detectDelimiter(firstLine);
    final rows = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(text);
    if (rows.length < 2) return const [];

    final headers = rows.first.map((h) => normalizeText(h.toString())).toList();
    final out = <Recipe>[];
    for (final row in rows.skip(1)) {
      if (row.every((c) => c.toString().trim().isEmpty)) continue;
      final fields = <String, dynamic>{};
      for (var i = 0; i < headers.length && i < row.length; i++) {
        fields[headers[i]] = row[i].toString();
      }
      final r = _fromFields(fields, out.length + 1);
      if (r != null) out.add(r);
    }
    return out;
  }

  static String _detectDelimiter(String headerLine) {
    final counts = {
      ';': ';'.allMatches(headerLine).length,
      '\t': '\t'.allMatches(headerLine).length,
      ',': ','.allMatches(headerLine).length,
    };
    var best = ';';
    for (final e in counts.entries) {
      if (e.value > counts[best]!) best = e.key;
    }
    return best;
  }

  // ---------------------------------------------------------------------------
  // Campos comunes JSON/CSV
  // ---------------------------------------------------------------------------

  static dynamic _pick(Map<String, dynamic> f, List<String> keys) {
    for (final k in keys) {
      final v = f[k];
      if (v != null && v.toString().trim().isNotEmpty) return v;
    }
    return null;
  }

  static Recipe? _fromFields(Map<String, dynamic> f, int index) {
    final d = _RecipeDraft();
    d.nombre = _pick(f, [
      'nombre',
      'titulo',
      'receta',
      'name',
      'title',
    ])?.toString().trim();
    d.categoria = _pick(f, [
      'categoria',
      'tipo',
      'category',
    ])?.toString().trim();

    final porciones = _pick(f, [
      'porciones',
      'raciones',
      'personas',
      'servings',
    ]);
    d.porciones = porciones is num
        ? porciones.toInt()
        : _firstInt(porciones?.toString() ?? '');

    final tiempo = _pick(f, ['tiempo', 'tiempo min', 'duracion', 'time']);
    d.tiempoMin = tiempo is num
        ? tiempo.toInt()
        : (tiempo == null ? null : parseMinutes(tiempo.toString()));

    final ing = _pick(f, ['ingredientes', 'ingredients']);
    if (ing is List) {
      d.ingredientes.addAll(
        ing.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
      );
    } else if (ing != null) {
      d.ingredientes.addAll(splitList(ing.toString()));
    }

    final pasos = _pick(f, [
      'elaboracion',
      'preparacion',
      'pasos',
      'instrucciones',
      'steps',
      'instructions',
    ]);
    final pasosList = pasos is List
        ? pasos.map((e) => e.toString())
        : (pasos?.toString().replaceAll('|', '\n').split('\n') ?? const []);
    for (final p in pasosList) {
      final clean = p
          .replaceFirst(_bulletRe, '')
          .replaceFirst(_stepNumberRe, '')
          .trim();
      if (clean.isNotEmpty) d.pasos.add(clean);
    }

    final notas = _pick(f, ['notas', 'observaciones', 'notes']);
    if (notas != null) d.notas.add(notas.toString().trim());

    final fav = f['favorita'];
    d.favorita = fav == true || fav == 1 || fav?.toString() == '1';
    return d.build(index);
  }

  /// Separa una lista escrita en una sola celda/línea: por saltos de línea,
  /// `|`, `;` o comas (sin partir decimales como "1,5").
  static List<String> splitList(String value) {
    List<String> parts;
    if (value.contains('\n')) {
      parts = value.split('\n');
    } else if (value.contains('|')) {
      parts = value.split('|');
    } else if (value.contains(';')) {
      parts = value.split(';');
    } else {
      parts = value.split(RegExp(r',(?!\d)'));
    }
    return parts
        .map((p) => p.replaceFirst(_bulletRe, '').trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------

  static int? _firstInt(String v) {
    final m = RegExp(r'\d+').firstMatch(v);
    return m == null ? null : int.parse(m.group(0)!);
  }

  /// "40 min" → 40, "1 h 30 min" → 90, "1h30" → 90, "1,5 horas" → 90,
  /// "45" → 45.
  static int? parseMinutes(String value) {
    final v = value.toLowerCase();
    final h = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(h|hs|hr|hrs|hora|horas)(?![a-z])',
    ).firstMatch(v);
    if (h != null) {
      final hours = double.parse(h.group(1)!.replaceAll(',', '.'));
      final rest = RegExp(r'(\d+)').firstMatch(v.substring(h.end));
      final mins = rest == null ? 0 : int.parse(rest.group(1)!);
      return (hours * 60).round() + mins;
    }
    return _firstInt(v);
  }

  static String formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  // ---------------------------------------------------------------------------
  // Exportación
  // ---------------------------------------------------------------------------

  /// Receta en formato texto (reimportable y fácil de compartir).
  static String formatRecipe(Recipe r) {
    final b = StringBuffer()..writeln('RECETA: ${r.nombre}');
    if ((r.categoria ?? '').trim().isNotEmpty) {
      b.writeln('CATEGORÍA: ${r.categoria!.trim()}');
    }
    if (r.porciones != null) b.writeln('PORCIONES: ${r.porciones}');
    if (r.tiempoMin != null) {
      b.writeln('TIEMPO: ${formatMinutes(r.tiempoMin!)}');
    }
    b
      ..writeln()
      ..writeln('INGREDIENTES:');
    for (final i in r.ingredientes) {
      b.writeln('- $i');
    }
    final pasos = r.pasos;
    if (pasos.isNotEmpty) {
      b
        ..writeln()
        ..writeln('PREPARACIÓN:');
      for (var i = 0; i < pasos.length; i++) {
        b.writeln('${i + 1}. ${pasos[i]}');
      }
    }
    if ((r.notas ?? '').trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln('NOTAS:')
        ..writeln(r.notas!.trim());
    }
    return b.toString();
  }

  static String formatRecipes(List<Recipe> recipes) =>
      recipes.map(formatRecipe).join('\n---\n\n');

  static const String plantilla = '''# PLANTILLA DE RECETAS
# Escribe tus recetas siguiendo este ejemplo (en el móvil o el ordenador)
# y luego impórtalas en la app: Recetas → menú ⋮ → Importar desde archivo.
# También puedes copiar el texto y usar "Pegar texto".
#
# - Las líneas que empiezan con # se ignoran (puedes borrarlas).
# - Solo hacen falta RECETA e INGREDIENTES; lo demás es opcional.
# - Un ingrediente por línea y un paso por línea.
# - Marca con (opcional) los ingredientes que no son imprescindibles.
# - Separa una receta de la siguiente con una línea de tres guiones: ---

RECETA: Tortilla de patatas
CATEGORÍA: Plato principal
PORCIONES: 4
TIEMPO: 40 min

INGREDIENTES:
- 4 huevos
- 500 g de patatas
- 1 cebolla (opcional)
- Aceite de oliva
- Sal

PREPARACIÓN:
1. Pelar las patatas y cortarlas en láminas finas.
2. Freír las patatas y la cebolla a fuego medio hasta que estén tiernas.
3. Batir los huevos con sal y mezclarlos con las patatas escurridas.
4. Cuajar la tortilla en la sartén por ambos lados.

NOTAS:
Queda más jugosa si la mezcla reposa 10 minutos antes de cuajarla.

---

RECETA: Ensalada de garbanzos
CATEGORÍA: Ensalada
PORCIONES: 2
TIEMPO: 15 min

INGREDIENTES:
- 400 g de garbanzos cocidos
- 2 tomates
- 1 pepino
- Media cebolla morada
- Aceite de oliva
- Vinagre
- Sal

PREPARACIÓN:
1. Escurrir y enjuagar los garbanzos.
2. Picar el tomate, el pepino y la cebolla.
3. Mezclar todo y aliñar con aceite, vinagre y sal.
''';
}

/// Acumulador mientras se lee una receta.
class _RecipeDraft {
  String? nombre;
  String? categoria;
  int? porciones;
  int? tiempoMin;
  bool favorita = false;
  final List<String> ingredientes = [];
  final List<String> pasos = [];
  final List<String> notas = [];

  bool get hasContent =>
      (nombre ?? '').isNotEmpty ||
      ingredientes.isNotEmpty ||
      pasos.isNotEmpty ||
      notas.isNotEmpty;

  Recipe? build(int index) {
    if (!hasContent) return null;
    final name = (nombre ?? '').trim();
    if (name.isEmpty && ingredientes.isEmpty && pasos.isEmpty) return null;
    String? clean(String? s) =>
        (s == null || s.trim().isEmpty) ? null : s.trim();
    return Recipe(
      nombre: name.isEmpty ? 'Receta importada $index' : name,
      categoria: clean(categoria),
      porciones: porciones,
      tiempoMin: tiempoMin,
      ingredientes: List.unmodifiable(ingredientes),
      elaboracion: pasos.join('\n'),
      notas: clean(notas.join('\n')),
      favorita: favorita,
    );
  }
}
