import 'package:flutter/material.dart';

// An enum to represent the available font weights
enum AppFontWeight {
  light,
  normal,
  medium,
  bold,
}

// Extension to get the actual FontWeight value and a display name
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