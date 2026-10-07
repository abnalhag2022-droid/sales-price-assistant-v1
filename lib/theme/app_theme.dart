import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF115E59);
  static const background = Color(0xFFF4F7F7);
  static const text = Color(0xFF17313A);
  static const muted = Color(0xFF6B7C83);
  static const line = Color(0xFFDCE7E8);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
    fontFamily: 'sans',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: text,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: primary, width: 1.4)),
      contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
    ),
  );
}
