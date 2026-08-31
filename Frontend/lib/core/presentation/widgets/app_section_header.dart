import 'package:flutter/material.dart';
import 'acadex_page_header.dart';

/// Legacy bridge widget delegating to [AcadexSectionHeader].
/// Maintained for test compatibility. Prefer using [AcadexSectionHeader] directly.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AcadexSectionHeader(
      title: title,
      subtitle: subtitle,
      count: count,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
