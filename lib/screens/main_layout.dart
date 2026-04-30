import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'marketplace_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  final bool firebaseConfigured;
  const MainLayout({super.key, this.firebaseConfigured = false});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void _switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Pages are rebuilt here so we can pass the tab-switch callback
    final pages = [
      DashboardScreen(onGoToMarketplace: () => _switchToTab(1)),
      const MarketplaceScreen(),
      ProfileScreen(firebaseConfigured: widget.firebaseConfigured),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A24),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _switchToTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_rounded),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
