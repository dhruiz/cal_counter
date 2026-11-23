import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/price_stats.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/food_repository.dart';
import 'core_providers.dart';

export 'core_providers.dart';

/// Parámetros de una búsqueda en el repertorio.
class FoodQuery extends Equatable {
  final String texto;
  final FoodFilter filtro;

  /// Null = todas; [kSinCategoria] = sin categoría.
  final int? categoriaId;

  const FoodQuery(
    this.texto, [
    this.filtro = FoodFilter.todos,
    this.categoriaId,
  ]);

  @override
  List<Object?> get props => [texto, filtro, categoriaId];
}

/// Resultados de búsqueda (texto o código) que se actualizan solos.
final foodSearchProvider = StreamProvider.autoDispose
    .family<List<Food>, FoodQuery>(
      (ref, q) => ref
          .watch(foodRepositoryProvider)
          .watchSearch(q.texto, filter: q.filtro, categoriaId: q.categoriaId),
    );

final foodProvider = StreamProvider.autoDispose.family<Food?, int>(
  (ref, id) => ref.watch(foodRepositoryProvider).watchFood(id),
);

final foodPortionsProvider = StreamProvider.autoDispose
    .family<List<FoodPortion>, int>(
      (ref, id) => ref.watch(foodRepositoryProvider).watchPortions(id),
    );

final foodPackagesProvider = StreamProvider.autoDispose
    .family<List<FoodPackage>, int>(
      (ref, id) => ref.watch(foodRepositoryProvider).watchPackages(id),
    );

final mostUsedFoodsProvider = StreamProvider.autoDispose<List<Food>>(
  (ref) => ref.watch(foodRepositoryProvider).watchMostUsed(),
);

/// Alimentos pendientes de completar, por prioridad.
final pendingFoodsProvider = StreamProvider.autoDispose<List<Food>>(
  (ref) => ref.watch(foodRepositoryProvider).watchPending(),
);

/// Número de pendientes (insignia de la pestaña Alimentos).
final pendingCountProvider = StreamProvider<int>(
  (ref) => ref.watch(foodRepositoryProvider).watchPendingCount(),
);

/// Compras del alimento (todas sus presentaciones), recientes primero.
final foodPurchasesProvider = StreamProvider.autoDispose
    .family<List<PurchaseRecord>, int>(
      (ref, id) =>
          ref.watch(purchaseRepositoryProvider).watchPurchasesForFood(id),
    );

/// Estadísticas de precio del alimento.
final foodPriceStatsProvider = Provider.autoDispose.family<PriceStats, int>((
  ref,
  id,
) {
  final compras = ref.watch(foodPurchasesProvider(id)).valueOrNull ?? const [];
  return ref.watch(getPriceStatsProvider)([for (final c in compras) c.compra]);
});

/// Recetas que usan el alimento.
final recipesUsingFoodProvider = StreamProvider.autoDispose
    .family<List<Recipe>, int>(
      (ref, id) => ref.watch(recipeRepositoryProvider).watchUsingFood(id),
    );

/// Categorías en el orden general de los pasillos, o en el de una tienda.
final categoriesProvider = StreamProvider.autoDispose
    .family<List<Category>, String?>(
      (ref, tienda) =>
          ref.watch(categoryRepositoryProvider).watchCategories(tienda: tienda),
    );

/// ¿La tienda tiene orden de pasillos propio?
final hasStoreOrderProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, tienda) =>
      ref.watch(categoryRepositoryProvider).watchHasStoreOrder(tienda),
);
