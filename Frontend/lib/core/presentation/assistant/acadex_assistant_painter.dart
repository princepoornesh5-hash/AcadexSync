import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'acadex_assistant_types.dart';

/// Master 3D Stylized Vector Painter for the Canonical ACADEX Assistant.
///
/// Features:
/// - Stylized 3D claymorphic finish with volumetric radial & linear gradients
/// - Distinctive modern swept-parted dark hairstyle with controlled highlights
/// - Modern slate-navy academic blazer with ACADEX royal-blue lapel trim and chest emblem
/// - Compact ACADEX-blue campus backpack with front pocket and miniature notebook with ribbon
/// - Articulated arms supporting multiple gestures: wave, point, wipe, write, magic, idle
/// - Morphable facial features: gaze tracking, blinking, eyebrows, smiling mouths
/// - Signature Magic Gesture sparkle aura with radiating starlets and glowing rings
/// - Dynamic floor shadow with breathing scale
class AcadexAssistantPainter extends CustomPainter {
  final AcadexAssistantPose pose;
  final AcadexAssistantExpression expression;
  final Offset gazeDirection;
  final double poseProgress;
  final double breathingValue;
  final double blinkValue;
  final double visibility;
  final double magicSparkleProgress;
  final bool isDark;
  final bool enableShadow;
  final Offset? stylusTarget;

