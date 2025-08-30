// FILE: lib/src/notifiers/inventory_notifier.dart
import 'package:flutter/material.dart';
import 'package:rhineix_mkey_app/src/core/database_helper.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';

class InventoryNotifier extends ChangeNotifier {
  final GithubService _githubService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  InventoryNotifier(this._githubService) {
    _githubService.addListener(_configChanged);
    loadProductsFromDb();
  }

  bool _isLoading = false;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String? _error;

  String _currentSearchQuery = '';
  String? _selectedCategory;
  SortOption _currentSortOption = SortOption.defaults;
  List<String> _allCategories = [];

  bool get isLoading => _isLoading;
  List<Product> get products => _allProducts;
  List<Product> get filteredProducts => _filteredProducts;
  List<String> get categories => _allCategories;
  String? get selectedCategory => _selectedCategory;
  String? get error => _error;

  void _configChanged() {
    syncFromNetwork();
  }

  Future<void> loadProductsFromDb() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allProducts = await _dbHelper.getAllProducts();
      _extractCategories();
      _applyFiltersAndSort();
    } catch (e) {
      _error = "فشل تحميل البيانات من قاعدة البيانات المحلية: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> syncFromNetwork() async {
    if (!_githubService.isConfigured) {
      const errorMsg = 'الرجاء إدخال إعدادات المزامنة أولاً.';
      _error = errorMsg;
      notifyListeners();
      return errorMsg;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final networkProducts = await _githubService.fetchInventory();
      await _dbHelper.batchUpdateProducts(networkProducts);
      await loadProductsFromDb();
      return null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return e.toString();
    }
  }

  void _extractCategories() {
    final uniqueCategories =
    _allProducts.expand((p) => p.categories).toSet().toList();
    uniqueCategories.sort();
    _allCategories = uniqueCategories;
  }

  void _applyFiltersAndSort() {
    List<Product> tempProducts = List.from(_allProducts);

    if (_selectedCategory != null) {
      tempProducts = tempProducts
          .where((p) => p.categories.contains(_selectedCategory))
          .toList();
    }

    if (_currentSearchQuery.isNotEmpty) {
      final lowerCaseQuery = _currentSearchQuery.toLowerCase();
      tempProducts = tempProducts.where((product) {
        return [
          product.name,
          product.sku,
          product.notes,
          product.oemPartNumber,
          product.compatiblePartNumber
        ]
            .any((field) => field?.toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
    }

    switch (_currentSortOption) {
      case SortOption.nameAsc:
        tempProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.quantityAsc:
        tempProducts.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case SortOption.quantityDesc:
        tempProducts.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case SortOption.dateDesc:
        tempProducts.sort((a, b) {
          final timeA = int.tryParse(a.id.split('_').last) ?? 0;
          final timeB = int.tryParse(b.id.split('_').last) ?? 0;
          return timeB.compareTo(timeA);
        });
        break;
      case SortOption.defaults:
        break;
    }
    _filteredProducts = tempProducts;
  }

  void filterProducts({String? query}) {
    if (query != null) _currentSearchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void selectCategory(String? category) {
    _selectedCategory = category;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void sortProducts(SortOption option) {
    _currentSortOption = option;
    _applyFiltersAndSort();
    notifyListeners();
  }

  Product? getProductById(String id) {
    try {
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _githubService.removeListener(_configChanged);
    super.dispose();
  }
}