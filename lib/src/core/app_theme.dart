// FILE: lib/src/core/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // This remains the seed for the DYNAMIC (System) theme
  static const Color _seedColor = Color(0xFF2A69C7);

  // Manually defined light theme from website's CSS
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2A69C7),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD7E2FF),
    onPrimaryContainer: Color(0xFF001B3F),
    secondary: Color(0xFF565E71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDAE2F9),
    onSecondaryContainer: Color(0xFF131C2B),
    tertiary: Color(0xFF705575),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFAD7FC),
    onTertiaryContainer: Color(0xFF29132E),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFF4F7F9), // from --bg-color
    onBackground: Color(0xFF1A1C1E),
    surface: Color(0xFFFFFFFF), // from --surface-color
    onSurface: Color(0xFF1A202C), // from --text-primary
    surfaceVariant: Color(0xFFE0E2EC),
    onSurfaceVariant: Color(0xFF44474F),
    outline: Color(0xFF74777F),
    outlineVariant: Color(0xFFC4C6D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2F3033),
    onInverseSurface: Color(0xFFF1F0F4),
    inversePrimary: Color(0xFFACC7FF),
  );

  // Manually defined dark theme from website's CSS
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF3D83EB), // from --accent-color (dark)
    onPrimary: Color(0xFF002F66),
    primaryContainer: Color(0xFF00458F),
    onPrimaryContainer: Color(0xFFD7E2FF),
    secondary: Color(0xFFBEC6DC),
    onSecondary: Color(0xFF283141),
    secondaryContainer: Color(0xFF3E4759),
    onSecondaryContainer: Color(0xFFDAE2F9),
    tertiary: Color(0xFFDDBCE0),
    onTertiary: Color(0xFF3F2844),
    tertiaryContainer: Color(0xFF573E5C),
    onTertiaryContainer: Color(0xFFFAD7FC),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFB4AB),
    background: Color(0xFF121212), // from --bg-color (dark)
    onBackground: Color(0xFFE3E2E6),
    surface: Color(0xFF1E1E1E), // from --surface-color (dark)
    onSurface: Color(0xFFE0E0E0), // from --text-primary (dark)
    surfaceVariant: Color(0xFF44474F),
    onSurfaceVariant: Color(0xFFC4C6D0),
    outline: Color(0xFF8E9099),
    outlineVariant: Color(0xFF44474F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE3E2E6),
    onInverseSurface: Color(0xFF1A1C1E),
    inversePrimary: Color(0xFF2A69C7),
  );

  static ThemeData getTheme({
    required ColorScheme colorScheme,
    required FontWeight fontWeight,
    bool isDark = false,
  }) {
    var textTheme =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    TextTheme weightedTextTheme = textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontWeight: fontWeight),
      displayMedium: textTheme.displayMedium?.copyWith(fontWeight: fontWeight),
      displaySmall: textTheme.displaySmall?.copyWith(fontWeight: fontWeight),
      headlineLarge: textTheme.headlineLarge?.copyWith(fontWeight: fontWeight),
      headlineMedium:
          textTheme.headlineMedium?.copyWith(fontWeight: fontWeight),
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
        scaffoldBackgroundColor:
            colorScheme.background, // Use background from scheme
        textTheme: GoogleFonts.cairoTextTheme(weightedTextTheme),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 1,
          shadowColor: const Color.fromARGB(26, 0, 0, 0),
          titleTextStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: colorScheme.onSurface),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                width: 0.8),
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
        ));
  }
}