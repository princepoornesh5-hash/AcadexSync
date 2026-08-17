import 'package:flutter/material.dart';

class DashboardStatModel {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final double? changePercent; // positive = up, negative = down, null = no change

  const DashboardStatModel({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.subtitle,
    this.changePercent,
  });
}
