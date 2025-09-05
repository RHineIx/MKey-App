import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CustomCacheManager {
  static const key = 'customCacheKey';
  static CacheManager? _instance;

  static Future<CacheManager> getInstance() async {
    if (_instance == null) {
      // Define the single, persistent base path for both metadata and image files.
      final basePath = await _getPersistentCachePath();

      _instance = CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 365),
          maxNrOfCacheObjects: 1000,
          // Use the persistent path for the repository database (the .json file).
          repo: JsonCacheInfoRepository(databaseName: basePath),
          // Use the persistent path for the file system (the actual image files).
          fileSystem: IOFileSystem(basePath),
        ),
      );
    }
    return _instance!;
  }

  /// Determines the persistent storage path.
  ///
  /// It prioritizes the app-specific external storage directory, as requested,
  /// and falls back to the internal documents directory if external storage is unavailable.
  static Future<String> _getPersistentCachePath() async {
    final extDir = await getExternalStorageDirectory();
    final baseDir = extDir ?? await getApplicationDocumentsDirectory();
    // The key is used as the sub-directory name.
    return p.join(baseDir.path, key);
  }

  /// Clears all files and metadata from the custom persistent cache.
  static Future<void> clearCache() async {
    final instance = await getInstance();
    await instance.emptyCache();
  }
}