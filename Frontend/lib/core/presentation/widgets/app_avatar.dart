import 'package:flutter/material.dart';
import '../design_system/acadex_colors.dart';

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

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AcadexColors.primaryNavy,
        border: Border.all(color: AcadexColors.borderLight, width: 1.5),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(initials),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  );
                },
              )
            : _buildFallback(initials),
      ),
    );

    if (onEdit != null) {
      return Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AcadexColors.emeraldTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  Widget _buildFallback(String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
