import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Geometry and rendered bounding box of the minute display card.
/// Source of truth for wiping and handwriting animation targets.
class MinuteDisplayBounds {
  final double left;
  final double top;
  final double width;
  final double height;

  const MinuteDisplayBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  Rect get rect => Rect.fromLTWH(left, top, width, height);
  Offset get center => Offset(left + (width * 0.5), top + (height * 0.5));

  /// Dedicated bounding box for the first digit (tens place: 0..5)
  Rect get firstDigitRect => Rect.fromLTWH(
        left + (width * 0.08),
        top + (height * 0.12),
        width * 0.40,
        height * 0.76,
      );

  /// Dedicated bounding box for the second digit (ones place: 0..9)
  Rect get secondDigitRect => Rect.fromLTWH(
        left + (width * 0.52),
        top + (height * 0.12),
        width * 0.40,
        height * 0.76,
      );

  static const MinuteDisplayBounds zero = MinuteDisplayBounds(
    left: 0.0,
    top: 0.0,
    width: 0.0,
    height: 0.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinuteDisplayBounds &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() =>
      'MinuteDisplayBounds(left: $left, top: $top, width: $width, height: $height)';
}

/// Extracted stroke segment and active stylus nib position for handwriting.
class DigitStrokeExtraction {
  final Path revealedPath;
  final Offset stylusTip;
  final bool isComplete;

