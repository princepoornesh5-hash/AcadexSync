import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// Compact, temporary speech bubble appearing above the ACADEX Assistant
/// during the greeting sequence of the minute change.
class AcadexSpeechBubble extends StatelessWidget {
  final String text;
  final double opacity;
  final double scale;
  final bool isDark;

  const AcadexSpeechBubble({
    super.key,
    required this.text,
    this.opacity = 1.0,
    this.scale = 1.0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.01 || text.isEmpty) {
      return const SizedBox.shrink();
    }

    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final fg = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale.clamp(0.5, 1.2),
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bubble Body
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                text,
                style: AcadexTypography.caption(color: fg).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Bubble Tail Pointer
            CustomPaint(
              size: const Size(10, 5),
              painter: _SpeechBubbleTailPainter(
                color: bg,
                borderColor: border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechBubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _SpeechBubbleTailPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.5, h)
      ..lineTo(w, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.5, h)
      ..lineTo(w, 0);

    canvas.drawPath(
      borderPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeechBubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}
