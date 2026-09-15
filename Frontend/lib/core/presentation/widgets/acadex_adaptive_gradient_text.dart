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
/// Operates as a strict TWO-STATE system (WHITE vs DARK NAVY) with dead-band hysteresis.
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

class _AcadexAdaptiveGradientTextState extends ConsumerState<AcadexAdaptiveGradientText>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ScrollPosition? _scrollPosition;
  Animation<double>? _routeAnimation;
  late final AnimationController _controller;
  late final CurvedAnimation _curvedAnimation;
  Animation<Color?>? _colorAnimation;

  AcadexAdaptiveTextMode _currentMode = AcadexAdaptiveTextMode.light;
  Color? _currentColor;
  Color? _targetColor;
  bool _isInitialized = false;
  bool _evaluationScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _currentColor = _targetColor;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detachScrollListener();
    _attachScrollListener();

    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = ModalRoute.of(context)?.animation;
    _routeAnimation?.addListener(_onRouteAnimation);

    _scheduleEvaluation();
  }

  void _onRouteAnimation() {
    if (_routeAnimation?.isCompleted ?? false) {
      _scheduleEvaluation();
    }
  }

  @override
  void didUpdateWidget(covariant AcadexAdaptiveGradientText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text ||
        widget.darkColor != oldWidget.darkColor ||
        widget.lightColor != oldWidget.lightColor ||
        widget.isSecondary != oldWidget.isSecondary) {
      _scheduleEvaluation();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scheduleEvaluation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachScrollListener();
    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = null;
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _attachScrollListener() {
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_onScrollChange);
  }

  void _detachScrollListener() {
    _scrollPosition?.removeListener(_onScrollChange);
    _scrollPosition = null;
  }

  void _onScrollChange() {
    _scheduleEvaluation();
  }

  void _scheduleEvaluation() {
    if (_evaluationScheduled || !mounted) return;
    _evaluationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluationScheduled = false;
      if (mounted) {
        _evaluatePosition();
      }
    });
  }

  void _evaluatePosition() {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (!_isGradientRole(authState)) return;

    final scope = AcadexGradientScope.maybeOf(context);
    if (scope == null) return;

    final gradientBox = scope.gradientKey.currentContext?.findRenderObject() as RenderBox?;
    final textRenderBox = context.findRenderObject() as RenderBox?;

    if (gradientBox == null || !gradientBox.hasSize || !gradientBox.attached ||
        textRenderBox == null || !textRenderBox.hasSize || !textRenderBox.attached) {
      if (!_isInitialized) {
        _scheduleEvaluation();
      }
      return;
    }

    final textCenterGlobal = textRenderBox.localToGlobal(
      Offset(0, textRenderBox.size.height / 2.0),
    );
    final localToGradient = gradientBox.globalToLocal(textCenterGlobal);
    final gradientHeight = gradientBox.size.height;
    if (gradientHeight <= 0) return;

    final t = (localToGradient.dy / gradientHeight).clamp(0.0, 1.0);

    final effectiveLight = widget.isSecondary ? const Color(0xFFCCE6FF) : widget.lightColor;
    final effectiveDark = widget.isSecondary ? const Color(0xFF334155) : widget.darkColor;

    if (!_isInitialized) {
      _isInitialized = true;
      final luminance = AcadexSuperAdminGradient.luminanceAt(t);
      final initialMode = luminance >= 0.30 ? AcadexAdaptiveTextMode.dark : AcadexAdaptiveTextMode.light;
      _currentMode = initialMode;
      _currentColor = initialMode == AcadexAdaptiveTextMode.light ? effectiveLight : effectiveDark;
      _targetColor = _currentColor;
      _colorAnimation = AlwaysStoppedAnimation<Color?>(_currentColor);
      if (mounted) setState(() {});
      return;
    }

    final newMode = AcadexSuperAdminGradient.evaluateMode(
      t: t,
      currentMode: _currentMode,
    );


    if (newMode != _currentMode) {
      final newTarget = newMode == AcadexAdaptiveTextMode.light ? effectiveLight : effectiveDark;
      final beginColor = _colorAnimation?.value ??
          _currentColor ??
          (newMode == AcadexAdaptiveTextMode.light ? effectiveDark : effectiveLight);

      _currentMode = newMode;
      _targetColor = newTarget;
      _currentColor = beginColor;

      _colorAnimation = ColorTween(
        begin: beginColor,
        end: newTarget,
      ).animate(_curvedAnimation);

      _controller.forward(from: 0.0);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGradRole = _isGradientRole(authState);
    final scope = AcadexGradientScope.maybeOf(context);

    // Safe deterministic fallback: when user is not in a gradient role OR content is outside gradient scope
    if (!isGradRole || scope == null) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
      );
    }

    final currentScroll = Scrollable.maybeOf(context)?.position;
    if (currentScroll != null && currentScroll != _scrollPosition) {
      _detachScrollListener();
      _scrollPosition = currentScroll;
      _scrollPosition?.addListener(_onScrollChange);
    }

    final effectiveLight = widget.isSecondary ? const Color(0xFFCCE6FF) : widget.lightColor;
    final effectiveDark = widget.isSecondary ? const Color(0xFF334155) : widget.darkColor;
    final fallbackColor = _currentMode == AcadexAdaptiveTextMode.light ? effectiveLight : effectiveDark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animatedColor = _colorAnimation?.value ?? _targetColor ?? fallbackColor;
        final finalStyle = (widget.style ?? const TextStyle()).copyWith(
          color: animatedColor,
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

class _AcadexAdaptiveGradientIconState extends ConsumerState<AcadexAdaptiveGradientIcon>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ScrollPosition? _scrollPosition;
  Animation<double>? _routeAnimation;
  late final AnimationController _controller;
  late final CurvedAnimation _curvedAnimation;
  Animation<Color?>? _colorAnimation;

  AcadexAdaptiveTextMode _currentMode = AcadexAdaptiveTextMode.light;
  Color? _currentColor;
  Color? _targetColor;
  bool _isInitialized = false;
  bool _evaluationScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _currentColor = _targetColor;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detachScrollListener();
    _attachScrollListener();

    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = ModalRoute.of(context)?.animation;
    _routeAnimation?.addListener(_onRouteAnimation);

    _scheduleEvaluation();
  }

  void _onRouteAnimation() {
    if (_routeAnimation?.isCompleted ?? false) {
      _scheduleEvaluation();
    }
  }

  @override
  void didUpdateWidget(covariant AcadexAdaptiveGradientIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.icon != oldWidget.icon ||
        widget.darkColor != oldWidget.darkColor ||
        widget.lightColor != oldWidget.lightColor ||
        widget.size != oldWidget.size) {
      _scheduleEvaluation();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scheduleEvaluation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachScrollListener();
    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = null;
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _attachScrollListener() {
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_onScrollChange);
  }

  void _detachScrollListener() {
    _scrollPosition?.removeListener(_onScrollChange);
    _scrollPosition = null;
  }

  void _onScrollChange() {
    _scheduleEvaluation();
  }

  void _scheduleEvaluation() {
    if (_evaluationScheduled || !mounted) return;
    _evaluationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluationScheduled = false;
      if (mounted) {
        _evaluatePosition();
      }
    });
  }

  void _evaluatePosition() {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (!_isGradientRole(authState)) return;

    final scope = AcadexGradientScope.maybeOf(context);
    if (scope == null) return;

    final gradientBox = scope.gradientKey.currentContext?.findRenderObject() as RenderBox?;
    final iconRenderBox = context.findRenderObject() as RenderBox?;

    if (gradientBox == null || !gradientBox.hasSize || !gradientBox.attached ||
        iconRenderBox == null || !iconRenderBox.hasSize || !iconRenderBox.attached) {
      if (!_isInitialized) {
        _scheduleEvaluation();
      }
      return;
    }

    final iconCenterGlobal = iconRenderBox.localToGlobal(
      Offset(0, iconRenderBox.size.height / 2.0),
    );
    final localToGradient = gradientBox.globalToLocal(iconCenterGlobal);
    final gradientHeight = gradientBox.size.height;
    if (gradientHeight <= 0) return;

    final t = (localToGradient.dy / gradientHeight).clamp(0.0, 1.0);

    if (!_isInitialized) {
      _isInitialized = true;
      final luminance = AcadexSuperAdminGradient.luminanceAt(t);
      final initialMode = luminance >= 0.30 ? AcadexAdaptiveTextMode.dark : AcadexAdaptiveTextMode.light;
      _currentMode = initialMode;
      _currentColor = initialMode == AcadexAdaptiveTextMode.light ? widget.lightColor : widget.darkColor;
      _targetColor = _currentColor;
      _colorAnimation = AlwaysStoppedAnimation<Color?>(_currentColor);
      if (mounted) setState(() {});
      return;
    }

    final newMode = AcadexSuperAdminGradient.evaluateMode(
      t: t,
      currentMode: _currentMode,
    );

    if (newMode != _currentMode) {
      final newTarget = newMode == AcadexAdaptiveTextMode.light ? widget.lightColor : widget.darkColor;
      final beginColor = _colorAnimation?.value ??
          _currentColor ??
          (newMode == AcadexAdaptiveTextMode.light ? widget.darkColor : widget.lightColor);

      _currentMode = newMode;
      _targetColor = newTarget;
      _currentColor = beginColor;

      _colorAnimation = ColorTween(
        begin: beginColor,
        end: newTarget,
      ).animate(_curvedAnimation);

      _controller.forward(from: 0.0);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGradRole = _isGradientRole(authState);
    final scope = AcadexGradientScope.maybeOf(context);

    if (!isGradRole || scope == null) {
      return Icon(widget.icon, size: widget.size);
    }

    final currentScroll = Scrollable.maybeOf(context)?.position;
    if (currentScroll != null && currentScroll != _scrollPosition) {
      _detachScrollListener();
      _scrollPosition = currentScroll;
      _scrollPosition?.addListener(_onScrollChange);
    }

    final fallbackColor = _currentMode == AcadexAdaptiveTextMode.light ? widget.lightColor : widget.darkColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animatedColor = _colorAnimation?.value ?? _targetColor ?? fallbackColor;
        return Icon(
          widget.icon,
          size: widget.size,
          color: animatedColor,
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

class _AcadexAdaptiveGradientBuilderState extends ConsumerState<AcadexAdaptiveGradientBuilder>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ScrollPosition? _scrollPosition;
  Animation<double>? _routeAnimation;
  late final AnimationController _controller;
  late final CurvedAnimation _curvedAnimation;

  AcadexAdaptiveTextMode _currentMode = AcadexAdaptiveTextMode.light;
  AcadexAdaptiveTextMode _previousMode = AcadexAdaptiveTextMode.light;
  bool _isInitialized = false;
  bool _evaluationScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detachScrollListener();
    _attachScrollListener();

    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = ModalRoute.of(context)?.animation;
    _routeAnimation?.addListener(_onRouteAnimation);

    _scheduleEvaluation();
  }

  void _onRouteAnimation() {
    if (_routeAnimation?.isCompleted ?? false) {
      _scheduleEvaluation();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scheduleEvaluation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachScrollListener();
    _routeAnimation?.removeListener(_onRouteAnimation);
    _routeAnimation = null;
    _controller.dispose();
    super.dispose();
  }

  void _attachScrollListener() {
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_onScrollChange);
  }

  void _detachScrollListener() {
    _scrollPosition?.removeListener(_onScrollChange);
    _scrollPosition = null;
  }

  void _onScrollChange() {
    _scheduleEvaluation();
  }

  void _scheduleEvaluation() {
    if (_evaluationScheduled || !mounted) return;
    _evaluationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluationScheduled = false;
      if (mounted) {
        _evaluatePosition();
      }
    });
  }

  void _evaluatePosition() {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (!_isGradientRole(authState)) return;

    final scope = AcadexGradientScope.maybeOf(context);
    if (scope == null) return;

    final gradientBox = scope.gradientKey.currentContext?.findRenderObject() as RenderBox?;
    final builderRenderBox = context.findRenderObject() as RenderBox?;

    if (gradientBox == null || !gradientBox.hasSize || !gradientBox.attached ||
        builderRenderBox == null || !builderRenderBox.hasSize || !builderRenderBox.attached) {
      if (!_isInitialized) {
        _scheduleEvaluation();
      }
      return;
    }

    final builderCenterGlobal = builderRenderBox.localToGlobal(
      Offset(0, builderRenderBox.size.height / 2.0),
    );
    final localToGradient = gradientBox.globalToLocal(builderCenterGlobal);
    final gradientHeight = gradientBox.size.height;
    if (gradientHeight <= 0) return;

    final t = (localToGradient.dy / gradientHeight).clamp(0.0, 1.0);

    if (!_isInitialized) {
      _isInitialized = true;
      final luminance = AcadexSuperAdminGradient.luminanceAt(t);
      final initialMode = luminance >= 0.30 ? AcadexAdaptiveTextMode.dark : AcadexAdaptiveTextMode.light;
      _previousMode = initialMode;
      _currentMode = initialMode;
      _controller.value = 1.0;
      if (mounted) setState(() {});
      return;
    }

    final newMode = AcadexSuperAdminGradient.evaluateMode(
      t: t,
      currentMode: _currentMode,
    );

    if (newMode != _currentMode) {
      _previousMode = _currentMode;
      _currentMode = newMode;
      _controller.forward(from: 0.0);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGradRole = _isGradientRole(authState);
    final scope = AcadexGradientScope.maybeOf(context);

    if (!isGradRole || scope == null) {
      return widget.builder(
        context,
        Theme.of(context).colorScheme.onSurface,
        Theme.of(context).colorScheme.onSurfaceVariant,
        Theme.of(context).primaryColor,
      );
    }

    final currentScroll = Scrollable.maybeOf(context)?.position;
    if (currentScroll != null && currentScroll != _scrollPosition) {
      _detachScrollListener();
      _scrollPosition = currentScroll;
      _scrollPosition?.addListener(_onScrollChange);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _curvedAnimation.value;
        final isLight = _currentMode == AcadexAdaptiveTextMode.light;
        final prevLight = _previousMode == AcadexAdaptiveTextMode.light;

        final targetPrimary = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF07111F);
        final prevPrimary = prevLight ? const Color(0xFFFFFFFF) : const Color(0xFF07111F);
        final primary = Color.lerp(prevPrimary, targetPrimary, progress) ?? targetPrimary;

        final targetSecondary = isLight ? const Color(0xFFCCE6FF) : const Color(0xFF334155);
        final prevSecondary = prevLight ? const Color(0xFFCCE6FF) : const Color(0xFF334155);
        final secondary = Color.lerp(prevSecondary, targetSecondary, progress) ?? targetSecondary;

        final targetAction = isLight ? const Color(0xFF93C5FD) : const Color(0xFF0066CC);
        final prevAction = prevLight ? const Color(0xFF93C5FD) : const Color(0xFF0066CC);
        final action = Color.lerp(prevAction, targetAction, progress) ?? targetAction;

        return widget.builder(context, primary, secondary, action);
      },
    );
  }
}

