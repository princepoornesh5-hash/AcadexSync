import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_theme.dart';

/// Professional, restrained tactile press feedback wrapper.
/// Subtly scales down (0.985) and triggers light haptic feedback on touch.
class AcadexPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final bool enableHaptic;
  final double pressedScale;

  const AcadexPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.enableHaptic = true,
    this.pressedScale = 0.985,
  });

  @override
  State<AcadexPressable> createState() => _AcadexPressableState();
}

class _AcadexPressableState extends State<AcadexPressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AcadexMotion.micro,
      reverseDuration: AcadexMotion.micro,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: AcadexMotion.curveDecelerate),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (AcadexMotion.isReducedMotion(context) || widget.onTap == null) {
      return InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: widget.borderRadius ?? AcadexRadius.borderRadiusMd,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Subtle fade + 6px vertical slide-in entrance animation for cards and list items.
/// Runs once upon mounting with a quick, professional 200ms duration.
class AcadexFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideOffset;

  const AcadexFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 200),
    this.slideOffset = 6.0,
  });

  @override
  State<AcadexFadeSlide> createState() => _AcadexFadeSlideState();
}

class _AcadexFadeSlideState extends State<AcadexFadeSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AcadexMotion.curveStandard,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AcadexMotion.curveStandard,
      ),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AcadexMotion.isReducedMotion(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Smooth expanding / collapsing accordion wrapper using Acadex curves & durations.
class AcadexAnimatedCollapse extends StatelessWidget {
  final bool isExpanded;
  final Widget child;
  final Duration duration;

  const AcadexAnimatedCollapse({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration = AcadexMotion.normal,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AcadexMotion.resolveDuration(context, duration);

    return AnimatedCrossFade(
      firstChild: child,
      secondChild: const SizedBox.shrink(),
      crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: effectiveDuration,
      firstCurve: AcadexMotion.curveStandard,
      secondCurve: AcadexMotion.curveDecelerate,
    );
  }
}
