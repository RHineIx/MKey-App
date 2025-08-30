// FILE: lib/src/core/app_theme.dart
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
    surface: const Color(0xFF121212),
  );

  static ThemeData getTheme({
    required ColorScheme colorScheme,
    required FontWeight fontWeight,
    bool isDark = false,
  }) {
    var textTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

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
        scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F9),
        textTheme: GoogleFonts.cairoTextTheme(weightedTextTheme),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 1,
          shadowColor: const Color.fromARGB(26, 0, 0, 0), // Corrected: Replaced withOpacity
          titleTextStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: colorScheme.onSurface
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 0.8),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        )
    );
  }
}