// FILE: lib/src/notifiers/supplier_notifier.dart
import 'package:flutter/material.dart';
import 'package:rhineix_mkey_app/src/core/database_helper.dart';
import 'package:rhineix_mkey_app/src/models/supplier_model.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';

class SupplierNotifier extends ChangeNotifier {
  final GithubService _githubService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  InventoryNotifier? _inventoryNotifier;

  SupplierNotifier(this._githubService) {
    _githubService.addListener(syncFromNetwork);
    loadSuppliersFromDb();
  }
  
  void setInventoryNotifier(InventoryNotifier notifier) {
    _inventoryNotifier = notifier;
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

  Future<void> addSupplier(String name, String? phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newSupplier = Supplier(
        id: 'sup_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phone: phone,
      );
      _suppliers.add(newSupplier);
      await _dbHelper.batchUpdateSuppliers(_suppliers);
      await _githubService.saveSuppliers(_suppliers);
      await loadSuppliersFromDb();
    } catch (e) {
      await loadSuppliersFromDb();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> updateSupplier(String id, String name, String? phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      final index = _suppliers.indexWhere((s) => s.id == id);
      if (index != -1) {
        _suppliers[index] = Supplier(id: id, name: name, phone: phone);
        await _dbHelper.batchUpdateSuppliers(_suppliers);
        await _githubService.saveSuppliers(_suppliers);
        await loadSuppliersFromDb();
      }
    } catch (e) {
      await loadSuppliersFromDb();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSupplier(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _suppliers.removeWhere((s) => s.id == id);
      // await _inventoryNotifier?.unlinkSupplier(id); // Unlink from products
      await _dbHelper.batchUpdateSuppliers(_suppliers);
      await _githubService.saveSuppliers(_suppliers);
      await loadSuppliersFromDb();
    } catch (e) {
      await loadSuppliersFromDb();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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