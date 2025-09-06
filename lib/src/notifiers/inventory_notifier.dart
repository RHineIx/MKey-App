import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/models/github_file_model.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/services/firestore_service.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';

class InventoryNotifier extends ChangeNotifier {
  FirestoreService _firestoreService;
  final GithubService _githubService;
  StreamSubscription? _productSubscription;

  static const _itemsPerPage = 20;

  InventoryNotifier(this._firestoreService, this._githubService) {
    _listenToProducts();
  }

  void updateFirestoreService(FirestoreService firestoreService) {
    _firestoreService = firestoreService;
    _productSubscription?.cancel();
    _listenToProducts();
  }

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  List<Product> _allProductsFromStream = [];
  List<Product> _filteredAndSortedProducts = [];
  List<Product> _displayedProducts = [];

  String _currentSearchQuery = '';
  String? _selectedCategory;
  SortOption _currentSortOption = SortOption.defaults;
  int _currentPage = 0;
  bool _hasMore = true;

  List<String> _allCategories = [];
  bool _isSelectionModeActive = false;
  final Set<String> _selectedItemIds = {};

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  List<Product> get displayedProducts => _displayedProducts;
  List<Product> get allProducts => _allProductsFromStream;
  List<String> get categories => _allCategories;
  String? get selectedCategory => _selectedCategory;
  String? get error => _error;
  bool get hasUncategorizedItems =>
      _allProductsFromStream.any((p) => p.categories.isEmpty);
  bool get isSelectionModeActive => _isSelectionModeActive;
  Set<String> get selectedItemIds => _selectedItemIds;

  void _listenToProducts() {
    if (!_firestoreService.isReady) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _productSubscription =
        _firestoreService.getProductsStream().listen((products) {
          _allProductsFromStream = products;
          _extractCategories();
          _applyFiltersAndSort();
          _loadInitialPage();
          _isLoading = false;
          _error = null;
          notifyListeners();
        }, onError: (e) {
          _error = "فشل تحميل المنتجات: $e";
          _isLoading = false;
          notifyListeners();
        });
  }

  void _applyFiltersAndSort() {
    List<Product> tempProducts = List.from(_allProductsFromStream);

    if (_selectedCategory == '_uncategorized_') {
      tempProducts = tempProducts.where((p) => p.categories.isEmpty).toList();
    } else if (_selectedCategory != null) {
      tempProducts = tempProducts
          .where((p) => p.categories.contains(_selectedCategory!))
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
        ].any((field) => field?.toLowerCase().contains(lowerCaseQuery) ?? false);
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

    _filteredAndSortedProducts = tempProducts;
  }

  void _loadInitialPage() {
    _currentPage = 0;
    _displayedProducts = [];
    _hasMore = true;
    _loadPage();
  }

  void _loadPage() {
    if (!_hasMore) return;

    final int startIndex = _currentPage * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;

    if (endIndex > _filteredAndSortedProducts.length) {
      endIndex = _filteredAndSortedProducts.length;
    }

    if (startIndex < _filteredAndSortedProducts.length) {
      _displayedProducts
          .addAll(_filteredAndSortedProducts.getRange(startIndex, endIndex));
    }

    _hasMore = _displayedProducts.length < _filteredAndSortedProducts.length;
    _currentPage++;
  }

