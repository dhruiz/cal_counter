import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../providers/foods_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/food_widgets.dart';
import 'barcode_scanner_view.dart';
import 'food_detail_view.dart';
import 'food_flows.dart';
import 'food_form_view.dart';
import 'settings_view.dart';

/// Pestaña "Alimentos": el repertorio, núcleo de recetas, compras y
/// calorías. Búsqueda por texto o código, filtros y pendientes de completar.
class FoodsView extends ConsumerStatefulWidget {
  const FoodsView({super.key});

  @override
  ConsumerState<FoodsView> createState() => _FoodsViewState();
}

class _FoodsViewState extends ConsumerState<FoodsView> {
  final _ctrl = TextEditingController();
  String _query = '';
  FoodFilter _filter = FoodFilter.todos;
  Timer? _debounce;

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
    if (food != null && mounted) await FoodDetailView.open(context, food.id!);
  }

  Future<void> _create() async {
    final id = await FoodFormView.open(
      context,
      nombreInicial: _query.trim().isEmpty ? null : _query.trim(),
    );
    if (id != null && mounted) await FoodDetailView.open(context, id);
  }

  List<Food> _results() {
    // Pendientes sin texto: por prioridad (recetas, compras recientes).
    if (_filter == FoodFilter.pendientes && _query.trim().isEmpty) {
      return ref.watch(pendingFoodsProvider).valueOrNull ?? const [];
    }
    return ref
            .watch(foodSearchProvider(FoodQuery(_query, _filter)))
            .valueOrNull ??
        const [];
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = ref.watch(pendingCountProvider).valueOrNull ?? 0;
    final results = _results();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimentos'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Escanear código',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scan,
          ),
          IconButton(
            tooltip: 'Ajustes y datos',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsView()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, marca o código',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final f in FoodFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        f == FoodFilter.pendientes && pendientes > 0
                            ? '${f.etiqueta} ($pendientes)'
                            : f.etiqueta,
                      ),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          if (pendientes > 0 && _filter == FoodFilter.todos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: InfoBanner(
                color: AppStyles.semaphOrange,
                icon: Icons.edit_note,
                text: pendientes == 1
                    ? '1 alimento pendiente de completar su tabla nutricional.'
                    : '$pendientes alimentos pendientes de completar su tabla '
                          'nutricional.',
                action: TextButton(
                  onPressed: () {
                    _ctrl.clear();
                    setState(() {
                      _query = '';
                      _filter = FoodFilter.pendientes;
                    });
                  },
                  child: const Text('Ver'),
                ),
              ),
            ),
          Expanded(
            child: results.isEmpty
                ? EmptyState(
                    icon: _filter == FoodFilter.pendientes
                        ? Icons.task_alt
                        : Icons.no_food_outlined,
                    title: _filter == FoodFilter.pendientes
                        ? 'Nada pendiente'
                        : 'Sin alimentos',
                    message: _filter == FoodFilter.pendientes
                        ? 'Todos tus alimentos tienen su tabla nutricional.'
                        : (_query.isEmpty
                              ? 'Crea alimentos, escanéalos o importa un '
                                    'repertorio desde Ajustes.'
                              : 'No hay resultados para «$_query».'),
                    actions: [
                      if (_filter != FoodFilter.pendientes)
                        FilledButton.icon(
                          onPressed: _create,
                          icon: const Icon(Icons.add),
                          label: Text(
                            _query.trim().isEmpty
                                ? 'Nuevo alimento'
                                : 'Crear «${_query.trim()}»',
                          ),
                        ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: results.length,
                    itemBuilder: (ctx, i) => FoodTile(
                      food: results[i],
                      onTap: () => FoodDetailView.open(context, results[i].id!),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'foods_fab',
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Alimento'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
    );
  }
}
