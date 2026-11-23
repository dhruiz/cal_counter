import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../providers/foods_provider.dart';

/// Selector de categoría para formularios ("Sin categoría" = null).
class CategoryDropdown extends ConsumerWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? helperText;

  const CategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.helperText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats =
        ref.watch(categoriesProvider(null)).valueOrNull ?? const <Category>[];
    final valido = cats.any((c) => c.id == value) ? value : null;
    return DropdownButtonFormField<int?>(
      key: ValueKey('cat_$valido'),
      initialValue: valido,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Categoría (sección del súper)',
        prefixIcon: const Icon(Icons.category_outlined),
        helperText: helperText,
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Sin categoría')),
        for (final c in cats)
          DropdownMenuItem<int?>(value: c.id, child: Text(c.nombre)),
      ],
      onChanged: onChanged,
    );
  }
}

/// Resultado de [pickCategory] (distingue "sin categoría" de cancelar).
class CategoryChoice {
  final int? categoriaId;

  const CategoryChoice(this.categoriaId);
}

/// Hoja para elegir categoría. Null si se cancela.
Future<CategoryChoice?> pickCategory(
  BuildContext context,
  WidgetRef ref, {
  int? actual,
}) async {
  final cats = await ref.read(categoryRepositoryProvider).getCategories();
  if (!context.mounted) return null;
  return showModalBottomSheet<CategoryChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        children: [
          const ListTile(
            title: Text(
              'Categoría',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final c in cats)
            ListTile(
              leading: Icon(
                c.id == actual
                    ? Icons.radio_button_checked
                    : Icons.circle_outlined,
              ),
              title: Text(c.nombre),
              onTap: () => Navigator.pop(ctx, CategoryChoice(c.id)),
            ),
          ListTile(
            leading: Icon(
              actual == null
                  ? Icons.radio_button_checked
                  : Icons.circle_outlined,
            ),
            title: const Text('Sin categoría'),
            onTap: () => Navigator.pop(ctx, const CategoryChoice(null)),
          ),
        ],
      ),
    ),
  );
}