  const DigitStrokeExtraction({
    required this.revealedPath,
    required this.stylusTip,
    required this.isComplete,
  });
}

/// High-fidelity handwriting vector paths for tabular figures 0 through 9.
/// Provides continuous stroke extraction and exact stylus nib tracking.
class AcadexDigitPath {
  /// Builds the canonical handwriting vector path for a given digit within [rect].
  static Path getDigitPath(String digitChar, Rect rect) {
    final p = Path();
    final l = rect.left;
    final t = rect.top;
    final w = rect.width;
    final h = rect.height;

    switch (digitChar) {
      case '0':
        // Counter-clockwise continuous oval starting from top center
        p.moveTo(l + (w * 0.50), t + (h * 0.12));
        p.cubicTo(
          l + (w * 0.20), t + (h * 0.12),
          l + (w * 0.14), t + (h * 0.35),
          l + (w * 0.14), t + (h * 0.50),
        );
        p.cubicTo(
          l + (w * 0.14), t + (h * 0.70),
          l + (w * 0.20), t + (h * 0.90),
          l + (w * 0.50), t + (h * 0.90),
        );
        p.cubicTo(
          l + (w * 0.80), t + (h * 0.90),
          l + (w * 0.86), t + (h * 0.70),
          l + (w * 0.86), t + (h * 0.50),
        );
        p.cubicTo(
          l + (w * 0.86), t + (h * 0.35),
          l + (w * 0.80), t + (h * 0.12),
          l + (w * 0.50), t + (h * 0.12),
        );
        break;

      case '1':
        // Modern clean 1: subtle apex entry then vertical downward stem
        p.moveTo(l + (w * 0.28), t + (h * 0.26));
        p.lineTo(l + (w * 0.52), t + (h * 0.12));
        p.lineTo(l + (w * 0.52), t + (h * 0.90));
        break;

      case '2':
        // Top arch, diagonal down-left stroke, horizontal baseline
        p.moveTo(l + (w * 0.20), t + (h * 0.30));
        p.cubicTo(
          l + (w * 0.22), t + (h * 0.12),
          l + (w * 0.80), t + (h * 0.12),
          l + (w * 0.82), t + (h * 0.30),
        );
        p.cubicTo(
          l + (w * 0.82), t + (h * 0.46),
          l + (w * 0.65), t + (h * 0.62),
          l + (w * 0.18), t + (h * 0.88),
        );
        p.lineTo(l + (w * 0.84), t + (h * 0.88));
        break;

      case '3':
        // Top curve, middle junction, bottom circular loop
        p.moveTo(l + (w * 0.22), t + (h * 0.16));
        p.cubicTo(
          l + (w * 0.42), t + (h * 0.10),
          l + (w * 0.78), t + (h * 0.12),
          l + (w * 0.78), t + (h * 0.34),
        );
        p.cubicTo(
          l + (w * 0.78), t + (h * 0.48),
          l + (w * 0.60), t + (h * 0.50),
          l + (w * 0.46), t + (h * 0.50),
        );
        p.cubicTo(
          l + (w * 0.72), t + (h * 0.50),
          l + (w * 0.82), t + (h * 0.60),
          l + (w * 0.82), t + (h * 0.74),
        );
        p.cubicTo(
          l + (w * 0.82), t + (h * 0.90),
          l + (w * 0.44), t + (h * 0.92),
          l + (w * 0.20), t + (h * 0.84),
        );
        break;

      case '4':
        // Two natural handwriting strokes:
        // Stroke 1: Slanted stem down-left and crossbar across
        p.moveTo(l + (w * 0.72), t + (h * 0.12));
        p.lineTo(l + (w * 0.16), t + (h * 0.64));
        p.lineTo(l + (w * 0.86), t + (h * 0.64));
        // Stroke 2: Vertical downward cross stroke
        p.moveTo(l + (w * 0.70), t + (h * 0.32));
        p.lineTo(l + (w * 0.70), t + (h * 0.90));
        break;

      case '5':
        // Top bar right-to-left, downward stem, full rounded bottom arc
        p.moveTo(l + (w * 0.80), t + (h * 0.12));
        p.lineTo(l + (w * 0.26), t + (h * 0.12));
        p.lineTo(l + (w * 0.24), t + (h * 0.44));
        p.cubicTo(
          l + (w * 0.38), t + (h * 0.40),
          l + (w * 0.82), t + (h * 0.46),
          l + (w * 0.82), t + (h * 0.70),
        );
        p.cubicTo(
          l + (w * 0.82), t + (h * 0.90),
          l + (w * 0.44), t + (h * 0.92),
          l + (w * 0.20), t + (h * 0.84),
        );
        break;

      case '6':
        // Top entry arch down to bottom circular loop
        p.moveTo(l + (w * 0.74), t + (h * 0.14));
        p.cubicTo(
          l + (w * 0.46), t + (h * 0.12),
          l + (w * 0.16), t + (h * 0.36),
          l + (w * 0.16), t + (h * 0.62),
        );
        p.cubicTo(
          l + (w * 0.16), t + (h * 0.88),
          l + (w * 0.42), t + (h * 0.92),
          l + (w * 0.58), t + (h * 0.92),
        );
        p.cubicTo(
          l + (w * 0.80), t + (h * 0.92),
          l + (w * 0.86), t + (h * 0.78),
          l + (w * 0.86), t + (h * 0.64),
        );
        p.cubicTo(
          l + (w * 0.86), t + (h * 0.48),
          l + (w * 0.66), t + (h * 0.44),
          l + (w * 0.46), t + (h * 0.44),
        );
        p.cubicTo(
          l + (w * 0.28), t + (h * 0.44),
          l + (w * 0.18), t + (h * 0.54),
          l + (w * 0.16), t + (h * 0.62),
        );
        break;

      case '7':
        // Top horizontal bar, slanted straight down to baseline
        p.moveTo(l + (w * 0.18), t + (h * 0.12));
        p.lineTo(l + (w * 0.84), t + (h * 0.12));
        p.lineTo(l + (w * 0.38), t + (h * 0.90));
        break;

      case '8':
        // Smooth continuous figure-eight starting at center junction
        p.moveTo(l + (w * 0.50), t + (h * 0.48));
        p.cubicTo(
          l + (w * 0.30), t + (h * 0.48),
          l + (w * 0.18), t + (h * 0.35),
          l + (w * 0.18), t + (h * 0.26),
        );
        p.cubicTo(
          l + (w * 0.18), t + (h * 0.12),
          l + (w * 0.34), t + (h * 0.10),
          l + (w * 0.50), t + (h * 0.10),
        );
        p.cubicTo(
          l + (w * 0.66), t + (h * 0.10),
          l + (w * 0.82), t + (h * 0.12),
          l + (w * 0.82), t + (h * 0.26),
        );
        p.cubicTo(
          l + (w * 0.82), t + (h * 0.36),
          l + (w * 0.70), t + (h * 0.48),
          l + (w * 0.50), t + (h * 0.48),
        );
        p.cubicTo(
          l + (w * 0.30), t + (h * 0.48),
          l + (w * 0.14), t + (h * 0.60),
          l + (w * 0.14), t + (h * 0.74),
        );
        p.cubicTo(
          l + (w * 0.14), t + (h * 0.90),
          l + (w * 0.34), t + (h * 0.92),
          l + (w * 0.50), t + (h * 0.92),
        );
        p.cubicTo(
          l + (w * 0.66), t + (h * 0.92),
          l + (w * 0.86), t + (h * 0.90),
          l + (w * 0.86), t + (h * 0.74),
        );
        p.cubicTo(
          l + (w * 0.86), t + (h * 0.60),
          l + (w * 0.70), t + (h * 0.48),
          l + (w * 0.50), t + (h * 0.48),
        );
        break;

      case '9':
        // Upper circular loop then curving descent
        p.moveTo(l + (w * 0.82), t + (h * 0.48));
        p.cubicTo(
          l + (w * 0.68), t + (h * 0.54),
          l + (w * 0.46), t + (h * 0.54),
          l + (w * 0.30), t + (h * 0.44),
        );
        p.cubicTo(
          l + (w * 0.14), t + (h * 0.34),
          l + (w * 0.18), t + (h * 0.16),
          l + (w * 0.40), t + (h * 0.10),
        );
        p.cubicTo(
          l + (w * 0.62), t + (h * 0.08),
          l + (w * 0.84), t + (h * 0.18),
          l + (w * 0.84), t + (h * 0.42),
        );
        p.lineTo(l + (w * 0.84), t + (h * 0.62));
        p.cubicTo(
          l + (w * 0.84), t + (h * 0.84),
          l + (w * 0.60), t + (h * 0.92),
          l + (w * 0.32), t + (h * 0.90),
        );
        break;

      default:
        // Default vertical stroke fallback
        p.moveTo(l + (w * 0.5), t + (h * 0.12));
        p.lineTo(l + (w * 0.5), t + (h * 0.90));
        break;
    }

    return p;
  }

