import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Density setting for the ambient particle field.
enum AcadexAmbientDensity {
  subtle,
  standard,
  dense,
  none;

  int particleCount(double screenWidth) {
    if (this == AcadexAmbientDensity.none) return 0;

    final isMobile = screenWidth < 640;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    switch (this) {
      case AcadexAmbientDensity.subtle:
        if (isMobile) return 30;
        if (isTablet) return 55;
        return 80;
      case AcadexAmbientDensity.standard:
        if (isMobile) return 45;
        if (isTablet) return 75;
        return 110;
      case AcadexAmbientDensity.dense:
        if (isMobile) return 65;
        if (isTablet) return 100;
        return 140;
      case AcadexAmbientDensity.none:
        return 0;
    }
  }
}

/// Internal particle descriptor generated deterministically.
class _ParticleSeed {
  final double relX;
  final double relY;
  final double radius;
  final double opacity;
  final double speed;
  final double amplitudeX;
  final double amplitudeY;
  final double phaseX;
  final double phaseY;
  final int depthLayer; // 0: background, 1: midground, 2: foreground

  const _ParticleSeed({
    required this.relX,
    required this.relY,
    required this.radius,
    required this.opacity,
    required this.speed,
    required this.amplitudeX,
    required this.amplitudeY,
    required this.phaseX,
    required this.phaseY,
    required this.depthLayer,
  });
}

/// Reusable Ambient Background for Acadex.
///
/// Renders a calm, living particle motion field behind UI surfaces using
/// an isolated [CustomPainter] and [RepaintBoundary].
class AcadexAmbientBackground extends StatefulWidget {
  final Widget? child;
  final AcadexAmbientDensity density;
  final Color? particleColor;
  final bool enablePointerInteraction;

  const AcadexAmbientBackground({
    super.key,
    this.child,
    this.density = AcadexAmbientDensity.standard,
    this.particleColor,
    this.enablePointerInteraction = true,
  });

  @override
  State<AcadexAmbientBackground> createState() => _AcadexAmbientBackgroundState();
}

