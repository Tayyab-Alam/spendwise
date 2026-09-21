import 'package:flutter/material.dart';

import '../../config/theme/typography.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('SpendWise', style: AppTypography.h1.copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Know where your money goes.',
              style: AppTypography.body.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}