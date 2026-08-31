import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/domain/models/auth_state.dart';
import '../../../features/auth/domain/models/role_enum.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'super_admin_gradient_background.dart';

bool _isGradientRole(AuthState authState) {
  if (authState is AuthAuthenticated) {
    return authState.user.role == AppRole.superAdmin ||
        authState.user.role == AppRole.collegeAdmin ||
        authState.user.role == AppRole.hod ||
        authState.user.role == AppRole.faculty ||
        authState.user.role == AppRole.student;
  }
  return false;
}

/// Reusable adaptive text component for content sitting DIRECTLY on the unified gradient.
/// Operates as a strict TWO-STATE system (WHITE vs DARK) with dead-band hysteresis.
/// Only transitions (350ms easeInOutCubic) when contrast threshold is crossed. Never settles into gray.
class AcadexAdaptiveGradientText extends ConsumerStatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final Color darkColor;
  final Color lightColor;
  final bool isSecondary;

  const AcadexAdaptiveGradientText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.darkColor = const Color(0xFF07111F),
    this.lightColor = const Color(0xFFFFFFFF),
    this.isSecondary = false,
  });

  @override
  ConsumerState<AcadexAdaptiveGradientText> createState() => _AcadexAdaptiveGradientTextState();
}

class _AcadexAdaptiveGradientTextState extends ConsumerState<AcadexAdaptiveGradientText> {
  ScrollPosition? _scrollPosition;
  Animation<double>? _routeAnimation;
  AcadexAdaptiveTextMode _currentMode = AcadexAdaptiveTextMode.light;
  Color? _displayedColor;
  Color? _targetColor;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detachScrollListener();
    _attachScrollListener();

    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = ModalRoute.of(context)?.animation;
    _routeAnimation?.addListener(_onRouteAnimation);

    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluatePosition());
  }

  void _onRouteAnimation() {
    if (_routeAnimation?.isCompleted ?? false) {
      _evaluatePosition();
    }
  }

  @override
  void didUpdateWidget(covariant AcadexAdaptiveGradientText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _evaluatePosition();
  }

  @override
  void dispose() {
    _detachScrollListener();
    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = null;
    super.dispose();
  }

  void _attachScrollListener() {
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_onScroll);
  }

  void _detachScrollListener() {
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = null;
  }

  void _onScroll() {
    _evaluatePosition();
  }

  void _evaluatePosition() {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (!_isGradientRole(authState)) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize && renderBox.attached) {
      final globalOffset = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.sizeOf(context).height;
      if (screenHeight > 0) {
        final centerY = globalOffset.dy + (renderBox.size.height / 2.0);
        final t = (centerY / screenHeight).clamp(0.0, 1.0);

        final effectiveLight = widget.isSecondary ? const Color(0xFFCCE6FF) : widget.lightColor;
        final effectiveDark = widget.isSecondary ? const Color(0xFF334155) : widget.darkColor;

        if (!_initialized) {
          _initialized = true;
          final luminance = AcadexSuperAdminGradient.luminanceAt(t);
          final initialMode = luminance >= 0.30 ? AcadexAdaptiveTextMode.dark : AcadexAdaptiveTextMode.light;
          _currentMode = initialMode;
          _targetColor = initialMode == AcadexAdaptiveTextMode.light ? effectiveLight : effectiveDark;
          _displayedColor = _targetColor;
          if (mounted) setState(() {});
          return;
        }

        // Two-state hysteresis evaluation:
        final newMode = AcadexSuperAdminGradient.evaluateMode(
          t: t,
          currentMode: _currentMode,
        );

        // ONLY trigger state change and animation when the threshold is crossed
        if (newMode != _currentMode) {
          final newTargetColor = newMode == AcadexAdaptiveTextMode.light ? effectiveLight : effectiveDark;
          setState(() {
            _currentMode = newMode;
            _targetColor = newTargetColor;
          });
        }
      }
    } else if (!_initialized) {
      // Re-schedule evaluation if layout is not ready on the initial frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _evaluatePosition());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGradRole = _isGradientRole(authState);

    // For non-gradient roles, render normal text with standard style
    if (!isGradRole) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
      );
    }

    // If ScrollPosition became available after didChangeDependencies, attach it
    final currentScroll = Scrollable.maybeOf(context)?.position;
    if (currentScroll != null && currentScroll != _scrollPosition) {
      _detachScrollListener();
      _scrollPosition = currentScroll;
      _scrollPosition?.addListener(_onScroll);
    }

    final effectiveLight = widget.isSecondary ? const Color(0xFFCCE6FF) : widget.lightColor;
    final effectiveDark = widget.isSecondary ? const Color(0xFF334155) : widget.darkColor;
    final target = _targetColor ?? (_currentMode == AcadexAdaptiveTextMode.light ? effectiveLight : effectiveDark);
    final beginColor = _displayedColor ?? target;

    return TweenAnimationBuilder<Color?>(
      key: ValueKey(target.toARGB32()),
      tween: ColorTween(begin: beginColor, end: target),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      onEnd: () {
        _displayedColor = target;
      },
      builder: (context, animatedColor, child) {
        _displayedColor = animatedColor ?? target;
        final finalStyle = (widget.style ?? const TextStyle()).copyWith(
          color: _displayedColor,
        );

        return Text(
          widget.text,
          style: finalStyle,
          textAlign: widget.textAlign,
          overflow: widget.overflow,
          maxLines: widget.maxLines,
        );
      },
    );
  }
}

