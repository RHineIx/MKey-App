import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
// google_fonts import is removed as it's now handled inside app_theme.dart
import 'package:provider/provider.dart';
import 'package:rhineix_workshop_app/src/core/app_theme.dart';
import 'package:rhineix_workshop_app/src/core/enums.dart';
import 'package:rhineix_workshop_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_workshop_app/src/services/config_service.dart';
import 'package:rhineix_workshop_app/src/services/github_service.dart';
import 'package:rhineix_workshop_app/src/ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (context) => ConfigService()),
        // Correctly pass the ConfigService to GithubService's constructor
        ChangeNotifierProvider(create: (context) => GithubService(context.read<ConfigService>())),
        ChangeNotifierProvider(
          create: (context) => InventoryNotifier(context.read<GithubService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeSettingsNotifier(context.read<ConfigService>()),
        ),
      ],
      child: const MKeyApp(),
    ),
  );
}

class ThemeSettingsNotifier extends ChangeNotifier {
  final ConfigService _configService;

  ThemeSettingsNotifier(this._configService) {
    _loadSettings();
  }

  ThemeMode _themeMode = ThemeMode.system;
  AppFontWeight _fontWeight = AppFontWeight.normal;

  ThemeMode get themeMode => _themeMode;
  AppFontWeight get fontWeight => _fontWeight;

  Future<void> _loadSettings() async {
    final isDarkMode = await _configService.loadThemeMode();
    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
    _fontWeight = await _configService.loadFontWeight();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _configService.saveThemeMode(mode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setFontWeight(AppFontWeight weight) async {
    _fontWeight = weight;
    await _configService.saveFontWeight(weight);
    notifyListeners();
  }
}

class MKeyApp extends StatelessWidget {
  const MKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSettings = context.watch<ThemeSettingsNotifier>();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'MKey',
          debugShowCheckedModeBanner: false,

          theme: AppTheme.getTheme(
            colorScheme: lightDynamic ?? AppTheme.lightColorScheme,
            fontWeight: themeSettings.fontWeight.value,
          ),
          darkTheme: AppTheme.getTheme(
            colorScheme: darkDynamic ?? AppTheme.darkColorScheme,
            fontWeight: themeSettings.fontWeight.value,
            isDark: true,
          ),
          themeMode: themeSettings.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}