  /// Extracts the visible stroke path up to [progress] (0.0 to 1.0) and returns
  /// the exact coordinates of the stylus tip leading the stroke.
  static DigitStrokeExtraction extractProgress(
    String digitChar,
    double progress,
    Rect rect,
  ) {
    final fullPath = getDigitPath(digitChar, rect);
    final metrics = fullPath.computeMetrics().toList();

    if (metrics.isEmpty) {
      return DigitStrokeExtraction(
        revealedPath: Path(),
        stylusTip: rect.center,
        isComplete: false,
      );
    }

    if (progress <= 0.0) {
      final startTip = metrics.first.getTangentForOffset(0.0)?.position ?? rect.center;
      return DigitStrokeExtraction(
        revealedPath: Path(),
        stylusTip: startTip,
        isComplete: false,
      );
    }

    if (progress >= 1.0) {
      final endTip =
          metrics.last.getTangentForOffset(metrics.last.length)?.position ?? rect.center;
      return DigitStrokeExtraction(
        revealedPath: fullPath,
        stylusTip: endTip,
        isComplete: true,
      );
    }

    double totalLength = 0.0;
    for (final m in metrics) {
      totalLength += m.length;
    }

    final targetLength = progress.clamp(0.0, 1.0) * totalLength;
    final revealed = Path();
    double accumulated = 0.0;
    Offset currentTip = rect.center;

    for (final m in metrics) {
      if (accumulated + m.length <= targetLength) {
        revealed.addPath(m.extractPath(0.0, m.length), Offset.zero);
        accumulated += m.length;
        currentTip = m.getTangentForOffset(m.length)?.position ?? currentTip;
      } else {
        final remain = targetLength - accumulated;
        revealed.addPath(m.extractPath(0.0, remain), Offset.zero);
        currentTip = m.getTangentForOffset(remain)?.position ?? currentTip;
        break;
      }
    }

    return DigitStrokeExtraction(
      revealedPath: revealed,
      stylusTip: currentTip,
      isComplete: false,
    );
  }
}

/// Helper calculating the exact wipe and writing targets within the minute card.
class MinuteWritingGeometry {
  /// Returns the exact local coordinate of the Assistant's stylus/hand
  /// for handwriting progress [writeProgress] (0.0 to 1.0).
  static Offset getStylusTip({
    required double writeProgress,
    required MinuteDisplayBounds bounds,
    required String minutes,
  }) {
    final safeMinutes = minutes.padLeft(2, '0');
    final char1 = safeMinutes[0];
    final char2 = safeMinutes[1];

    if (writeProgress <= 0.0) {
      // Resting on the starting stroke of digit 1
      return AcadexDigitPath.extractProgress(char1, 0.0, bounds.firstDigitRect).stylusTip;
    } else if (writeProgress < 0.48) {
      // Writing digit 1
      final p1 = (writeProgress / 0.48).clamp(0.0, 1.0);
      return AcadexDigitPath.extractProgress(char1, p1, bounds.firstDigitRect).stylusTip;
    } else if (writeProgress < 0.52) {
      // Pen-lift transition: smoothly interpolating from end of digit 1 to start of digit 2
      final tip1 = AcadexDigitPath.extractProgress(char1, 1.0, bounds.firstDigitRect).stylusTip;
      final tip2 = AcadexDigitPath.extractProgress(char2, 0.0, bounds.secondDigitRect).stylusTip;
      final t = ((writeProgress - 0.48) / 0.04).clamp(0.0, 1.0);
      final curve = Curves.easeInOut.transform(t);
      // Slight arc upward during pen travel
      final lift = math.sin(t * math.pi) * (bounds.height * 0.12);
      return Offset.lerp(tip1, tip2, curve)!.translate(0, -lift);
    } else {
      // Writing digit 2
      final p2 = ((writeProgress - 0.52) / 0.48).clamp(0.0, 1.0);
      return AcadexDigitPath.extractProgress(char2, p2, bounds.secondDigitRect).stylusTip;
    }
  }

