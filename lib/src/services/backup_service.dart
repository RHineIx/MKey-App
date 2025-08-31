// FILE: lib/src/services/backup_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:file_saver/file_saver.dart';
import 'package:rhineix_mkey_app/src/core/database_helper.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final GithubService _githubService;

  BackupService(this._githubService);

  Future<String?> createAndSaveBackup() async {
    final archive = Archive();

    final products = await _dbHelper.getAllProducts();
    final sales = await _dbHelper.getAllSales();
    final suppliers = await _dbHelper.getAllSuppliers();
    final activityLogs = await _dbHelper.getAllActivityLogs();
    
    archive.addFile(ArchiveFile('inventory.json', -1, utf8.encode(jsonEncode({'items': products.map((p) => p.toMapForJson()).toList()}))));
    archive.addFile(ArchiveFile('sales.json', -1, utf8.encode(jsonEncode(sales.map((s) => s.toMap()).toList()))));
    archive.addFile(ArchiveFile('suppliers.json', -1, utf8.encode(jsonEncode(suppliers.map((s) => s.toMap()).toList()))));
    archive.addFile(ArchiveFile('audit-log.json', -1, utf8.encode(jsonEncode(activityLogs.map((l) => l.toMap()).toList()))));

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('Failed to encode zip file');
    }

    final Uint8List zipBytes = Uint8List.fromList(zipData);
    final fileName = 'master_key_backup_${DateTime.now().toIso8601String()}.zip';
    
    // Use saveAs to open file picker and get the path
    return await FileSaver.instance.saveAs(
      name: fileName,
      bytes: zipBytes,
      ext: 'zip',
      mimeType: MimeType.zip,
    );
  }

  Future<void> restoreFromBackup(String path) async {
    final inputStream = InputFileStream(path);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    for (final file in archive.files) {
      final data = utf8.decode(file.content as List<int>);
      final jsonData = jsonDecode(data);

      switch (file.name) {
        case 'inventory.json':
          final products = (jsonData['items'] as List).map((p) => Product.fromJson(p)).toList();
          await _dbHelper.batchUpdateProducts(products);
          break;
        case 'sales.json':
          final sales = (jsonData as List).map((s) => Sale.fromJson(s)).toList();
          await _dbHelper.batchUpdateSales(sales);
          break;
        case 'suppliers.json':
          final suppliers = (jsonData as List).map((s) => Supplier.fromJson(s)).toList();
          await _dbHelper.batchUpdateSuppliers(suppliers);
          break;
        case 'audit-log.json':
          final logs = (jsonData as List).map((l) => ActivityLog.fromJson(l)).toList();
          await _dbHelper.batchUpdateActivityLogs(logs);
          break;
      }
    }

    final products = await _dbHelper.getAllProducts();
    await _githubService.saveInventory(products);
    final sales = await _dbHelper.getAllSales();
    await _githubService.saveSales(sales);
    final suppliers = await _dbHelper.getAllSuppliers();
    await _githubService.saveSuppliers(suppliers);
    final logs = await _dbHelper.getAllActivityLogs();
    await _githubService.saveActivityLogs(logs);
  }
}