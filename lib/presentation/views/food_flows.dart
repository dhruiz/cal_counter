import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food.dart';
import '../../domain/errors/domain_errors.dart';
import '../../domain/services/barcode.dart';
import '../../domain/services/scale_barcode.dart';
import '../providers/foods_provider.dart';
import '../widgets/add_food_popup.dart';
import 'food_form_view.dart';
import 'food_picker_view.dart';
import 'recipe_detail_view.dart';

/// Flujos compartidos "en casa" sobre alimentos: completar pendientes,
/// resolver un código de barras y registrar en el contador.
class FoodFlows {
  FoodFlows._();

  /// Devuelve el alimento con la tabla completa. Si está pendiente, ofrece
  /// completarla en ese momento (formulario + lectura de etiqueta). Null si
  /// el usuario no la completa.
  static Future<Food?> ensureComplete(
    BuildContext context,
    WidgetRef ref,
    Food food,
  ) async {
    if (!food.pendiente) return food;
    // El alimento de una receta se completa en la receta (su tabla se
    // calcula de los ingredientes y se sobrescribiría).
    final receta = food.id == null
        ? null
        : await ref.read(recipeRepositoryProvider).watchByFood(food.id!).first;
    if (receta != null) {
      if (!context.mounted) return null;
      final ver = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Faltan datos de la receta'),
          content: Text(
            '«${food.nombreCompleto}» es el alimento de la receta '
            '«${receta.nombre}» y aún no se puede contar: añade sus '
            'ingredientes con su cantidad.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ahora no'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ver receta'),
            ),
          ],
        ),
      );
      if (ver == true && context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailView(recipeId: receta.id!),
          ),
        );
      }
      return null;
    }
    if (!context.mounted) return null;
    final faltan = food.nutricion.faltantes
        .map((n) => n.etiqueta.toLowerCase())
        .join(', ');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Falta la tabla nutricional'),
        content: Text(
          '"${food.nombreCompleto}" no tiene $faltan. Complétalo para poder '
          'contarlo (puedes leer la etiqueta con la cámara).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Completar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return null;
    final id = await FoodFormView.open(context, food: food, completar: true);
    if (id == null) return null;
    final updated = await ref.read(foodRepositoryProvider).getFood(id);
    if (updated == null || updated.pendiente) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sigue pendiente: faltan datos esenciales.'),
          ),
        );
      }
      return null;
    }
    return updated;
  }

  /// Registra el alimento en el día actual (completándolo antes si hace
  /// falta). Devuelve true si se añadió.
  static Future<bool> registerIntake(
    BuildContext context,
    WidgetRef ref,
    Food food, {
    double? initialQuantity,
  }) async {
    if (!food.esAlimento) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '«${food.nombreCompleto}» no es un alimento: no se cuenta en el día.',
          ),
        ),
      );
      return false;
    }
    final complete = await ensureComplete(context, ref, food);
    if (complete == null || !context.mounted) return false;
    return AddFoodPopup.showForToday(
      context,
      ref,
      complete,
      initialQuantity: initialQuantity,
    );
  }

  /// Código escaneado EN CASA: devuelve su alimento. Si no está registrado,
  /// ofrece darlo de alta completo (con tabla nutricional) o añadirlo como
  /// otra presentación de un alimento existente.
  static Future<Food?> foodForBarcode(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async => (await scanAtHome(context, ref, code))?.food;

  /// Como [foodForBarcode], y si es una etiqueta de báscula con el peso
  /// incrustado devuelve también los gramos del paquete.
  static Future<({Food food, double? gramos})?> scanAtHome(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    if (isVariableMeasure(code)) {
      final matches = await ref
          .read(scaleRepositoryProvider)
          .findAnyStore(code);
      if (!context.mounted) return null;
      if (matches.isNotEmpty) {
        final m = matches.first;
        final label = ScaleLabel.parse(
          code,
          longitudClave: m.tienda.longitudClave,
        );
        final gramos =
            (label != null && m.tienda.formatoBascula == ScaleFormat.peso)
            ? label.comoPesoG
            : null;
        return (food: m.alimento, gramos: gramos);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Etiqueta de báscula aún sin aprender: escanéala una vez en el '
            'modo carrito. Ahora elige el alimento.',
          ),
        ),
      );
      final food = await FoodPickerView.pick(context);
      return food == null ? null : (food: food, gramos: null);
    }
    final food = await _foodForBarcode(context, ref, code);
    return food == null ? null : (food: food, gramos: null);
  }

  static Future<Food?> _foodForBarcode(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final repo = ref.read(foodRepositoryProvider);
    final match = await repo.findByBarcode(code);
    if (!context.mounted) return null;
    if (match != null) {
      if (match.food.archivado) {
        await repo.setArchived(match.food.id!, false);
        return match.food.copyWith(archivado: false);
      }
      return match.food;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Código no registrado'),
              subtitle: Text(code),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Dar de alta un alimento nuevo'),
              subtitle: const Text('Nombre, marca y tabla nutricional'),
              onTap: () => Navigator.pop(ctx, 'nuevo'),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Es otra presentación de uno que ya tengo'),
              subtitle: const Text('Otro tamaño o envase del mismo producto'),
              onTap: () => Navigator.pop(ctx, 'existente'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return null;
    if (choice == 'nuevo') {
      final id = await FoodFormView.open(context, codigoBarras: code);
      return id == null ? null : repo.getFood(id);
    }
    final food = await FoodPickerView.pick(
      context,
      title: 'Elegir alimento para el código',
    );
    if (food == null || !context.mounted) return null;
    try {
      await repo.savePackage(
        FoodPackage(alimentoId: food.id!, codigoBarras: code),
      );
    } on DuplicateBarcodeException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return null;
    }
    return food;
  }
}
