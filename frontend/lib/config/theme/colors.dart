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
  // SEMANTIC — DARK THEME
  // ============================================================
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFF04444);
  static const Color warning = Color(0xFFF59E0B);

  // ============================================================
  // SEMANTIC — LIGHT THEME (deeper for better contrast)
  // ============================================================
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
  // LIGHT THEME — WARM CREAMY
  // ============================================================
  static const Color lightBg = Color(0xFFFAF8F3);          // warm cream
  static const Color lightSurface = Color(0xFFFFFFFF);     // pure white for cards
  static const Color lightElevated = Color(0xFFF5F2EC);    // soft cream
  static const Color lightBorder = Color(0xFFE8E3D8);      // warm beige border
  static const Color lightText = Color(0xFF1F1D1A);        // warm near-black
  static const Color lightTextSecondary = Color(0xFF6B6860); // warm gray

  // ============================================================
  // GRADIENTS (subtle only)
  // ============================================================
  static const LinearGradient balanceCardGradientDark = LinearGradient(
    colors: [Color(0xFF1B1F26), Color(0xFF14171C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient balanceCardGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F2EC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}