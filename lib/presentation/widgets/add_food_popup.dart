import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/meal.dart';
import '../../domain/services/money.dart';
import '../providers/foods_provider.dart';
import '../providers/home_provider.dart';
import '../providers/settings_provider.dart';

/// Diálogo para registrar una cantidad de un alimento (con la tabla
/// completa) en una comida del día. Devuelve true si se agregó.
class AddFoodPopup extends ConsumerStatefulWidget {
  final Food food;
  final List<Meal> availableMeals;
  final DateTime selectedDate;

  /// Cantidad inicial (p. ej. la porción de una receta). Si es null se
  /// sugiere el máximo que cabe en las metas restantes.
  final double? initialQuantity;

  const AddFoodPopup({
    super.key,
    required this.food,
    required this.availableMeals,
    required this.selectedDate,
    this.initialQuantity,
  });

  /// Abre el popup sobre el día actual del contador. Devuelve true si se
  /// agregó. (El día se actualiza solo: observa la base de datos.)
  static Future<bool> showForToday(
    BuildContext context,
    WidgetRef ref,
    Food food, {
    double? initialQuantity,
  }) async {
    await ref.read(homeProvider.notifier).refresh();
    if (!context.mounted) return false;
    final homeState = ref.read(homeProvider);
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AddFoodPopup(
        food: food,
        availableMeals: homeState.meals,
        selectedDate: homeState.selectedDate,
        initialQuantity: initialQuantity,
      ),
    );
    return added == true;
  }

  @override
  ConsumerState<AddFoodPopup> createState() => _AddFoodPopupState();
}

class _AddFoodPopupState extends ConsumerState<AddFoodPopup> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  Meal? _selectedMeal;
  bool _isCreatingNewMeal = false;
  bool _saving = false;

  String get _u => widget.food.u;

  @override
  void initState() {
    super.initState();
    if (widget.availableMeals.isNotEmpty) {
      _selectedMeal = widget.availableMeals.last;
    } else {
      _isCreatingNewMeal = true;
    }
    final initial = widget.initialQuantity;
    if (initial != null && initial > 0) {
      _setQuantity(initial);
    } else {
      _prefillSuggestedQuantity();
    }
  }

  void _setQuantity(double v) {
    _quantityController.text = AppUtils.formatNumero(v).replaceAll('.', ',');
    _quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _quantityController.text.length,
    );
  }

  /// Pre-rellena la cantidad con el máximo que no supera NINGUNA meta diaria
  /// (kcal, grasas, carbos, proteínas). Si ya no queda margen o el alimento
  /// no aporta nada, el campo se deja vacío.
  void _prefillSuggestedQuantity() {
    final settings = ref.read(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final home = ref.read(homeProvider);
    final n = widget.food.nutricion;

    double? maxGrams;
    void consider(double remaining, double? per100) {
      if (per100 == null || per100 <= 0) return; // este nutriente no limita
      final grams = remaining * 100 / per100;
      if (maxGrams == null || grams < maxGrams!) maxGrams = grams;
    }

    consider(settings.kcalTarget - home.totalKcal, n.kcal);
    consider(settingsNotifier.fatsRequired - home.totalFats, n.grasas);
    consider(settingsNotifier.carbsRequired - home.totalCarbs, n.carbohidratos);
    consider(
      settingsNotifier.proteinsRequired - home.totalProteins,
      n.proteinas,
    );

    if (maxGrams == null) return;
    final suggestion = maxGrams!.floor();
    if (suggestion <= 0) return;
    _setQuantity(suggestion.toDouble());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  double? get _quantity {
    final q = parseDecimal(_quantityController.text);
    return (q == null || q <= 0) ? null : q;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final quantity = _quantity!;
    setState(() => _saving = true);
    try {
      int mealId;
      if (_isCreatingNewMeal || _selectedMeal == null) {
        final name = 'Comida_${widget.availableMeals.length + 1}';
        mealId = await ref.read(createMealIfNotExistsProvider)(
          name,
          widget.selectedDate,
        );
      } else {
        mealId = _selectedMeal!.id!;
      }
      await ref.read(addFoodToMealProvider)(
        mealId: mealId,
        food: widget.food,
        quantity: quantity,
      );
      // Uso para la lista de "más usados" (persiste en el repertorio).
      final foodId = widget.food.id;
      if (foodId != null) {
        await ref.read(foodRepositoryProvider).incrementUsage(foodId);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo agregar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodId = widget.food.id;
    final portions = foodId == null
        ? const <FoodPortion>[]
        : ref.watch(foodPortionsProvider(foodId)).valueOrNull ?? const [];
    final q = _quantity;
    final kcal = widget.food.nutricion.kcal;

    return AlertDialog(
      title: Text('Agregar ${widget.food.nombreCompleto}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _quantityController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Cantidad ($_u)',
                  suffixText: _u,
                  helperText: (q != null && kcal != null)
                      ? '≈ ${(kcal * q / 100).round()} kcal'
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  final n = parseDecimal(value);
                  if (n == null || n <= 0) return '> 0';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              if (portions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final p in portions)
                      ActionChip(
                        label: Text(
                          '1 ${p.nombre} (${AppUtils.formatNumero(p.gramos)} $_u)',
                        ),
                        onPressed: () => setState(() => _setQuantity(p.gramos)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (!_isCreatingNewMeal && widget.availableMeals.isNotEmpty)
                DropdownButtonFormField<Meal>(
                  initialValue: _selectedMeal,
                  decoration: const InputDecoration(labelText: 'Comida'),
                  items: [
                    for (final m in widget.availableMeals)
                      DropdownMenuItem(value: m, child: Text(m.name)),
                  ],
                  onChanged: (val) => setState(() => _selectedMeal = val),
                ),
              if (!_isCreatingNewMeal)
                TextButton(
                  onPressed: () => setState(() {
                    _isCreatingNewMeal = true;
                    _selectedMeal = null;
                  }),
                  child: const Text('Nueva Comida'),
                ),
              if (_isCreatingNewMeal)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Se creará: Comida_${widget.availableMeals.length + 1}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: q != null && !_saving ? _submit : null,
          child: const Text('Ok'),
        ),
      ],
    );
  }
}
