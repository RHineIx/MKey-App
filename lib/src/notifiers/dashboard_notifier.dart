// FILE: lib/src/notifiers/dashboard_notifier.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rhineix_mkey_app/src/core/database_helper.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/product_model.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';

class Bestseller {
  final String name;
  final int count;
  Bestseller({required this.name, required this.count});
}

class DashboardNotifier extends ChangeNotifier {
  final GithubService _githubService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Product> _allProducts = [];

  DashboardNotifier(this._githubService) {
    _githubService.addListener(syncFromNetwork);
    loadSalesFromDb();
  }

  bool _isLoading = false;
  List<Sale> _allSales = [];
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

  Future<void> loadSalesFromDb() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allProducts = await _dbHelper.getAllProducts();
      _allSales = await _dbHelper.getAllSales();
      _applyFilter();
    } catch (e) {
      _error = "فشل تحميل المبيعات من قاعدة البيانات المحلية: $e";
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
      final networkSales = await _githubService.fetchSales();
      final networkProducts = await _githubService.fetchInventory();

      await _dbHelper.batchUpdateSales(networkSales);
      await _dbHelper.batchUpdateProducts(networkProducts);

      await loadSalesFromDb();
      return null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return _error;
    }
  }

  Future<int> archiveOldSales() async {
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    final salesToArchive = _allSales.where((sale) {
      final saleDate = DateTime.tryParse(sale.saleDate);
      return saleDate != null && saleDate.isBefore(threeMonthsAgo);
    }).toList();

    if (salesToArchive.isEmpty) {
      return 0; // No sales to archive
    }

    final remainingSales = _allSales.where((sale) {
      final saleDate = DateTime.tryParse(sale.saleDate);
      return saleDate == null || !saleDate.isBefore(threeMonthsAgo);
    }).toList();

    _isLoading = true;
    notifyListeners();

    try {
      final archiveFileName = 'sales_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
      await _githubService.createArchiveFile(archiveFileName, salesToArchive);

      _allSales = remainingSales;
      await _dbHelper.batchUpdateSales(_allSales);
      await _githubService.saveSales(_allSales);

      await loadSalesFromDb();
      return salesToArchive.length;
    } catch (e) {
      await loadSalesFromDb(); // Revert on failure
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    _githubService.removeListener(syncFromNetwork);
    super.dispose();
  }
}