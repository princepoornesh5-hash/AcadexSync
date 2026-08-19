import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AcadexAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool isOnline;
  final Color? backgroundColor;
  final Color? textColor;

  const AcadexAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 38,
    this.isOnline = false,
    this.backgroundColor,
    this.textColor,
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

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? _generateColor(name);
    final fg = textColor ?? Colors.white;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            image: imageUrl != null && imageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null || imageUrl!.isEmpty
              ? Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: fg,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        ),
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
      ],
    );
  }
}
