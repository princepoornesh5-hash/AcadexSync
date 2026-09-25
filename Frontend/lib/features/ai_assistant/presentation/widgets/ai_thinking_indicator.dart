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
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);
            final curve = Curves.easeInOut.transform(
              progress < 0.5 ? progress * 2 : (1.0 - progress) * 2,
            );
            final scale = 0.6 + (curve * 0.4);
            final opacity = 0.3 + (curve * 0.7);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AcadexColors.primary.withValues(alpha: opacity),
              ),
              transform: Matrix4.diagonal3Values(scale, scale, 1.0),
            );
          },
        );
      }),
    );
  }
}
