import 'package:flutter/material.dart';

class QuickActionModel {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String route; // target route or module name for ComingSoon

  const QuickActionModel({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.route,
  });
}