/// Adaptive icon component with strict two-state threshold switching.
class AcadexAdaptiveGradientIcon extends ConsumerStatefulWidget {
  final IconData icon;
  final double? size;
  final Color darkColor;
  final Color lightColor;

  const AcadexAdaptiveGradientIcon(
    this.icon, {
    super.key,
    this.size,
    this.darkColor = const Color(0xFF07111F),
    this.lightColor = const Color(0xFFFFFFFF),
  });

  @override
  ConsumerState<AcadexAdaptiveGradientIcon> createState() => _AcadexAdaptiveGradientIconState();
}

class _AcadexAdaptiveGradientIconState extends ConsumerState<AcadexAdaptiveGradientIcon> {
  ScrollPosition? _scrollPosition;
  Animation<double>? _routeAnimation;
  AcadexAdaptiveTextMode _currentMode = AcadexAdaptiveTextMode.light;
  Color? _displayedColor;
  Color? _targetColor;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detachScrollListener();
    _attachScrollListener();

    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = ModalRoute.of(context)?.animation;
    _routeAnimation?.addListener(_onRouteAnimation);

    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluatePosition());
  }

  void _onRouteAnimation() {
    if (_routeAnimation?.isCompleted ?? false) {
      _evaluatePosition();
    }
  }

  @override
  void didUpdateWidget(covariant AcadexAdaptiveGradientIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _evaluatePosition();
  }

  @override
  void dispose() {
    _detachScrollListener();
    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = null;
    super.dispose();
  }

  void _attachScrollListener() {
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_onScroll);
  }

  void _detachScrollListener() {
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = null;
  }

  void _onScroll() {
    _evaluatePosition();
  }

  void _evaluatePosition() {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (!_isGradientRole(authState)) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize && renderBox.attached) {
      final globalOffset = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.sizeOf(context).height;
      if (screenHeight > 0) {
        final centerY = globalOffset.dy + (renderBox.size.height / 2.0);
        final t = (centerY / screenHeight).clamp(0.0, 1.0);

        if (!_initialized) {
          _initialized = true;
          final luminance = AcadexSuperAdminGradient.luminanceAt(t);
          final initialMode = luminance >= 0.30 ? AcadexAdaptiveTextMode.dark : AcadexAdaptiveTextMode.light;
          _currentMode = initialMode;
          _targetColor = initialMode == AcadexAdaptiveTextMode.light ? widget.lightColor : widget.darkColor;
          _displayedColor = _targetColor;
          if (mounted) setState(() {});
          return;
        }

        final newMode = AcadexSuperAdminGradient.evaluateMode(
          t: t,
          currentMode: _currentMode,
        );

        if (newMode != _currentMode) {
          final newTargetColor = newMode == AcadexAdaptiveTextMode.light ? widget.lightColor : widget.darkColor;
          setState(() {
            _currentMode = newMode;
            _targetColor = newTargetColor;
          });
        }
      }
    } else if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _evaluatePosition());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGradRole = _isGradientRole(authState);

    if (!isGradRole) {
      return Icon(widget.icon, size: widget.size);
    }

    final currentScroll = Scrollable.maybeOf(context)?.position;
    if (currentScroll != null && currentScroll != _scrollPosition) {
      _detachScrollListener();
      _scrollPosition = currentScroll;
      _scrollPosition?.addListener(_onScroll);
    }

    final target = _targetColor ?? (_currentMode == AcadexAdaptiveTextMode.light ? widget.lightColor : widget.darkColor);
    final beginColor = _displayedColor ?? target;

    return TweenAnimationBuilder<Color?>(
      key: ValueKey(target.toARGB32()),
      tween: ColorTween(begin: beginColor, end: target),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      onEnd: () {
        _displayedColor = target;
      },
      builder: (context, animatedColor, child) {
        _displayedColor = animatedColor ?? target;
        return Icon(
          widget.icon,
          size: widget.size,
          color: _displayedColor,
        );
      },
    );
  }
}

