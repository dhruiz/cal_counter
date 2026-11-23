import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../domain/entities/food.dart';
import '../providers/search_provider.dart';
import 'food_form_view.dart';

/// Selector de un alimento de la base de calorías (para vincularlo a una
/// receta o producto). Devuelve el [Food] elegido o null.
///
/// Usa [searchFoodsProvider] directamente para no alterar el estado de
/// búsqueda de `SearchView`.
class FoodPickerView extends ConsumerStatefulWidget {
  final String initialQuery;

  const FoodPickerView({super.key, this.initialQuery = ''});

  static Future<Food?> pick(BuildContext context, {String initialQuery = ''}) {
    return Navigator.push<Food>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodPickerView(initialQuery: initialQuery),
      ),
    );
  }

  @override
  ConsumerState<FoodPickerView> createState() => _FoodPickerViewState();
}

class _FoodPickerViewState extends ConsumerState<FoodPickerView> {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  List<Food> _results = const [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().isNotEmpty) _search(widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    final res = await ref.read(searchFoodsProvider)(q.trim());
    if (!mounted) return;
    setState(() {
      _results = res;
      _searching = false;
    });
  }

  Future<void> _createFood() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodFormView(initialName: _ctrl.text.trim()),
      ),
    );
    if (created == true) {
      ref.invalidate(mostUsedFoodsProvider);
      await _search(_ctrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        title: TextField(
          controller: _ctrl,
          autofocus: widget.initialQuery.isEmpty,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Buscar alimento...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Elige el alimento del contador de calorías con el que se '
              'registrará. Si no existe, créalo con sus valores por 100 g.',
              style: AppStyles.labelText,
            ),
          ),
          if (_searching) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              children: [
                ..._results.map(
                  (f) => ListTile(
                    title: Text(f.name),
                    subtitle: Text(
                      '${f.kcalPer100} kcal | G: ${f.grasasPer100} | '
                      'C: ${f.carbsPer100} | P: ${f.proteinsPer100} (por 100g)',
                      style: AppStyles.labelText,
                    ),
                    onTap: () => Navigator.pop(context, f),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Crear alimento nuevo'),
                  onTap: _createFood,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
