import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:rhineix_workshop_app/src/models/product_model.dart';
import 'package:rhineix_workshop_app/src/services/config_service.dart';

class GithubService extends ChangeNotifier {
  final ConfigService _configService;
  late final Dio _dio;
  late final CacheOptions _cacheOptions;

  String? _username;
  String? _repo;
  String? _token;
  bool _isConfigured = false;

  GithubService(this._configService) {
    _cacheOptions = CacheOptions(
      store: MemCacheStore(), // Stores in memory
      policy: CachePolicy.refresh, // Always fetch from network, but serve cache if network fails
      maxStale: const Duration(days: 7), // Cache is valid for 7 days
    );

    _dio = Dio()..interceptors.add(DioCacheInterceptor(options: _cacheOptions));

    loadConfig();
  }

  // Getters remain the same
  bool get isConfigured => _isConfigured;
  String? get username => _username;
  String? get repo => _repo;
  String? get token => _token;

  Map<String, String> get authHeaders => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/vnd.github.v3+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  Future<void> loadConfig() async {
    final config = await _configService.loadConfig();
    _username = config['username'];
    _repo = config['repo'];
    _token = config['token'];
    _isConfigured = _username != null && _repo != null && _token != null;
    notifyListeners();
  }

  Future<void> saveConfig(String username, String repo, String token) async {
    await _configService.saveConfig(username, repo, token);
    await loadConfig();
  }

  String getImageUrl(String imagePath) {
    return 'https://raw.githubusercontent.com/$_username/$_repo/main/$imagePath';
  }

  Future<List<Product>> fetchInventory() async {
    if (!_isConfigured) {
      throw Exception('إعدادات المزامنة غير مكتملة. الرجاء إدخالها في صفحة الإعدادات.');
    }

    final url = 'https://api.github.com/repos/$_username/$_repo/contents/inventory.json';

    try {
      final response = await _dio.get(url, options: Options(headers: authHeaders));

      if (response.statusCode == 200) {
        final responseBody = response.data;
        final String content = utf8.decode(base64.decode(responseBody['content'].replaceAll('\n', '')));
        final jsonData = json.decode(content) as Map<String, dynamic>;
        final List<dynamic> itemsJson = jsonData['items'] as List<dynamic>;
        return itemsJson.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('فشل تحميل المخزون: Status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return []; // File not found, return empty list
      }
      // Re-throw other Dio errors
      throw Exception('فشل الاتصال: ${e.message}');
    }
  }
}