import 'package:flutter/material.dart';

class AppColors {
  // Official Brand Palette per Part 5.2
  static const Color primaryGreen = Color(0xFF006B52);
  static const Color darkGreen = Color(0xFF004D3B);
  static const Color emerald = Color(0xFF008866);
  static const Color secondaryGreen = Color(0xFF10A77D);
  static const Color pastelGreen = Color(0xFFDDF4E8);
  static const Color veryLightGreen = Color(0xFFEFF9F3);
  static const Color mainBackground = Color(0xFFF4FAF7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFD9E9E1);
  static const Color mainText = Color(0xFF173A31);
  static const Color secondaryText = Color(0xFF71867E);

  // Status & Calendar Palette
  static const Color reservationBlue = Color(0xFFDCEBFF);
  static const Color reservationBlueText = Color(0xFF1554A3);
  static const Color holidayRed = Color(0xFFFDE7EA);
  static const Color holidayRedText = Color(0xFFB42335);
  static const Color disabledGray = Color(0xFFE8ECEE);
  static const Color disabledText = Color(0xFF68737A);

  // Alerts
  static const Color warning = Color(0xFFFFF2D9);
  static const Color success = Color(0xFFDDF4E8);
  static const Color error = Color(0xFFFDE7EA);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [darkGreen, emerald],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient softBackgroundGradient = LinearGradient(
    colors: [mainBackground, veryLightGreen],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
