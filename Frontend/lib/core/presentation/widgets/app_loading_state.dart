import 'package:flutter/material.dart';
import 'acadex_feedback.dart';

/// Legacy bridge widget delegating to [AcadexLoadingState].
/// Maintained for test compatibility. Prefer using [AcadexLoadingState] directly.
class AppLoadingState extends StatelessWidget {
  final String? message;

  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AcadexLoadingState(message: message ?? 'Loading...');
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
    return AcadexSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
