import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_adaptive_gradient_text.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsSection extends ConsumerWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final isGradientRole = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.superAdmin ||
            authState.user.role == AppRole.collegeAdmin ||
            authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.faculty ||
            authState.user.role == AppRole.student);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: isGradientRole
              ? AcadexAdaptiveGradientText(
                  title.toUpperCase(),
                  style: AcadexTypography.eyebrow().copyWith(fontWeight: FontWeight.w700),
                )
              : Text(
                  title.toUpperCase(),
                  style: AcadexTypography.eyebrow(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(
              color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              width: 1,
            ),
            boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
          ),
          child: ClipRRect(
            borderRadius: AcadexRadius.borderRadiusLg,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultIconColor = iconColor ?? (isDark ? AcadexColors.primaryMuted : AcadexColors.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: defaultIconColor.withValues(alpha: 0.1),
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: Icon(icon, size: 18, color: defaultIconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AcadexTypography.body(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AcadexColors.primary,
        activeThumbColor: Colors.white,
      ),
    );
  }
}

class ThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeSelector({super.key, required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ThemeOption(
          title: "Light",
          icon: LucideIcons.sun,
          isSelected: currentMode == ThemeMode.light,
          onTap: () => onChanged(ThemeMode.light),
        ),
        const SizedBox(width: 12),
        _ThemeOption(
          title: "Dark",
          icon: LucideIcons.moon,
          isSelected: currentMode == ThemeMode.dark,
          onTap: () => onChanged(ThemeMode.dark),
        ),
        const SizedBox(width: 12),
        _ThemeOption(
          title: "System",
          icon: LucideIcons.monitor,
          isSelected: currentMode == ThemeMode.system,
          onTap: () => onChanged(ThemeMode.system),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark
        ? AcadexColors.primaryHover.withValues(alpha: 0.25)
        : AcadexColors.primaryLight;
    final selectedBorder = isDark ? AcadexColors.primaryMuted : AcadexColors.primary;
    final selectedFg = isDark ? Colors.white : AcadexColors.primary;

    final unselectedBg = isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface;
    final unselectedBorder = isDark ? AcadexColors.darkHairline : AcadexColors.hairline;
    final unselectedFg = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            border: Border.all(
              color: isSelected ? selectedBorder : unselectedBorder,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: AcadexRadius.borderRadiusLg,
            boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? selectedFg : unselectedFg, size: 22),
              const SizedBox(height: 10),
              Text(
                title,
                style: AcadexTypography.caption(
                  color: isSelected ? selectedFg : unselectedFg,
                ).copyWith(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
              )
            ],
          ),
        ),
      ),
    );
  }
}
