// FILE: lib/src/notifiers/activity_log_notifier.dart
import 'package:flutter/material.dart';
import 'package:rhineix_mkey_app/src/core/database_helper.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';

class ActivityLogNotifier extends ChangeNotifier {
  final GithubService _githubService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  ActivityLogNotifier(this._githubService) {
    _githubService.addListener(syncFromNetwork);
    loadLogsFromDb();
  }

  bool _isLoading = false;
  List<ActivityLog> _allLogs = [];
  String? _error;

  ActivityLogFilter _filter = ActivityLogFilter.all;
  List<ActivityLog> _filteredLogs = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ActivityLog> get filteredLogs => _filteredLogs;
  ActivityLogFilter get filter => _filter;

  Future<void> loadLogsFromDb() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allLogs = await _dbHelper.getAllActivityLogs();
      _applyFilter();
    } catch (e) {
      _error = "فشل تحميل سجل النشاطات من قاعدة البيانات المحلية: $e";
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
      final networkLogs = await _githubService.fetchActivityLogs();
      await _dbHelper.batchUpdateActivityLogs(networkLogs);
      await loadLogsFromDb();
      return null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return _error;
    }
  }

  Future<void> logAction({
    required String action,
    required String targetId,
    required String targetName,
    String user = 'المستخدم', // TODO: Get from SettingsNotifier
    Map<String, dynamic> details = const {},
  }) async {
    final newLog = ActivityLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().toIso8601String(),
      user: user,
      action: action,
      targetId: targetId,
      targetName: targetName,
      details: details,
    );

    _allLogs.insert(0, newLog);
    await _dbHelper.batchUpdateActivityLogs(_allLogs);
    await _githubService.saveActivityLogs(_allLogs);

    // Refresh the view
    _applyFilter();
    notifyListeners();
  }

  void setFilter(ActivityLogFilter newFilter) {
    if (_filter == newFilter) return;
    _filter = newFilter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_filter == ActivityLogFilter.all) {
      _filteredLogs = _allLogs;
      return;
    }

    const lifecycleActions = ['ITEM_CREATED', 'ITEM_DELETED'];
    const otherUpdateActions = [
      'NAME_UPDATED', 'SKU_UPDATED', 'CATEGORY_UPDATED',
      'PRICE_UPDATED', 'NOTES_UPDATED', 'IMAGE_UPDATED', 'SUPPLIER_UPDATED'
    ];

    _filteredLogs = _allLogs.where((log) {
      switch (_filter) {
        case ActivityLogFilter.sale:
          return log.action == 'SALE_RECORDED';
        case ActivityLogFilter.quantity:
          return log.action == 'QUANTITY_UPDATED';
        case ActivityLogFilter.lifecycle:
          return lifecycleActions.contains(log.action);
        case ActivityLogFilter.other:
          return otherUpdateActions.contains(log.action);
        default:
          return true;
      }
    }).toList();
  }

  @override
  void dispose() {
    _githubService.removeListener(syncFromNetwork);
    super.dispose();
  }
}