import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/data_provider.dart';
import '../providers/foods_provider.dart';
import '../providers/purchases_provider.dart';
import 'foods_view.dart';
import 'home_view.dart';
import 'recipes_view.dart';
import 'shopping_lists_view.dart';

/// Raíz de la app: barra inferior con los cuatro módulos. Cada pestaña es
/// independiente y conserva su estado (IndexedStack); las subpantallas se
/// abren con `Navigator.push` sobre la barra. "Alimentos" muestra cuántos
/// están pendientes de completar.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _pages = <Widget>[
    HomeView(),
    FoodsView(),
    RecipesView(),
    ShoppingListsView(),
  ];

  @override
  Widget build(BuildContext context) {
    // Al abrir la app se purga el historial de precios de más de 3 meses.
    ref.watch(purgeOnStartupProvider);
    // Y se incorpora, una vez por versión, la lista de frutas y verduras.
    ref.listen<AsyncValue<int>>(autoImportProduceProvider, (_, next) {
      final n = next.valueOrNull ?? 0;
      if (n > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se añadieron $n frutas, verduras y hortalizas a tus alimentos.',
            ),
          ),
        );
      }
    });
    final pendientes = ref.watch(pendingCountProvider).valueOrNull ?? 0;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Calorías',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendientes > 0,
              label: Text('$pendientes'),
              child: const Icon(Icons.kitchen_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendientes > 0,
              label: Text('$pendientes'),
              child: const Icon(Icons.kitchen),
            ),
            label: 'Alimentos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recetas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
        ],
      ),
    );
  }
}
