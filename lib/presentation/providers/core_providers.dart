import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/drift_transaction_runner.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../data/repositories/shopping_list_repository_impl.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/meal_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import '../../domain/repositories/transaction_runner.dart';
import '../../domain/usecases/add_food_to_meal.dart';
import '../../domain/usecases/add_ingredients_to_shopping_list.dart';
import '../../domain/usecases/cart.dart';
import '../../domain/usecases/create_meal_if_not_exists.dart';
import '../../domain/usecases/food_registration.dart';
import '../../domain/usecases/get_price_stats.dart';
import '../../domain/usecases/purge_old_purchases.dart';
import '../../domain/usecases/register_purchase.dart';
import '../../domain/usecases/save_meal_as_food.dart';

/// Único punto de creación de la base de datos. En tests se sustituye por una
/// en memoria con `ProviderScope(overrides: [appDatabaseProvider...])`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.dispositivo();
  ref.onDispose(db.close);
  return db;
});

final transactionRunnerProvider = Provider<TransactionRunner>(
  (ref) => DriftTransactionRunner(ref.watch(appDatabaseProvider)),
);

// Repositorios -----------------------------------------------------------------

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (ref) => PurchaseRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>(
  (ref) => ShoppingListRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final mealRepositoryProvider = Provider<MealRepository>(
  (ref) => MealRepositoryImpl(ref.watch(appDatabaseProvider)),
);

// Casos de uso -----------------------------------------------------------------

final addFoodToMealProvider = Provider<AddFoodToMeal>(
  (ref) => AddFoodToMeal(ref.watch(mealRepositoryProvider)),
);

final createMealIfNotExistsProvider = Provider<CreateMealIfNotExists>(
  (ref) => CreateMealIfNotExists(ref.watch(mealRepositoryProvider)),
);

final saveMealAsFoodProvider = Provider<SaveMealAsFood>(
  (ref) => SaveMealAsFood(ref.watch(foodRepositoryProvider)),
);

final registerFoodInStoreProvider = Provider<RegisterFoodInStore>(
  (ref) => RegisterFoodInStore(
    ref.watch(foodRepositoryProvider),
    ref.watch(transactionRunnerProvider),
  ),
);

final saveFoodWithPackageProvider = Provider<SaveFoodWithPackage>(
  (ref) => SaveFoodWithPackage(
    ref.watch(foodRepositoryProvider),
    ref.watch(transactionRunnerProvider),
  ),
);

final registerPurchaseProvider = Provider<RegisterPurchase>(
  (ref) => RegisterPurchase(
    ref.watch(foodRepositoryProvider),
    ref.watch(purchaseRepositoryProvider),
  ),
);

final purgeOldPurchasesProvider = Provider<PurgeOldPurchases>(
  (ref) => PurgeOldPurchases(ref.watch(purchaseRepositoryProvider)),
);

final getPriceStatsProvider = Provider<GetPriceStats>((ref) => GetPriceStats());

final addToCartProvider = Provider<AddToCart>(
  (ref) => AddToCart(
    ref.watch(shoppingListRepositoryProvider),
    ref.watch(purchaseRepositoryProvider),
    ref.watch(foodRepositoryProvider),
    ref.watch(transactionRunnerProvider),
  ),
);

final updateCartItemProvider = Provider<UpdateCartItem>(
  (ref) => UpdateCartItem(
    ref.watch(shoppingListRepositoryProvider),
    ref.watch(purchaseRepositoryProvider),
    ref.watch(transactionRunnerProvider),
  ),
);

final removeFromCartProvider = Provider<RemoveFromCart>(
  (ref) => RemoveFromCart(
    ref.watch(shoppingListRepositoryProvider),
    ref.watch(purchaseRepositoryProvider),
    ref.watch(transactionRunnerProvider),
  ),
);

final addIngredientsToShoppingListProvider =
    Provider<AddIngredientsToShoppingList>(
      (ref) => AddIngredientsToShoppingList(
        ref.watch(shoppingListRepositoryProvider),
      ),
    );
