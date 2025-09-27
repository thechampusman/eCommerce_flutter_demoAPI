import 'package:flutter/material.dart';

class AppColors {
  
  static const Color primaryOrange = Color(0xFFFF9900);
  static const Color primaryBlue = Color(0xFF232F3E);
  static const Color darkBlue = Color(0xFF131A22);

  
  static const Color textPrimary = Color(0xFF0F1111);
  static const Color textSecondary = Color(0xFF565959);
  static const Color textLight = Color(0xFF767676);
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF3F3F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD5D9D9);
  static const Color borderLight = Color(0xFFE7E7E7);

  
  static const Color success = Color(0xFF48BB78);
  static const Color error = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFED8936);
  static const Color info = Color(0xFF3182CE);

  
  static Color cardShadow = Colors.black.withOpacity(0.08);
  static Color cardBorder = Colors.grey.withOpacity(0.2);
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.backgroundGray, AppColors.background],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryBlue, AppColors.darkBlue],
  );
}

class AppConstants {
  
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  
  static const double glassBlur = 15.0;
  static const double glassOpacity = 0.15;

  
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
}
