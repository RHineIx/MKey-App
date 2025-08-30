import 'package:shared_preferences/shared_preferences.dart';
import 'package:rhineix_workshop_app/src/core/enums.dart';

class ConfigService {
  static const _usernameKey = 'github_username';
  static const _repoKey = 'github_repo';
  static const _tokenKey = 'github_token';
  static const _themeModeKey = 'theme_mode';
  static const _fontWeightKey = 'font_weight';

  // Renamed to saveConfig
  Future<void> saveConfig(String username, String repo, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_repoKey, repo);
    await prefs.setString(_tokenKey, token);
  }

  // Renamed to loadConfig
  Future<Map<String, String?>> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_usernameKey),
      'repo': prefs.getString(_repoKey),
      'token': prefs.getString(_tokenKey),
    };
  }

  Future<void> saveThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, isDarkMode);
  }

  Future<bool?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeModeKey);
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