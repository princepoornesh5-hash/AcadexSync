import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';

class AttendanceProgressIndicator extends StatelessWidget {
  final double percentage;
  final double height;
  final bool animate;

  const AttendanceProgressIndicator({
    super.key,
    required this.percentage,
    this.height = 8.0,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 75 
        ? DashboardColors.success 
        : percentage >= 60 
            ? DashboardColors.warning 
            : DashboardColors.error;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth * (percentage / 100).clamp(0.0, 1.0);
          
          if (!animate) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: targetWidth,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            );
          }

          return Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: targetWidth),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, width, child) {
                return Container(
                  width: width,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
