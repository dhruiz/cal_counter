import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/shopping_list.dart';
import '../providers/shopping_provider.dart';
import '../widgets/empty_state.dart';
import 'shopping_list_detail_view.dart';

/// Pestaña "Compras": listas de compra.
class ShoppingListsView extends ConsumerWidget {
  const ShoppingListsView({super.key});

  /// Pide un nombre (nuevo o renombrar). Devuelve null si se cancela.
  static Future<String?> askName(
    BuildContext context, {
    required String title,
    required String initial,
  }) async {
    final ctrl = TextEditingController(text: initial);
    ctrl.selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return (name == null || name.isEmpty) ? null : name;
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await askName(
      context,
      title: 'Nueva lista',
      initial: 'Compra ${AppUtils.formatFechaCorta(DateTime.now())}',
    );
    if (name == null || !context.mounted) return;
    final id = await ref.read(shoppingListsProvider.notifier).create(name);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShoppingListDetailView(listaId: id)),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final name = await askName(
      context,
      title: 'Renombrar lista',
      initial: list.nombre,
    );
    if (name != null) {
      await ref.read(shoppingListsProvider.notifier).rename(list.id!, name);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar lista'),
        content: Text('¿Eliminar "${list.nombre}" y todos sus artículos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(shoppingListsProvider.notifier).delete(list.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingListsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas de compra'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nueva_lista',
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva lista'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.lists.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Aún no tienes listas',
              message:
                  'Crea una lista y ve añadiendo lo que necesitas, o lleva '
                  'los ingredientes que te faltan desde una receta.',
              actions: [
                ElevatedButton.icon(
                  onPressed: () => _create(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear mi primera lista'),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
              itemCount: state.lists.length,
              itemBuilder: (ctx, i) {
                final list = state.lists[i];
                final done =
                    list.totalItems > 0 && list.comprados == list.totalItems;
                return Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: done
                          ? const Icon(
                              Icons.check_circle,
                              color: AppStyles.semaphGreen,
                              size: 36,
                            )
                          : CircularProgressIndicator(
                              value: list.totalItems == 0
                                  ? 0
                                  : list.comprados / list.totalItems,
                              backgroundColor: Colors.grey.withValues(
                                alpha: 0.25,
                              ),
                            ),
                    ),
                    title: Text(list.nombre),
                    subtitle: Text(
                      list.totalItems == 0
                          ? 'Vacía · creada el ${AppUtils.formatFecha(list.creada)}'
                          : '${list.comprados} de ${list.totalItems} comprados',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'rename') _rename(context, ref, list);
                        if (v == 'delete') _delete(context, ref, list);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('Renombrar'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ShoppingListDetailView(listaId: list.id!),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
