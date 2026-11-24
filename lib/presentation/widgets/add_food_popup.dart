import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/meal.dart';
import '../../domain/services/meal_naming.dart';
import '../../domain/usecases/add_food_to_meal.dart';
import '../../domain/usecases/create_meal_if_not_exists.dart';
import '../providers/home_provider.dart';
import '../providers/search_provider.dart';
import '../providers/settings_provider.dart';

final addFoodToMealProvider = Provider<AddFoodToMeal>((ref) {
  return AddFoodToMeal(ref.watch(mealRepositoryProvider));
});

final createMealIfNotExistsProvider = Provider<CreateMealIfNotExists>((ref) {
  return CreateMealIfNotExists(ref.watch(mealRepositoryProvider));
});

class AddFoodPopup extends ConsumerStatefulWidget {
  final Food food;
  final List<Meal> availableMeals;
  final DateTime selectedDate;

  /// Cantidad inicial en gramos (p. ej. la porción de una receta). Si es null
  /// se sugiere el máximo que cabe en las metas restantes.
  final double? initialQuantity;

  const AddFoodPopup({
    super.key,
    required this.food,
    required this.availableMeals,
    required this.selectedDate,
    this.initialQuantity,
  });

  /// Abre el popup sobre el día actual del contador (desde recetas o
  /// productos) y refresca [homeProvider] si se agregó. Devuelve true si se
  /// agregó.
  static Future<bool> showForToday(
    BuildContext context,
    WidgetRef ref,
    Food food, {
    double? initialQuantity,
  }) async {
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
    if (added == true) {
      await ref.read(homeProvider.notifier).refresh();
      return true;
    }
    return false;
  }

  @override
  ConsumerState<AddFoodPopup> createState() => _AddFoodPopupState();
}

class _AddFoodPopupState extends ConsumerState<AddFoodPopup> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  Meal? _selectedMeal;
  bool _isCreatingNewMeal = false;

  /// Evita un segundo envío mientras se guarda (antes, dos toques rápidos en
  /// "Ok" añadían el alimento dos veces).
  bool _submitting = false;

  /// Nombre de la comida que se creará con "Nueva comida".
  late final String _newMealName = nextMealName(widget.availableMeals);

  double? get _quantity {
    final q = AppUtils.parseDecimal(_quantityController.text);
    return (q != null && q > 0) ? q : null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.availableMeals.isNotEmpty) {
      _selectedMeal = widget.availableMeals.last;
    } else {
      // If no meals, we default to creating "Comida_1"
      _isCreatingNewMeal = true;
    }
    final initial = widget.initialQuantity;
    if (initial != null && initial > 0) {
      _quantityController.text = AppUtils.formatNumero(initial);
      _quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantityController.text.length,
      );
    } else {
      _prefillSuggestedQuantity();
    }
  }

  /// Pre-rellena la cantidad con el máximo de gramos que no supera NINGUNA
  /// meta diaria (kcal, grasas, carbos, proteínas): para cada límite se
  /// calcula cuántos gramos caben en su restante (meta exacta, sin
  /// tolerancia) y se sugiere el menor. Si ya no queda margen o el alimento
  /// no aporta nada, el campo se deja vacío.
  void _prefillSuggestedQuantity() {
    final settings = ref.read(settingsProvider);
    final home = ref.read(homeProvider);
    final food = widget.food;

    double? maxGrams;
    void consider(double remaining, double per100) {
      if (per100 <= 0) return; // este nutriente no limita
      final grams = remaining * 100 / per100;
      if (maxGrams == null || grams < maxGrams!) maxGrams = grams;
    }

    consider(settings.kcalTarget - home.totalKcal, food.kcalPer100);
    consider(settings.fatsRequired - home.totalFats, food.grasasPer100);
    consider(settings.carbsRequired - home.totalCarbs, food.carbsPer100);
    consider(
      settings.proteinsRequired - home.totalProteins,
      food.proteinsPer100,
    );

    if (maxGrams == null) return; // alimento sin valores nutricionales

    final suggestion = maxGrams!.floor();
    if (suggestion <= 0) return; // alguna meta ya alcanzada/superada

    _quantityController.text = suggestion.toString();
    // Pre-selecciona todo el valor sugerido: con el campo enfocado
    // (autofocus) el usuario puede sobrescribirlo de inmediato o aceptarlo.
    _quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _quantityController.text.length,
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final quantity = _quantity;
    if (quantity == null) return;
    setState(() => _submitting = true);

    try {
      final int mealId;
      if (_isCreatingNewMeal || _selectedMeal == null) {
        // "Comida_N" libre (nextMealName): con `comidas + 1` el nombre podía
        // existir ya y el alimento acababa en esa otra comida.
        final createMeal = ref.read(createMealIfNotExistsProvider);
        mealId = await createMeal(_newMealName, widget.selectedDate);
      } else {
        mealId = _selectedMeal!.id!;
      }

      final addFood = ref.read(addFoodToMealProvider);
      await addFood(mealId: mealId, food: widget.food, quantity: quantity);

      // Registra el uso para la lista de "más usados" (persistente en db_alimentos).
      final foodId = widget.food.id;
      if (foodId != null) {
        await ref.read(recordFoodUsageProvider)(foodId);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo agregar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar ${widget.food.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _quantityController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Cantidad (g)',
                suffixText: 'g',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [AppUtils.decimalInputFormatter],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final n = AppUtils.parseDecimal(value);
                if (n == null || n <= 0) return '> 0';
                return null;
              },
              onChanged: (_) => setState(() {}), // Update button state
            ),
            const SizedBox(height: 16),
            if (!_isCreatingNewMeal && widget.availableMeals.isNotEmpty)
              DropdownButtonFormField<Meal>(
                initialValue: _selectedMeal,
                decoration: const InputDecoration(labelText: 'Comida'),
                items: widget.availableMeals.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m.name));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedMeal = val;
                  });
                },
              ),
            if (!_isCreatingNewMeal)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isCreatingNewMeal = true;
                    _selectedMeal = null;
                  });
                },
                child: const Text('Nueva Comida'),
              ),
            if (_isCreatingNewMeal)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Se creará: $_newMealName',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _quantity != null && !_submitting ? _submit : null,
          child: const Text('Ok'),
        ),
      ],
    );
  }
}
