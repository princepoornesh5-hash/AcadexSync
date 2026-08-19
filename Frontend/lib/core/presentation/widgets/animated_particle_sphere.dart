import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Preset variants for the 3D Particle Sphere.
enum ParticleSphereVariant {
  login,
  splash,
  dashboard,
}

/// Internal descriptor for a 3D spherical particle generated deterministically.
class _SphereParticle3D {
  final double x;
  final double y;
  final double z;
  final double baseRadius;
  final double baseBrightness;
  final double orbitPhase;
  final bool isHighlight;

  const _SphereParticle3D({
    required this.x,
    required this.y,
    required this.z,
    required this.baseRadius,
    required this.baseBrightness,
    required this.orbitPhase,
    required this.isHighlight,
  });
}

/// Three-Dimensional Spherical Particle Background for Acadex.
///
/// Shared across Login, Splash, and all User Dashboards (Super Admin, College Admin,
/// HOD, Faculty, Student).
///
/// Features:
/// - Deterministic Fibonacci sphere volume distribution
/// - True 3D rotation matrix & perspective projection
/// - Light Mode (vibrant deep sapphire & cobalt particles on pale slate canvas)
/// - Dark Mode (luminous cyan & soft indigo-white particles on deep space navy canvas)
/// - Smooth 250ms animated transitions on theme changes
/// - Responsive density & positioning per screen variant
/// - RepaintBoundary + IgnorePointer isolation for 60fps performance
class AnimatedParticleSphereBackground extends StatefulWidget {
  final Widget? child;
  final ParticleSphereVariant variant;
  final Alignment? sphereAlignment;
  final double? customSphereRadius;
  final double? rotationDurationSeconds;
  final double? intensityMultiplier;
  final bool enableMouseParallax;
  final bool drawBackground;

  const AnimatedParticleSphereBackground({
    super.key,
    this.child,
    this.variant = ParticleSphereVariant.login,
    this.sphereAlignment,
    this.customSphereRadius,
    this.rotationDurationSeconds,
    this.intensityMultiplier,
    this.enableMouseParallax = true,
    this.drawBackground = true,
  });

  @override
  State<AnimatedParticleSphereBackground> createState() =>
      _AnimatedParticleSphereBackgroundState();
}

