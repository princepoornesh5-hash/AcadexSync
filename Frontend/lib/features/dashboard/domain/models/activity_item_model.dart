import 'package:flutter/material.dart';

class ActivityItemModel {
  final String title;
  final String subtitle;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const ActivityItemModel({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });
}
