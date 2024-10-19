// lib/src/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.darkGreen,
      accentColor: AppColors.yellow,
      scaffoldBackgroundColor: AppColors.lightGreen,
      appBarTheme: AppBarTheme(
        color: AppColors.darkGreen,
        textTheme: TextTheme(
          headline6: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: AppColors.red,
        textTheme: ButtonTextTheme.primary,
      ),
      
    );
  }
}
