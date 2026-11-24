import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cooking_pot.dart';
import '../../domain/repositories/cooking_pot_repository.dart';

/// Recipientes en SharedPreferences, como una lista JSON.
class CookingPotRepositoryImpl implements CookingPotRepository {
  static const String key = 'recipientes_cocina';

  @override
  Future<List<CookingPot>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final e in list)
          if (e is Map &&
              e['nombre'] is String &&
              e['gramos'] is num &&
              (e['gramos'] as num) > 0)
            CookingPot(
              nombre: e['nombre'] as String,
              gramos: (e['gramos'] as num).toDouble(),
            ),
      ];
    } on FormatException {
      return const [];
    }
  }

  Future<List<CookingPot>> _write(List<CookingPot> pots) async {
    final prefs = await SharedPreferences.getInstance();
    pots.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
    await prefs.setString(
      key,
      jsonEncode([
        for (final p in pots) {'nombre': p.nombre, 'gramos': p.gramos},
      ]),
    );
    return pots;
  }

  @override
  Future<List<CookingPot>> save(CookingPot pot) async {
    final nombre = pot.nombre.trim();
    final pots = [
      for (final p in await getAll())
        if (p.nombre.toLowerCase() != nombre.toLowerCase()) p,
      CookingPot(nombre: nombre, gramos: pot.gramos),
    ];
    return _write(pots);
  }

  @override
  Future<List<CookingPot>> delete(String nombre) async {
    final pots = [
      for (final p in await getAll())
        if (p.nombre.toLowerCase() != nombre.trim().toLowerCase()) p,
    ];
    return _write(pots);
  }
}
