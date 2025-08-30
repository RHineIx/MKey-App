import 'package:flutter/material.dart';
import 'package:rhineix_workshop_app/src/core/database_helper.dart';
import 'package:rhineix_workshop_app/src/models/product_model.dart';
import 'package:rhineix_workshop_app/src/services/github_service.dart';

enum SortOption { defaults, nameAsc, quantityAsc, quantityDesc }

class InventoryNotifier extends ChangeNotifier {
  final GithubService _githubService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  InventoryNotifier(this._githubService) {
    _githubService.addListener(syncFromNetwork); // Sync when config changes
    loadProductsFromDb(); // Load local data immediately on startup
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
      await loadProductsFromDb(); // Reload from DB to show the latest data
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      // On failure, keep the old data, just stop loading and report error message
      _isLoading = false;
      notifyListeners();
      return e.toString(); // Return error message
    }
  }

  void _extractCategories() {
    final uniqueCategories = _allProducts.expand((p) => p.categories ?? []).toSet().cast<String>().toList();
    uniqueCategories.sort();
    _allCategories = uniqueCategories;
  }

  void _applyFiltersAndSort() {
    List<Product> tempProducts = List.from(_allProducts);
    if (_selectedCategory != null) {
      tempProducts = tempProducts.where((p) => p.categories?.contains(_selectedCategory) ?? false).toList();
    }
    if (_currentSearchQuery.isNotEmpty) {
      final lowerCaseQuery = _currentSearchQuery.toLowerCase();
      tempProducts = tempProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(lowerCaseQuery);
        final skuMatch = product.sku.toLowerCase().contains(lowerCaseQuery);
        return nameMatch || skuMatch;
      }).toList();
    }
    switch (_currentSortOption) {
      case SortOption.nameAsc:
        tempProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.quantityAsc:
        tempProducts.sort((a, b) => (a.quantity ?? 0).compareTo(b.quantity ?? 0));
        break;
      case SortOption.quantityDesc:
        tempProducts.sort((a, b) => (b.quantity ?? 0).compareTo(a.quantity ?? 0));
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

  @override
  void dispose() {
    _githubService.removeListener(_configChanged);
    super.dispose();
  }
}