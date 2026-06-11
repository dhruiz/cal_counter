import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../data/models/food_model.dart';
import '../../domain/entities/food.dart';
import '../providers/search_provider.dart';

class FoodFormView extends ConsumerStatefulWidget {
  final Food? foodToEdit;

  const FoodFormView({super.key, this.foodToEdit});

  @override
  ConsumerState<FoodFormView> createState() => _FoodFormViewState();
}

class _FoodFormViewState extends ConsumerState<FoodFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _kcalController;
  late TextEditingController _protController;
  late TextEditingController _fatsController;
  late TextEditingController _carbsController;

  @override
  void initState() {
    super.initState();
    final f = widget.foodToEdit;
    _nameController = TextEditingController(text: f?.name ?? '');
    _kcalController = TextEditingController(
      text: f?.kcalPer100.toString() ?? '',
    );
    _protController = TextEditingController(
      text: f?.proteinsPer100.toString() ?? '',
    );
    _fatsController = TextEditingController(
      text: f?.grasasPer100.toString() ?? '',
    );
    _carbsController = TextEditingController(
      text: f?.carbsPer100.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _protController.dispose();
    _fatsController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final kcal = double.parse(_kcalController.text);
    final prot = double.parse(_protController.text);
    final fats = double.parse(_fatsController.text);
    final carbs = double.parse(_carbsController.text);

    final repo = ref.read(foodRepositoryProvider);

    try {
      if (widget.foodToEdit == null) {
        // Create
        final newFood = FoodModel(
          name: name,
          kcalPer100: kcal,
          proteinsPer100: prot,
          grasasPer100: fats,
          carbsPer100: carbs,
        );
        await repo.insertFood(newFood);
      } else {
        // Update
        final updatedFood = FoodModel(
          id: widget.foodToEdit!.id,
          name: name,
          kcalPer100: kcal,
          proteinsPer100: prot,
          grasasPer100: fats,
          carbsPer100: carbs,
        );
        await repo.updateFood(updatedFood);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Alimento guardado')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.foodToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Alimento' : 'Nuevo Alimento'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _buildNumField(_kcalController, 'Kcal (por 100g)'),
              const SizedBox(height: 16),
              _buildNumField(_fatsController, 'Grasas (g)'),
              const SizedBox(height: 16),
              _buildNumField(_carbsController, 'Carbohidratos (g)'),
              const SizedBox(height: 16),
              _buildNumField(_protController, 'Proteínas (g)'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
      ],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        if (double.tryParse(v) == null) return 'Inválido';
        return null;
      },
    );
  }
}
