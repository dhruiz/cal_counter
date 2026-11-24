import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/user_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _formKey = GlobalKey<FormState>();

  // Existing controllers
  late TextEditingController _weightController;
  late TextEditingController _kcalController;
  late TextEditingController _proteinsController;
  late TextEditingController _fatsController;
  late TextEditingController _toleranceController;

  // New TDEE controllers
  late TextEditingController _bodyFatController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  late String _selectedSex;
  late double _selectedActivity;

  // Weight goal
  late String _selectedGoal;
  late TextEditingController _adjustmentController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);

    _weightController = TextEditingController(
      text: AppUtils.formatDecimalEditable(settings.weightKg),
    );
    _kcalController = TextEditingController(
      text: settings.kcalTarget.toString(),
    );
    _proteinsController = TextEditingController(
      text: AppUtils.formatDecimalEditable(settings.proteinsPerKg),
    );
    _fatsController = TextEditingController(
      text: AppUtils.formatDecimalEditable(settings.fatsPerKg),
    );
    _toleranceController = TextEditingController(
      text: settings.tolerancePercent.toString(),
    );

    // TDEE fields
    _bodyFatController = TextEditingController(
      text: settings.bodyFatPercent == null
          ? ''
          : AppUtils.formatDecimalEditable(settings.bodyFatPercent!),
    );
    _heightController = TextEditingController(
      text: AppUtils.formatDecimalEditable(settings.heightCm),
    );
    _ageController = TextEditingController(text: settings.age.toString());
    _selectedSex = settings.sex;
    _selectedActivity = settings.activityFactor;

    _selectedGoal = settings.goal;
    _adjustmentController = TextEditingController(
      text: settings.adjustmentPercent.toString(),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _kcalController.dispose();
    _proteinsController.dispose();
    _fatsController.dispose();
    _toleranceController.dispose();
    _bodyFatController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _adjustmentController.dispose();
    super.dispose();
  }

  /// Lee los campos decimales aceptando coma o punto.
  double? _decimal(TextEditingController c) => AppUtils.parseDecimal(c.text);

  bool _isBodyFatValid() {
    final value = _decimal(_bodyFatController);
    return value != null && value > 0 && value <= 60;
  }

  /// Recalcula la kcal objetivo automáticamente a partir de los datos
  /// personales, el factor de actividad y el objetivo de peso.
  /// Silencioso: si faltan datos o son inválidos, no toca el campo.
  void _recalculateTDEE() {
    final weight = _decimal(_weightController);
    if (weight == null || weight <= 0) return;

    double tmb;
    if (_isBodyFatValid()) {
      // Katch-McArdle (solo requiere peso y % grasa)
      final bodyFat = _decimal(_bodyFatController)!;
      final lbm = weight * (1 - (bodyFat / 100));
      tmb = 370 + (21.6 * lbm);
    } else {
      // Mifflin-St Jeor (requiere altura y edad)
      final height = _decimal(_heightController);
      final age = int.tryParse(_ageController.text);
      if (height == null || height <= 0 || age == null || age <= 0) return;
      final c = _selectedSex == 'male' ? 5.0 : -161.0;
      tmb = (10 * weight) + (6.25 * height) - (5 * age) + c;
    }

    final tdee = tmb * _selectedActivity;

    // Ajuste por objetivo de peso: déficit (perder) o superávit (ganar)
    final adjustment = int.tryParse(_adjustmentController.text) ?? 0;
    double target = tdee;
    if (_selectedGoal == 'lose') {
      target = tdee * (1 - adjustment / 100);
    } else if (_selectedGoal == 'gain') {
      target = tdee * (1 + adjustment / 100);
    }

    _kcalController.text = target.round().toString();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newSettings = UserSettings(
        weightKg: _decimal(_weightController)!,
        kcalTarget: int.parse(_kcalController.text),
        proteinsPerKg: _decimal(_proteinsController)!,
        fatsPerKg: _decimal(_fatsController)!,
        tolerancePercent: int.parse(_toleranceController.text),
        bodyFatPercent: _decimal(_bodyFatController),
        heightCm: _decimal(_heightController)!,
        age: int.parse(_ageController.text),
        sex: _selectedSex,
        activityFactor: _selectedActivity,
        goal: _selectedGoal,
        adjustmentPercent: int.tryParse(_adjustmentController.text) ?? 0,
      );

      ref.read(settingsProvider.notifier).updateSettings(newSettings);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    // Con "seguir al sistema" el interruptor refleja el tema que se ve.
    final isDarkMode = ThemeNotifier.isDarkFor(
      themeMode,
      MediaQuery.platformBrightnessOf(context),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, size: 20),
              Switch(
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).setDark(value);
                },
                activeThumbColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildSectionTitle('Datos Personales'),
              _buildTextField(
                controller: _weightController,
                label: 'Peso (kg)',
                isDecimal: true,
                onValueChanged: _recalculateTDEE,
              ),
              _buildTextField(
                controller: _heightController,
                label: 'Altura (cm)',
                isDecimal: true,
                onValueChanged: _recalculateTDEE,
              ),
              _buildTextField(
                controller: _ageController,
                label: 'Edad (años)',
                isDecimal: false,
                onValueChanged: _recalculateTDEE,
              ),
              _buildTextField(
                controller: _bodyFatController,
                label: '% Grasa Corporal (opcional)',
                isDecimal: true,
                isRequired: false,
                isBodyFat: true,
                onValueChanged: _recalculateTDEE,
              ),
              const SizedBox(height: AppStyles.paddingSmall),

              // Sex selector
              _buildSexSelector(),
              const SizedBox(height: AppStyles.paddingSmall),

              // Activity factor dropdown
              _buildActivityDropdown(),
              const SizedBox(height: AppStyles.paddingMedium),

              // Weight goal selector (recálculo automático de TDEE)
              _buildGoalSelector(),
              const SizedBox(height: AppStyles.paddingLarge),

              _buildSectionTitle('Objetivos'),
              _buildTextField(
                controller: _kcalController,
                label: 'Kcal Objetivo',
                isDecimal: false,
              ),
              _buildTextField(
                controller: _proteinsController,
                label: 'Proteínas (g/kg)',
                isDecimal: true,
              ),
              _buildTextField(
                controller: _fatsController,
                label: 'Grasas (g/kg)',
                isDecimal: true,
              ),
              _buildTextField(
                controller: _toleranceController,
                label: 'Tolerancia (%)',
                isDecimal: false,
                isTolerance: true,
              ),

              const SizedBox(height: AppStyles.paddingLarge),
              _buildCalculatedValues(),

              const SizedBox(height: AppStyles.paddingLarge),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Aceptar', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.paddingSmall),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSexSelector() {
    final isBodyFatValid = _isBodyFatValid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sexo', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'male',
              label: Text('Hombre'),
              icon: Icon(Icons.man),
            ),
            ButtonSegment(
              value: 'female',
              label: Text('Mujer'),
              icon: Icon(Icons.woman),
            ),
          ],
          selected: {_selectedSex},
          onSelectionChanged: isBodyFatValid
              ? null
              : (Set<String> newSelection) {
                  setState(() {
                    _selectedSex = newSelection.first;
                    _recalculateTDEE();
                  });
                },
        ),
        if (isBodyFatValid)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Deshabilitado (% grasa corporal introducido)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActivityDropdown() {
    return DropdownButtonFormField<double>(
      initialValue: _selectedActivity,
      decoration: const InputDecoration(
        labelText: 'Factor de Actividad',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 1.2, child: Text('1.2 - Sedentario')),
        DropdownMenuItem(value: 1.375, child: Text('1.375 - Ejercicio ligero')),
        DropdownMenuItem(value: 1.55, child: Text('1.55 - Ejercicio moderado')),
        DropdownMenuItem(
          value: 1.725,
          child: Text('1.725 - Ejercicio intenso'),
        ),
        DropdownMenuItem(value: 1.9, child: Text('1.9 - Atleta extremo')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedActivity = value!;
          _recalculateTDEE();
        });
      },
      validator: (value) {
        if (value == null) return 'Requerido';
        return null;
      },
    );
  }

  Widget _buildGoalSelector() {
    final isMaintain = _selectedGoal == 'maintain';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Objetivo de peso', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'lose',
              label: Text('Perder'),
              icon: Icon(Icons.trending_down),
            ),
            ButtonSegment(
              value: 'maintain',
              label: Text('Mantener'),
              icon: Icon(Icons.trending_flat),
            ),
            ButtonSegment(
              value: 'gain',
              label: Text('Ganar'),
              icon: Icon(Icons.trending_up),
            ),
          ],
          selected: {_selectedGoal},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selectedGoal = newSelection.first;
              _recalculateTDEE();
            });
          },
        ),
        if (!isMaintain) ...[
          const SizedBox(height: AppStyles.paddingMedium),
          TextFormField(
            controller: _adjustmentController,
            decoration: InputDecoration(
              labelText: _selectedGoal == 'lose'
                  ? 'Déficit calórico (%)'
                  : 'Superávit calórico (%)',
              border: const OutlineInputBorder(),
              suffixText: '%',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (_selectedGoal == 'maintain') return null;
              final n = int.tryParse(value ?? '');
              if (n == null || n <= 0 || n > 50) return '1 - 50';
              return null;
            },
            onChanged: (_) => setState(() => _recalculateTDEE()),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDecimal,
    bool isTolerance = false,
    bool isRequired = true,
    bool isBodyFat = false,
    VoidCallback? onValueChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
        inputFormatters: [
          isDecimal
              ? AppUtils.decimalInputFormatter
              : FilteringTextInputFormatter.digitsOnly,
        ],
        validator: (value) {
          if (!isRequired && (value == null || value.trim().isEmpty)) {
            return null; // Optional field
          }

          if (value == null || value.trim().isEmpty) {
            return 'Requerido';
          }

          if (isBodyFat) {
            final n = AppUtils.parseDecimal(value);
            if (n == null || n <= 0 || n > 60) {
              return 'Debe estar entre 1% y 60%';
            }
          } else if (isTolerance) {
            final n = int.tryParse(value);
            if (n == null || n < 0 || n > 100) return '0 - 100';
          } else {
            final n = isDecimal
                ? AppUtils.parseDecimal(value)
                : int.tryParse(value);
            if (n == null || n <= 0) return 'Debe ser positivo';
          }

          return null;
        },
        onChanged: (_) => setState(() {
          onValueChanged?.call();
        }), // Rebuild + recálculo automático de TDEE cuando aplica
      ),
    );
  }

  Widget _buildCalculatedValues() {
    // Misma fórmula que el contador (UserSettings), con lo que hay escrito.
    final preview = ref
        .read(settingsProvider)
        .copyWith(
          weightKg: _decimal(_weightController) ?? 0,
          kcalTarget: int.tryParse(_kcalController.text) ?? 0,
          proteinsPerKg: _decimal(_proteinsController) ?? 0,
          fatsPerKg: _decimal(_fatsController) ?? 0,
        );
    final proteinsReq = preview.proteinsRequired;
    final fatsReq = preview.fatsRequired;
    final carbsReq = preview.carbsRequired;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requerimientos Calculados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildResultRow('Proteínas', '${proteinsReq.toStringAsFixed(1)} g'),
            _buildResultRow('Grasas', '${fatsReq.toStringAsFixed(1)} g'),
            _buildResultRow(
              'Carbohidratos',
              '${carbsReq.toStringAsFixed(1)} g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
