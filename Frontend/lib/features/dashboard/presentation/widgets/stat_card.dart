import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/dashboard_stat_model.dart';

class StatCard extends StatefulWidget {
  final DashboardStatModel stat;
  final int animationDelay;

  const StatCard({
    super.key,
    required this.stat,
    this.animationDelay = 0,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: AcadexSpacing.cardPaddingCompact,
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              width: 1,
            ),
            boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.stat.iconBackground,
                      borderRadius: AcadexRadius.borderRadiusMd,
                    ),
                    child: Icon(
                      widget.stat.icon,
                      color: widget.stat.iconColor,
                      size: 19,
                    ),
                  ),
                  if (widget.stat.changePercent != null)
                    _buildChangePill(widget.stat.changePercent!, isDark),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.stat.value,
                    style: AcadexTypography.heading1(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.stat.title,
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ).copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.stat.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.stat.subtitle!,
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangePill(double change, bool isDark) {
    final isPositive = change >= 0;
    final bg = isPositive
        ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
        : (isDark ? AcadexColors.errorDarkContainer : AcadexColors.errorLight);
    final fg = isPositive ? AcadexColors.success : AcadexColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AcadexRadius.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            style: AcadexTypography.eyebrow(color: fg),
          ),
        ],
      ),
    );
  }
}
