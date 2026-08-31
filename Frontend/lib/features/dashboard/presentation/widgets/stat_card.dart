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

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AcadexBreakpoints.isMobile(context);
    final isSmallMobile = AcadexBreakpoints.isSmallMobile(context);
    final isPrimaryMetric = widget.stat.iconColor == DashboardColors.primary ||
        widget.stat.iconColor == AcadexColors.primary;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: isPrimaryMetric
                ? AcadexColors.primaryTint
                : AcadexColors.surface,
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(
              color: isPrimaryMetric
                  ? const Color(0xFFDBEAFE)
                  : AcadexColors.hairline,
              width: 1,
            ),
            boxShadow: AcadexShadows.lightSm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Centered Icon
              Container(
                width: isMobile ? 36 : 40,
                height: isMobile ? 36 : 40,
                decoration: BoxDecoration(
                  color: widget.stat.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    widget.stat.icon,
                    color: widget.stat.iconColor,
                    size: isMobile ? 18 : 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 2. Large Centered Number
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  widget.stat.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 20 : (isMobile ? 22 : 26),
                    fontWeight: FontWeight.w800,
                    color: isPrimaryMetric
                        ? const Color(0xFF003366)
                        : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),

              // 3. Centered Label
              Text(
                widget.stat.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 11.5 : 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // 4. Centered Supporting Description
              if (widget.stat.subtitle != null && widget.stat.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.stat.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 9.5 : 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              if (widget.stat.changePercent != null) ...[
                const SizedBox(height: 4),
                _buildChangePill(widget.stat.changePercent!, false),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AcadexRadius.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
            size: 11,
            color: fg,
          ),
          const SizedBox(width: 3),
          Text(
            '${change.abs().toStringAsFixed(1)}%',
            style: AcadexTypography.eyebrow(color: fg).copyWith(fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}
