// FILE: lib/src/notifiers/settings_notifier.dart
import 'package:flutter/material.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/services/config_service.dart';

class SettingsNotifier extends ChangeNotifier {
  final ConfigService _configService;

  SettingsNotifier(this._configService) {
    _loadSettings();
  }

  // Theme settings
  ThemeMode _themeMode = ThemeMode.system;
  AppFontWeight _fontWeight = AppFontWeight.normal;

  // General settings
  String _currentUser = 'المستخدم';
  String _activeCurrency = 'IQD';
  double _exchangeRate = 1460.0;

  // Getters
  ThemeMode get themeMode => _themeMode;
  AppFontWeight get fontWeight => _fontWeight;
  String get currentUser => _currentUser;
  String get activeCurrency => _activeCurrency;
  double get exchangeRate => _exchangeRate;

  Future<void> _loadSettings() async {
    // Load Theme
    final isDarkMode = await _configService.loadThemeMode();
    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
    _fontWeight = await _configService.loadFontWeight();

    // Load General Config
    final generalConfig = await _configService.loadGeneralConfig();
    _currentUser = generalConfig['currentUser'];
    _activeCurrency = generalConfig['activeCurrency'];
    _exchangeRate = generalConfig['exchangeRate'];

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

  Future<void> saveGeneralConfig({
    required String currentUser,
    required String activeCurrency,
    required double exchangeRate,
  }) async {
    _currentUser = currentUser;
    _activeCurrency = activeCurrency;
    _exchangeRate = exchangeRate;
    await _configService.saveGeneralConfig(
      currentUser: currentUser,
      activeCurrency: activeCurrency,
      exchangeRate: exchangeRate,
    );
    notifyListeners();
  }

  void toggleCurrency() {
    _activeCurrency = (_activeCurrency == 'IQD') ? 'USD' : 'IQD';
    saveGeneralConfig(
        currentUser: _currentUser,
        activeCurrency: _activeCurrency,
        exchangeRate: _exchangeRate
    );
  }
}