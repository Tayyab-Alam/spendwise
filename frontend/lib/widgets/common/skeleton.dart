import 'package:flutter/material.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';

/// Animated shimmer placeholder for loading states.
///
/// Usage:
/// ```dart
/// SkeletonBox(width: double.infinity, height: 160, borderRadius: 24)
/// ```
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.lg,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? AppColors.darkSurface : AppColors.lightBorder;
    final highlightColor =
        isDark ? AppColors.darkElevated : AppColors.lightSurface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.lerp(baseColor, highlightColor, _animation.value)!,
                Color.lerp(highlightColor, baseColor, _animation.value)!,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Row of skeleton boxes — useful for a 2-tile stats row.
class SkeletonRow extends StatelessWidget {
  final int count;
  final double height;
  final double borderRadius;
  final double gap;

  const SkeletonRow({
    super.key,
    required this.count,
    required this.height,
    this.borderRadius = AppRadius.lg,
    this.gap = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count * 2 - 1, (i) {
        if (i.isOdd) return SizedBox(width: gap);
        return Expanded(
          child: SkeletonBox(height: height, borderRadius: borderRadius),
        );
      }),
    );
  }
}
