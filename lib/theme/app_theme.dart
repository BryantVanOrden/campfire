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

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.mediumGreen,  // Keeping green as the primary color
      scaffoldBackgroundColor: Colors.black, // Dark background for the entire app
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
      colorScheme: ColorScheme.dark().copyWith(
        primary: AppColors.mediumGreen,
        secondary: AppColors.lightGreen,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.lightGreen,
        unselectedItemColor: Colors.grey,
        backgroundColor: AppColors.darkGreen, // Darker background for bottom bar
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: Colors.white, // Ensuring text stands out on the dark background
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardColor: Colors.grey[900], // Darker color for card widgets
      dialogBackgroundColor: Colors.grey[850], // Darker background for dialogs
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: AppColors.mediumGreen, // Button text color
        ),
      ),
    );
  }
}
