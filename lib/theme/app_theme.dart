import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.darkGreen,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppColors.darkGreen,
        secondary: AppColors.mediumGreen,
      ),
      scaffoldBackgroundColor: AppColors.offWhite,
      appBarTheme: const AppBarTheme(
        color: AppColors.darkGreen,
        titleTextStyle: TextStyle(
          color: AppColors.offWhite,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.offWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.darkGreen,
        unselectedItemColor: AppColors.mediumGreen,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: AppColors.darkGreen,
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