  AcadexAssistantPainter({
    required this.pose,
    required this.expression,
    required this.gazeDirection,
    required this.poseProgress,
    required this.breathingValue,
    required this.blinkValue,
    required this.visibility,
    required this.magicSparkleProgress,
    required this.isDark,
    this.enableShadow = true,
    this.stylusTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (visibility <= 0.005) return;

    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;

    // Apply visibility fade and vertical emergence
    if (visibility < 1.0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = Color.fromRGBO(255, 255, 255, visibility),
      );
    }

    // Breathing calculations (subtle, calm vertical & horizontal rhythm)
    final breathY = -math.sin(breathingValue * 2 * math.pi) * (h * 0.012);
    final breathScaleY = 1.0 + (math.sin(breathingValue * 2 * math.pi) * 0.008);
    final breathScaleX = 1.0 - (math.sin(breathingValue * 2 * math.pi) * 0.005);

    // 1. Dynamic Floor Shadow
    if (enableShadow) {
      _paintFloorShadow(canvas, cx, h, w, breathScaleX);
    }

    // Anchor body at baseline
    canvas.save();
    canvas.translate(cx, h * 0.92);
    canvas.translate(0, breathY);
    canvas.scale(breathScaleX, breathScaleY);
    canvas.translate(-cx, -h * 0.92);

    // 2. Compact Campus Backpack (mounted over right shoulder, rendered behind body)
    _paintBackpack(canvas, cx, h, w, breathY);

    // 3. Torso, Academic Blazer & Shirt Collar
    _paintTorsoAndClothing(canvas, cx, h, w);

    // 4. Left Arm & Hand (Resting naturally)
    _paintLeftArm(canvas, cx, h, w);

    // 5. Right Arm & Hand (Articulated for active gestures)
    final handTipOffset = _paintRightArm(canvas, cx, h, w);

    // 6. Neck & Collar Opening
    _paintNeck(canvas, cx, h, w);

    // 7. Head, Face, Eyes, Eyebrows & Hair
    _paintHeadAndFace(canvas, cx, h, w);

    // 8. Magic Gesture Stardust Aura & Sparkle Ring
    if (pose == AcadexAssistantPose.magic || magicSparkleProgress > 0.01) {
      _paintMagicSparkles(canvas, handTipOffset, w, h);
    }

    canvas.restore();

    if (visibility < 1.0) {
      canvas.restore();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. FLOOR SHADOW
  // ---------------------------------------------------------------------------
  void _paintFloorShadow(Canvas canvas, double cx, double h, double w, double scaleX) {
    final shadowY = h * 0.95;
    final shadowW = w * 0.60 * scaleX;
    final shadowH = h * 0.12;

    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? Colors.black : const Color(0xFF0F172A))
              .withValues(alpha: isDark ? 0.35 : 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, shadowY),
        width: shadowW,
        height: shadowH,
      ));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, shadowY), width: shadowW, height: shadowH),
      shadowPaint,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. CAMPUS BACKPACK
  // ---------------------------------------------------------------------------
  void _paintBackpack(Canvas canvas, double cx, double h, double w, double breathY) {
    // Positioned over right shoulder (viewer's right)
    final bpX = cx + (w * 0.22);
    final bpY = (h * 0.58) + (breathY * 0.4);
    final bpW = w * 0.32;
    final bpH = h * 0.44;

    final bpRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(bpX, bpY), width: bpW, height: bpH),
      Radius.circular(w * 0.10),
    );

    // 3D ACADEX Blue Gradient
    final bpGradient = LinearGradient(
      begin: const Alignment(-0.6, -0.8),
      end: const Alignment(0.8, 0.9),
      colors: const [
        Color(0xFF3B82F6), // Vibrant ACADEX highlight
        Color(0xFF2563EB), // ACADEX royal blue
        Color(0xFF1D4ED8), // Deep blue shadow
        Color(0xFF1E3A8A), // Occlusion depth
      ],
      stops: const [0.0, 0.45, 0.80, 1.0],
    );

    canvas.drawRRect(
      bpRect,
      Paint()
        ..shader = bpGradient.createShader(bpRect.outerRect)
        ..style = PaintingStyle.fill,
    );

    // Front pocket pouch
    final pocketRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(bpX + (w * 0.02), bpY + (bpH * 0.16)),
        width: bpW * 0.76,
        height: bpH * 0.46,
      ),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(
      pocketRect,
      Paint()
        ..color = const Color(0xFF1D4ED8)
        ..style = PaintingStyle.fill,
    );

    // Zipper seam detail
    final zipPaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(pocketRect, zipPaint);

    // Miniature Campus Notebook peeking out of backpack top
    final noteW = bpW * 0.44;
    final noteH = bpH * 0.40;
    final noteRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bpX - (bpW * 0.28), bpY - (bpH * 0.65), noteW, noteH),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(
      noteRect,
      Paint()
        ..color = const Color(0xFFF8FAFC)
        ..style = PaintingStyle.fill,
    );
    // Notebook binding/pages seam
    canvas.drawRRect(
      noteRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Amber bookmark ribbon
    final ribbonPath = Path()
      ..moveTo(bpX - (bpW * 0.12), bpY - (bpH * 0.65))
      ..lineTo(bpX - (bpW * 0.04), bpY - (bpH * 0.65))
      ..lineTo(bpX - (bpW * 0.04), bpY - (bpH * 0.38))
      ..lineTo(bpX - (bpW * 0.08), bpY - (bpH * 0.44))
      ..lineTo(bpX - (bpW * 0.12), bpY - (bpH * 0.38))
      ..close();
    canvas.drawPath(
      ribbonPath,
      Paint()
        ..color = const Color(0xFFF59E0B) // Amber college ribbon
        ..style = PaintingStyle.fill,
    );

    // Top grab loop handle
    final handlePath = Path()
      ..moveTo(bpX - (bpW * 0.15), bpY - (bpH * 0.50))
      ..quadraticBezierTo(bpX, bpY - (bpH * 0.72), bpX + (bpW * 0.15), bpY - (bpH * 0.50));
    canvas.drawPath(
      handlePath,
      Paint()
        ..color = const Color(0xFF1E40AF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TORSO, ACADEMIC BLAZER & SHIRT
  // ---------------------------------------------------------------------------
  void _paintTorsoAndClothing(Canvas canvas, double cx, double h, double w) {
    final torsoW = w * 0.44; // Well-proportioned tailored academic cut
    final shoulderY = h * 0.48;
    final hemY = h * 0.88;

    // 3D Academic Blazer Main Silhouette
    final blazerPath = Path()
      ..moveTo(cx - (torsoW * 0.50), shoulderY) // Left shoulder
      ..quadraticBezierTo(cx, shoulderY - (h * 0.02), cx + (torsoW * 0.50), shoulderY) // Collar bridge to Right shoulder
      ..lineTo(cx + (torsoW * 0.48), hemY) // Right hem
      ..quadraticBezierTo(cx, hemY + (h * 0.03), cx - (torsoW * 0.48), hemY) // Bottom curve
      ..close();

    // 3D Slate-Navy Fabric Gradient
    final blazerGradient = LinearGradient(
      begin: const Alignment(-0.5, -0.9),
      end: const Alignment(0.6, 1.0),
      colors: const [
        Color(0xFF334155), // Soft top light
        Color(0xFF1E293B), // Primary slate navy
        Color(0xFF0F172A), // Shadow depth
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    canvas.drawPath(
      blazerPath,
      Paint()
        ..shader = blazerGradient.createShader(blazerPath.getBounds())
        ..style = PaintingStyle.fill,
    );

    // Inner Clean Ivory Shirt at V-Neck
    final shirtVPath = Path()
      ..moveTo(cx - (w * 0.09), shoulderY)
      ..lineTo(cx + (w * 0.09), shoulderY)
      ..lineTo(cx, shoulderY + (h * 0.14))
      ..close();

    canvas.drawPath(
      shirtVPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        ).createShader(shirtVPath.getBounds())
        ..style = PaintingStyle.fill,
    );

    // ACADEX Royal-Blue Lapel Trim running along the V opening
    final lapelLeft = Path()
      ..moveTo(cx - (w * 0.10), shoulderY)
      ..lineTo(cx, shoulderY + (h * 0.15))
      ..lineTo(cx - (w * 0.03), shoulderY + (h * 0.15))
      ..lineTo(cx - (w * 0.12), shoulderY + (h * 0.04))
      ..close();

    final lapelRight = Path()
      ..moveTo(cx + (w * 0.10), shoulderY)
      ..lineTo(cx, shoulderY + (h * 0.15))
      ..lineTo(cx + (w * 0.03), shoulderY + (h * 0.15))
      ..lineTo(cx + (w * 0.12), shoulderY + (h * 0.04))
      ..close();

    final lapelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1D4ED8)],
      ).createShader(Rect.fromLTWH(cx - (w * 0.12), shoulderY, w * 0.24, h * 0.16))
      ..style = PaintingStyle.fill;

    canvas.drawPath(lapelLeft, lapelPaint);
    canvas.drawPath(lapelRight, lapelPaint);

    // ACADEX Brand Pin / Collegiate Emblem on left chest
    final badgeX = cx - (torsoW * 0.28);
    final badgeY = shoulderY + (h * 0.11);
    final badgeRadius = w * 0.032;

    // Badge metallic blue body
    canvas.drawCircle(
      Offset(badgeX, badgeY),
      badgeRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1E3A8A)],
        ).createShader(Rect.fromCircle(center: Offset(badgeX, badgeY), radius: badgeRadius))
        ..style = PaintingStyle.fill,
    );
    // Badge white crest silhouette ("A" monogram / academic crest)
    final crestPath = Path()
      ..moveTo(badgeX, badgeY - (badgeRadius * 0.55))
      ..lineTo(badgeX + (badgeRadius * 0.45), badgeY + (badgeRadius * 0.50))
      ..lineTo(badgeX - (badgeRadius * 0.45), badgeY + (badgeRadius * 0.50))
      ..close();
    canvas.drawPath(
      crestPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Front closure seam & button
    canvas.drawLine(
      Offset(cx, shoulderY + (h * 0.16)),
      Offset(cx, hemY - (h * 0.02)),
      Paint()
        ..color = const Color(0xFF0F172A)
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(cx, shoulderY + (h * 0.22)),
      w * 0.014,
      Paint()..color = const Color(0xFF0F172A),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. LEFT ARM & HAND (Resting naturally, seamlessly attached at shoulder seam)
  // ---------------------------------------------------------------------------
  void _paintLeftArm(Canvas canvas, double cx, double h, double w) {
    final shoulderX = cx - (w * 0.22);
    final shoulderY = h * 0.48;
    final armW = w * 0.11;
    final upperArmL = h * 0.19;
    final forearmL = h * 0.17;
    final handRadius = w * 0.042;

    canvas.save();
    canvas.translate(shoulderX, shoulderY);

    // Upper arm hanging straight down
    final upperRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-armW * 0.5, 0, armW, upperArmL),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(
      upperRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF334155), Color(0xFF1E293B)],
        ).createShader(upperRect.outerRect)
        ..style = PaintingStyle.fill,
    );

    // Forearm
    canvas.translate(0, upperArmL * 0.90);
    final forearmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-armW * 0.45, 0, armW * 0.90, forearmL),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(
      forearmRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ).createShader(forearmRect.outerRect)
        ..style = PaintingStyle.fill,
    );

    // Shirt Cuff
    final cuffRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-armW * 0.40, forearmL - (h * 0.02), armW * 0.80, h * 0.02),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(cuffRect, Paint()..color = const Color(0xFFF8FAFC));

    // Left hand in soft resting posture
    canvas.translate(0, forearmL);
    final handCenter = Offset(0, handRadius * 0.5);
    final handPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFFFFE0CC), Color(0xFFF5C29E), Color(0xFFE5A882)],
      ).createShader(Rect.fromCircle(center: handCenter, radius: handRadius))
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: handCenter, width: handRadius * 1.5, height: handRadius * 1.7),
      handPaint,
    );

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // 5. RIGHT ARM & HAND (Articulated for active gestures)
  // ---------------------------------------------------------------------------
  Offset _paintRightArm(Canvas canvas, double cx, double h, double w) {
    final shoulderX = cx + (w * 0.22);
    final shoulderY = h * 0.48;
    final upperArmL = h * 0.28;
    final forearmL = h * 0.26;
    final handRadius = w * 0.045;
    final stylusL = w * 0.38;

    double armAngle = 0.0;
    double elbowAngle = 0.0;
    double handAngle = 0.0;
    Offset handOffset = Offset.zero;

    // Choreographed kinematics per pose
    switch (pose) {
      case AcadexAssistantPose.idle:
      case AcadexAssistantPose.appear:
      case AcadexAssistantPose.disappear:
        // Calm resting stance
        armAngle = 0.08 + (math.sin(breathingValue * 2 * math.pi) * 0.02);
        elbowAngle = 0.15;
        break;

      case AcadexAssistantPose.greet:
        armAngle = -0.55;
        elbowAngle = -0.45;
        handAngle = -0.10;
        break;

      case AcadexAssistantPose.wave:
        armAngle = -1.05;
        elbowAngle = -0.75;
        final waveOsc = math.sin(poseProgress * 6 * math.pi);
        handAngle = waveOsc * 0.30;
        handOffset = Offset(waveOsc * (w * 0.03), 0);
        break;

      case AcadexAssistantPose.point:
      case AcadexAssistantPose.reach:
        armAngle = -0.75;
        elbowAngle = -0.15;
        handAngle = -0.10;
        break;

      case AcadexAssistantPose.wipe:
        if (stylusTarget != null) {
          final ik = _solveArmIK(
            shoulder: Offset(shoulderX, shoulderY),
            target: stylusTarget!,
            l1: upperArmL,
            l2: forearmL + (handRadius * 0.8) + stylusL,
          );
          armAngle = ik.armAngle;
          elbowAngle = ik.elbowAngle;
          handAngle = ik.handAngle;
        } else {
          armAngle = -0.45;
          elbowAngle = 0.35;
        }
        break;

      case AcadexAssistantPose.write:
        if (stylusTarget != null) {
          final ik = _solveArmIK(
            shoulder: Offset(shoulderX, shoulderY),
            target: stylusTarget!,
            l1: upperArmL,
            l2: forearmL + (handRadius * 0.8) + stylusL,
          );
          armAngle = ik.armAngle;
          elbowAngle = ik.elbowAngle;
          handAngle = ik.handAngle;
        } else {
          armAngle = -0.50;
          elbowAngle = 0.40;
        }
        break;

      case AcadexAssistantPose.magic:
        // Signature Magic Gesture: arm raised gracefully with upward flourish
        armAngle = -1.15;
        elbowAngle = -0.65;
        handAngle = -0.20;
        break;

      case AcadexAssistantPose.happy:
        armAngle = -0.45;
        elbowAngle = -0.80;
        handAngle = -0.15;
        break;

      case AcadexAssistantPose.surprise:
        armAngle = -0.70;
        elbowAngle = -0.70;
        handAngle = 0.15;
        break;

      case AcadexAssistantPose.focused:
        armAngle = 0.05;
        elbowAngle = 0.20;
        break;
    }

    canvas.save();
    canvas.translate(shoulderX, shoulderY);
    canvas.rotate(armAngle);

    // Upper Arm Sleeve
    final upperArmW = w * 0.11;
    final upperArmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-upperArmW * 0.5, 0, upperArmW, upperArmL),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(
      upperArmRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF334155), Color(0xFF1E293B)],
        ).createShader(upperArmRect.outerRect)
        ..style = PaintingStyle.fill,
    );

    // Elbow Joint & Forearm
    canvas.translate(0, upperArmL * 0.90);
    canvas.rotate(elbowAngle);

    final forearmW = w * 0.10;
    final forearmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-forearmW * 0.5, 0, forearmW, forearmL),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(
      forearmRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ).createShader(forearmRect.outerRect)
        ..style = PaintingStyle.fill,
    );

    // Shirt Cuff
    final cuffRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-forearmW * 0.45, forearmL - (h * 0.02), forearmW * 0.90, h * 0.02),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(cuffRect, Paint()..color = const Color(0xFFF8FAFC));

    // Wrist & Hand
    canvas.translate(handOffset.dx, forearmL + handOffset.dy);
    canvas.rotate(handAngle);

    // Articulated 3D Hand
    final handPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: const [Color(0xFFFFE0CC), Color(0xFFF5C29E), Color(0xFFE5A882)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: handRadius))
      ..style = PaintingStyle.fill;

    // Palm base
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, handRadius * 0.5), width: handRadius * 1.5, height: handRadius * 1.7),
      handPaint,
    );

    // Gestures
    if (pose == AcadexAssistantPose.write || pose == AcadexAssistantPose.wipe) {
      // Sleek digital academic stylus held gracefully in hand
      final penW = w * 0.022;
      final penPath = Path()
        ..moveTo(-penW * 0.5, handRadius * 0.2)
        ..lineTo(penW * 0.5, handRadius * 0.2)
        ..lineTo(penW * 0.35, stylusL * 0.85)
        ..lineTo(0.0, stylusL) // precise nib tip at (0, stylusL)
        ..lineTo(-penW * 0.35, stylusL * 0.85)
        ..close();

      canvas.drawPath(
        penPath,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF60A5FA), Color(0xFF93C5FD)],
          ).createShader(penPath.getBounds())
          ..style = PaintingStyle.fill,
      );

      // Grip detail
      canvas.drawRect(
        Rect.fromLTWH(-penW * 0.6, handRadius * 0.35, penW * 1.2, stylusL * 0.15),
        Paint()..color = const Color(0xFFCBD5E1),
      );

      // Illuminated cyan nib point
      canvas.drawCircle(
        Offset(0.0, stylusL),
        1.5,
        Paint()..color = const Color(0xFF93C5FD),
      );
    } else if (pose == AcadexAssistantPose.point) {
      final fingerPath = Path()
        ..moveTo(-w * 0.015, handRadius * 0.8)
        ..lineTo(-w * 0.015, handRadius * 2.0)
        ..arcToPoint(Offset(w * 0.015, handRadius * 2.0), radius: Radius.circular(w * 0.015))
        ..lineTo(w * 0.015, handRadius * 0.8)
        ..close();
      canvas.drawPath(fingerPath, handPaint);
    } else if (pose == AcadexAssistantPose.wave || pose == AcadexAssistantPose.magic) {
      for (int i = -2; i <= 2; i++) {
        final fAngle = i * 0.18;
        final fLen = handRadius * (1.5 - (i.abs() * 0.2));
        final fX = math.sin(fAngle) * fLen;
        final fY = handRadius * 0.5 + (math.cos(fAngle) * fLen);
        canvas.drawCircle(Offset(fX, fY), w * 0.015, handPaint);
      }
    }

    // Capture global tip coordinates for magic particles
    final matrix = Matrix4.fromFloat64List(canvas.getTransform());
    final tipLocalY = (pose == AcadexAssistantPose.write || pose == AcadexAssistantPose.wipe)
        ? stylusL
        : (handRadius * 2.0);
    final globalHandTip = MatrixUtils.transformPoint(matrix, Offset(0, tipLocalY));

    canvas.restore();

    return globalHandTip;
  }

  /// Analytical two-bone Inverse Kinematics with natural downward elbow pole-vector preference.
  _ArmIKSolution _solveArmIK({
    required Offset shoulder,
    required Offset target,
    required double l1,
    required double l2,
  }) {
    final dx = target.dx - shoulder.dx;
    final dy = target.dy - shoulder.dy;
    final dist = math.sqrt((dx * dx) + (dy * dy));

    final minReach = (l1 - l2).abs() + 2.0;
    final maxReach = (l1 + l2) * 0.98;
    final d = dist.clamp(minReach, maxReach);

    // Law of Cosines for interior elbow angle
    final cosElbow = ((l1 * l1) + (l2 * l2) - (d * d)) / (2 * l1 * l2);
    final beta = math.acos(cosElbow.clamp(-1.0, 1.0));
    // Controlled elbow preference: natural downward/forward bend toward target
    final elbowAngle = -(math.pi - beta);

    // Law of Cosines for shoulder offset angle
    final cosShoulder = ((l1 * l1) + (d * d) - (l2 * l2)) / (2 * l1 * d);
    final alpha = math.acos(cosShoulder.clamp(-1.0, 1.0));

    // Direction to target in standard Cartesian
    final phi = math.atan2(dy, dx);
    final thetaArm = phi + alpha;
    final armAngle = thetaArm - (math.pi / 2);

    return _ArmIKSolution(
      armAngle: armAngle,
      elbowAngle: elbowAngle,
      handAngle: 0.0,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. NECK
  // ---------------------------------------------------------------------------
  void _paintNeck(Canvas canvas, double cx, double h, double w) {
    final neckW = w * 0.13;
    final neckH = h * 0.08;
    final neckY = h * 0.44;

    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, neckY), width: neckW, height: neckH),
      Radius.circular(w * 0.04),
    );

    // Warm 3D skin tone with collar occlusion shadow
    canvas.drawRRect(
      neckRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF5C29E), Color(0xFFE5A882), Color(0xFFD4936E)],
        ).createShader(neckRect.outerRect)
        ..style = PaintingStyle.fill,
    );
  }

  // ---------------------------------------------------------------------------
  // 7. HEAD, FACE, EYES, EYEBROWS & HAIR
  // ---------------------------------------------------------------------------
  void _paintHeadAndFace(Canvas canvas, double cx, double h, double w) {
    final headRadius = w * 0.20; // Well-proportioned head
    final headCenterY = h * 0.27; // Elevated above neck and blazer collar
    final headCenter = Offset(cx, headCenterY);

    // Ears (Subtle, clean 3D clay curves)
    final earY = headCenterY + (h * 0.015);
    final earW = w * 0.055;
    final earH = h * 0.080;
    final earPaint = Paint()
      ..color = const Color(0xFFF5C29E)
      ..style = PaintingStyle.fill;

    // Left ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - (headRadius * 0.98), earY), width: earW, height: earH),
      earPaint,
    );
    // Right ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + (headRadius * 0.98), earY), width: earW, height: earH),
      earPaint,
    );

    // 3D Head Silhouette & Soft Lighting
    final headGradient = RadialGradient(
      center: const Alignment(-0.35, -0.42),
      radius: 0.92,
      colors: const [
        Color(0xFFFFF0E5), // Soft key light highlight
        Color(0xFFFFDFC4), // Warm clay surface
        Color(0xFFF5C29E), // Base skin tone
        Color(0xFFE5A882), // Occlusion rim
      ],
      stops: const [0.0, 0.40, 0.75, 1.0],
    );

    canvas.drawCircle(
      headCenter,
      headRadius,
      Paint()
        ..shader = headGradient.createShader(Rect.fromCircle(center: headCenter, radius: headRadius))
        ..style = PaintingStyle.fill,
    );

    // Cheerful Rosy Cheek Blush
    final blushPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF472B6).withValues(alpha: 0.28),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius * 0.4));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - (headRadius * 0.55), headCenterY + (headRadius * 0.28)),
        width: w * 0.09,
        height: h * 0.04,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + (headRadius * 0.55), headCenterY + (headRadius * 0.28)),
        width: w * 0.09,
        height: h * 0.04,
      ),
      blushPaint,
    );

    // Expressive Eyes (with Gaze Tracking & Expression Morphing)
    _paintEyes(canvas, cx, headCenterY, headRadius, w, h);

    // Eyebrows
    _paintEyebrows(canvas, cx, headCenterY, headRadius, w, h);

    // Friendly Mouth
    _paintMouth(canvas, cx, headCenterY, headRadius, w, h);

    // Distinctive Modern Swept-Parted Haircut
    _paintHair(canvas, cx, headCenterY, headRadius, w, h);
  }

  // ---------------------------------------------------------------------------
  // EYES
  // ---------------------------------------------------------------------------
  void _paintEyes(Canvas canvas, double cx, double headY, double headR, double w, double h) {
    final eyeSpacing = headR * 0.45;
    final eyeY = headY + (headR * 0.04);
    final eyeW = w * 0.095;
    final eyeH = eyeW * 1.15;

    for (int side = -1; side <= 1; side += 2) {
      final eyeX = cx + (side * eyeSpacing);
      final eyeCenter = Offset(eyeX, eyeY);

      if (blinkValue > 0.65) {
        // Closed / blinking eye curve
        final blinkPath = Path()
          ..moveTo(eyeX - (eyeW * 0.5), eyeY)
          ..quadraticBezierTo(eyeX, eyeY + (eyeH * 0.2), eyeX + (eyeW * 0.5), eyeY);
        canvas.drawPath(
          blinkPath,
          Paint()
            ..color = const Color(0xFF2A1A14)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }

      // Sclera (Eye White with Soft Ambient Occlusion)
      final eyeRect = Rect.fromCenter(center: eyeCenter, width: eyeW, height: eyeH);
      canvas.drawOval(
        eyeRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE2E8F0), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
            stops: [0.0, 0.3, 1.0],
          ).createShader(eyeRect)
          ..style = PaintingStyle.fill,
      );

      // Gaze Tracking Offset
      final gazeX = gazeDirection.dx.clamp(-1.0, 1.0) * (eyeW * 0.22);
      final gazeY = gazeDirection.dy.clamp(-1.0, 1.0) * (eyeH * 0.22);
      final pupilCenter = eyeCenter.translate(gazeX, gazeY);

      // Warm Amber-Brown Iris
      final irisRadius = eyeW * 0.38;
      canvas.drawCircle(
        pupilCenter,
        irisRadius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.2),
            colors: const [Color(0xFF78350F), Color(0xFF451A03), Color(0xFF270E04)],
          ).createShader(Rect.fromCircle(center: pupilCenter, radius: irisRadius))
          ..style = PaintingStyle.fill,
      );

      // Deep Obsidian Pupil
      canvas.drawCircle(
        pupilCenter,
        irisRadius * 0.55,
        Paint()..color = const Color(0xFF0F172A),
      );

      // Dual Specular 3D Light Highlights (Primary + Secondary Ambient Bounce)
      canvas.drawCircle(
        pupilCenter.translate(-irisRadius * 0.32, -irisRadius * 0.32),
        irisRadius * 0.35,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        pupilCenter.translate(irisRadius * 0.28, irisRadius * 0.25),
        irisRadius * 0.16,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // EYEBROWS
  // ---------------------------------------------------------------------------
  void _paintEyebrows(Canvas canvas, double cx, double headY, double headR, double w, double h) {
    final browSpacing = headR * 0.45;
    final browBaseY = headY - (headR * 0.20);
    final browW = w * 0.080;

    final browPaint = Paint()
      ..color = const Color(0xFF2D1B13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int side = -1; side <= 1; side += 2) {
      final browX = cx + (side * browSpacing);
      double browY = browBaseY;
      double tilt = 0.0;

      if (expression == AcadexAssistantExpression.focused) {
        tilt = side * 0.06; // subtle focused concentration
      }

      final browPath = Path()
        ..moveTo(browX - (browW * 0.5), browY - (tilt * browW))
        ..quadraticBezierTo(browX, browY - (h * 0.008), browX + (browW * 0.5), browY + (tilt * browW));

      canvas.drawPath(browPath, browPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // MOUTH
  // ---------------------------------------------------------------------------
  void _paintMouth(Canvas canvas, double cx, double headY, double headR, double w, double h) {
    final mouthY = headY + (headR * 0.50);
    final mouthW = w * 0.080;

    final mouthPaint = Paint()
      ..color = const Color(0xFF881337)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    if (expression == AcadexAssistantExpression.focused) {
      // Subtle, intelligent, composed mouth line with very slight pleasant upturn
      final focusedSmile = Path()
        ..moveTo(cx - (mouthW * 0.35), mouthY)
        ..quadraticBezierTo(cx, mouthY + (h * 0.006), cx + (mouthW * 0.35), mouthY);
      canvas.drawPath(focusedSmile, mouthPaint);
    } else if (expression == AcadexAssistantExpression.success) {
      // Small confident, satisfied smile
      final successSmile = Path()
        ..moveTo(cx - (mouthW * 0.45), mouthY - (h * 0.002))
        ..quadraticBezierTo(cx, mouthY + (h * 0.018), cx + (mouthW * 0.45), mouthY - (h * 0.002));
      canvas.drawPath(successSmile, mouthPaint);
    } else {
      // Gentle, friendly, calm smile
      final calmSmile = Path()
        ..moveTo(cx - (mouthW * 0.42), mouthY)
        ..quadraticBezierTo(cx, mouthY + (h * 0.014), cx + (mouthW * 0.42), mouthY);
      canvas.drawPath(calmSmile, mouthPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // HAIR
  // ---------------------------------------------------------------------------
  void _paintHair(Canvas canvas, double cx, double headY, double headR, double w, double h) {
    // 3D Volumetric Swept-Parted Hair (Modern styled academic mentor hair)
    final hairPath = Path()
      // Left side curve behind ear
      ..moveTo(cx - (headR * 1.05), headY)
      ..cubicTo(
        cx - (headR * 1.15),
        headY - (headR * 0.85),
        cx - (headR * 0.55),
        headY - (headR * 1.35),
        cx,
        headY - (headR * 1.25),
      )
      // Top crest volume with side-part crest
      ..cubicTo(
        cx + (headR * 0.45),
        headY - (headR * 1.38),
        cx + (headR * 1.15),
        headY - (headR * 0.90),
        cx + (headR * 1.05),
        headY,
      )
      // Right temple sweep
      ..quadraticBezierTo(cx + (headR * 0.85), headY - (headR * 0.35), cx + (headR * 0.55), headY - (headR * 0.30))
      // Forehead swept fringe (parted on the left, swooping across forehead)
      ..quadraticBezierTo(cx + (headR * 0.20), headY - (headR * 0.55), cx - (headR * 0.15), headY - (headR * 0.25))
      ..quadraticBezierTo(cx - (headR * 0.65), headY - (headR * 0.40), cx - (headR * 1.05), headY)
      ..close();

    // 3D Hair Shading Gradient
    final hairGradient = LinearGradient(
      begin: const Alignment(-0.6, -0.9),
      end: const Alignment(0.7, 1.0),
      colors: const [
        Color(0xFF5A3324), // Sheen highlight
        Color(0xFF3A1E14), // Modern dark warm brown
        Color(0xFF20120D), // Deep shadow
      ],
      stops: const [0.0, 0.50, 1.0],
    );

    canvas.drawPath(
      hairPath,
      Paint()
        ..shader = hairGradient.createShader(hairPath.getBounds())
        ..style = PaintingStyle.fill,
    );

    // Front sweeping hair highlight streak
    final highlightPath = Path()
      ..moveTo(cx - (headR * 0.25), headY - (headR * 1.05))
      ..quadraticBezierTo(cx + (headR * 0.15), headY - (headR * 1.18), cx + (headR * 0.55), headY - (headR * 0.85))
      ..quadraticBezierTo(cx + (headR * 0.15), headY - (headR * 1.00), cx - (headR * 0.25), headY - (headR * 1.05));

    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = const Color(0xFF7C4A36).withValues(alpha: 0.65)
        ..style = PaintingStyle.fill,
    );
  }

  // ---------------------------------------------------------------------------
  // 8. SIGNATURE MAGIC GESTURE SPARKLES
  // ---------------------------------------------------------------------------
  void _paintMagicSparkles(Canvas canvas, Offset handCenter, double w, double h) {
    final progress = (pose == AcadexAssistantPose.magic)
        ? (magicSparkleProgress > 0 ? magicSparkleProgress : (poseProgress * 2.0).clamp(0.0, 1.0))
        : magicSparkleProgress;

    if (progress <= 0.01) return;

    // Expanding Luminous Cyan & Sapphire Pulse Ring
    final maxRingR = w * 0.28;
    final ringRadius = maxRingR * progress;
    final ringAlpha = (1.0 - progress).clamp(0.0, 1.0) * 0.75;

    final ringPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF67E8F9).withValues(alpha: ringAlpha),
          const Color(0xFF3B82F6).withValues(alpha: ringAlpha * 0.5),
          Colors.transparent,
        ],
        stops: const [0.85, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: handCenter, radius: ringRadius + 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(handCenter, ringRadius, ringPaint);

    // Radiating 4-Pointed Starlets and Shimmering Orbs
    final starCount = 8;
    for (int i = 0; i < starCount; i++) {
      final angle = (i * (2 * math.pi / starCount)) + (progress * 1.5);
      final dist = (w * 0.08) + (progress * (w * 0.20) * (0.8 + (0.4 * math.sin(i * 1.7))));
      final starCenter = handCenter.translate(math.cos(angle) * dist, math.sin(angle) * dist);
      final starSize = (w * 0.035) * (1.0 - (progress * 0.5));
      final starAlpha = (1.0 - progress).clamp(0.0, 1.0);

      if (i % 2 == 0) {
        // 4-pointed radiant starlet
        _draw4PointStar(
          canvas,
          starCenter,
          starSize,
          const Color(0xFF67E8F9).withValues(alpha: starAlpha),
          angle,
        );
      } else {
        // Glowing stardust orb
        canvas.drawCircle(
          starCenter,
          starSize * 0.45,
          Paint()
            ..color = const Color(0xFF60A5FA).withValues(alpha: starAlpha)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _draw4PointStar(Canvas canvas, Offset center, double size, Color color, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -size)
      ..quadraticBezierTo(0, 0, size, 0)
      ..quadraticBezierTo(0, 0, 0, size)
      ..quadraticBezierTo(0, 0, -size, 0)
      ..quadraticBezierTo(0, 0, 0, -size)
      ..close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AcadexAssistantPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.expression != expression ||
        oldDelegate.gazeDirection != gazeDirection ||
        oldDelegate.poseProgress != poseProgress ||
        oldDelegate.breathingValue != breathingValue ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.visibility != visibility ||
        oldDelegate.magicSparkleProgress != magicSparkleProgress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.enableShadow != enableShadow ||
        oldDelegate.stylusTarget != stylusTarget;
  }
}

class _ArmIKSolution {
  final double armAngle;
  final double elbowAngle;
  final double handAngle;

  const _ArmIKSolution({
    required this.armAngle,
    required this.elbowAngle,
    this.handAngle = 0.0,
  });
}
