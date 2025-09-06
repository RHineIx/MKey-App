import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/app_theme.dart';
import 'package:rhineix_mkey_app/src/core/custom_cache_manager.dart';
import 'package:rhineix_mkey_app/src/notifiers/activity_log_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/dashboard_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';
import 'package:rhineix_mkey_app/src/services/auth_service.dart';
import 'package:rhineix_mkey_app/src/services/backup_service.dart';
import 'package:rhineix_mkey_app/src/services/config_service.dart';
import 'package:rhineix_mkey_app/src/services/fcm_service.dart';
import 'package:rhineix_mkey_app/src/services/firestore_service.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/ui/screens/auth_wrapper.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final fcmService = FCMService();
  await fcmService.initNotifications();
  final customCacheManager = await CustomCacheManager.getInstance();

  runApp(
    MultiProvider(
      providers: [
        Provider<CacheManager>.value(value: customCacheManager),
        Provider(create: (_) => ConfigService()),
        Provider.value(value: fcmService),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => GithubService()),
        ChangeNotifierProxyProvider<AuthService, FirestoreService>(
          create: (context) => FirestoreService(null),
          update: (_, auth, __) => FirestoreService(auth.currentUser?.uid),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsNotifier(context.read<ConfigService>()),
        ),
        ChangeNotifierProxyProvider3<FirestoreService, GithubService,
            CacheManager, BackupService>(
          create: (context) => BackupService(
            firestoreService: context.read<FirestoreService>(),
            githubService: context.read<GithubService>(),
            cacheManager: context.read<CacheManager>(),
          ),
          update: (_, firestore, github, cache, notifier) => notifier!
            ..updateServices(
              firestoreService: firestore,
              githubService: github,
              cacheManager: cache,
            ),
        ),
        ChangeNotifierProxyProvider<FirestoreService, InventoryNotifier>(
          create: (context) => InventoryNotifier(
            context.read<FirestoreService>(),
            context.read<GithubService>(),
          ),
          update: (_, firestore, notifier) =>
          notifier!..updateFirestoreService(firestore),
        ),
        ChangeNotifierProxyProvider<FirestoreService, SupplierNotifier>(
          create: (context) =>
              SupplierNotifier(context.read<FirestoreService>()),
          update: (_, firestore, notifier) =>
          notifier!..updateFirestoreService(firestore),
        ),
        ChangeNotifierProxyProvider<FirestoreService, ActivityLogNotifier>(
          create: (context) =>
              ActivityLogNotifier(context.read<FirestoreService>()),
          update: (_, firestore, notifier) =>
          notifier!..updateFirestoreService(firestore),
        ),
        ChangeNotifierProxyProvider<FirestoreService, DashboardNotifier>(
          create: (context) =>
              DashboardNotifier(context.read<FirestoreService>()),
          update: (_, firestore, notifier) =>
          notifier!..updateFirestoreService(firestore),
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
        final appMode = settingsNotifier.appThemeMode;
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (appMode == AppThemeMode.system && lightDynamic != null && darkDynamic != null) {
          // Use the dynamic color seed to generate a new, harmonized color scheme.
          lightColorScheme = ColorScheme.fromSeed(seedColor: lightDynamic.primary);
          darkColorScheme = ColorScheme.fromSeed(seedColor: darkDynamic.primary, brightness: Brightness.dark);
        } else {
          // Fallback to the predefined static theme.
          lightColorScheme = AppTheme.lightColorScheme;
          darkColorScheme = AppTheme.darkColorScheme;
        }

        final themeMode = switch (appMode) {
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          AppThemeMode.system => ThemeMode.system,
        };

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
          home: const AuthWrapper(),
        );
      },
    );
  }
}