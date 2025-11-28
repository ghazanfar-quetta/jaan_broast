// lib/core/constants/app_themes.dart
import 'package:flutter/material.dart';
import 'app_constants.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(AppConstants.primaryColorLight),
      colorScheme: const ColorScheme.light(
        primary: Color(AppConstants.primaryColorLight),
        secondary: Color(AppConstants.accentColorLight),
        background: Color(AppConstants.backgroundColorLight),
        surface: Color(AppConstants.surfaceColorLight),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Color(AppConstants.textColorLight),
        onSurface: Color(AppConstants.textColorLight),
      ),
      scaffoldBackgroundColor: const Color(AppConstants.backgroundColorLight),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppConstants.primaryColorLight),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(AppConstants.surfaceColorLight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(AppConstants.primaryColorDark),
      colorScheme: const ColorScheme.dark(
        primary: Color(AppConstants.primaryColorDark),
        secondary: Color(AppConstants.accentColorDark),
        background: Color(AppConstants.backgroundColorDark),
        surface: Color(AppConstants.surfaceColorDark),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: Color(AppConstants.textColorDark),
        onSurface: Color(AppConstants.textColorDark),
      ),
      scaffoldBackgroundColor: const Color(AppConstants.backgroundColorDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppConstants.surfaceColorDark),
        foregroundColor: Color(AppConstants.textColorDark),
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(AppConstants.surfaceColorDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium,
        ),
      ),
    );
  }
}
