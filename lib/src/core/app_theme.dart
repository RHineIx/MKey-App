import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF2A69C7);

  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  );

  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );

  // A single method to generate a theme with a dynamic font weight
  static ThemeData getTheme({
    required ColorScheme colorScheme,
    required FontWeight fontWeight,
    bool isDark = false,
  }) {
    var textTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    // Apply the selected font weight to all text styles
    TextTheme weightedTextTheme = textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontWeight: fontWeight),
      displayMedium: textTheme.displayMedium?.copyWith(fontWeight: fontWeight),
      displaySmall: textTheme.displaySmall?.copyWith(fontWeight: fontWeight),
      headlineLarge: textTheme.headlineLarge?.copyWith(fontWeight: fontWeight),
      headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: fontWeight),
      headlineSmall: textTheme.headlineSmall?.copyWith(fontWeight: fontWeight),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: fontWeight),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: fontWeight),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: fontWeight),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontWeight: fontWeight),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontWeight: fontWeight),
      bodySmall: textTheme.bodySmall?.copyWith(fontWeight: fontWeight),
      labelLarge: textTheme.labelLarge?.copyWith(fontWeight: fontWeight),
      labelMedium: textTheme.labelMedium?.copyWith(fontWeight: fontWeight),
      labelSmall: textTheme.labelSmall?.copyWith(fontWeight: fontWeight),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.cairoTextTheme(weightedTextTheme),
    );
  }
}