  /// Returns the exact local coordinate of the Assistant's wiper across the minute display.
  static Offset getWipeTip({
    required double wipeProgress,
    required MinuteDisplayBounds bounds,
  }) {
    final t = wipeProgress.clamp(0.0, 1.0);
    return Offset(
      bounds.left + (bounds.width * t),
      bounds.top + (bounds.height * 0.50),
    );
  }
}

/// CustomPainter rendering the mechanical split-flap minute display card:
/// 1. Calm static state: clean Inter tabular figures
/// 2. Wipe state: progressive erasure of old digits leaving 100% invisible surface
/// 3. Blank state: completely empty card with physical seam
/// 4. Handwriting state: progressive pixel-by-pixel ink stroke construction
class MinuteWritingPainter extends CustomPainter {
  final String currentMinutes;
  final String? oldMinutes;
  final bool isWiping;
  final bool isWriting;
  final double wipeProgress;
  final double writeProgress;
  final double fontSize;
  final bool isCompact;

  const MinuteWritingPainter({
    required this.currentMinutes,
    this.oldMinutes,
    this.isWiping = false,
    this.isWriting = false,
    this.wipeProgress = 0.0,
    this.writeProgress = 1.0,
    this.fontSize = 18.0,
    this.isCompact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = MinuteDisplayBounds(
      left: 0.0,
      top: 0.0,
      width: size.width,
      height: size.height,
    );

    // -------------------------------------------------------------------------
    // 1. WIPING PHASE: Old minute digits erased progressively
    // -------------------------------------------------------------------------
    if (isWiping && oldMinutes != null) {
      final t = wipeProgress.clamp(0.0, 1.0);

      // Once wipe reaches 1.0, the old minute is 100% invisible
      if (t >= 0.999) {
        return; // Blank state
      }

      final wipeX = size.width * t;

      // Clip to show only the portion of the old digits not yet wiped
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(wipeX, 0, size.width, size.height));
      _paintMinuteText(canvas, size, oldMinutes!);
      canvas.restore();

      // Soft luminous wiper boundary line
      if (t > 0.02 && t < 0.98) {
        final glowPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(wipeX, 0),
            Offset(wipeX, size.height),
            [
              const Color(0xFF60A5FA).withOpacity(0.0),
              const Color(0xFF60A5FA).withOpacity(0.70),
              const Color(0xFF93C5FD).withOpacity(0.95),
              const Color(0xFF60A5FA).withOpacity(0.70),
              const Color(0xFF60A5FA).withOpacity(0.0),
            ],
            [0.0, 0.25, 0.50, 0.75, 1.0],
          )
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(wipeX, 2), Offset(wipeX, size.height - 2), glowPaint);
      }
      return;
    }

