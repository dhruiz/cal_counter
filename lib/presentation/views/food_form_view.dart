import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/food.dart';
import '../../domain/errors.dart';
import '../providers/search_provider.dart';

class FoodFormView extends ConsumerStatefulWidget {
  final Food? foodToEdit;

  /// Nombre propuesto al crear (p. ej. el de un producto escaneado).
  final String? initialName;

  const FoodFormView({super.key, this.foodToEdit, this.initialName});

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.foodToEdit;
    _nameController = TextEditingController(
      text: f?.name ?? widget.initialName ?? '',
    );
    String num(double? v) => v == null ? '' : AppUtils.formatDecimalEditable(v);
    _kcalController = TextEditingController(text: num(f?.kcalPer100));
    _protController = TextEditingController(text: num(f?.proteinsPer100));
    _fatsController = TextEditingController(text: num(f?.grasasPer100));
    _carbsController = TextEditingController(text: num(f?.carbsPer100));
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
    if (_saving || !_formKey.currentState!.validate()) return;

    final food = Food(
      id: widget.foodToEdit?.id,
      name: _nameController.text.trim(),
      kcalPer100: AppUtils.parseDecimal(_kcalController.text)!,
      proteinsPer100: AppUtils.parseDecimal(_protController.text)!,
      grasasPer100: AppUtils.parseDecimal(_fatsController.text)!,
      carbsPer100: AppUtils.parseDecimal(_carbsController.text)!,
    );

    final repo = ref.read(foodRepositoryProvider);
    setState(() => _saving = true);

    try {
      if (widget.foodToEdit == null) {
        // Alta: si el nombre ya existe se avisa (antes se sobrescribía en
        // silencio el alimento existente).
        await repo.insertFood(food);
      } else {
        await repo.updateFood(food);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Alimento guardado')));
        Navigator.pop(context, true);
      }
    } on DuplicateFoodNameException catch (e) {
      _fail(e.toString());
    } catch (e) {
      _fail('Error: $e');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
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
                onPressed: _saving ? null : _save,
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
      inputFormatters: [AppUtils.decimalInputFormatter],
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        if (AppUtils.parseDecimal(v) == null) return 'Inválido';
        return null;
      },
    );
  }
}
