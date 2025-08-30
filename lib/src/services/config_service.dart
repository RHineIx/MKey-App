// FILE: lib/src/services/config_service.dart
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  // GitHub Config Keys
  static const _usernameKey = 'github_username';
  static const _repoKey = 'github_repo';
  static const _tokenKey = 'github_token';

  // Theme Config Keys
  static const _themeModeKey = 'app_theme_mode'; // Changed from bool key
  static const _fontWeightKey = 'font_weight';

  // General App Config Keys
  static const _currencyKey = 'app_currency';
  static const _userKey = 'app_user';
  static const _exchangeRateKey = 'app_exchange_rate';

  // --- GitHub Config ---
  Future<void> saveGitHubConfig(String username, String repo, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_repoKey, repo);
    await prefs.setString(_tokenKey, token);
  }

  Future<Map<String, String?>> loadGitHubConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_usernameKey),
      'repo': prefs.getString(_repoKey),
      'token': prefs.getString(_tokenKey),
    };
  }

  // --- General App Config ---
  Future<void> saveGeneralConfig({
    required String currentUser,
    required String activeCurrency,
    required double exchangeRate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, currentUser);
    await prefs.setString(_currencyKey, activeCurrency);
    await prefs.setDouble(_exchangeRateKey, exchangeRate);
  }

  Future<Map<String, dynamic>> loadGeneralConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'currentUser': prefs.getString(_userKey) ?? 'المستخدم',
      'activeCurrency': prefs.getString(_currencyKey) ?? 'IQD',
      'exchangeRate': prefs.getDouble(_exchangeRateKey) ?? 1460.0,
    };
  }

  // --- Theme Config ---
  Future<void> saveThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<AppThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeModeKey);
    return AppThemeMode.values.firstWhere(
          (e) => e.name == themeName,
      orElse: () => AppThemeMode.system, // Default to system/monet
    );
  }

  Future<void> saveFontWeight(AppFontWeight weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontWeightKey, weight.name);
  }

  Future<AppFontWeight> loadFontWeight() async {
    final prefs = await SharedPreferences.getInstance();
    final weightName = prefs.getString(_fontWeightKey);
    return AppFontWeight.values.firstWhere(
          (e) => e.name == weightName,
      orElse: () => AppFontWeight.normal,
    );
  }
}