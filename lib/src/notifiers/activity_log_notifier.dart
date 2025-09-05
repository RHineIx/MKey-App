import 'dart:async'; // FIXED: Missing import
import 'package:flutter/material.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/activity_log_model.dart';
import 'package:rhineix_mkey_app/src/services/firestore_service.dart';

class ActivityLogNotifier extends ChangeNotifier {
  FirestoreService _firestoreService;
  StreamSubscription? _logSubscription; // FIXED: Class was undefined

  ActivityLogNotifier(this._firestoreService) {
    _listenToLogs();
  }

  // Method to update the service when the user logs in
  void updateFirestoreService(FirestoreService firestoreService) {
    _firestoreService = firestoreService;
    _logSubscription?.cancel();
    _listenToLogs();
  }

  bool _isLoading = true;
  List<ActivityLog> _allLogs = [];
  String? _error;
  ActivityLogFilter _filter = ActivityLogFilter.all;
  List<ActivityLog> _filteredLogs = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ActivityLog> get filteredLogs => _filteredLogs;
  ActivityLogFilter get filter => _filter;

  void _listenToLogs() {
    if (!_firestoreService.isReady) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _logSubscription =
        _firestoreService.getActivityLogsStream().listen((logs) {
          _allLogs = logs;
          _applyFilter();
          _isLoading = false;
          _error = null;
          notifyListeners();
        }, onError: (e) {
          _error = "فشل تحميل سجل النشاطات: $e";
          _isLoading = false;
          notifyListeners();
        });
  }

  Future<void> clearLogs() async {
    if (!_firestoreService.isReady) return;
    await _firestoreService.clearActivityLogs();
    // The stream will automatically update the UI
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
      'PRICE_UPDATED', 'NOTES_UPDATED', 'IMAGE_UPDATED', 'SUPPLIER_UPDATED', 'CATEGORY_RENAMED'
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
    _logSubscription?.cancel();
    super.dispose();
  }
}