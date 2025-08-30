// FILE: lib/src/notifiers/supplier_notifier.dart
import 'package:flutter/material.dart';
import 'package:rhineix_mkey_app/src/core/database_helper.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';

class SupplierNotifier extends ChangeNotifier { // Corrected: Added 'extends ChangeNotifier'
  final GithubService _githubService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  SupplierNotifier(this._githubService) {
    _githubService.addListener(syncFromNetwork);
    loadSuppliersFromDb();
  }

  bool _isLoading = false;
  List<Supplier> _suppliers = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<Supplier> get suppliers => _suppliers;
  String? get error => _error;

  Future<void> loadSuppliersFromDb() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _suppliers = await _dbHelper.getAllSuppliers();
    } catch (e) {
      _error = "فشل تحميل المورّدين من قاعدة البيانات المحلية: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> syncFromNetwork() async {
    if (!_githubService.isConfigured) {
      _error = 'إعدادات المزامنة غير مكتملة.';
      notifyListeners();
      return _error;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final networkSuppliers = await _githubService.fetchSuppliers();
      await _dbHelper.batchUpdateSuppliers(networkSuppliers);
      await loadSuppliersFromDb();
      return null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return _error;
    }
  }

  Supplier? getSupplierById(String id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _githubService.removeListener(syncFromNetwork);
    super.dispose();
  }
}