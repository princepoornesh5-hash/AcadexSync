import 'package:flutter/material.dart';
import 'acadex_avatar.dart';

/// Legacy bridge widget delegating to [AcadexAvatar].
/// Maintained for test compatibility. Prefer using [AcadexAvatar] directly.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final VoidCallback? onEdit;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40.0,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AcadexAvatar(
      name: name,
      imageUrl: imageUrl,
      size: size,
      onEdit: onEdit,
    );
  }
}
