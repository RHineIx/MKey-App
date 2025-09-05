import 'dart:async'; // FIXED: Missing import
import 'package:flutter/material.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/services/firestore_service.dart';

class Bestseller {
  final String name;
  final int count;
  Bestseller({required this.name, required this.count});
}

class DashboardNotifier extends ChangeNotifier {
  FirestoreService _firestoreService;
  StreamSubscription? _salesSubscription; // FIXED: Class was undefined
  StreamSubscription? _productsSubscription; // FIXED: Class was undefined

  DashboardNotifier(this._firestoreService) {
    _listenToData();
  }

  void updateFirestoreService(FirestoreService firestoreService) {
    _firestoreService = firestoreService;
    _salesSubscription?.cancel();
    _productsSubscription?.cancel();
    _listenToData();
  }

  bool _isLoading = true;
  List<Sale> _allSales = [];
  List<Product> _allProducts = [];
  String? _error;

  DashboardPeriod _period = DashboardPeriod.today;
  List<Sale> _filteredSales = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Sale> get filteredSales => _filteredSales;
  DashboardPeriod get period => _period;

  List<Bestseller> get bestsellers {
    final Map<String, int> itemSales = {};
    for (var sale in _filteredSales) {
      itemSales[sale.itemId] = (itemSales[sale.itemId] ?? 0) + sale.quantitySold;
    }

    final sortedBestsellers = itemSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedBestsellers.take(5).map((entry) {
      final product = _allProducts.firstWhere(
            (p) => p.id == entry.key,
        orElse: () => Product(id: entry.key, name: 'منتج محذوف', sku: ''),
      );
      return Bestseller(name: product.name, count: entry.value);
    }).toList();
  }

  void _listenToData() {
    if (!_firestoreService.isReady) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _productsSubscription = _firestoreService.getProductsStream().listen(
          (products) {
        _allProducts = products;
        if (!_isLoading || _allSales.isNotEmpty) {
          _applyFilter();
          notifyListeners();
        }
      },
      onError: (e) => _handleError(e),
    );

    _salesSubscription = _firestoreService.getSalesStream().listen(
          (sales) {
        _allSales = sales;
        _isLoading = false;
        _error = null;
        _applyFilter();
        notifyListeners();
      },
      onError: (e) => _handleError(e),
    );
  }

  void _handleError(Object e) {
    _error = "فشل تحميل البيانات: $e";
    _isLoading = false;
    notifyListeners();
  }

  // FIXED: Renamed method to match what UI expects
  Future<void> deleteSale(String saleId) async {
    if (!_firestoreService.isReady) return;

    final saleToDelete = _allSales.firstWhere((s) => s.saleId == saleId);
    final productToUpdate = _allProducts.firstWhere((p) => p.id == saleToDelete.itemId);

    final updatedProduct = Product(
      id: productToUpdate.id,
      name: productToUpdate.name,
      sku: productToUpdate.sku,
      quantity: productToUpdate.quantity + saleToDelete.quantitySold,
      alertLevel: productToUpdate.alertLevel,
      costPriceIqd: productToUpdate.costPriceIqd,
      sellPriceIqd: productToUpdate.sellPriceIqd,
      costPriceUsd: productToUpdate.costPriceUsd,
      sellPriceUsd: productToUpdate.sellPriceUsd,
      imagePath: productToUpdate.imagePath,
      categories: productToUpdate.categories,
      oemPartNumber: productToUpdate.oemPartNumber,
      compatiblePartNumber: productToUpdate.compatiblePartNumber,
      notes: productToUpdate.notes,
      supplierId: productToUpdate.supplierId,
    );

    await _firestoreService.setProduct(updatedProduct);
    await _firestoreService.deleteSale(saleId);
  }

  void setPeriod(DashboardPeriod newPeriod) {
    if (_period == newPeriod) return;
    _period = newPeriod;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_period) {
      case DashboardPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case DashboardPeriod.week:
        startDate = now.subtract(const Duration(days: 6));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case DashboardPeriod.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    _filteredSales = _allSales.where((sale) {
      final saleDate = DateTime.tryParse(sale.saleDate);
      return saleDate != null && !saleDate.isBefore(startDate);
    }).toList();
  }

  @override
  void dispose() {
    _salesSubscription?.cancel();
    _productsSubscription?.cancel();
    super.dispose();
  }
}