// FILE: lib/src/core/enums.dart
import 'package:flutter/material.dart';

enum AppFontWeight {
  light,
  normal,
  medium,
  bold,
}

extension AppFontWeightExtension on AppFontWeight {
  FontWeight get value {
    switch (this) {
      case AppFontWeight.light:
        return FontWeight.w300;
      case AppFontWeight.normal:
        return FontWeight.w400;
      case AppFontWeight.medium:
        return FontWeight.w500;
      case AppFontWeight.bold:
        return FontWeight.w700;
    }
  }

  String get displayName {
    switch (this) {
      case AppFontWeight.light:
        return 'خفيف';
      case AppFontWeight.normal:
        return 'عادي';
      case AppFontWeight.medium:
        return 'متوسط';
      case AppFontWeight.bold:
        return 'عريض (Bold)';
    }
  }
}

enum SortOption {
  defaults,
  nameAsc,
  quantityAsc,
  quantityDesc,
  dateDesc,
}

enum DashboardPeriod { today, week, month }

enum ActivityLogFilter { all, sale, quantity, lifecycle, other }