  void loadMoreProducts() {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 100), () {
      _loadPage();
      _isLoadingMore = false;
      notifyListeners();
    });
  }

  void _refreshList() {
    _applyFiltersAndSort();
    _loadInitialPage();
    notifyListeners();
  }

  void filterProducts({String? query}) {
    _currentSearchQuery = query ?? '';
    _refreshList();
  }

  void selectCategory(String? category) {
    _selectedCategory = category;
    _refreshList();
  }

  void sortProducts(SortOption option) {
    _currentSortOption = option;
    _refreshList();
  }

  Future<void> addProduct(Product product, File? imageFile) async {
    await _addOrUpdateProduct(product, imageFile);
  }

  Future<void> updateProduct(Product updatedProduct, File? imageFile, {required Product originalProduct}) async {
    await _addOrUpdateProduct(updatedProduct, imageFile, originalProduct: originalProduct);
  }

  Future<void> _logChanges(Product oldProduct, Product newProduct) async {
    final changes = <Future<void>>[];

    if (oldProduct.name != newProduct.name) {
      changes.add(_firestoreService.addActivityLog(ActivityLog(id: 'log_${DateTime.now().millisecondsSinceEpoch}_name', timestamp: DateTime.now().toIso8601String(), user: 'المستخدم', action: 'NAME_UPDATED', targetId: newProduct.id, targetName: newProduct.name, details: {'from': oldProduct.name, 'to': newProduct.name})));
    }
    if (oldProduct.sku != newProduct.sku) {
      changes.add(_firestoreService.addActivityLog(ActivityLog(id: 'log_${DateTime.now().millisecondsSinceEpoch}_sku', timestamp: DateTime.now().toIso8601String(), user: 'المستخدم', action: 'SKU_UPDATED', targetId: newProduct.id, targetName: newProduct.name, details: {'from': oldProduct.sku, 'to': newProduct.sku})));
    }
    if (!listEquals(oldProduct.categories, newProduct.categories)) {
      changes.add(_firestoreService.addActivityLog(ActivityLog(id: 'log_${DateTime.now().millisecondsSinceEpoch}_cat', timestamp: DateTime.now().toIso8601String(), user: 'المستخدم', action: 'CATEGORY_UPDATED', targetId: newProduct.id, targetName: newProduct.name, details: {'from': oldProduct.categories, 'to': newProduct.categories})));
    }
    if (oldProduct.sellPriceIqd != newProduct.sellPriceIqd || oldProduct.sellPriceUsd != newProduct.sellPriceUsd) {
      changes.add(_firestoreService.addActivityLog(ActivityLog(id: 'log_${DateTime.now().millisecondsSinceEpoch}_price', timestamp: DateTime.now().toIso8601String(), user: 'المستخدم', action: 'PRICE_UPDATED', targetId: newProduct.id, targetName: newProduct.name, details: {'from': '${oldProduct.sellPriceIqd} IQD', 'to': '${newProduct.sellPriceIqd} IQD'})));
    }
    if (oldProduct.notes != newProduct.notes) {
      changes.add(_firestoreService.addActivityLog(ActivityLog(id: 'log_${DateTime.now().millisecondsSinceEpoch}_notes', timestamp: DateTime.now().toIso8601String(), user: 'المستخدم', action: 'NOTES_UPDATED', targetId: newProduct.id, targetName: newProduct.name, details: {'info' : 'تم تغيير الملاحظات'})));
    }
    if (oldProduct.supplierId != newProduct.supplierId) {
      changes.add(_firestoreService.addActivityLog(ActivityLog(id: 'log_${DateTime.now().millisecondsSinceEpoch}_supplier', timestamp: DateTime.now().toIso8601String(), user: 'المستخدم', action: 'SUPPLIER_UPDATED', targetId: newProduct.id, targetName: newProduct.name, details: {'from': oldProduct.supplierId ?? 'N/A', 'to': newProduct.supplierId ?? 'N/A'})));
    }

    await Future.wait(changes);
  }

  Future<void> _addOrUpdateProduct(Product product, File? imageFile, {Product? originalProduct}) async {
    if (!_firestoreService.isReady) throw Exception("Service not ready.");
    final isEditing = originalProduct != null;

    Product productWithImage = product;

    if (imageFile != null) {
      final imagePath = await _githubService.uploadImage(imageFile, product.sku);
      productWithImage = Product(
        id: product.id, name: product.name, sku: product.sku, quantity: product.quantity,
        alertLevel: product.alertLevel, costPriceIqd: product.costPriceIqd, sellPriceIqd: product.sellPriceIqd,
        costPriceUsd: product.costPriceUsd, sellPriceUsd: product.sellPriceUsd, notes: product.notes,
        imagePath: imagePath, categories: product.categories, oemPartNumber: product.oemPartNumber,
        compatiblePartNumber: product.compatiblePartNumber, supplierId: product.supplierId,
      );
      if(isEditing){
        await _firestoreService.addActivityLog(ActivityLog(id: 'log_${DateTime.now().millisecondsSinceEpoch}_image', timestamp: DateTime.now().toIso8601String(), user: 'المستخدم', action: 'IMAGE_UPDATED', targetId: productWithImage.id, targetName: productWithImage.name, details: {'info' : 'تم تحديث الصورة'}));
      }
    }

    await _firestoreService.setProduct(productWithImage);

    if (isEditing) {
      await _logChanges(originalProduct, productWithImage);
    } else {
      await _firestoreService.addActivityLog(ActivityLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now().toIso8601String(), user: 'المستخدم',
        action: 'ITEM_CREATED', targetId: productWithImage.id, targetName: productWithImage.name,
        details: {'sku': product.sku, 'quantity': product.quantity},
      ));
    }
  }

  Future<void> updateProductQuantity({
    required String productId,
    required int newQuantity,
    required String reason,
  }) async {
    if (!_firestoreService.isReady) return;

    final product = _allProductsFromStream.firstWhere((p) => p.id == productId);

    final updatedProduct = Product(
      id: product.id, name: product.name, sku: product.sku,
      quantity: newQuantity,
      alertLevel: product.alertLevel, costPriceIqd: product.costPriceIqd,
      sellPriceIqd: product.sellPriceIqd, costPriceUsd: product.costPriceUsd,
      sellPriceUsd: product.sellPriceUsd, imagePath: product.imagePath,
      categories: product.categories, oemPartNumber: product.oemPartNumber,
      compatiblePartNumber: product.compatiblePartNumber, notes: product.notes,
      supplierId: product.supplierId,
    );
    await _firestoreService.setProduct(updatedProduct);

    await _firestoreService.addActivityLog(ActivityLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().toIso8601String(), user: 'المستخدم',
      action: 'QUANTITY_UPDATED', targetId: updatedProduct.id, targetName: updatedProduct.name,
      details: { 'from': product.quantity, 'to': updatedProduct.quantity, 'reason': reason.isEmpty ? 'تعديل سريع' : reason },
    ));
  }

  Future<void> recordSale({
    required Product product, required int quantity, required double price,
    required String currency, required DateTime saleDate, required String notes,
    required double exchangeRate,
  }) async {
    if (!_firestoreService.isReady) return;

    final isIqd = currency == 'IQD';
    final sale = Sale(
      saleId: 'sale_${DateTime.now().millisecondsSinceEpoch}', itemId: product.id, itemName: product.name,
      quantitySold: quantity, sellPriceIqd: isIqd ? price : (price * exchangeRate), costPriceIqd: product.costPriceIqd,
      sellPriceUsd: isIqd ? (price / exchangeRate) : price, costPriceUsd: product.costPriceUsd,
      saleDate: DateFormat('yyyy-MM-dd').format(saleDate), notes: notes, timestamp: DateTime.now().toIso8601String(),
    );
    final updatedProduct = Product(
        id: product.id, name: product.name, sku: product.sku, quantity: product.quantity - quantity,
        alertLevel: product.alertLevel, costPriceIqd: product.costPriceIqd, sellPriceIqd: product.sellPriceIqd,
        costPriceUsd: product.costPriceUsd, sellPriceUsd: product.sellPriceUsd, notes: product.notes,
        imagePath: product.imagePath, categories: product.categories, oemPartNumber: product.oemPartNumber,
        compatiblePartNumber: product.compatiblePartNumber, supplierId: product.supplierId);

    await _firestoreService.setProduct(updatedProduct);
    await _firestoreService.addSale(sale);

    await _firestoreService.addActivityLog(ActivityLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}_sale',
        timestamp: sale.timestamp, user: 'المستخدم', action: 'SALE_RECORDED',
        targetId: product.id, targetName: product.name,
        details: {'quantity': quantity, 'price': price, 'currency': currency}));

    await _firestoreService.addActivityLog(ActivityLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}_qty',
        timestamp: sale.timestamp, user: 'المستخدم', action: 'QUANTITY_UPDATED',
        targetId: product.id, targetName: product.name,
        details: {'from': product.quantity, 'to': updatedProduct.quantity, 'reason': 'عملية بيع'}));
  }

  Future<void> deleteProduct(String productId) async {
    if (!_firestoreService.isReady) return;

    final productToDelete = _allProductsFromStream.firstWhere((p) => p.id == productId);

    await _firestoreService.deleteProduct(productId);

    await _firestoreService.addActivityLog(ActivityLog(
        action: 'ITEM_DELETED', id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        targetId: productToDelete.id, targetName: productToDelete.name,
        timestamp: DateTime.now().toIso8601String(), user: 'المستخدم', details: {'sku': productToDelete.sku, 'last_quantity': productToDelete.quantity}));

    if (productToDelete.imagePath != null && _githubService.isConfigured) {
      _githubService.getDirectoryListing('images').then((files) {
        final imageFile = files.firstWhere((f) => f.path == productToDelete.imagePath, orElse: () => GithubFile(path: '', sha: ''));
        if (imageFile.sha.isNotEmpty) {
          _githubService.deleteFile(imageFile.path, imageFile.sha);
        }
      }).catchError((e) {
        debugPrint("Could not delete image from GitHub: $e");
      });
    }
  }

  Future<void> handleBulkCategoryChange(List<String> newCategories) async {
    if (!_firestoreService.isReady) return;
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (String id in _selectedItemIds) {
      final docRef = _firestoreService.userDocRef!.collection('products').doc(id);
      batch.update(docRef, {'categories': newCategories});
    }
    await batch.commit();
    exitSelectionMode();
  }

  Future<void> handleBulkSupplierChange(String? newSupplierId) async {
    if (!_firestoreService.isReady) return;
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (String id in _selectedItemIds) {
      final docRef = _firestoreService.userDocRef!.collection('products').doc(id);
      batch.update(docRef, {'supplierId': newSupplierId});
    }
    await batch.commit();
    exitSelectionMode();
  }

  Future<void> renameCategory(String oldName, String newName) async {
    if (!_firestoreService.isReady) return;
    WriteBatch batch = FirebaseFirestore.instance.batch();

    final productsToUpdate = _allProductsFromStream.where((p) => p.categories.contains(oldName));
    for (final product in productsToUpdate) {
      final docRef = _firestoreService.userDocRef!.collection('products').doc(product.id);
      final newCategories = product.categories.map((c) => c == oldName ? newName : c).toList();
      batch.update(docRef, {'categories': newCategories});
    }
    await batch.commit();

    await _firestoreService.addActivityLog(ActivityLog(
      action: 'CATEGORY_RENAMED', id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      targetId: 'categories', targetName: 'All Categories',
      details: {'from': oldName, 'to': newName},
      timestamp: DateTime.now().toIso8601String(), user: 'المستخدم',
    ));
    _allCategories =
        _allCategories.map((c) => c == oldName ? newName : c).toList();
    if (_selectedCategory == oldName) {
      _selectedCategory = newName;
    }
    notifyListeners();
  }

  Future<List<GithubFile>> findUnusedImages() async {
    if (!_githubService.isConfigured) return [];
    final repoImages = await _githubService.getDirectoryListing('images');
    final usedImagePaths = _allProductsFromStream.map((p) => p.imagePath).where((p) => p != null).toSet();
    final unused = repoImages.where((file) => !usedImagePaths.contains(file.path)).toList();
    return unused;
  }

  Future<int> deleteUnusedImages(List<GithubFile> imagesToDelete) async {
    if (!_githubService.isConfigured) return 0;
    int successCount = 0;
    for (final image in imagesToDelete) {
      try {
        await _githubService.deleteFile(image.path, image.sha);
        successCount++;
      } catch (e) {
        debugPrint('Failed to delete ${image.path}: $e');
      }
    }
    return successCount;
  }

  void enterSelectionMode(String initialProductId) {
    if (_isSelectionModeActive) return;
    _isSelectionModeActive = true;
    _selectedItemIds.clear();
    _selectedItemIds.add(initialProductId);
    notifyListeners();
  }

  void exitSelectionMode() {
    if (!_isSelectionModeActive) return;
    _isSelectionModeActive = false;
    _selectedItemIds.clear();
    notifyListeners();
  }

  void toggleSelection(String productId) {
    if (!_isSelectionModeActive) return;

    if (_selectedItemIds.contains(productId)) {
      _selectedItemIds.remove(productId);
    } else {
      _selectedItemIds.add(productId);
    }

    if (_selectedItemIds.isEmpty) {
      exitSelectionMode();
    } else {
      notifyListeners();
    }
  }

  void _extractCategories() {
    final uniqueCategories =
    _allProductsFromStream.expand((p) => p.categories).toSet().toList();
    uniqueCategories.sort();
    _allCategories = uniqueCategories;
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    super.dispose();
  }
}