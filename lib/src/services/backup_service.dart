import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/services/firestore_service.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:share_plus/share_plus.dart';

class BackupService extends ChangeNotifier {
  FirestoreService _firestoreService;
  GithubService _githubService;
  CacheManager _cacheManager;

  bool _isWorking = false;
  String _statusMessage = '';

  bool get isWorking => _isWorking;
  String get statusMessage => _statusMessage;

  BackupService({
    required FirestoreService firestoreService,
    required GithubService githubService,
    required CacheManager cacheManager,
  })  : _firestoreService = firestoreService,
        _githubService = githubService,
        _cacheManager = cacheManager;
  
  void updateServices({
    required FirestoreService firestoreService,
    required GithubService githubService,
    required CacheManager cacheManager,
  }) {
    _firestoreService = firestoreService;
    _githubService = githubService;
    _cacheManager = cacheManager;
  }

  void _updateStatus(String message, {bool working = true}) {
    _isWorking = working;
    _statusMessage = message;
    notifyListeners();
  }

  Future<void> createBackup({
    required List<Product> products,
    required List<Sale> sales,
    required List<Supplier> suppliers,
    required List<ActivityLog> activityLogs,
  }) async {
    _updateStatus('بدء عملية النسخ الاحتياطي...');
    try {
      final archive = Archive();

      _updateStatus('جاري أرشفة البيانات...');
      archive.addFile(ArchiveFile(
          'inventory.json', -1, utf8.encode(jsonEncode(products.map((p) => p.toMapForJson()).toList()))));
      archive.addFile(ArchiveFile(
          'sales.json', -1, utf8.encode(jsonEncode(sales.map((s) => s.toMap()).toList()))));
      archive.addFile(ArchiveFile('suppliers.json', -1,
          utf8.encode(jsonEncode(suppliers.map((s) => s.toMap()).toList()))));
      archive.addFile(ArchiveFile('activity_logs.json', -1,
          utf8.encode(jsonEncode(activityLogs.map((l) => l.toMap()).toList()))));

      final imagePaths =
          products.map((p) => p.imagePath).whereType<String>().toSet();

      int imageCount = 0;
      for (final imagePath in imagePaths) {
        imageCount++;
        _updateStatus('جاري ضغط الصور ($imageCount/${imagePaths.length})...');
        try {
          final imageUrl = _githubService.getImageUrl(imagePath);
          final file = await _cacheManager.getSingleFile(imageUrl,
              headers: _githubService.authHeaders);
          final bytes = await file.readAsBytes();
          archive.addFile(
              ArchiveFile('images/${imagePath.split('/').last}', -1, bytes));
        } catch (e) {
          debugPrint('Could not cache image for backup: $imagePath. Error: $e');
        }
      }

      _updateStatus('جاري إنشاء ملف ZIP...');
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData == null) {
        throw Exception('فشل إنشاء ملف النسخة الاحتياطية.');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'mkey_backup_${DateTime.now().toIso8601String().split('T').first}.zip';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(zipData);

      _updateStatus('جاهز للمشاركة...', working: false);
      await Share.shareXFiles([XFile(file.path)], subject: 'MKey Backup');

    } finally {
      _updateStatus('', working: false);
    }
  }

  Future<void> restoreFromBackup() async {
    _updateStatus('بدء عملية الاستعادة...');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        throw Exception('لم يتم اختيار ملف.');
      }

      _updateStatus('جاري قراءة ملف النسخة الاحتياطية...');
      final file = File(result.files.single.path!);
      final inputStream = InputFileStream(file.path);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      List<Product> products = [];
      List<Sale> sales = [];
      List<Supplier> suppliers = [];
      List<ActivityLog> activityLogs = [];

      _updateStatus('جاري تحليل البيانات...');
      for (final file in archive.files) {
        if (file.isFile) {
          final data = file.content as Uint8List;
          final jsonString = utf8.decode(data);
          final jsonData = jsonDecode(jsonString);

          if (file.name == 'inventory.json') {
            products = (jsonData as List)
                .map<Product>((item) => Product.fromJson(item))
                .toList();
          } else if (file.name == 'sales.json') {
            sales = (jsonData as List)
                .map<Sale>((item) => Sale.fromJson(item))
                .toList();
          } else if (file.name == 'suppliers.json') {
            suppliers = (jsonData as List)
                .map<Supplier>((item) => Supplier.fromJson(item))
                .toList();
          } else if (file.name == 'activity_logs.json') {
            activityLogs = (jsonData as List)
                .map<ActivityLog>((item) => ActivityLog.fromJson(item))
                .toList();
          }
        }
      }

      _updateStatus('جاري استعادة الصور إلى GitHub...');
      final imageFiles = archive.files.where((f) => f.name.startsWith('images/'));
      int imageCount = 0;
      for (final imageFile in imageFiles) {
        imageCount++;
         _updateStatus('جاري رفع الصور ($imageCount/${imageFiles.length})...');
        await _githubService.uploadRestoredImage(imageFile.name, imageFile.content);
      }
      
      _updateStatus('جاري استعادة البيانات إلى Firestore...');
      await _firestoreService.performRestore(
        products: products,
        sales: sales,
        suppliers: suppliers,
        activityLogs: activityLogs,
      );

      _updateStatus('اكتملت الاستعادة بنجاح!', working: false);

    } finally {
      if (_isWorking) {
         _updateStatus('انتهت العملية.', working: false);
      }
    }
  }
}