// FILE: lib/main.dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/app_theme.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/notifiers/activity_log_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/dashboard_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';
import 'package:rhineix_mkey_app/src/services/config_service.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/ui/screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        // Independent Services and Notifiers
        Provider(create: (context) => ConfigService()),
        ChangeNotifierProvider(
            create: (context) =>
                GithubService(context.read<ConfigService>())),
        ChangeNotifierProvider(
          create: (context) =>
              DashboardNotifier(context.read<GithubService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SettingsNotifier(context.read<ConfigService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ActivityLogNotifier(context.read<GithubService>()),
        ),

        // Dependent Notifiers using ProxyProvider
        ChangeNotifierProxyProvider<ActivityLogNotifier, InventoryNotifier>(
          create: (context) => InventoryNotifier(
            context.read<GithubService>(),
            null,
          ),
          update: (context, activityLogNotifier, inventoryNotifier) =>
          inventoryNotifier!..setActivityLogNotifier(activityLogNotifier),
        ),
        ChangeNotifierProxyProvider<InventoryNotifier, SupplierNotifier>(
          create: (context) => SupplierNotifier(
            context.read<GithubService>(),
            null,
          ),
          update: (context, inventoryNotifier, supplierNotifier) =>
          supplierNotifier!..setInventoryNotifier(inventoryNotifier),
        ),
      ],
      child: const MKeyApp(),
    ),
  );
}

class MKeyApp extends StatelessWidget {
  const MKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsNotifier = context.watch<SettingsNotifier>();
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {

        final bool useDynamicColor = settingsNotifier.appThemeMode == AppThemeMode.system;

        final ColorScheme lightColorScheme = useDynamicColor
            ? lightDynamic ?? AppTheme.lightColorScheme
            : AppTheme.lightColorScheme;

        final ColorScheme darkColorScheme = useDynamicColor
            ? darkDynamic ?? AppTheme.darkColorScheme
            : AppTheme.darkColorScheme;

        ThemeMode themeMode;
        switch(settingsNotifier.appThemeMode) {
          case AppThemeMode.light:
            themeMode = ThemeMode.light;
            break;
          case AppThemeMode.dark:
            themeMode = ThemeMode.dark;
            break;
          case AppThemeMode.system:
            themeMode = ThemeMode.system;
            break;
        }

        return MaterialApp(
          title: 'MASTER KEY',
          debugShowCheckedModeBanner: false,

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
          ],
          locale: const Locale('ar'),

          theme: AppTheme.getTheme(
            colorScheme: lightColorScheme,
            fontWeight: settingsNotifier.fontWeight.value,
          ),
          darkTheme: AppTheme.getTheme(
            colorScheme: darkColorScheme,
            fontWeight: settingsNotifier.fontWeight.value,
            isDark: true,
          ),
          themeMode: themeMode,
          home: const MainShell(),
        );
      },
    );
  }
}