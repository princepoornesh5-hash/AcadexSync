import 'package:flutter/material.dart';

/// Authoritative ACADEXSYNC logo widget rendering the official branding asset.
class AcadexLogo extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;
  final bool hasShadow;

  const AcadexLogo({
    super.key,
    this.size = 44,
    this.borderRadius,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF1B5AFB).withValues(alpha: 0.3),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/branding/acadexsync_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
