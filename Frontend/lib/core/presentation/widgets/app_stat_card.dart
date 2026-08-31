import 'package:flutter/material.dart';
import 'acadex_card.dart';

/// Legacy bridge widget delegating to [AcadexStatCard].
/// Maintained for test compatibility. Prefer using [AcadexStatCard] directly.
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AcadexStatCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      onTap: onTap,
    );
  }
}
