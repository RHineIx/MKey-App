// FILE: lib/src/notifiers/dashboard_notifier.dart
import 'package:flutter/material.dart';
import 'package:rhineix_mkey_app/src/core/database_helper.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/sale_model.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';

class DashboardNotifier extends ChangeNotifier {
  final GithubService _githubService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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

  Future<void> loadSalesFromDb() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
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
      await _dbHelper.batchUpdateSales(networkSales);
      await loadSalesFromDb();
      return null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return _error;
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
    DateTime startDate; // Corrected: Removed 'final'

    switch (_period) {
      case DashboardPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case DashboardPeriod.week:
      // Corrected logic to properly set the start date for the week
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