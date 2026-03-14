import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xff2563eb);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
    scaffoldBackgroundColor: const Color(0xfff1f5f9),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade100),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 68,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xff2563eb).withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff2563eb));
        }
        return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _seed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _seed,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xff0a0f1e),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xff1a2235),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xff243047)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 68,
      backgroundColor: const Color(0xff111827),
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xff2563eb).withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xff60a5fa));
        }
        return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xff64748b));
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xff1a2235),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff2d3f5e)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff2d3f5e)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _seed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xff94a3b8)),
      hintStyle: const TextStyle(color: Color(0xff475569)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _seed,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xff1e293b),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
