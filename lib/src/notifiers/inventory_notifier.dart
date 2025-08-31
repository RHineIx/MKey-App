// FILE: lib/src/notifiers/inventory_notifier.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rhineix_mkey_app/src/core/database_helper.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
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
  bool get hasUncategorizedItems => _allProducts.any((p) => p.categories.isEmpty);

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

  Future<void> addProduct(Product product, File? imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? imagePath;
      if (imageFile != null) {
        imagePath = await _githubService.uploadImage(imageFile, product.sku);
      }
      
      final newProduct = Product(
        id: product.id,
        name: product.name,
        sku: product.sku,
        quantity: product.quantity,
        alertLevel: product.alertLevel,
        costPriceIqd: product.costPriceIqd,
        sellPriceIqd: product.sellPriceIqd,
        costPriceUsd: product.costPriceUsd,
        sellPriceUsd: product.sellPriceUsd,
        notes: product.notes,
        imagePath: imagePath,
        categories: product.categories,
        oemPartNumber: product.oemPartNumber,
        compatiblePartNumber: product.compatiblePartNumber,
        supplierId: product.supplierId,
      );

      _allProducts.add(newProduct);
      await _dbHelper.batchUpdateProducts(_allProducts);
      await _githubService.saveInventory(_allProducts);
      await loadProductsFromDb();

    } catch(e) {
      await loadProductsFromDb();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

   Future<void> updateProduct(Product product, File? imageFile) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      String? imagePath = product.imagePath;
      if (imageFile != null) {
        imagePath = await _githubService.uploadImage(imageFile, product.sku);
      }

      final updatedProduct = Product(
        id: product.id,
        name: product.name,
        sku: product.sku,
        quantity: product.quantity,
        alertLevel: product.alertLevel,
        costPriceIqd: product.costPriceIqd,
        sellPriceIqd: product.sellPriceIqd,
        costPriceUsd: product.costPriceUsd,
        sellPriceUsd: product.sellPriceUsd,
        notes: product.notes,
        imagePath: imagePath,
        categories: product.categories,
        oemPartNumber: product.oemPartNumber,
        compatiblePartNumber: product.compatiblePartNumber,
        supplierId: product.supplierId,
      );

      final index = _allProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _allProducts[index] = updatedProduct;
        await _dbHelper.batchUpdateProducts(_allProducts);
        await _githubService.saveInventory(_allProducts);
        await loadProductsFromDb();
      }
    } catch(e) {
      await loadProductsFromDb();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordSale({
    required Product product,
    required int quantity,
    required double price,
    required String currency,
    required DateTime saleDate,
    required String notes,
    required double exchangeRate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedProduct = Product(
          id: product.id,
          name: product.name,
          sku: product.sku,
          quantity: product.quantity - quantity,
          alertLevel: product.alertLevel,
          costPriceIqd: product.costPriceIqd,
          sellPriceIqd: product.sellPriceIqd,
          costPriceUsd: product.costPriceUsd,
          sellPriceUsd: product.sellPriceUsd,
          notes: product.notes,
          imagePath: product.imagePath,
          categories: product.categories,
          oemPartNumber: product.oemPartNumber,
          compatiblePartNumber: product.compatiblePartNumber,
          supplierId: product.supplierId);
      
      final index = _allProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _allProducts[index] = updatedProduct;
      }

      final isIqd = currency == 'IQD';
      final sale = Sale(
        saleId: 'sale_${DateTime.now().millisecondsSinceEpoch}',
        itemId: product.id,
        itemName: product.name,
        quantitySold: quantity,
        sellPriceIqd: isIqd ? price : (price * exchangeRate),
        costPriceIqd: product.costPriceIqd,
        sellPriceUsd: isIqd ? (price / exchangeRate) : price,
        costPriceUsd: product.costPriceUsd,
        saleDate: DateFormat('yyyy-MM-dd').format(saleDate),
        notes: notes,
        timestamp: DateTime.now().toIso8601String(),
      );

      final allSales = await _dbHelper.getAllSales();
      allSales.add(sale);
      await _dbHelper.batchUpdateSales(allSales);
      await _dbHelper.batchUpdateProducts(_allProducts);

      await _githubService.saveInventory(_allProducts);
      await _githubService.saveSales(allSales);
      
      await loadProductsFromDb();
      
    } catch (e) {
      await loadProductsFromDb(); // Revert on failure
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> deleteProduct(String productId) async {
     _isLoading = true;
    notifyListeners();
    try {
      _allProducts.removeWhere((p) => p.id == productId);
      await _dbHelper.batchUpdateProducts(_allProducts);
      await _githubService.saveInventory(_allProducts);
      await loadProductsFromDb();
    } catch (e) {
      await loadProductsFromDb();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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

    if (_selectedCategory == '_uncategorized_') {
      tempProducts = tempProducts.where((p) => p.categories.isEmpty).toList();
    } else if (_selectedCategory != null) {
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