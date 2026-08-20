import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';
import '../design_system/acadex_spacing.dart';

class AppLoadingState extends StatelessWidget {
  final String? message;

  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AcadexColors.primaryNavy,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AcadexSpacing.md),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 13,
                color: AcadexColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AcadexColors.borderLight,
        borderRadius: borderRadius ?? AcadexRadius.smBorder,
      ),
    );
  }
}
