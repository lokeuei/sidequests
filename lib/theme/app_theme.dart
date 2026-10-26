import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Golden-hour explorer": warm paper, deep pine, persimmon.
/// Display serif (Fraunces) for voice, Outfit for everything else.
class AppColors {
  static const pine = Color(0xFF1E4D3F);
  static const persimmon = Color(0xFFD95D39);
  static const amber = Color(0xFFE9A13B);
  static const sand = Color(0xFFF3EDE0);
  static const paper = Color(0xFFFFFDF7);
  static const ink = Color(0xFF1C2420);
  static const moss = Color(0xFF7FC6A4);
  static const night = Color(0xFF101814);
  static const nightSurface = Color(0xFF16211C);
  static const nightInk = Color(0xFFF1ECE0);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.pine,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.pine,
      secondary: AppColors.persimmon,
      tertiary: AppColors.amber,
      surface: AppColors.paper,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.sand,
      textTheme: _text(base.textTheme, AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.pine,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.amber,
      onPrimary: AppColors.night,
      secondary: AppColors.moss,
      tertiary: AppColors.persimmon,
      surface: AppColors.nightSurface,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.night,
      textTheme: _text(base.textTheme, AppColors.nightInk),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
    );
  }

  static TextTheme _text(TextTheme base, Color ink) {
    final body = GoogleFonts.outfitTextTheme(base);
    return body.copyWith(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        height: 1.05,
        color: ink,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: ink,
      ),
      displaySmall: GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.15,
        color: ink,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleLarge: GoogleFonts.fraunces(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: ink),
      bodyMedium: body.bodyMedium?.copyWith(color: ink),
      bodySmall: body.bodySmall?.copyWith(color: ink.withValues(alpha: 0.72)),
    );
  }
}
