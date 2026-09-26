import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  // ============================================================
  // DARK THEME
  // ============================================================
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        error: AppColors.expense,
        outline: AppColors.darkBorder,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.darkText),
        iconTheme: const IconThemeData(color: AppColors.darkText),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.0),
        ),
        hintStyle:
            AppTypography.body.copyWith(color: AppColors.darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 0.5,
        space: 0.5,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(color: AppColors.darkText),
        displayMedium: AppTypography.h2.copyWith(color: AppColors.darkText),
        titleLarge: AppTypography.h3.copyWith(color: AppColors.darkText),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkText),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.darkText),
        bodySmall: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
      ),
      extensions: const [
        SpendWiseColors(
          income: AppColors.income,
          expense: AppColors.expense,
          warning: AppColors.warning,
          elevatedSurface: AppColors.darkElevated,
          textSecondary: AppColors.darkTextSecondary,
        ),
      ],
    );
  }

  // ============================================================
  // LIGHT THEME — WARM CREAMY
  // ============================================================
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        error: AppColors.lightExpense,
        outline: AppColors.lightBorder,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.lightText),
        iconTheme: const IconThemeData(color: AppColors.lightText),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.5),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.04),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightExpense, width: 1.0),
        ),
        hintStyle:
            AppTypography.body.copyWith(color: AppColors.lightTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 0.5,
        space: 0.5,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(color: AppColors.lightText),
        displayMedium: AppTypography.h2.copyWith(color: AppColors.lightText),
        titleLarge: AppTypography.h3.copyWith(color: AppColors.lightText),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.lightText),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.lightText),
        bodySmall:
            AppTypography.caption.copyWith(color: AppColors.lightTextSecondary),
      ),
      extensions: const [
        SpendWiseColors(
          income: AppColors.lightIncome,
          expense: AppColors.lightExpense,
          warning: AppColors.lightWarning,
          elevatedSurface: AppColors.lightElevated,
          textSecondary: AppColors.lightTextSecondary,
        ),
      ],
    );
  }
}

// ============================================================
// THEME EXTENSION — Semantic colors
// ============================================================
class SpendWiseColors extends ThemeExtension<SpendWiseColors> {
  final Color income;
  final Color expense;
  final Color warning;
  final Color elevatedSurface;
  final Color textSecondary;

  const SpendWiseColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.elevatedSurface,
    required this.textSecondary,
  });

  @override
  SpendWiseColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? elevatedSurface,
    Color? textSecondary,
  }) {
    return SpendWiseColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  SpendWiseColors lerp(ThemeExtension<SpendWiseColors>? other, double t) {
    if (other is! SpendWiseColors) return this;
    return SpendWiseColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}