    // -------------------------------------------------------------------------
    // 2. CLEAR BLANK STATE: Visually empty minute region before writing starts
    // -------------------------------------------------------------------------
    if (isWriting && writeProgress <= 0.0) {
      return; // Absolutely empty minute region
    }

    // -------------------------------------------------------------------------
    // 3. PROGRESSIVE PIXEL-BY-PIXEL HANDWRITING
    // -------------------------------------------------------------------------
    if (isWriting) {
      final safeMinutes = currentMinutes.padLeft(2, '0');
      final char1 = safeMinutes[0];
      final char2 = safeMinutes[1];

      final inkPaint = Paint()
        ..color = const Color(0xFFF8FAFC)
        ..strokeWidth = isCompact ? 2.2 : 2.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final glowPaint = Paint()
        ..color = const Color(0xFF3B82F6).withOpacity(0.42)
        ..strokeWidth = isCompact ? 3.8 : 4.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8)
        ..style = PaintingStyle.stroke;

      // When write reaches 1.0, show complete vector strokes cleanly with magic glow
      if (writeProgress >= 1.0) {
        final ext1 = AcadexDigitPath.extractProgress(char1, 1.0, bounds.firstDigitRect);
        final ext2 = AcadexDigitPath.extractProgress(char2, 1.0, bounds.secondDigitRect);
        canvas.drawPath(ext1.revealedPath, glowPaint);
        canvas.drawPath(ext1.revealedPath, inkPaint);
        canvas.drawPath(ext2.revealedPath, glowPaint);
        canvas.drawPath(ext2.revealedPath, inkPaint);
        return;
      }

      // Sequential digit timing:
      // Digit 1: writeProgress 0.00 -> 0.48
      // Pen transition: writeProgress 0.48 -> 0.52
      // Digit 2: writeProgress 0.52 -> 1.00
      final p1 = (writeProgress / 0.48).clamp(0.0, 1.0);
      final p2 = writeProgress < 0.52
          ? 0.0
          : ((writeProgress - 0.52) / 0.48).clamp(0.0, 1.0);

      // Draw Digit 1
      if (p1 > 0.0) {
        final ext1 = AcadexDigitPath.extractProgress(char1, p1, bounds.firstDigitRect);
        canvas.drawPath(ext1.revealedPath, glowPaint);
        canvas.drawPath(ext1.revealedPath, inkPaint);

        if (p1 < 1.0) {
          _paintNibSparkle(canvas, ext1.stylusTip);
        }
      }

