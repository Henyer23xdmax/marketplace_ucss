import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/constants/theme_constants.dart';
import 'catalog/home_feed_screen.dart';
import 'favorites/favorites_screen.dart';
import 'publish/create_product_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeFeedScreen(),
    FavoritesScreen(),
    CreateProductScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _currentIndex,
        backgroundColor: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.95)
            : AppColors.surface.withValues(alpha: 0.92),
        activeColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        inactiveColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        iconSize: 24,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.compass),
            activeIcon: Icon(CupertinoIcons.compass_fill),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.heart),
            activeIcon: Icon(CupertinoIcons.heart_fill),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.plus_circle),
            activeIcon: Icon(CupertinoIcons.plus_circle_fill),
            label: 'Vender',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bag),
            activeIcon: Icon(CupertinoIcons.bag_fill),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person_fill),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
