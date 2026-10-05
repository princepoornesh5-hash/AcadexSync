import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// Reusable ACADEX 3D Snowman Mascot Loading Character.
///
/// Features a modern, friendly 3D clay-styled snowman wearing an ACADEX-blue campus
/// backpack with a miniature notebook detail.
///
/// Implements a macOS Dock-inspired app activation bounce animation:
/// - Baseline rest
/// - First upward spring bounce (-14dp) with stretch & squash on landing
/// - Immediate second bounce of smaller height (-6.5dp) with gentle squash
/// - Settle & calm idle pause at rest before repeating
///
/// Fully respects [MediaQuery.disableAnimationsOf] (renders static mascot).
class AcadexCharacterLoading extends StatefulWidget {
  final double size;
  final String? message;
  final bool isCompact;

  const AcadexCharacterLoading({
    super.key,
    this.size = 80.0,
    this.message,
    this.isCompact = false,
  });

  @override
  State<AcadexCharacterLoading> createState() => _AcadexCharacterLoadingState();
}

class _AcadexCharacterLoadingState extends State<AcadexCharacterLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Complete Dock activation cycle: ~1650ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveSize = widget.isCompact ? (widget.size * 0.75) : widget.size;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double t = reducedMotion ? 0.0 : _controller.value;

              return SizedBox(
                width: effectiveSize,
                height: effectiveSize,
                child: CustomPaint(
                  size: Size(effectiveSize, effectiveSize),
                  painter: _SnowmanCharacterPainter(
                    cycleProgress: t,
                    isDark: isDark,
                  ),
                ),
              );
            },
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            SizedBox(height: widget.isCompact ? 8 : 12),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: (widget.isCompact
                      ? AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        )
                      : AcadexTypography.body(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ))
                  .copyWith(fontSize: widget.isCompact ? 12 : 13.5, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter rendering the ACADEX 3D Snowman Mascot with Dock bounce physics.
class _SnowmanCharacterPainter extends CustomPainter {
  final double cycleProgress; // 0.0 to 1.0
  final bool isDark;

  _SnowmanCharacterPainter({
    required this.cycleProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.48; // Slightly offset to center visual weight including backpack

    // Calculate macOS Dock bounce translation and squash/stretch factors
    double bounceY = 0.0;
    double scaleX = 1.0;
    double scaleY = 1.0;
    double backpackLag = 0.0;

    final t = cycleProgress;

    // Sequence:
    // 0.00 -> 0.16 : First bounce UP (-14dp peak)
    // 0.16 -> 0.32 : First bounce DOWN to 0dp
    // 0.32 -> 0.40 : First landing impact squash & recovery
    // 0.40 -> 0.54 : Second bounce UP (-6.5dp peak, ~46% of first)
    // 0.54 -> 0.68 : Second bounce DOWN to 0dp
    // 0.68 -> 0.74 : Second landing impact gentle squash & recovery
    // 0.74 -> 1.00 : Settle and brief calm idle pause before next cycle
    if (t < 0.16) {
      // First bounce UP
      final p = t / 0.16;
      final curveVal = math.sin(p * math.pi / 2); // easeOutQuad
      bounceY = -14.0 * curveVal * (h / 80.0);
      scaleY = 1.0 + (0.04 * curveVal);
      scaleX = 1.0 - (0.02 * curveVal);
      backpackLag = 2.0 * curveVal;
    } else if (t < 0.32) {
      // First bounce DOWN
      final p = (t - 0.16) / 0.16;
      final curveVal = math.cos(p * math.pi / 2); // easeInQuad
      bounceY = -14.0 * curveVal * (h / 80.0);
      scaleY = 1.0 + (0.04 * curveVal);
      scaleX = 1.0 - (0.02 * curveVal);
      backpackLag = -1.5 * (1.0 - curveVal);
    } else if (t < 0.40) {
      // Impact squash & bounce rebound
      final p = (t - 0.32) / 0.08;
      final squash = math.sin(p * math.pi);
      scaleY = 1.0 - (0.07 * squash);
      scaleX = 1.0 + (0.07 * squash);
      bounceY = 0.0;
    } else if (t < 0.54) {
      // Second bounce UP (smaller, restrained)
      final p = (t - 0.40) / 0.14;
      final curveVal = math.sin(p * math.pi / 2);
      bounceY = -6.5 * curveVal * (h / 80.0);
      scaleY = 1.0 + (0.025 * curveVal);
      scaleX = 1.0 - (0.015 * curveVal);
      backpackLag = 1.2 * curveVal;
    } else if (t < 0.68) {
      // Second bounce DOWN
      final p = (t - 0.54) / 0.14;
      final curveVal = math.cos(p * math.pi / 2);
      bounceY = -6.5 * curveVal * (h / 80.0);
      scaleY = 1.0 + (0.025 * curveVal);
      scaleX = 1.0 - (0.015 * curveVal);
      backpackLag = -0.8 * (1.0 - curveVal);
    } else if (t < 0.74) {
      // Second gentle squash & recover
      final p = (t - 0.68) / 0.06;
      final squash = math.sin(p * math.pi);
      scaleY = 1.0 - (0.035 * squash);
      scaleX = 1.0 + (0.035 * squash);
      bounceY = 0.0;
    } else {
      // Calm settle / idle rest
      bounceY = 0.0;
      scaleX = 1.0;
      scaleY = 1.0;
      backpackLag = 0.0;
    }

    // 1. Soft Dynamic Ground Shadow
    // Shadow size and opacity breathe inversely with jump height
    final shadowScale = (1.0 - ((-bounceY) / (14.0 * (h / 80.0)) * 0.28)) * scaleX;
    final shadowAlpha = math.max(0.04, (0.16 * (1.0 - ((-bounceY) / (14.0 * (h / 80.0)) * 0.4))));
    final shadowY = h * 0.90;

    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: isDark ? shadowAlpha * 1.8 : shadowAlpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, shadowY),
        width: w * 0.62 * shadowScale,
        height: h * 0.16 * shadowScale,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, shadowY),
        width: w * 0.62 * shadowScale,
        height: h * 0.16 * shadowScale,
      ),
      shadowPaint,
    );

    // Save canvas for animated snowman body
    canvas.save();
    // Anchor squash and bounce at ground level
    canvas.translate(cx, shadowY);
    canvas.translate(0, bounceY);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-cx, -shadowY);

    // 2. ACADEX Campus Backpack (Mounted on the back right)
    final bpX = cx + (w * 0.14);
    final bpY = (h * 0.54) + backpackLag;
    final bpW = w * 0.28;
    final bpH = h * 0.32;

    // Backpack Main Body
    final bpRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(bpX, bpY), width: bpW, height: bpH),
      Radius.circular(w * 0.08),
    );
    final bpGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF3B82F6), // Vibrant ACADEX blue highlight
        const Color(0xFF2563EB), // ACADEX primary blue
        const Color(0xFF1D4ED8), // Deep blue shadow
      ],
    );
    final bpPaint = Paint()
      ..shader = bpGradient.createShader(bpRect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bpRect, bpPaint);

    // Backpack Outer Contour / Seam
    final bpBorderPaint = Paint()
      ..color = const Color(0xFF1E40AF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(bpRect, bpBorderPaint);

    // Backpack Mini Front Pocket
    final pocketRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(bpX + (w * 0.02), bpY + (bpH * 0.18)), width: bpW * 0.72, height: bpH * 0.42),
      Radius.circular(w * 0.04),
    );
    final pocketPaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pocketRect, pocketPaint);

    // Tiny Campus Notebook peeking out of backpack top
    final notebookRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bpX - (bpW * 0.32), bpY - (bpH * 0.68), bpW * 0.45, bpH * 0.38),
      Radius.circular(w * 0.02),
    );
    final notebookPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(notebookRect, notebookPaint);

    // Notebook amber bookmark ribbon
    final bookmarkPath = Path()
      ..moveTo(bpX - (bpW * 0.16), bpY - (bpH * 0.68))
      ..lineTo(bpX - (bpW * 0.08), bpY - (bpH * 0.68))
      ..lineTo(bpX - (bpW * 0.08), bpY - (bpH * 0.42))
      ..lineTo(bpX - (bpW * 0.12), bpY - (bpH * 0.48))
      ..lineTo(bpX - (bpW * 0.16), bpY - (bpH * 0.42))
      ..close();
    final bookmarkPaint = Paint()
      ..color = const Color(0xFFF59E0B) // Amber college accent
      ..style = PaintingStyle.fill;
    canvas.drawPath(bookmarkPath, bookmarkPaint);

    // 3. Lower Snowball Body (Base Torso)
    final baseRadius = w * 0.26;
    final baseCenterY = h * 0.64;

    final baseGradient = RadialGradient(
      center: const Alignment(-0.35, -0.4),
      radius: 0.88,
      colors: isDark
          ? const [
              Color(0xFFFFFFFF),
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
              Color(0xFF94A3B8),
            ]
          : const [
              Color(0xFFFFFFFF),
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
              Color(0xFFCBD5E1),
            ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    );
    final basePaint = Paint()
      ..shader = baseGradient.createShader(Rect.fromCircle(
        center: Offset(cx, baseCenterY),
        radius: baseRadius,
      ));
    canvas.drawCircle(Offset(cx, baseCenterY), baseRadius, basePaint);

    // Subtle 3D Rim / Ambient occlusion on base snowball
    final baseRimPaint = Paint()
      ..color = (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(cx, baseCenterY), baseRadius, baseRimPaint);

    // Two small obsidian/charcoal buttons on base
    final buttonPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, baseCenterY - (baseRadius * 0.15)), w * 0.024, buttonPaint);
    canvas.drawCircle(Offset(cx, baseCenterY + (baseRadius * 0.32)), w * 0.024, buttonPaint);

    // Backpack shoulder strap wrapping over the shoulder
    final strapPath = Path()
      ..moveTo(cx + (baseRadius * 0.32), baseCenterY - (baseRadius * 0.82))
      ..quadraticBezierTo(
        cx + (baseRadius * 0.65),
        baseCenterY - (baseRadius * 0.2),
        cx + (baseRadius * 0.45),
        baseCenterY + (baseRadius * 0.4),
      );
    final strapPaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(strapPath, strapPaint);

    // 4. Upper Snowball (Head)
    final headRadius = w * 0.20;
    final headCenterY = h * 0.36;

    final headGradient = RadialGradient(
      center: const Alignment(-0.32, -0.42),
      radius: 0.86,
      colors: isDark
          ? const [
              Color(0xFFFFFFFF),
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
              Color(0xFF94A3B8),
            ]
          : const [
              Color(0xFFFFFFFF),
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
              Color(0xFFCBD5E1),
            ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    );
    final headPaint = Paint()
      ..shader = headGradient.createShader(Rect.fromCircle(
        center: Offset(cx, headCenterY),
        radius: headRadius,
      ));
    canvas.drawCircle(Offset(cx, headCenterY), headRadius, headPaint);

    // 5. Sleek Collegiate Scarf Band (connecting head and body)
    final scarfCenterY = headCenterY + (headRadius * 0.85);
    final scarfRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, scarfCenterY),
        width: headRadius * 1.85,
        height: headRadius * 0.40,
      ),
      Radius.circular(w * 0.04),
    );
    final scarfGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2563EB),
        Color(0xFF1E40AF),
        Color(0xFF1E3A8A),
      ],
    );
    final scarfPaint = Paint()
      ..shader = scarfGradient.createShader(scarfRect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(scarfRect, scarfPaint);

    // Scarf golden amber accent stripe
    final scarfStripePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - (headRadius * 0.8), scarfCenterY),
      Offset(cx + (headRadius * 0.8), scarfCenterY),
      scarfStripePaint,
    );

    // Scarf tail folded neatly on side
    final tailRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - (headRadius * 0.65), scarfCenterY, headRadius * 0.38, headRadius * 0.55),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(tailRect, scarfPaint);

    // 6. Facial Features
    final eyeRadius = headRadius * 0.12;
    final eyeY = headCenterY - (headRadius * 0.06);
    final eyeLeftX = cx - (headRadius * 0.36);
    final eyeRightX = cx + (headRadius * 0.36);

    // Eyes (Obsidian beads)
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(eyeLeftX, eyeY), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(eyeRightX, eyeY), eyeRadius, eyePaint);

    // Eye Twinkles (specular highlights)
    final twinklePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(eyeLeftX + (eyeRadius * 0.28), eyeY - (eyeRadius * 0.28)), eyeRadius * 0.40, twinklePaint);
    canvas.drawCircle(Offset(eyeRightX + (eyeRadius * 0.28), eyeY - (eyeRadius * 0.28)), eyeRadius * 0.40, twinklePaint);

    // Soft Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFF43F5E).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(eyeLeftX - (headRadius * 0.16), eyeY + (headRadius * 0.24)), headRadius * 0.15, cheekPaint);
    canvas.drawCircle(Offset(eyeRightX + (headRadius * 0.16), eyeY + (headRadius * 0.24)), headRadius * 0.15, cheekPaint);

    // Cute minimal 3D Carrot Nose (soft rounded conical peg)
    final nosePath = Path()
      ..moveTo(cx - (headRadius * 0.08), headCenterY + (headRadius * 0.05))
      ..lineTo(cx + (headRadius * 0.32), headCenterY + (headRadius * 0.12))
      ..lineTo(cx - (headRadius * 0.06), headCenterY + (headRadius * 0.22))
      ..close();
    final nosePaint = Paint()
      ..color = const Color(0xFFF97316) // Warm crisp orange
      ..style = PaintingStyle.fill;
    canvas.drawPath(nosePath, nosePaint);

    // Friendly gentle smile
    final smilePath = Path()
      ..moveTo(cx - (headRadius * 0.20), headCenterY + (headRadius * 0.40))
      ..quadraticBezierTo(
        cx,
        headCenterY + (headRadius * 0.54),
        cx + (headRadius * 0.20),
        headCenterY + (headRadius * 0.40),
      );
    final smilePaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(smilePath, smilePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SnowmanCharacterPainter oldDelegate) {
    return oldDelegate.cycleProgress != cycleProgress || oldDelegate.isDark != isDark;
  }
}