class _AnimatedParticleSphereBackgroundState
    extends State<AnimatedParticleSphereBackground>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _themeController;
  Offset? _mousePos;
  List<_SphereParticle3D>? _cachedParticles;
  int _lastParticleCount = 0;
  bool _isDarkCurrent = true;

  bool get _isTestEnvironment {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('Test');
  }

  double get _effectiveRotationDuration {
    if (widget.rotationDurationSeconds != null) {
      return widget.rotationDurationSeconds!;
    }
    switch (widget.variant) {
      case ParticleSphereVariant.dashboard:
        return 52.0; // Majestic slow ambient rotation for dashboards
      case ParticleSphereVariant.splash:
        return 28.0;
      case ParticleSphereVariant.login:
        return 32.0;
    }
  }

  double get _effectiveIntensity {
    if (widget.intensityMultiplier != null) {
      return widget.intensityMultiplier!;
    }
    switch (widget.variant) {
      case ParticleSphereVariant.dashboard:
        return 0.72; // Calibrated ambient intensity for readability
      case ParticleSphereVariant.splash:
        return 1.0;
      case ParticleSphereVariant.login:
        return 1.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _effectiveRotationDuration.toInt()),
    );

    _themeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0, // Default to dark mode state
    );

    if (!_isTestEnvironment) {
      _rotationController.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark != _isDarkCurrent) {
      _isDarkCurrent = isDark;
      if (isDark) {
        _themeController.forward();
      } else {
        _themeController.reverse();
      }
    } else {
      _themeController.value = isDark ? 1.0 : 0.0;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  int _resolveParticleCount(double screenWidth) {
    if (widget.variant == ParticleSphereVariant.dashboard) {
      if (screenWidth < 640) return 380; // Mobile dashboard
      if (screenWidth < 1024) return 650; // Tablet dashboard
      return 1100; // Desktop dashboard
    } else {
      if (screenWidth < 640) return 450; // Mobile
      if (screenWidth < 1024) return 800; // Tablet
      return 1400; // Desktop
    }
  }

  List<_SphereParticle3D> _generateParticles(int count) {
    if (_cachedParticles != null && _lastParticleCount == count) {
      return _cachedParticles!;
    }

    final rand = math.Random(42); // Deterministic seed
    final list = <_SphereParticle3D>[];
    const goldenRatio = 1.618033988749895;

    for (int i = 0; i < count; i++) {
      // Fibonacci sphere distribution for uniform spherical coverage
      final y = 1.0 - (i / (count - 1)) * 2.0; // range [-1, 1]
      final radiusAtY = math.sqrt(math.max(0.0, 1.0 - y * y));
      final theta = 2.0 * math.pi * i / goldenRatio;

      final nx = math.cos(theta) * radiusAtY;
      final nz = math.sin(theta) * radiusAtY;

      // Volumetric depth jitter: distribute between core and outer shell
      // 65% near outer surface (r: 0.85 - 1.02), 35% inner volume (r: 0.30 - 0.85)
      final isOuter = rand.nextDouble() < 0.65;
      final double r;
      if (isOuter) {
        r = 0.85 + rand.nextDouble() * 0.18;
      } else {
        r = 0.30 + math.pow(rand.nextDouble(), 0.6) * 0.55;
      }

      // Small high-frequency organic offset
      final px = (nx * r) + (rand.nextDouble() - 0.5) * 0.04;
      final py = (y * r) + (rand.nextDouble() - 0.5) * 0.04;
      final pz = (nz * r) + (rand.nextDouble() - 0.5) * 0.04;

      final isHighlight = rand.nextDouble() < 0.035; // Top 3.5% bright nodes
      final double baseSize;
      final double baseBright;

      if (isHighlight) {
        baseSize = 1.8 + rand.nextDouble() * 0.6;
        baseBright = 0.85 + rand.nextDouble() * 0.15;
      } else if (rand.nextDouble() < 0.22) {
        // Medium bright (22%)
        baseSize = 1.2 + rand.nextDouble() * 0.5;
        baseBright = 0.55 + rand.nextDouble() * 0.25;
      } else {
        // Tiny ambient points (74.5%)
        baseSize = 0.6 + rand.nextDouble() * 0.45;
        baseBright = 0.20 + rand.nextDouble() * 0.25;
      }

      list.add(
        _SphereParticle3D(
          x: px,
          y: py,
          z: pz,
          baseRadius: baseSize,
          baseBrightness: baseBright,
          orbitPhase: rand.nextDouble() * 2.0 * math.pi,
          isHighlight: isHighlight,
        ),
      );
    }

    _cachedParticles = list;
    _lastParticleCount = count;
    return list;
  }

  Alignment _resolveAlignment(double screenWidth) {
    if (widget.sphereAlignment != null) {
      return widget.sphereAlignment!;
    }
    switch (widget.variant) {
      case ParticleSphereVariant.dashboard:
        // Position upper-right on desktop to avoid blocking left-aligned cards
        return screenWidth >= 1024
            ? const Alignment(0.62, -0.32)
            : const Alignment(0.25, -0.40);
      case ParticleSphereVariant.login:
        return screenWidth >= 900
            ? const Alignment(-0.35, 0.0)
            : Alignment.center;
      case ParticleSphereVariant.splash:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.of(context).disableAnimations || _isTestEnvironment;

    if (reduceMotion && _rotationController.isAnimating) {
      _rotationController.stop();
    } else if (!reduceMotion && !_rotationController.isAnimating) {
      _rotationController.repeat();
    }

    final sphereWidget = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final h = constraints.maxHeight > 0
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        final particleCount = _resolveParticleCount(w);
        final particles = _generateParticles(particleCount);

        // Calculate responsive radius
        final minDim = math.min(w, h);
        final double baseRadius;
        if (widget.customSphereRadius != null) {
          baseRadius = widget.customSphereRadius!;
        } else if (widget.variant == ParticleSphereVariant.dashboard) {
          baseRadius = w < 640
              ? minDim * 0.44
              : w < 1024
                  ? minDim * 0.48
                  : minDim * 0.54;
        } else {
          baseRadius = w < 640
              ? minDim * 0.48
              : w < 1024
                  ? minDim * 0.52
                  : minDim * 0.58;
        }

        final sphereCenter = Offset(
          (w / 2) + (_resolveAlignment(w).x * (w / 4)),
          (h / 2) + (_resolveAlignment(w).y * (h / 4)),
        );

        final canvas = RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_rotationController, _themeController]),
            builder: (context, _) {
              return CustomPaint(
                size: Size(w, h),
                painter: _ParticleSpherePainter(
                  progress: reduceMotion ? 0.0 : _rotationController.value,
                  themeProgress: _themeController.value,
                  particles: particles,
                  sphereCenter: sphereCenter,
                  sphereRadius: baseRadius,
                  intensity: _effectiveIntensity,
                  drawBackground: widget.drawBackground,
                  mousePos: widget.enableMouseParallax ? _mousePos : null,
                  screenSize: Size(w, h),
                ),
              );
            },
          ),
        );

        return IgnorePointer(child: canvas);
      },
    );

    final hasPointerSupport = widget.enableMouseParallax &&
        (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    Widget backgroundLayer = sphereWidget;
    if (hasPointerSupport) {
      backgroundLayer = MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePos = event.localPosition;
          });
        },
        onExit: (_) {
          if (_mousePos != null) {
            setState(() {
              _mousePos = null;
            });
          }
        },
        child: sphereWidget,
      );
    }

    if (widget.child == null) {
      return backgroundLayer;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        backgroundLayer,
        widget.child!,
      ],
    );
  }
}

