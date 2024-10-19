import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.darkGreen,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppColors.darkGreen,
        secondary: AppColors
            .yellow, // Use secondary for what was previously 'accentColor'
      ),
      scaffoldBackgroundColor: AppColors.lightGreen,
      appBarTheme: AppBarTheme(
        color: AppColors.darkGreen,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
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