class _AcadexAmbientBackgroundState extends State<AcadexAmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset? _pointerPos;
  List<_ParticleSeed>? _cachedParticles;
  int _lastParticleCount = 0;

  bool get _isTestEnvironment {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('Test');
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    if (!_isTestEnvironment) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ParticleSeed> _getParticles(int count) {
    if (_cachedParticles != null && _lastParticleCount == count) {
      return _cachedParticles!;
    }

    final rand = math.Random(42); // Deterministic seed
    final list = <_ParticleSeed>[];

    for (int i = 0; i < count; i++) {
      // Depth group distribution: 45% background, 35% midground, 20% foreground
      final depthRoll = rand.nextDouble();
      final int depth;
      final double radius;
      final double baseOpacity;
      final double speedFactor;

      if (depthRoll < 0.45) {
        depth = 0;
        radius = 1.0 + rand.nextDouble() * 0.4;
        baseOpacity = 0.06 + rand.nextDouble() * 0.05;
        speedFactor = 0.6 + rand.nextDouble() * 0.2;
      } else if (depthRoll < 0.80) {
        depth = 1;
        radius = 1.4 + rand.nextDouble() * 0.6;
        baseOpacity = 0.10 + rand.nextDouble() * 0.06;
        speedFactor = 0.9 + rand.nextDouble() * 0.25;
      } else {
        depth = 2;
        radius = 2.0 + rand.nextDouble() * 0.6;
        baseOpacity = 0.14 + rand.nextDouble() * 0.08;
        speedFactor = 1.2 + rand.nextDouble() * 0.3;
      }

      list.add(
        _ParticleSeed(
          relX: rand.nextDouble(),
          relY: rand.nextDouble(),
          radius: radius,
          opacity: baseOpacity,
          speed: speedFactor,
          amplitudeX: 18.0 + rand.nextDouble() * 24.0,
          amplitudeY: 14.0 + rand.nextDouble() * 20.0,
          phaseX: rand.nextDouble() * 2 * math.pi,
          phaseY: rand.nextDouble() * 2 * math.pi,
          depthLayer: depth,
        ),
      );
    }

    _cachedParticles = list;
    _lastParticleCount = count;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.density == AcadexAmbientDensity.none) {
      return widget.child ?? const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations || _isTestEnvironment;

    // Respect reduced motion accessibility & test environment
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }

    final baseParticleColor = widget.particleColor ??
        (isDark ? const Color(0xFF818CF8) : AcadexColors.primary);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final count = widget.density.particleCount(screenWidth);
        final particles = _getParticles(count);

        final canvasWidget = RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _AcadexParticlePainter(
                  progress: reduceMotion ? 0.0 : _controller.value,
                  particles: particles,
                  baseColor: baseParticleColor,
                  pointerPos: widget.enablePointerInteraction ? _pointerPos : null,
                  isDark: isDark,
                ),
              );
            },
          ),
        );

        return IgnorePointer(
          child: canvasWidget,
        );
      },
    );

    final hasPointerSupport = widget.enablePointerInteraction &&
        (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    Widget backgroundLayer = content;
    if (hasPointerSupport) {
      backgroundLayer = MouseRegion(
        onHover: (event) {
          setState(() {
            _pointerPos = event.localPosition;
          });
        },
        onExit: (_) {
          if (_pointerPos != null) {
            setState(() {
              _pointerPos = null;
            });
          }
        },
        child: content,
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

/// Custom painter executing organic flow field math without widget tree rebuilds.
class _AcadexParticlePainter extends CustomPainter {
  final double progress;
  final List<_ParticleSeed> particles;
  final Color baseColor;
  final Offset? pointerPos;
  final bool isDark;

  _AcadexParticlePainter({
    required this.progress,
    required this.particles,
    required this.baseColor,
    required this.pointerPos,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..isAntiAlias = true;
    final t = progress * 2 * math.pi;

    for (final p in particles) {
      // Primary wave + secondary harmonic harmonic drift
      final speedT = t * p.speed;
      final dx1 = math.sin(speedT + p.phaseX) * p.amplitudeX;
      final dx2 = math.sin(speedT * 0.7 + p.phaseX) * (p.amplitudeX * 0.3);
      final dy1 = math.cos(speedT * 0.8 + p.phaseY) * p.amplitudeY;
      final dy2 = math.sin(speedT * 1.4 + p.phaseY) * (p.amplitudeY * 0.25);

      double px = (p.relX * size.width) + dx1 + dx2;
      double py = (p.relY * size.height) + dy1 + dy2;

      // Wrap around bounds softly
      if (px < -10) px += size.width + 20;
      if (px > size.width + 10) px -= size.width + 20;
      if (py < -10) py += size.height + 20;
      if (py > size.height + 10) py -= size.height + 20;

      // Desktop subtle pointer displacement (max 4–8px with smooth falloff)
      if (pointerPos != null) {
        final dist = (Offset(px, py) - pointerPos!).distance;
        const maxDist = 120.0;
        if (dist < maxDist && dist > 0) {
          final factor = (1.0 - (dist / maxDist));
          final smoothFactor = factor * factor; // Quadratic falloff
          final angle = math.atan2(py - pointerPos!.dy, px - pointerPos!.dx);
          const maxPush = 6.0;
          px += math.cos(angle) * maxPush * smoothFactor;
          py += math.sin(angle) * maxPush * smoothFactor;
        }
      }

      // Subtle opacity breathing based on depth and harmonic
      final breath = math.sin(speedT * 0.5 + p.phaseX) * 0.15;
      final effectiveOpacity = (p.opacity + (p.opacity * breath)).clamp(0.04, 0.28);

      paint.color = baseColor.withValues(alpha: effectiveOpacity);
      canvas.drawCircle(Offset(px, py), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AcadexParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pointerPos != pointerPos ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.isDark != isDark;
  }
}