/// Custom painter rendering the 3D particle sphere with full Light & Dark mode adaptation.
class _ParticleSpherePainter extends CustomPainter {
  final double progress;
  final double themeProgress; // 0.0 = Light Mode, 1.0 = Dark Mode
  final List<_SphereParticle3D> particles;
  final Offset sphereCenter;
  final double sphereRadius;
  final double intensity;
  final bool drawBackground;
  final Offset? mousePos;
  final Size screenSize;

  _ParticleSpherePainter({
    required this.progress,
    required this.themeProgress,
    required this.particles,
    required this.sphereCenter,
    required this.sphereRadius,
    required this.intensity,
    required this.drawBackground,
    required this.mousePos,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Draw Atmospheric Backdrop (Light or Dark)
    if (drawBackground) {
      _drawAtmosphericBackdrop(canvas, size);
    } else {
      // Draw subtle radial glow aura only
      _drawSubtleSphereAura(canvas);
    }

    // 2. Compute 3D Rotation Angles
    final rotationAngleY = progress * 2.0 * math.pi;
    final subtleTiltX = 0.22 * math.sin(progress * 2.0 * math.pi * 0.5);
    final subtleDriftZ = 0.08 * math.cos(progress * 2.0 * math.pi * 0.3);

    // Mouse parallax angle offset (max ~3.5 degrees)
    double mouseTiltY = 0.0;
    double mouseTiltX = 0.0;
    if (mousePos != null && screenSize.width > 0 && screenSize.height > 0) {
      final normX = (mousePos!.dx / screenSize.width) - 0.5; // [-0.5, 0.5]
      final normY = (mousePos!.dy / screenSize.height) - 0.5;
      mouseTiltY = normX * 0.08; // ~4.5 degrees
      mouseTiltX = -normY * 0.08;
    }

    final totalAngleY = rotationAngleY + mouseTiltY;
    final totalAngleX = subtleTiltX + mouseTiltX;
    final totalAngleZ = subtleDriftZ;

    final cosY = math.cos(totalAngleY);
    final sinY = math.sin(totalAngleY);
    final cosX = math.cos(totalAngleX);
    final sinX = math.sin(totalAngleX);
    final cosZ = math.cos(totalAngleZ);
    final sinZ = math.sin(totalAngleZ);

    // Directional lighting unit vector (from top-left-front)
    const lx = -0.57735;
    const ly = -0.57735;
    const lz = -0.57735;

    // Perspective camera distance (in sphere radius units)
    const cameraDist = 2.4;

    final pointPaint = Paint()..isAntiAlias = true;
    final glowPaint = Paint()..isAntiAlias = true;

    // 3. Transform, Project, and Render Particles
    for (final p in particles) {
      // Subtle orbital harmonic breathing
      final orbitT = progress * 2.0 * math.pi * 1.5 + p.orbitPhase;
      final harmonicWiggle = math.sin(orbitT) * 0.015;
      final px = p.x + (p.x * harmonicWiggle);
      final py = p.y + (p.y * harmonicWiggle);
      final pz = p.z + (p.z * harmonicWiggle);

      // Rotate around Y-axis
      final x1 = px * cosY + pz * sinY;
      final y1 = py;
      final z1 = -px * sinY + pz * cosY;

      // Rotate around X-axis
      final x2 = x1;
      final y2 = y1 * cosX - z1 * sinX;
      final z2 = y1 * sinX + z1 * cosX;

      // Rotate around Z-axis
      final x3 = x2 * cosZ - y2 * sinZ;
      final y3 = x2 * sinZ + y2 * cosZ;
      final z3 = z2; // [-1.05, 1.05]

      // Perspective Projection
      final perspective = cameraDist / (cameraDist + z3);
      final screenX = sphereCenter.dx + (x3 * sphereRadius * perspective);
      final screenY = sphereCenter.dy + (y3 * sphereRadius * perspective);

      // Depth metric: 0.0 (closest to camera) to 1.0 (farthest away)
      final depthNorm = ((z3 + 1.05) / 2.1).clamp(0.0, 1.0);

      // Directional diffuse lighting (dot product with normal)
      final normalDotLight = -(x3 * lx + y3 * ly + z3 * lz);
      final diffuseLight = normalDotLight.clamp(0.0, 1.0);

      // Depth-based size attenuation
      final renderRadius = math.max(
        0.4,
        p.baseRadius * perspective * (1.20 - 0.45 * depthNorm),
      );

      final frontBoost = (1.0 - depthNorm);
      final lightFactor = 0.35 + (0.65 * diffuseLight);

      // Opacity calculation based on depth, lighting, theme, and intensity
      final darkOpacity = (p.baseBrightness *
              (0.08 + 0.85 * frontBoost * lightFactor) *
              intensity)
          .clamp(0.03, 0.95);

      final lightOpacity = (p.baseBrightness *
              (0.12 + 0.70 * frontBoost * lightFactor) *
              (intensity * 1.1))
          .clamp(0.06, 0.85);

      final dynamicOpacity =
          lightOpacity + (darkOpacity - lightOpacity) * themeProgress;

      // --- COLOR PALETTE DEFINITION ---
      // Dark Mode Palette: Luminous Cyan & White front, Deep Sapphire rear
      final Color darkColor;
      if (p.isHighlight) {
        darkColor = Color.lerp(
          const Color(0xFF67E8F9), // Bright Cyan
          const Color(0xFFFFFFFF), // Pure White
          frontBoost * lightFactor,
        )!;
      } else if (frontBoost > 0.5) {
        darkColor = Color.lerp(
          const Color(0xFF818CF8), // Indigo 400
          const Color(0xFFE0E7FF), // Indigo 100
          (frontBoost - 0.5) * 2.0 * lightFactor,
        )!;
      } else {
        darkColor = Color.lerp(
          const Color(0xFF312E81), // Indigo 900
          const Color(0xFF6366F1), // Indigo 500
          frontBoost * 2.0,
        )!;
      }

      // Light Mode Palette: Deep Sapphire & Vibrant Cobalt front, Slate-Blue rear
      final Color lightColor;
      if (p.isHighlight) {
        lightColor = Color.lerp(
          const Color(0xFF1D4ED8), // Cobalt Blue 700
          const Color(0xFF0284C7), // Sky 600
          frontBoost * lightFactor,
        )!;
      } else if (frontBoost > 0.5) {
        lightColor = Color.lerp(
          const Color(0xFF2563EB), // Royal Blue 600
          const Color(0xFF1E3A8A), // Deep Sapphire Blue 900
          (frontBoost - 0.5) * 2.0 * lightFactor,
        )!;
      } else {
        lightColor = Color.lerp(
          const Color(0xFF64748B), // Slate 500
          const Color(0xFF3B82F6), // Blue 500
          frontBoost * 2.0,
        )!;
      }

      // Smooth Theme Interpolation
      final finalColor = Color.lerp(lightColor, darkColor, themeProgress)!;

      // Draw soft outer bloom halo for highlight nodes
      if (p.isHighlight) {
        final glowAlpha =
            (dynamicOpacity * (0.22 + 0.10 * themeProgress)).clamp(0.0, 1.0);
        glowPaint.color = finalColor.withValues(alpha: glowAlpha);
        canvas.drawCircle(
          Offset(screenX, screenY),
          renderRadius * 2.6,
          glowPaint,
        );
      }

      pointPaint.color = finalColor.withValues(alpha: dynamicOpacity);
      canvas.drawCircle(Offset(screenX, screenY), renderRadius, pointPaint);
    }
  }

  /// Draws the complete atmospheric backdrop for full-page screens (Login/Splash).
  void _drawAtmosphericBackdrop(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Dark Mode Colors
    const darkColors = [
      Color(0xFF020617), // Slate 950
      Color(0xFF070C1E), // Dark Navy
      Color(0xFF0B132B), // Rich Deep Sapphire
      Color(0xFF020617),
    ];

    // Light Mode Colors
    const lightColors = [
      Color(0xFFF8FAFC), // Slate 50
      Color(0xFFF1F5F9), // Slate 100
      Color(0xFFE2E8F0), // Slate 200
      Color(0xFFF8FAFC),
    ];

    final currentColors = List<Color>.generate(4, (i) {
      return Color.lerp(lightColors[i], darkColors[i], themeProgress)!;
    });

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: currentColors,
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    _drawSubtleSphereAura(canvas);
  }

  /// Draws subtle radial illumination behind the sphere center.
  void _drawSubtleSphereAura(Canvas canvas) {
    final glowRadius = sphereRadius * 1.55;
    final glowRect = Rect.fromCircle(center: sphereCenter, radius: glowRadius);

    final darkGlow1 = const Color(0xFF38BDF8).withValues(alpha: 0.08 * intensity);
    final darkGlow2 = const Color(0xFF6366F1).withValues(alpha: 0.05 * intensity);

    final lightGlow1 = const Color(0xFF0284C7).withValues(alpha: 0.06 * intensity);
    final lightGlow2 = const Color(0xFF3B82F6).withValues(alpha: 0.03 * intensity);

    final g1 = Color.lerp(lightGlow1, darkGlow1, themeProgress)!;
    final g2 = Color.lerp(lightGlow2, darkGlow2, themeProgress)!;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [g1, g2, Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(glowRect);
    canvas.drawCircle(sphereCenter, glowRadius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ParticleSpherePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.themeProgress != themeProgress ||
        oldDelegate.sphereCenter != sphereCenter ||
        oldDelegate.sphereRadius != sphereRadius ||
        oldDelegate.intensity != intensity ||
        oldDelegate.drawBackground != drawBackground ||
        oldDelegate.mousePos != mousePos ||
        oldDelegate.screenSize != screenSize;
  }
}