      // Draw Digit 2 (Only appears after Digit 1 is complete!)
      if (p2 > 0.0) {
        final ext2 = AcadexDigitPath.extractProgress(char2, p2, bounds.secondDigitRect);
        canvas.drawPath(ext2.revealedPath, glowPaint);
        canvas.drawPath(ext2.revealedPath, inkPaint);

        if (p2 < 1.0) {
          _paintNibSparkle(canvas, ext2.stylusTip);
        }
      }

      return;
    }

    // -------------------------------------------------------------------------
    // 4. CALM STATIC STATE: Standard mechanical split-flap text
    // -------------------------------------------------------------------------
    _paintMinuteText(canvas, size, currentMinutes);
  }

  void _paintNibSparkle(Canvas canvas, Offset tip) {
    // Soft cyan halo around active handwriting nib
    canvas.drawCircle(
      tip,
      3.0,
      Paint()
        ..color = const Color(0xFF60A5FA).withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    // Brilliant white point
    canvas.drawCircle(
      tip,
      1.2,
      Paint()..color = Colors.white,
    );
  }

  void _paintMinuteText(Canvas canvas, Size size, String text) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontFeatures: const [ui.FontFeature.tabularFigures()],
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFF8FAFC),
        letterSpacing: -0.3,
        height: 1.0,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant MinuteWritingPainter oldDelegate) {
    return oldDelegate.currentMinutes != currentMinutes ||
        oldDelegate.oldMinutes != oldMinutes ||
        oldDelegate.isWiping != isWiping ||
        oldDelegate.isWriting != isWriting ||
        oldDelegate.wipeProgress != wipeProgress ||
        oldDelegate.writeProgress != writeProgress ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.isCompact != isCompact;
  }
}

/// CustomPainter rendering the mechanical split-flap hour display card:
/// 1. Calm static state: clean tabular figures (1..12, centered, no layout jumps)
/// 2. Wipe state: progressive erasure of old hour digits with luminous sweep line
/// 3. Blank state: completely empty card with physical center seam
/// 4. Handwriting state: progressive vector stroke construction for single or double digits
class HourWritingPainter extends CustomPainter {
  final String currentHours;
  final String? oldHours;
  final bool isWiping;
  final bool isWriting;
  final double wipeProgress;
  final double writeProgress;
  final double fontSize;
  final bool isCompact;

