import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../providers/foods_provider.dart';
import 'food_widgets.dart';

/// Cuerpo de los buscadores de alimentos: más usados (con el buscador vacío),
/// resultados por texto o código y "Crear «lo que escribiste»".
class FoodSearchBody extends ConsumerWidget {
  final String query;
  final FoodFilter filter;
  final ValueChanged<Food> onSelect;
  final ValueChanged<Food>? onLongPress;

  /// Si se indica, se ofrece crear un alimento con el texto buscado.
  final ValueChanged<String>? onCreate;
  final bool showMostUsed;
  final String emptyHint;

  const FoodSearchBody({
    super.key,
    required this.query,
    required this.onSelect,
    this.filter = FoodFilter.todos,
    this.onLongPress,
    this.onCreate,
    this.showMostUsed = true,
    this.emptyHint = 'Escribe para buscar o escanea un código',
  });

  Widget _createTile(BuildContext context) {
    final q = query.trim();
    return ListTile(
      leading: const Icon(Icons.add_circle_outline),
      title: Text(q.isEmpty ? 'Crear alimento nuevo' : 'Crear «$q»'),
      onTap: () => onCreate!(q),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = query.trim();
    if (q.isEmpty && showMostUsed && filter == FoodFilter.todos) {
      final mostUsed = ref.watch(mostUsedFoodsProvider).valueOrNull ?? [];
      if (mostUsed.isEmpty) {
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyHint, textAlign: TextAlign.center),
            ),
            if (onCreate != null) _createTile(context),
          ],
        );
      }
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Usados con frecuencia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final f in mostUsed)
            FoodTile(
              food: f,
              onTap: () => onSelect(f),
              onLongPress: onLongPress == null ? null : () => onLongPress!(f),
            ),
          if (onCreate != null) _createTile(context),
        ],
      );
    }

    final async = ref.watch(foodSearchProvider(FoodQuery(q, filter)));
    final results = async.valueOrNull;
    if (results == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (results.isEmpty) {
      return ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se encontraron alimentos.',
              textAlign: TextAlign.center,
            ),
          ),
          if (onCreate != null) _createTile(context),
        ],
      );
    }
    return ListView.builder(
      itemCount: results.length + (onCreate == null ? 0 : 1),
      itemBuilder: (ctx, i) {
        if (i == results.length) return _createTile(ctx);
        final f = results[i];
        return FoodTile(
          food: f,
          onTap: () => onSelect(f),
          onLongPress: onLongPress == null ? null : () => onLongPress!(f),
        );
      },
    );
  }
}
