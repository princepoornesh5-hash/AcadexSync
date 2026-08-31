import 'package:flutter/material.dart';
import 'acadex_feedback.dart';

/// Legacy bridge widget delegating to [AcadexErrorState].
/// Maintained for test compatibility. Prefer using [AcadexErrorState] directly.
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    return AcadexErrorState(
      title: title,
      message: message,
      onRetry: onRetry,
    );
  }
}
