import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../domain/entities/food.dart';
import '../providers/foods_provider.dart';
import '../widgets/food_search_body.dart';
import 'barcode_scanner_view.dart';
import 'food_detail_view.dart';
import 'food_flows.dart';
import 'food_form_view.dart';

/// "Agregar ingesta": busca en el repertorio (texto o código), completa la
/// tabla si el alimento está pendiente y lo registra en el día. Se cierra al
/// registrar.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final _ctrl = TextEditingController();
  String _query = '';
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

  Future<void> _register(Food food) async {
    final navigator = Navigator.of(context);
    final added = await FoodFlows.registerIntake(context, ref, food);
    if (added && mounted) navigator.pop();
  }

  Future<void> _scan() async {
    final code = await BarcodeScannerView.scan(
      context,
      title: 'Escanear envase',
    );
    if (code == null || !mounted) return;
    final res = await FoodFlows.scanAtHome(context, ref, code);
    if (res == null || !mounted) return;
    final navigator = Navigator.of(context);
    final added = await FoodFlows.registerIntake(
      context,
      ref,
      res.food,
      initialQuantity: res.gramos,
    );
    if (added && mounted) navigator.pop();
  }

  Future<void> _create(String nombre) async {
    final id = await FoodFormView.open(
      context,
      nombreInicial: nombre,
      soloAlimento: true,
    );
    if (id == null || !mounted) return;
    final food = await ref.read(foodRepositoryProvider).getFood(id);
    if (food != null && mounted) await _register(food);
  }

  void _actions(Food food) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                food.nombreCompleto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Ver ficha'),
              onTap: () {
                Navigator.pop(ctx);
                FoodDetailView.open(context, food.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(ctx);
                FoodFormView.open(context, food: food);
              },
            ),
            if (food.usoCount > 0)
              ListTile(
                leading: const Icon(Icons.history_toggle_off),
                title: const Text('Quitar de "usados con frecuencia"'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(foodRepositoryProvider).resetUsage(food.id!);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Buscar alimentos o código...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
        ),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scan,
            tooltip: 'Escanear envase',
          ),
        ],
      ),
      body: FoodSearchBody(
        query: _query,
        onSelect: _register,
        onLongPress: _actions,
        onCreate: _create,
        soloAlimentos: true,
      ),
    );
  }
}
