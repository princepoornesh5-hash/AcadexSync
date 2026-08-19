import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';

class AcadexEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  const AcadexEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = LucideIcons.inbox,
    this.onActionTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            title,
            style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AcadexTypography.body(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
          ),
          if (onActionTap != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onActionTap,
              child: Text(actionLabel!),
            ),
          ]
        ],
      ),
    );
  }
}
