import 'package:flutter/material.dart';

enum NotificationType { success, error, info, syncing }

enum AppThemeMode {
  light('فاتح'),
  dark('داكن'),
  system('النظام');

  const AppThemeMode(this.displayName);
  final String displayName;
}

enum AppFontWeight {
  light('خفيف', FontWeight.w300),
  normal('عادي', FontWeight.w400),
  medium('متوسط', FontWeight.w500),
  bold('عريض', FontWeight.w700);

  const AppFontWeight(this.displayName, this.value);
  final String displayName;
  final FontWeight value;
}

enum SortOption {
  defaults,
  nameAsc,
  quantityAsc,
  quantityDesc,
  dateDesc
}

enum DashboardPeriod { today, week, month }

enum ActivityLogFilter {
  all,
  sale,
  quantity,
  lifecycle,
  other,
}