/// Adaptive builder for compound elements directly on the gradient with strict two-state hysteresis.
class AcadexAdaptiveGradientBuilder extends ConsumerStatefulWidget {
  final Widget Function(BuildContext context, Color primaryColor, Color secondaryColor, Color actionColor) builder;

  const AcadexAdaptiveGradientBuilder({
    super.key,
    required this.builder,
  });

  @override
  ConsumerState<AcadexAdaptiveGradientBuilder> createState() => _AcadexAdaptiveGradientBuilderState();
}

class _AcadexAdaptiveGradientBuilderState extends ConsumerState<AcadexAdaptiveGradientBuilder> {
  ScrollPosition? _scrollPosition;
  Animation<double>? _routeAnimation;
  AcadexAdaptiveTextMode _currentMode = AcadexAdaptiveTextMode.light;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_onScroll);

    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = ModalRoute.of(context)?.animation;
    _routeAnimation?.addListener(_onRouteAnimation);

    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluatePosition());
  }

  void _onRouteAnimation() {
    if (_routeAnimation?.isCompleted ?? false) {
      _evaluatePosition();
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = null;
    super.dispose();
  }

  void _onScroll() {
    _evaluatePosition();
  }

  void _evaluatePosition() {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (!_isGradientRole(authState)) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize && renderBox.attached) {
      final globalOffset = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.sizeOf(context).height;
      if (screenHeight > 0) {
        final centerY = globalOffset.dy + (renderBox.size.height / 2.0);
        final t = (centerY / screenHeight).clamp(0.0, 1.0);

        if (!_initialized) {
          _initialized = true;
          final luminance = AcadexSuperAdminGradient.luminanceAt(t);
          final initialMode = luminance >= 0.30 ? AcadexAdaptiveTextMode.dark : AcadexAdaptiveTextMode.light;
          _currentMode = initialMode;
          if (mounted) setState(() {});
          return;
        }

        final newMode = AcadexSuperAdminGradient.evaluateMode(
          t: t,
          currentMode: _currentMode,
        );

        if (newMode != _currentMode) {
          setState(() {
            _currentMode = newMode;
          });
        }
      }
    } else if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _evaluatePosition());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGradRole = _isGradientRole(authState);

    if (!isGradRole) {
      return widget.builder(
        context,
        Theme.of(context).colorScheme.onSurface,
        Theme.of(context).colorScheme.onSurfaceVariant,
        Theme.of(context).primaryColor,
      );
    }

    final currentScroll = Scrollable.maybeOf(context)?.position;
    if (currentScroll != null && currentScroll != _scrollPosition) {
      _scrollPosition?.removeListener(_onScroll);
      _scrollPosition = currentScroll;
      _scrollPosition?.addListener(_onScroll);
    }

    final isLight = _currentMode == AcadexAdaptiveTextMode.light;
    final primary = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF07111F);
    final secondary = isLight ? const Color(0xFFCCE6FF) : const Color(0xFF334155);
    final action = isLight ? const Color(0xFF93C5FD) : const Color(0xFF0066CC);

    return widget.builder(context, primary, secondary, action);
  }
}
