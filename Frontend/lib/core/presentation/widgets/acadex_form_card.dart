import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AcadexFormCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool isSaving;
  final String? saveLabel;

  const AcadexFormCard({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.onSave,
    this.onCancel,
    this.isSaving = false,
    this.saveLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Theme.of(context).primaryColor, size: 24),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
          
          // Form Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: child,
          ),
          
          // Footer Actions
          if (onSave != null || onCancel != null) ...[
            Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    if (onCancel != null)
                      TextButton(
                        onPressed: isSaving ? null : onCancel,
                        child: Text("Cancel", style: AcadexTypography.button(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)),
                      ),
                    if (onSave != null)
                      ElevatedButton(
                        onPressed: isSaving ? null : onSave,
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(saveLabel ?? "Save Changes"),
                      ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class AcadexFormField extends StatelessWidget {
  final String label;
  final Widget child;

  const AcadexFormField({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: isDark ? AcadexColors.darkInk : const Color(0xFF07111F),
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 24),
      ],
    );
  }
}
