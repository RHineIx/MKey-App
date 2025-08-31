// FILE: lib/src/ui/screens/main_shell.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/ui/screens/activity_log_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/dashboard_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/inventory_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/settings_screen.dart';
import 'package:rhineix_mkey_app/src/ui/screens/suppliers_screen.dart';
import 'package:app_links/app_links.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  DateTime? _lastPressedAt;

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
      if (mounted) _processLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (mounted) _processLink(uri);
    });
  }

  void _processLink(Uri uri) {
    String fragment = uri.fragment;
    if (fragment.startsWith('/')) {
        fragment = fragment.substring(1);
    }

    if (fragment.startsWith('setup=')) {
      final encodedData = fragment.substring(6);
      try {
        final decodedJson = utf8.decode(base64.decode(encodedData));
        final config = json.decode(decodedJson) as Map<String, dynamic>;
        
        final username = config['username'];
        final repo = config['repo'];
        final pat = config['pat'];

        if (username != null && repo != null && pat != null) {
          final githubService = context.read<GithubService>();
          githubService.saveConfig(username, repo, pat);

          showAppSnackBar(context, message: 'تم استلام إعدادات المزامنة بنجاح!', type: NotificationType.success);
        } else {
            throw Exception('Incomplete config data');
        }
      } catch (e) {
        showAppSnackBar(context, message: 'فشل معالجة رابط الإعداد: $e', type: NotificationType.error);
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        // If not on the main tab, navigate back to it
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
      ),
    );
  }
}