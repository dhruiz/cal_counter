/// Texto de las líneas de ingredientes que se añaden desde el buscador:
/// "200 g de arroz redondo, lavado", "2 dientes de ajo (opcional)".
library;

/// Número para mostrar: sin decimales si es entero, si no hasta 2 con coma
/// ("1,5"). Puro: no depende de la configuración regional.
String formatQuantity(double v) {
  final r = (v * 100).roundToDouble() / 100;
  if (r == r.roundToDouble()) return r.toInt().toString();
  var s = r.toStringAsFixed(2);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  return s.replaceAll('.', ',');
}

/// Plural sencillo en español: "diente" → "dientes", "unidad" → "unidades",
/// "nuez" → "nueces". Las unidades métricas no cambian.
String pluralize(String palabra) {
  final w = palabra.trim();
  if (w.isEmpty || w == 'g' || w == 'ml') return w;
  final last = w[w.length - 1].toLowerCase();
  if (last == 's') return w;
  if (last == 'z') return '${w.substring(0, w.length - 1)}ces';
  if ('aeiouáéó'.contains(last)) return '${w}s';
  return '${w}es';
}

/// Nombre del alimento dentro de una frase: la primera letra en minúscula
/// salvo que parezca una sigla ("Arroz redondo" → "arroz redondo", "AOVE"
/// se queda igual).
String _enFrase(String nombre) {
  final n = nombre.trim();
  if (n.length < 2) return n.toLowerCase();
  final segunda = n[1];
  if (segunda.toUpperCase() == segunda && segunda.toLowerCase() != segunda) {
    return n;
  }
  return n[0].toLowerCase() + n.substring(1);
}

/// Cantidad con su unidad: "200 g", "1 diente", "2 dientes".
String quantityText(double cantidad, String unidad) {
  final u = unidad.trim();
  final n = formatQuantity(cantidad);
  if (u == 'g' || u == 'ml') return '$n $u';
  return '$n ${cantidad == 1 ? u : pluralize(u)}';
}

/// Línea de ingrediente a partir del alimento elegido.
String ingredientLine({
  required String nombreAlimento,
  double? cantidad,
  String? unidad,
  String? nota,
  bool opcional = false,
}) {
  final b = StringBuffer();
  final nombre = _enFrase(nombreAlimento);
  if (cantidad != null && cantidad > 0) {
    b.write('${quantityText(cantidad, unidad ?? 'g')} de $nombre');
  } else {
    b.write(nombreAlimento.trim());
  }
  final n = nota?.trim() ?? '';
  if (n.isNotEmpty) b.write(', $n');
  if (opcional) b.write(' (opcional)');
  return b.toString();
}

final RegExp _cantidadInicial = RegExp(r'^(\d+(?:[.,]\d+)?|½|¼|¾)(\s*)');

const Map<String, double> _fraccionesInicio = {'½': 0.5, '¼': 0.25, '¾': 0.75};

/// Texto de una línea con las cantidades multiplicadas por [factor]. Una
/// línea vinculada con cantidad se rehace con [nombreAlimento]; una de texto
/// libre cambia el número del principio ("4 huevos" × 1,5 → "6 huevos") o, si
/// no lo tiene, indica la escala ("Sal (×1,5)").
String scaledIngredientText({
  required String texto,
  required double factor,
  String? nombreAlimento,
  double? cantidad,
  String? unidad,
  String? nota,
  bool opcional = false,
}) {
  if (factor == 1) return texto;
  if (nombreAlimento != null && cantidad != null && cantidad > 0) {
    return ingredientLine(
      nombreAlimento: nombreAlimento,
      cantidad: cantidad * factor,
      unidad: unidad,
      nota: nota,
      opcional: opcional || texto.toLowerCase().contains('(opcional)'),
    );
  }
  final m = _cantidadInicial.firstMatch(texto);
  if (m != null) {
    final raw = m.group(1)!;
    final v =
        _fraccionesInicio[raw] ?? double.tryParse(raw.replaceAll(',', '.'));
    if (v != null) {
      return '${formatQuantity(v * factor)}${m.group(2)}'
          '${texto.substring(m.end)}';
    }
  }
  return '$texto (×${formatQuantity(factor)})';
}

/// Cantidad legible para listas: "750 g", "1,25 kg", "500 ml", "1,5 L".
String humanQuantity(double v, String unidad) {
  if (unidad == 'g' && v >= 1000) return '${formatQuantity(v / 1000)} kg';
  if (unidad == 'ml' && v >= 1000) return '${formatQuantity(v / 1000)} L';
  return quantityText(v, unidad);
}
