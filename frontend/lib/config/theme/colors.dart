import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================================
  // PRIMARY (Indigo/Purple)
  // ============================================================
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF5B52E8);
  static const Color primaryDark = Color(0xFF4A42B8);

  // ============================================================
  // SEMANTIC
  // ============================================================
  static const Color income = Color(0xFF22C55E);   // restrained green
  static const Color expense = Color(0xFFF04444);  // restrained red
  static const Color warning = Color(0xFFF59E0B);  // amber
  static const Color lightIncome = Color(0xFF16A34A);
  static const Color lightExpense = Color(0xFFDC2626);
  static const Color lightWarning = Color(0xFFD97706);

  // ============================================================
  // DARK THEME
  // ============================================================
  static const Color darkBg = Color(0xFF0B0D10);
  static const Color darkSurface = Color(0xFF14171C);
  static const Color darkElevated = Color(0xFF1B1F26);
  static const Color darkBorder = Color(0xFF292E36);
  static const Color darkText = Color(0xFFF5F7FA);
  static const Color darkTextSecondary = Color(0xFF9AA1AC);

  // ============================================================
  // LIGHT THEME
  // ============================================================
  static const Color lightBg = Color(0xFFFAF8F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF5F2EC);
  static const Color lightBorder = Color(0xFFE8E3D8);
  static const Color lightText = Color(0xFF1F1D1A);
  static const Color lightTextSecondary = Color(0xFF6B6860);

  // ============================================================
  // GRADIENTS (subtle only)
  // ============================================================
  static const LinearGradient balanceCardGradientDark = LinearGradient(
    colors: [Color(0xFF1B1F26), Color(0xFF14171C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient balanceCardGradientLight = LinearGradient(
    colors: [Color(0xFFF5F2EC), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}