  const HourWritingPainter({
    required this.currentHours,
    this.oldHours,
    this.isWiping = false,
    this.isWriting = false,
    this.wipeProgress = 0.0,
    this.writeProgress = 1.0,
    this.fontSize = 18.0,
    this.isCompact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. WIPING PHASE
    if (isWiping && oldHours != null) {
      final t = wipeProgress.clamp(0.0, 1.0);
      if (t >= 0.999) return; // Blank state

      final wipeX = size.width * t;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(wipeX, 0, size.width, size.height));
      _paintHourText(canvas, size, oldHours!);
      canvas.restore();

      // Soft luminous wiper boundary line
      if (t > 0.02 && t < 0.98) {
        final glowPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(wipeX, 0),
            Offset(wipeX, size.height),
            [
              const Color(0xFF60A5FA).withOpacity(0.0),
              const Color(0xFF60A5FA).withOpacity(0.70),
              const Color(0xFF93C5FD).withOpacity(0.95),
              const Color(0xFF60A5FA).withOpacity(0.70),
              const Color(0xFF60A5FA).withOpacity(0.0),
            ],
            [0.0, 0.25, 0.50, 0.75, 1.0],
          )
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(wipeX, 2), Offset(wipeX, size.height - 2), glowPaint);
      }
      return;
    }

    // 2. CLEAR BLANK STATE
    if (isWriting && writeProgress <= 0.0) {
      return; // Absolutely empty hour region
    }

    // 3. PROGRESSIVE HANDWRITING
    if (isWriting) {
      final inkPaint = Paint()
        ..color = const Color(0xFFF8FAFC)
        ..strokeWidth = isCompact ? 2.2 : 2.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final glowPaint = Paint()
        ..color = const Color(0xFF3B82F6).withOpacity(0.42)
        ..strokeWidth = isCompact ? 3.8 : 4.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8)
        ..style = PaintingStyle.stroke;

      final isSingleDigit = currentHours.length == 1;

      if (isSingleDigit) {
        final char = currentHours[0];
        final rect = Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.12,
          size.width * 0.50,
          size.height * 0.76,
        );

        if (writeProgress >= 1.0) {
          final ext = AcadexDigitPath.extractProgress(char, 1.0, rect);
          canvas.drawPath(ext.revealedPath, glowPaint);
          canvas.drawPath(ext.revealedPath, inkPaint);
          return;
        }

        final p = writeProgress.clamp(0.0, 1.0);
        if (p > 0.0) {
          final ext = AcadexDigitPath.extractProgress(char, p, rect);
          canvas.drawPath(ext.revealedPath, glowPaint);
          canvas.drawPath(ext.revealedPath, inkPaint);
          if (p < 1.0) {
            _paintNibSparkle(canvas, ext.stylusTip);
          }
        }
        return;
      } else {
        // Double digit hours: "10", "11", "12"
        final char1 = currentHours[0];
        final char2 = currentHours[1];
        final rect1 = Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.12,
          size.width * 0.40,
          size.height * 0.76,
        );
        final rect2 = Rect.fromLTWH(
          size.width * 0.52,
          size.height * 0.12,
          size.width * 0.40,
          size.height * 0.76,
        );

        if (writeProgress >= 1.0) {
          final ext1 = AcadexDigitPath.extractProgress(char1, 1.0, rect1);
          final ext2 = AcadexDigitPath.extractProgress(char2, 1.0, rect2);
          canvas.drawPath(ext1.revealedPath, glowPaint);
          canvas.drawPath(ext1.revealedPath, inkPaint);
          canvas.drawPath(ext2.revealedPath, glowPaint);
          canvas.drawPath(ext2.revealedPath, inkPaint);
          return;
        }

        final p1 = (writeProgress / 0.48).clamp(0.0, 1.0);
        final p2 = writeProgress < 0.52
            ? 0.0
            : ((writeProgress - 0.52) / 0.48).clamp(0.0, 1.0);

        if (p1 > 0.0) {
          final ext1 = AcadexDigitPath.extractProgress(char1, p1, rect1);
          canvas.drawPath(ext1.revealedPath, glowPaint);
          canvas.drawPath(ext1.revealedPath, inkPaint);
          if (p1 < 1.0) {
            _paintNibSparkle(canvas, ext1.stylusTip);
          }
        }

        if (p2 > 0.0) {
          final ext2 = AcadexDigitPath.extractProgress(char2, p2, rect2);
          canvas.drawPath(ext2.revealedPath, glowPaint);
          canvas.drawPath(ext2.revealedPath, inkPaint);
          if (p2 < 1.0) {
            _paintNibSparkle(canvas, ext2.stylusTip);
          }
        }
        return;
      }
    }

    // 4. CALM STATIC STATE
    _paintHourText(canvas, size, currentHours);
  }

  void _paintNibSparkle(Canvas canvas, Offset tip) {
    canvas.drawCircle(
      tip,
      3.0,
      Paint()
        ..color = const Color(0xFF60A5FA).withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    canvas.drawCircle(
      tip,
      1.2,
      Paint()..color = Colors.white,
    );
  }

  void _paintHourText(Canvas canvas, Size size, String text) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontFeatures: const [ui.FontFeature.tabularFigures()],
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFF8FAFC),
        letterSpacing: -0.3,
        height: 1.0,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant HourWritingPainter oldDelegate) {
    return oldDelegate.currentHours != currentHours ||
        oldDelegate.oldHours != oldHours ||
        oldDelegate.isWiping != isWiping ||
        oldDelegate.isWriting != isWriting ||
        oldDelegate.wipeProgress != wipeProgress ||
        oldDelegate.writeProgress != writeProgress ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.isCompact != isCompact;
  }
}

