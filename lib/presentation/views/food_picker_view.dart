import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../domain/entities/food.dart';
import '../providers/foods_provider.dart';
import '../widgets/food_search_body.dart';
import 'barcode_scanner_view.dart';
import 'food_flows.dart';
import 'food_form_view.dart';

/// Selector de un alimento del repertorio (vincular ingredientes, artículos
/// de listas...). Busca por texto o código y permite crear uno nuevo.
/// Devuelve el alimento elegido o null.
class FoodPickerView extends ConsumerStatefulWidget {
  final String initialQuery;
  final String title;

  /// Solo alimentos (ingredientes de recetas): sin artículos de limpieza,
  /// higiene...; lo que se cree aquí es un alimento.
  final bool soloAlimentos;

  /// Alimentos que no se ofrecen (p. ej. el de la propia receta).
  final Set<int> excluir;

  const FoodPickerView({
    super.key,
    this.initialQuery = '',
    this.title = 'Elegir alimento',
    this.soloAlimentos = false,
    this.excluir = const {},
  });

  static Future<Food?> pick(
    BuildContext context, {
    String initialQuery = '',
    String title = 'Elegir alimento',
    bool soloAlimentos = false,
    Set<int> excluir = const {},
  }) {
    return Navigator.push<Food>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodPickerView(
          initialQuery: initialQuery,
          title: title,
          soloAlimentos: soloAlimentos,
          excluir: excluir,
        ),
      ),
    );
  }

  @override
  ConsumerState<FoodPickerView> createState() => _FoodPickerViewState();
}

class _FoodPickerViewState extends ConsumerState<FoodPickerView> {
  late final TextEditingController _ctrl;
  late String _query;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = v);
    });
  }

  Future<void> _scan() async {
    final code = await BarcodeScannerView.scan(context);
    if (code == null || !mounted) return;
    final food = await FoodFlows.foodForBarcode(context, ref, code);
    if (food == null || !mounted) return;
    if (widget.soloAlimentos && !food.esAlimento) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('«${food.nombreCompleto}» no es un alimento.')),
      );
      return;
    }
    Navigator.pop(context, food);
  }

  Future<void> _create(String nombre) async {
    final id = await FoodFormView.open(
      context,
      nombreInicial: nombre,
      soloAlimento: widget.soloAlimentos,
    );
    if (id == null || !mounted) return;
    final food = await ref.read(foodRepositoryProvider).getFood(id);
    if (food != null && mounted) Navigator.pop(context, food);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Escanear código',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scan,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, marca o código',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: FoodSearchBody(
        query: _query,
        onSelect: (f) => Navigator.pop(context, f),
        onCreate: _create,
        soloAlimentos: widget.soloAlimentos,
        excluir: widget.excluir,
      ),
    );
  }
}
