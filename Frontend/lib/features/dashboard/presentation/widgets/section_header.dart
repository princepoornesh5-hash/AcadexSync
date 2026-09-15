import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_adaptive_gradient_text.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SectionHeader extends ConsumerWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? titleColor;
  final Color? actionColor;
  final bool showAccent;
  final Color? accentColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.titleColor,
    this.actionColor,
    this.showAccent = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isGradientRole = authState is AuthAuthenticated &&
        (authState.user.role == AppRole.superAdmin ||
            authState.user.role == AppRole.collegeAdmin ||
            authState.user.role == AppRole.hod ||
            authState.user.role == AppRole.faculty ||
            authState.user.role == AppRole.student);

    final standardTitleColor = titleColor ?? Theme.of(context).colorScheme.onSurface;
    final standardActionColor = actionColor ?? Theme.of(context).primaryColor;
    final effectiveAccentColor = accentColor ?? const Color(0xFF0080FF);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showAccent || isGradientRole) ...[
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: effectiveAccentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: isGradientRole && titleColor == null
                    ? AcadexAdaptiveGradientText(
                        title,
                        style: AcadexTypography.title().copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        title,
                        style: AcadexTypography.title(
                          color: standardTitleColor,
                        ).copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: standardActionColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(48, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: isGradientRole && actionColor == null
                ? AcadexAdaptiveGradientText(
                    actionLabel!,
                    style: AcadexTypography.button().copyWith(fontWeight: FontWeight.w600),
                  )
                : Text(
                    actionLabel!,
                    style: AcadexTypography.button(
                      color: standardActionColor,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
          ),
      ],
    );
  }
}
