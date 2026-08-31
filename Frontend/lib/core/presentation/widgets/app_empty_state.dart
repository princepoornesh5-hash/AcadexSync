import 'package:flutter/material.dart';
import 'acadex_feedback.dart';

/// Legacy bridge widget delegating to [AcadexEmptyState].
/// Maintained for test compatibility. Prefer using [AcadexEmptyState] directly.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AcadexEmptyState(
      title: title,
      description: description,
      icon: icon,
      actionLabel: actionLabel,
      onActionTap: onAction,
    );
  }
}
