import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppColors {
  // Static Basic Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Static Fallback Constants
  static const Color primary = AppTheme.lightPrimary;
  static const Color secondary = AppTheme.lightSecondary;
  static const Color background = AppTheme.lightBackground;
  static const Color surface = AppTheme.lightSurface;
  static const Color card = AppTheme.lightCard;
  static const Color cardBackground = AppTheme.lightCard;
  static const Color textPrimary = AppTheme.lightTextPrimary;
  static const Color textSecondary = AppTheme.lightTextSecondary;
  static const Color textMuted = AppTheme.lightTextMuted;
  static const Color border = AppTheme.lightBorder;

  // Semantic Status Colors
  static const Color success = AppTheme.success;
  static const Color warning = AppTheme.warning;
  static const Color error = AppTheme.error;
  static const Color info = AppTheme.info;

  // --- DYNAMIC THEME-AWARE HELPERS ---
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getPrimary(BuildContext context) {
    return isDark(context) ? AppTheme.darkPrimary : AppTheme.lightPrimary;
  }

  static Color getSecondary(BuildContext context) {
    return isDark(context) ? AppTheme.darkSecondary : AppTheme.lightSecondary;
  }

  static Color getBackground(BuildContext context) {
    return isDark(context) ? AppTheme.darkBackground : AppTheme.lightBackground;
  }

  static Color getSurface(BuildContext context) {
    return isDark(context) ? AppTheme.darkSurface : AppTheme.lightSurface;
  }

  static Color getCard(BuildContext context) {
    return isDark(context) ? AppTheme.darkCard : AppTheme.lightCard;
  }

  static Color getBorder(BuildContext context) {
    return isDark(context) ? AppTheme.darkBorder : AppTheme.lightBorder;
  }

  static Color getTextPrimary(BuildContext context) {
    return isDark(context) ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return isDark(context) ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  }

  static Color getTextMuted(BuildContext context) {
    return isDark(context) ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
  }
}
