// FILE: lib/src/ui/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rhineix_mkey_app/src/ui/screens/activity_log_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/dashboard_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/inventory_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/settings_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/suppliers_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('MASTER KEY'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.group),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SuppliersScreen(),
              ));
            },
            tooltip: 'المورّدون',
          ),
          IconButton(
            icon: const Icon(Symbols.settings), // Corrected icon name
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
            icon: Icon(Symbols.inventory_2), // Corrected icon name
            activeIcon: Icon(Symbols.inventory_2, fill: 1),
            label: 'المخزون',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.monitoring), // Corrected icon name
            activeIcon: Icon(Symbols.monitoring, fill: 1),
            label: 'لوحة المعلومات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.history), // Corrected icon name
            activeIcon: Icon(Symbols.history, fill: 1),
            label: 'سجل النشاط',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}