/// CustomPainter rendering the mechanical split-flap AM/PM period card:
/// 1. Calm static state: clean AM or PM text in high-contrast cyan/slate
/// 2. Wipe state: progressive erasure of old period flap with luminous sweep line
/// 3. Blank state: completely empty card
/// 4. Reveal state: progressive mechanical split-flap reveal of new period
class PeriodWritingPainter extends CustomPainter {
  final String currentPeriod;
  final String? oldPeriod;
  final bool isWiping;
  final bool isWriting;
  final double wipeProgress;
  final double writeProgress;
  final double fontSize;
  final bool isCompact;

  const PeriodWritingPainter({
    required this.currentPeriod,
    this.oldPeriod,
    this.isWiping = false,
    this.isWriting = false,
    this.wipeProgress = 0.0,
    this.writeProgress = 1.0,
    this.fontSize = 12.0,
    this.isCompact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. WIPING PHASE
    if (isWiping && oldPeriod != null) {
      final t = wipeProgress.clamp(0.0, 1.0);
      if (t >= 0.999) return;

      final wipeX = size.width * t;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(wipeX, 0, size.width, size.height));
      _paintPeriodText(canvas, size, oldPeriod!);
      canvas.restore();

      if (t > 0.02 && t < 0.98) {
        final glowPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(wipeX, 0),
            Offset(wipeX, size.height),
            [
              const Color(0xFF60A5FA).withOpacity(0.0),
              const Color(0xFF60A5FA).withOpacity(0.70),
              const Color(0xFF93C5FD).withOpacity(0.95),
              const Color(0xFF60A5FA).withOpacity(0.70),
              const Color(0xFF60A5FA).withOpacity(0.0),
            ],
            [0.0, 0.25, 0.50, 0.75, 1.0],
          )
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(wipeX, 2), Offset(wipeX, size.height - 2), glowPaint);
      }
      return;
    }

    // 2. CLEAR BLANK STATE
    if (isWriting && writeProgress <= 0.0) {
      return;
    }

    // 3. PROGRESSIVE REVEAL
    if (isWriting) {
      final t = writeProgress.clamp(0.0, 1.0);
      final wipeX = size.width * t;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, 0, wipeX, size.height));
      _paintPeriodText(canvas, size, currentPeriod);
      canvas.restore();

      if (t > 0.02 && t < 0.98) {
        final glowPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(wipeX, 0),
            Offset(wipeX, size.height),
            [
              const Color(0xFF60A5FA).withOpacity(0.0),
              const Color(0xFF60A5FA).withOpacity(0.70),
              const Color(0xFF93C5FD).withOpacity(0.95),
              const Color(0xFF60A5FA).withOpacity(0.70),
              const Color(0xFF60A5FA).withOpacity(0.0),
            ],
            [0.0, 0.25, 0.50, 0.75, 1.0],
          )
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(wipeX, 2), Offset(wipeX, size.height - 2), glowPaint);
      }
      return;
    }

    // 4. CALM STATIC STATE
    _paintPeriodText(canvas, size, currentPeriod);
  }

  void _paintPeriodText(Canvas canvas, Size size, String text) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF93C5FD),
        letterSpacing: 0.2,
        height: 1.0,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant PeriodWritingPainter oldDelegate) {
    return oldDelegate.currentPeriod != currentPeriod ||
        oldDelegate.oldPeriod != oldPeriod ||
        oldDelegate.isWiping != isWiping ||
        oldDelegate.isWriting != isWriting ||
        oldDelegate.wipeProgress != wipeProgress ||
        oldDelegate.writeProgress != writeProgress ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.isCompact != isCompact;
  }
}
