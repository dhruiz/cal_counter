import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/meal_item.dart';
import '../providers/home_provider.dart';

class MealItemsDialog extends ConsumerWidget {
  final String mealName;
  final List<MealItem> items;

  const MealItemsDialog({
    super.key,
    required this.mealName,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(mealName),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No hay items en esta comida.'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    // Stack para anclar los íconos a las esquinas derechas:
                    // Editar (arriba) y Eliminar (abajo). El contenido reserva
                    // espacio a la derecha vía contentPadding.
                    child: Stack(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            48,
                            8,
                          ),
                          title: Text(
                            item.alimento,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Cantidad: ${item.cantidad.toStringAsFixed(1)}g',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '${item.kcal.toStringAsFixed(0)} kcal\n'
                                'G: ${item.grasas.toStringAsFixed(1)}g\n'
                                'C: ${item.carbohidratos.toStringAsFixed(1)}g\n'
                                'P: ${item.proteinas.toStringAsFixed(1)}g',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditQuantityDialog(context, ref, item);
                            },
                            tooltip: 'Editar cantidad',
                          ),
                        ),
                        // Eliminar: ancla la parte superior del ícono en la
                        // línea de 3/4 de la tarjeta (justo encima del 1/4
                        // inferior). Alignment.y=0.5 → top = 0.75*(alto-icono).
                        Positioned.fill(
                          child: Align(
                            alignment: const Alignment(1.0, 0.5),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _showDeleteConfirmation(context, ref, item);
                              },
                              tooltip: 'Eliminar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  void _showEditQuantityDialog(
    BuildContext context,
    WidgetRef ref,
    MealItem item,
  ) {
    final controller = TextEditingController(
      text: item.cantidad.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Cantidad'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nueva cantidad (gramos)',
            suffixText: 'g',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newCantidad = double.tryParse(controller.text);
              if (newCantidad != null && newCantidad > 0) {
                Navigator.pop(ctx);
                await ref
                    .read(homeProvider.notifier)
                    .updateMealItemQuantity(item.id!, newCantidad);
                if (context.mounted) {
                  Navigator.pop(context); // Close the main dialog
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, ingrese una cantidad válida'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    MealItem item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Item'),
        content: Text('¿Seguro que desea eliminar "${item.alimento}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(homeProvider.notifier).deleteMealItem(item.id!);
              if (context.mounted) {
                Navigator.pop(context); // Close the main dialog
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
