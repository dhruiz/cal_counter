import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food.dart';
import '../../domain/entities/meal.dart';
import '../../domain/usecases/add_food_to_meal.dart';
import '../../domain/usecases/create_meal_if_not_exists.dart';
import '../providers/home_provider.dart';
import '../providers/search_provider.dart';

// We need a provider for AddFoodToMeal and CreateMealIfNotExists
// We can define them here or in home_provider.dart.
// Let's assume they are needed here.

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

  const AddFoodPopup({
    super.key,
    required this.food,
    required this.availableMeals,
    required this.selectedDate,
  });

  @override
  ConsumerState<AddFoodPopup> createState() => _AddFoodPopupState();
}

class _AddFoodPopupState extends ConsumerState<AddFoodPopup> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  Meal? _selectedMeal;
  bool _isCreatingNewMeal = false;

  @override
  void initState() {
    super.initState();
    if (widget.availableMeals.isNotEmpty) {
      _selectedMeal = widget.availableMeals.last;
    } else {
      // If no meals, we default to creating "Comida_1"
      _isCreatingNewMeal = true;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.parse(_quantityController.text);
    int mealId;

    if (_isCreatingNewMeal || _selectedMeal == null) {
      // Create new meal
      // Name logic: Comida_n+1
      // If we have meals, find max index.
      int nextIndex = 1;
      if (widget.availableMeals.isNotEmpty) {
        // Try to parse "Comida_X"
        // Or just count + 1?
        // Requirement says "Nueva Comida permite crear Comida_n+1".
        // Let's assume standard naming "Comida_1", "Comida_2".
        // We can regex parse existing names or just use length + 1.
        // Length + 1 is safer if they are sequential.
        nextIndex = widget.availableMeals.length + 1;
      }
      final name = 'Comida_$nextIndex';

      final createMeal = ref.read(createMealIfNotExistsProvider);
      mealId = await createMeal(name, widget.selectedDate);
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
              decoration: const InputDecoration(
                labelText: 'Cantidad (g)',
                suffixText: 'g',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requerido';
                final n = double.tryParse(value);
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
                  'Se creará: Comida_${widget.availableMeals.length + 1}',
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
          onPressed:
              _quantityController.text.isNotEmpty &&
                  double.tryParse(_quantityController.text) != null &&
                  double.parse(_quantityController.text) > 0
              ? _submit
              : null,
          child: const Text('Ok'),
        ),
      ],
    );
  }
}
