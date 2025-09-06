import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rhineix_mkey_app/src/ui/screens/activity_log_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/dashboard_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/inventory_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/settings_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/suppliers_screen.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  DateTime? _lastPressedAt;

  static const List<Widget> _widgetOptions = <Widget>[
    InventoryScreen(),
    DashboardScreen(),
    ActivityLogScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        if (_selectedIndex != 0) {
          _onItemTapped(0);
          return;
        }

        final now = DateTime.now();
        final shouldExit = _lastPressedAt != null &&
            now.difference(_lastPressedAt!) < const Duration(seconds: 2);

        if (shouldExit) {
          SystemNavigator.pop();
        } else {
          _lastPressedAt = now;
          showAppSnackBar(
            context,
            message: 'اضغط مرة أخرى للخروج',
            type: NotificationType.info,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MASTER KEY'),
          actions: [
            IconButton(
              icon: const Icon(Symbols.group, weight: 700),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SuppliersScreen(),
                ));
              },
              tooltip: 'المورّدون',
            ),
            IconButton(
              icon: const Icon(Symbols.settings, weight: 700),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ));
              },
              tooltip: 'الإعدادات',
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Symbols.inventory_2),
              activeIcon: Icon(Symbols.inventory_2, fill: 1, weight: 700),
              label: 'المخزون',
            ),
            BottomNavigationBarItem(
              icon: Icon(Symbols.monitoring),
              activeIcon: Icon(Symbols.monitoring, fill: 1, weight: 700),
              label: 'لوحة المعلومات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Symbols.history),
              activeIcon: Icon(Symbols.history, fill: 1, weight: 700),
              label: 'سجل النشاط',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}