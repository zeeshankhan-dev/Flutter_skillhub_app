import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF2D5C85), // Primary Blue
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D5C85),
      elevation: 0,
    ),
    textTheme: TextTheme(
      headline1: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      bodyText1: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8E44AD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    ),
  );

  final ThemeData adminTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black.withOpacity(0.2),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white),
    ),
  );

}
