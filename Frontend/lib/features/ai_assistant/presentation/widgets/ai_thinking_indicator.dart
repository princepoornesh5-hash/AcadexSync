import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class AiThinkingIndicator extends StatefulWidget {
  const AiThinkingIndicator({super.key});

  @override
  State<AiThinkingIndicator> createState() => _AiThinkingIndicatorState();
}

class _AiThinkingIndicatorState extends State<AiThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "ACADEXSYNC is thinking...",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            if (reduceMotion) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AcadexColors.primary.withValues(alpha: 0.7),
                ),
              );
            }

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.22;
                final progress = (_controller.value - delay).clamp(0.0, 1.0);
                final curve = Curves.easeInOut.transform(
                  progress < 0.5 ? progress * 2 : (1.0 - progress) * 2,
                );
                final scale = 0.7 + (curve * 0.4);
                final opacity = 0.35 + (curve * 0.65);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  width: 5.5,
                  height: 5.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AcadexColors.primary.withValues(alpha: opacity),
                  ),
                  transform: Matrix4.diagonal3Values(scale, scale, 1.0),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
