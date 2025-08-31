// FILE: lib/src/services/github_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/services/config_service.dart';

class GithubService extends ChangeNotifier {
  final ConfigService _configService;
  late final Dio _dio;
  late final CacheOptions _cacheOptions;

  String? _username;
  String? _repo;
  String? _token;
  bool _isConfigured = false;
  
  final Map<String, String?> _fileShas = {};

  GithubService(this._configService) {
    _cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.refresh,
      maxStale: const Duration(days: 7),
    );
    _dio = Dio()..interceptors.add(DioCacheInterceptor(options: _cacheOptions));
    loadConfig();
  }

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
    final config = await _configService.loadGitHubConfig();
    _username = config['username'];
    _repo = config['repo'];
    _token = config['token'];
    _isConfigured = _username != null &&
        _username!.isNotEmpty &&
        _repo != null &&
        _repo!.isNotEmpty &&
        _token != null &&
        _token!.isNotEmpty;
    notifyListeners();
  }

  Future<void> saveConfig(String username, String repo, String token) async {
    await _configService.saveGitHubConfig(username, repo, token);
    await loadConfig();
  }

  String getImageUrl(String imagePath) {
    return 'https://raw.githubusercontent.com/$_username/$_repo/main/$imagePath';
  }

  Future<dynamic> _fetchAndParse(String filePath, dynamic defaultValue) async {
    if (!isConfigured) throw Exception('GitHub service is not configured.');
    final url = 'https://api.github.com/repos/$_username/$_repo/contents/$filePath';
    try {
      final response = await _dio.get(url, options: Options(headers: authHeaders));
      if (response.statusCode == 200) {
        final responseBody = response.data;
        _fileShas[filePath] = responseBody['sha'];
        final String content = utf8.decode(
            base64.decode(responseBody['content'].replaceAll('\n', '')));
        return json.decode(content);
      } else {
        throw Exception('Failed to load $filePath: Status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _fileShas[filePath] = null;
        return defaultValue;
      }
      throw Exception('Network failed for $filePath: ${e.message}');
    }
  }

  Future<void> _saveJsonFile(String filePath, dynamic data, String commitMessage) async {
    if (!isConfigured) throw Exception('GitHub service is not configured.');
    final url = 'https://api.github.com/repos/$_username/$_repo/contents/$filePath';
    
    const jsonEncoder = JsonEncoder.withIndent('  ');
    final String prettyJson = jsonEncoder.convert(data);
    final String content = base64.encode(utf8.encode(prettyJson));
    
    final body = {
      'message': commitMessage,
      'content': content,
      'sha': _fileShas[filePath],
    };

    final response = await _dio.put(url, data: body, options: Options(headers: authHeaders));

    if (response.statusCode == 200 || response.statusCode == 201) {
      _fileShas[filePath] = response.data['content']['sha'];
    } else {
      throw Exception('Failed to save $filePath: Status code ${response.statusCode}');
    }
  }
  
  Future<List<Product>> fetchInventory() async {
    final data = await _fetchAndParse('inventory.json', {'items': []});
    if (data['items'] is List) {
      return (data['items'] as List).map((item) => Product.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<Sale>> fetchSales() async {
    final data = await _fetchAndParse('sales.json', []);
    if (data is List) {
      return data.map((item) => Sale.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<Supplier>> fetchSuppliers() async {
    final data = await _fetchAndParse('suppliers.json', []);
    if (data is List) {
      return data.map((item) => Supplier.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<ActivityLog>> fetchActivityLogs() async {
    final data = await _fetchAndParse('audit-log.json', []);
    if (data is List) {
      return data.map((item) => ActivityLog.fromJson(item)).toList();
    }
    return [];
  }
  
  Future<void> saveInventory(List<Product> products) async {
    final dataToSave = {
      'items': products.map((p) => p.toMapForJson()).toList(),
    };
    await _saveJsonFile('inventory.json', dataToSave, 'Update inventory data');
  }

  Future<void> saveSales(List<Sale> sales) async {
    final dataToSave = sales.map((s) => s.toMap()).toList();
    await _saveJsonFile('sales.json', dataToSave, 'Update sales data');
  }
  
  Future<void> saveSuppliers(List<Supplier> suppliers) async {
    final dataToSave = suppliers.map((s) => s.toMap()).toList();
    await _saveJsonFile('suppliers.json', dataToSave, 'Update suppliers data');
  }

  Future<void> saveActivityLogs(List<ActivityLog> logs) async {
    final dataToSave = logs.map((l) => l.toMap()).toList();
    await _saveJsonFile('audit-log.json', dataToSave, 'Update activity logs');
  }

  Future<String> uploadImage(File imageFile, String sku) async {
    if (!isConfigured) throw Exception('GitHub service is not configured.');

    final fileName = 'img_${sku}_${DateTime.now().millisecondsSinceEpoch}.webp';
    final path = 'images/$fileName';
    final url = 'https://api.github.com/repos/$_username/$_repo/contents/$path';

    final bytes = await imageFile.readAsBytes();
    final String content = base64.encode(bytes);

    final body = {
      'message': 'Upload image: $fileName',
      'content': content,
    };

    final response = await _dio.put(url, data: body, options: Options(headers: authHeaders));

    if (response.statusCode == 201) {
      return response.data['content']['path'];
    } else {
      throw Exception('Failed to upload image: Status code ${response.statusCode}');
    }
  }
}