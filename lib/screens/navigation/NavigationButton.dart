import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:sure_wholesaler/models/cart_model.dart';
import 'package:sure_wholesaler/screens/cart/Cart_Screen.dart';
import 'package:sure_wholesaler/screens/categories/category_screen.dart';
import 'package:sure_wholesaler/screens/home/home_screen.dart';
import 'package:sure_wholesaler/screens/profile/Profile_Screen.dart';
import 'package:sure_wholesaler/notifiers/cart_notifier.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

final regularCartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider).value;
  if (cart == null) return 0;
  
  // Return total quantity of all items in cart (regardless of delivery type)
  // as we bypassed warehouse filtering
  return cart.totalQuantity;
});

// Subscription cart count disabled project-wide.
// final subscriptionCartCountProvider = Provider<int>((ref) {
//   final cart = ref.watch(cartProvider).value;
//   if (cart == null) return 0;
//   final activeWarehouseId =
//       ref.watch(selectedWarehousesProvider).firstOrNull ?? cart.warehouseId;
//   return _cartQuantity(
//     _visibleWarehouseItems(cart, activeWarehouseId)
//         .where((item) => item.isSubscription),
//   );
// });

int _cartQuantity(Iterable<CartItem> items) {
  return items.fold(0, (sum, item) => sum + item.quantity);
}

Iterable<CartItem> _visibleWarehouseItems(
  CartItemModel cart,
  String? activeWarehouseId,
) {
  if (activeWarehouseId == null) return cart.items;
  return cart.warehouseItems.entries.where((entry) => entry.key == activeWarehouseId).expand((entry) => entry.value);
}

class NavigationButton extends ConsumerStatefulWidget {
  const NavigationButton({super.key});

  @override
  ConsumerState<NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends ConsumerState<NavigationButton> {
  late final PageController pageController;

  final List<Widget> pages = const [
    HomeScreen(),
    CategoryScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(
      label: 'Categories',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
    ),
    _NavItem(label: 'Cart', icon: Icons.local_mall_outlined, activeIcon: Icons.local_mall),
    _NavItem(label: 'Profile', icon: Icons.account_circle_outlined, activeIcon: Icons.account_circle),
  ];

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  void _onTap(int index) {
    HapticFeedback.lightImpact(); // 🔥 premium feel

    ref.read(navIndexProvider.notifier).state = index;
    pageController.jumpToPage(index);

    // pageController.animateToPage(
    //   index,
    //   duration: const Duration(milliseconds: 30),
    //   curve: Curves.,
    // );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navIndexProvider);

    // Sync page controller when index changes from outside (e.g. Home categories)
    ref.listen(navIndexProvider, (prev, next) {
      if (pageController.hasClients && pageController.page?.round() != next) {
        pageController.jumpToPage(next);
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (selectedIndex != 0) {
          _onTap(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: pages,
        ),
        bottomNavigationBar: _FloatingNavBar(
          selectedIndex: selectedIndex,
          items: _items,
          onTap: _onTap,
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _FloatingNavBar extends ConsumerWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final regularCartCount = ref.watch(regularCartCountProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final selected = index == selectedIndex;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 24,
                            color: selected ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                          if (index == 2 && regularCartCount > 0)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  regularCartCount > 99 ? '99+' : regularCartCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 20),
                        opacity: selected ? 1 : 0,
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
