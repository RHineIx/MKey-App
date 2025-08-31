// FILE: lib/src/ui/screens/main_shell.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/ui/screens/activity_log_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/dashboard_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/inventory_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/settings_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/suppliers_screen.dart';
import 'package:app_links/app_links.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  static const List<Widget> _widgetOptions = <Widget>[
    InventoryScreen(),
    DashboardScreen(),
    ActivityLogScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    final initialUri = await _appLinks.getInitialAppLink();
    if (initialUri != null) {
      _processLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;
      _processLink(uri);
    });
  }

  void _processLink(Uri uri) {
    if (uri.fragment.startsWith('setup=')) {
      final encodedData = uri.fragment.substring(6);
      try {
        final decodedJson = utf8.decode(base64.decode(encodedData));
        final config = json.decode(decodedJson) as Map<String, dynamic>;

        if (config['username'] != null && config['repo'] != null && config['pat'] != null) {
          final githubService = context.read<GithubService>();
          githubService.saveConfig(config['username'], config['repo'], config['pat']);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم استلام الإعدادات بنجاح!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل معالجة الرابط: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
            icon: const Icon(Symbols.settings),
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
            activeIcon: Icon(Symbols.inventory_2, fill: 1),
            label: 'المخزون',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.monitoring),
            activeIcon: Icon(Symbols.monitoring, fill: 1),
            label: 'لوحة المعلومات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.history),
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