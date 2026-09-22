import 'package:flutter/material.dart';

import '../config/theme/colors.dart';
import '../config/theme/spacing.dart';
import '../config/theme/typography.dart';

class AppSnackbar {
  AppSnackbar._();

  /// Show a success snackbar with green accent.
  static void success(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.income,
      icon: Icons.check_circle_outline,
    );
  }

  /// Show an error snackbar with red accent.
  static void error(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.expense,
      icon: Icons.error_outline,
    );
  }

  /// Show an informational snackbar with primary accent.
  static void info(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.primary,
      icon: Icons.info_outline,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        elevation: 4,
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
