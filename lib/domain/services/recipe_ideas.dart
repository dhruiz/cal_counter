import 'dart:math';

import '../entities/recipe.dart';
import 'ingredient_matcher.dart';

/// Orden de la lista de recetas.
enum RecipeOrder {
  /// Favoritas primero y después de la A a la Z.
  favoritas('Favoritas primero'),

  /// Las que hace más tiempo que no preparas (las nunca preparadas al final).
  haceTiempo('Hace más tiempo que no la preparas'),

  /// Las últimas que preparaste.
  recientes('Preparadas hace poco');

  final String etiqueta;

  const RecipeOrder(this.etiqueta);
}

int _porNombre(Recipe a, Recipe b) =>
    normalizeText(a.nombre).compareTo(normalizeText(b.nombre));

/// Ordena las recetas según [orden].
List<Recipe> sortRecipes(List<Recipe> recetas, RecipeOrder orden) {
  final out = [...recetas];
  switch (orden) {
    case RecipeOrder.favoritas:
      out.sort((a, b) {
        if (a.favorita != b.favorita) return a.favorita ? -1 : 1;
        return _porNombre(a, b);
      });
    case RecipeOrder.haceTiempo:
    case RecipeOrder.recientes:
      out.sort((a, b) {
        final fa = a.ultimaPreparacion;
        final fb = b.ultimaPreparacion;
        if (fa == null && fb == null) return _porNombre(a, b);
        if (fa == null) return 1;
        if (fb == null) return -1;
        final c = orden == RecipeOrder.haceTiempo
            ? fa.compareTo(fb)
            : fb.compareTo(fa);
        return c != 0 ? c : _porNombre(a, b);
      });
  }
  return out;
}

/// Categorías de las recetas (sin repetir, sin distinguir mayúsculas), de la
/// A a la Z.
List<String> recipeCategories(List<Recipe> recetas) {
  final porClave = <String, String>{};
  for (final r in recetas) {
    final c = r.categoria?.trim() ?? '';
    if (c.isEmpty) continue;
    porClave.putIfAbsent(normalizeText(c), () => c);
  }
  final out = porClave.values.toList()
    ..sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
  return out;
}

/// La receta es de esa categoría (sin tildes ni mayúsculas).
bool isInCategory(Recipe r, String categoria) =>
    normalizeText(r.categoria ?? '') == normalizeText(categoria);

/// Días desde que se preparó (0 = hoy), o null si nunca.
int? daysSincePrepared(Recipe r, DateTime hoy) {
  final f = r.ultimaPreparacion;
  if (f == null) return null;
  final d0 = DateTime(f.year, f.month, f.day);
  final d1 = DateTime(hoy.year, hoy.month, hoy.day);
  return d1.difference(d0).inDays;
}

/// "hoy", "ayer", "hace 5 días", "hace 3 semanas", "hace 2 meses".
String preparedAgo(int dias) {
  if (dias <= 0) return 'hoy';
  if (dias == 1) return 'ayer';
  if (dias < 14) return 'hace $dias días';
  if (dias < 60) return 'hace ${dias ~/ 7} semanas';
  final meses = dias ~/ 30;
  return meses == 1 ? 'hace 1 mes' : 'hace $meses meses';
}

/// Peso de una receta para sugerirla: las favoritas y las que hace tiempo
/// que no preparas salen más; las preparadas en los últimos días, casi nunca.
double ideaWeight(Recipe r, DateTime hoy) {
  var w = r.favorita ? 3.0 : 1.0;
  final dias = daysSincePrepared(r, hoy);
  if (dias == null) return w;
  if (dias < 3) return w * 0.1;
  return w * (1 + min(dias, 60) / 15);
}

/// Receta al azar para cuando no se te ocurre qué cocinar (ponderada por
/// [ideaWeight]). [excluir] son las que ya se propusieron. Null si no queda
/// ninguna.
Recipe? suggestRecipe(
  List<Recipe> recetas, {
  required DateTime hoy,
  Random? random,
  Set<int> excluir = const {},
}) {
  final candidatas = [
    for (final r in recetas)
      if (!excluir.contains(r.id)) r,
  ];
  if (candidatas.isEmpty) return null;
  final pesos = [for (final r in candidatas) ideaWeight(r, hoy)];
  final total = pesos.fold<double>(0, (a, b) => a + b);
  var x = (random ?? Random()).nextDouble() * total;
  for (var i = 0; i < candidatas.length; i++) {
    x -= pesos[i];
    if (x <= 0) return candidatas[i];
  }
  return candidatas.last;
}
