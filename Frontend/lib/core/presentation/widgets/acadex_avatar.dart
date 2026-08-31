import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AcadexAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool isOnline;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onEdit;

  const AcadexAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 38,
    this.isOnline = false,
    this.backgroundColor,
    this.textColor,
    this.onEdit,
  });

  String get _initials {
    final clean = name.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _generateColor(String text) {
    final colors = [
      AcadexColors.primary,
      AcadexColors.accentPurple,
      AcadexColors.accentTeal,
      AcadexColors.accentOrange,
      AcadexColors.info,
      const Color(0xFFD946EF),
      const Color(0xFF06B6D4),
    ];
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  Widget _buildInitialsFallback(Color bg, Color fg) {
    return Container(
      width: size,
      height: size,
      color: bg,
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: fg,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? _generateColor(name);
    final fg = textColor ?? Colors.white;

    final avatarWidget = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitialsFallback(bg, fg),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: size,
                    height: size,
                    color: bg.withValues(alpha: 0.2),
                    child: Center(
                      child: SizedBox(
                        width: size * 0.4,
                        height: size * 0.4,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
              )
            : _buildInitialsFallback(bg, fg),
      ),
    );

    return Stack(
      children: [
        avatarWidget,
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AcadexColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        if (onEdit != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AcadexColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
