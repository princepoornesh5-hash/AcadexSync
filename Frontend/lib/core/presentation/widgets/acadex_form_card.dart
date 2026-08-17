import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AcadexFormCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool isSaving;

  const AcadexFormCard({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.onSave,
    this.onCancel,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineDark),
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
                  Icon(icon, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.hairlineDark),
          
          // Form Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: child,
          ),
          
          // Footer Actions
          if (onSave != null || onCancel != null) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.hairlineDark),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancel != null)
                    TextButton(
                      onPressed: isSaving ? null : onCancel,
                      child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
                    ),
                  const SizedBox(width: 16),
                  if (onSave != null)
                    ElevatedButton(
                      onPressed: isSaving ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.onDark,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 24),
      ],
    );
  }
}
