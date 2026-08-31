import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/quick_action_model.dart';

// ── Compact tile used in mobile horizontal scroll row ──────────────────────

class QuickActionTile extends StatefulWidget {
  final QuickActionModel action;

  const QuickActionTile({super.key, required this.action});

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 90),
      vsync: this,
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) => _ctrl.reverse();
  void _up(_) {
    _ctrl.forward();
    context.push(widget.action.route);
  }
  void _cancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isPrimaryAction = widget.action.iconColor == AcadexColors.primary ||
        widget.action.iconColor == DashboardColors.primary;

    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 96,
          height: 108,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isPrimaryAction
                ? AcadexColors.superAdminSoftAction
                : (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface),
            borderRadius: AcadexRadius.borderRadiusMd,
            border: Border.all(
              color: isPrimaryAction
                  ? AcadexColors.superAdminPrimaryAction
                  : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
              width: isPrimaryAction ? 1.2 : 1.0,
            ),
            boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPrimaryAction ? Colors.white : widget.action.iconBackground,
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: Icon(
                  widget.action.icon,
                  color: isPrimaryAction ? AcadexColors.superAdminPrimaryAction : widget.action.iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.action.label,
                textAlign: TextAlign.center,
                style: AcadexTypography.caption(
                  color: isPrimaryAction
                      ? AcadexColors.superAdminDeepAction
                      : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                ).copyWith(
                  fontWeight: isPrimaryAction ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 11,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Horizontal scrollable row on mobile, Wrap on desktop ───────────────────

class QuickActionsRow extends StatelessWidget {
  final List<QuickActionModel> actions;

  const QuickActionsRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final isMobile = AcadexBreakpoints.isMobile(context);

    if (isMobile) {
      return SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: actions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => QuickActionTile(action: actions[i]),
        ),
      );
    }

    // Desktop / tablet — wrap grid
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((a) => QuickActionCard(action: a)).toList(),
    );
  }
}

// ── Desktop card (preserved for non-mobile layout) ─────────────────────────

class QuickActionCard extends StatefulWidget {
  final QuickActionModel action;

  const QuickActionCard({super.key, required this.action});

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) => _ctrl.reverse();
  void _up(_) {
    _ctrl.forward();
    context.push(widget.action.route);
  }
  void _cancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.action.iconBackground,
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: Icon(
                  widget.action.icon,
                  color: widget.action.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.action.label,
                textAlign: TextAlign.center,
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
