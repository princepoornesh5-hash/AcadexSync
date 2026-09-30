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
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final padding = EdgeInsets.all(isMobile ? 16.0 : 24.0);

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
            padding: padding,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Theme.of(context).primaryColor, size: isMobile ? 20 : 24),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AcadexTypography.title(color: Theme.of(context).colorScheme.onSurface)
                        .copyWith(fontSize: isMobile ? 16 : 18),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
          
          // Form Content
          Padding(
            padding: padding,
            child: child,
          ),
          
          // Footer Actions
          if (onSave != null || onCancel != null) ...[
            Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
            Padding(
              padding: padding,
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (onSave != null)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                            ),
                            onPressed: isSaving ? null : onSave,
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    saveLabel ?? "Save Changes",
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                          ),
                        if (onCancel != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                            ),
                            onPressed: isSaving ? null : onCancel,
                            child: Text(
                              "Cancel",
                              style: AcadexTypography.button(
                                color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onCancel != null) ...[
                          TextButton(
                            onPressed: isSaving ? null : onCancel,
                            child: Text(
                              "Cancel",
                              style: AcadexTypography.button(
                                color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (onSave != null)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 44),
                              shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                            ),
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
          ],
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
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        child,
        SizedBox(height: isMobile ? 16 : 24),
      ],
    );
  }
}
