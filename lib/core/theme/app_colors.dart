import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C94FF);
  static const Color primaryDark = Color(0xFF3D35CC);
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentLight = Color(0xFF4DFFD8);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF22223B);
  static const Color darkBorder = Color(0xFF2D2D4A);
  static const Color darkDivider = Color(0xFF2A2A40);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF8F8FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F0FF);
  static const Color lightBorder = Color(0xFFE0E0F0);
  static const Color lightDivider = Color(0xFFEEEEFF);

  // Text colors – dark theme
  static const Color darkTextPrimary = Color(0xFFF0F0FF);
  static const Color darkTextSecondary = Color(0xFF9090B0);
  static const Color darkTextHint = Color(0xFF5A5A7A);

  // Text colors – light theme
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF5A5A7A);
  static const Color lightTextHint = Color(0xFF9090B0);

  // Chat bubble colors
  static const Color userBubbleDark = Color(0xFF6C63FF);
  static const Color userBubbleLight = Color(0xFF6C63FF);
  static const Color aiBubbleDark = Color(0xFF22223B);
  static const Color aiBubbleLight = Color(0xFFEEEEFF);

  // Status colors
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4D6A);
  static const Color info = Color(0xFF4DA6FF);

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF22223B), Color(0xFF2D2D4A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
