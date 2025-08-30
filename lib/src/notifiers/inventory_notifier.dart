import 'package:flutter/material.dart';
import 'package:rhineix_workshop_app/src/models/product_model.dart';
import 'package:rhineix_workshop_app/src/services/github_service.dart';

// We define an enum to represent the sort options for type safety.
enum SortOption { defaults, nameAsc, quantityAsc, quantityDesc }

class InventoryNotifier extends ChangeNotifier {
  final GithubService _githubService;

  InventoryNotifier(this._githubService) {
    _githubService.addListener(_configChanged);
  }

  bool _isLoading = false;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String? _error;

  // State variables for filtering and sorting
  String _currentSearchQuery = '';
  String? _selectedCategory;
  SortOption _currentSortOption = SortOption.defaults;
  List<String> _allCategories = [];

  // Public getters
  bool get isLoading => _isLoading;
  List<Product> get products => _allProducts;
  List<Product> get filteredProducts => _filteredProducts;
  List<String> get categories => _allCategories;
  String? get selectedCategory => _selectedCategory;
  String? get error => _error;

  void _configChanged() {
    fetchInventory();
  }

  Future<void> fetchInventory({VoidCallback? onFilterChanged}) async {
    if (!_githubService.isConfigured) {
      _allProducts = [];
      _filteredProducts = [];
      _error = 'الرجاء إدخال إعدادات المزامنة أولاً.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    if (_allProducts.isEmpty) notifyListeners();

    try {
      _allProducts = await _githubService.fetchInventory();
      // Corrected: Explicitly cast the list to List<String>
      final uniqueCategories = _allProducts.expand((p) => p.categories ?? []).toSet().toList().cast<String>();
      uniqueCategories.sort();
      _allCategories = uniqueCategories;
      _applyFiltersAndSort();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      onFilterChanged?.call();
      notifyListeners();
    }
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