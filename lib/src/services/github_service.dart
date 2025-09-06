import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rhineix_mkey_app/src/core/app_config.dart';
import 'package:rhineix_mkey_app/src/models/github_file_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';

class GithubService extends ChangeNotifier {
  late final Dio _dio;

  final String _username = AppConfig.githubUsername;
  final String _repo = AppConfig.githubRepo;
  final String _token = AppConfig.githubToken;

  final bool _isConfigured;

  GithubService() : _isConfigured = true {
    _dio = Dio();
    if (_token.startsWith('ghp_YOUR_FALLBACK')) {
      debugPrint("WARNING: Using fallback GitHub token.");
    }
  }

  bool get isConfigured => _isConfigured;
  Map<String, String> get authHeaders => {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/vnd.github.v3+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  String getImageUrl(String imagePath) {
    if (!isConfigured) return '';
    return 'https://raw.githubusercontent.com/$_username/$_repo/main/$imagePath';
  }

  Future<String> uploadImage(File imageFile, String sku) async {
    if (!isConfigured) throw Exception('GitHub service is not configured.');

    final fileName =
        'img_${sku}_${DateTime.now().millisecondsSinceEpoch}.webp';
    final path = 'images/$fileName';
    final bytes = await imageFile.readAsBytes();

    return await uploadRestoredImage(path, bytes);
  }

  Future<String> uploadRestoredImage(String path, Uint8List bytes) async {
    if (!isConfigured) throw Exception('GitHub service is not configured.');

    final url = 'https://api.github.com/repos/$_username/$_repo/contents/$path';
    final String content = base64.encode(bytes);

    final body = <String, dynamic>{
      'message': 'Upload/Restore image: ${path.split('/').last}',
      'content': content,
    };

    try {
      final existingFileResponse =
          await _dio.get(url, options: Options(headers: authHeaders));
      if (existingFileResponse.statusCode == 200) {
        body['sha'] = existingFileResponse.data['sha'];
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        rethrow;
      }
    }

    final response =
        await _dio.put(url, data: body, options: Options(headers: authHeaders));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data['content']['path'];
    } else {
      throw Exception(
          'Failed to upload restored image: Status code ${response.statusCode}');
    }
  }

  Future<List<GithubFile>> getDirectoryListing(String path) async {
    if (!isConfigured) return [];
    final url = 'https://api.github.com/repos/$_username/$_repo/contents/$path';

    try {
      final response =
          await _dio.get(url, options: Options(headers: authHeaders));
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => GithubFile.fromJson(item))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw Exception('Failed to list directory: ${e.message}');
    }
  }

  Future<void> deleteFile(String path, String sha) async {
    if (!isConfigured) throw Exception('GitHub service is not configured.');
    final url = 'https://api.github.com/repos/$_username/$_repo/contents/$path';
    final body = {
      'message': 'Cleanup: Delete unused file $path',
      'sha': sha,
    };

    final response = await _dio.delete(url,
        data: body, options: Options(headers: authHeaders));

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete file: Status code ${response.statusCode}');
    }
  }

  Future<List<Sale>> fetchArchivedSales(String path) async {
    if (!isConfigured) throw Exception('GitHub service is not configured.');
    final url = 'https://api.github.com/repos/$_username/$_repo/contents/$path';
    try {
      final response =
          await _dio.get(url, options: Options(headers: authHeaders));
      if (response.statusCode == 200) {
        final String decodedContent =
            utf8.decode(base64.decode(response.data['content'].replaceAll('\n', '')));
        final data = json.decode(decodedContent);
        if (data is List) {
          return data.map((item) => Sale.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch archived sales: $e');
    }
  }

  Future<List<GithubFile>> getArchiveList() async {
    return getDirectoryListing('archive');
  }
}