import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';

/// Accessible Terms and Privacy Policy acceptance checkbox for registration and activation flows.
///
/// Features:
/// - Initially unchecked by default (explicit affirmative consent).
/// - Clickable inline links to in-app /terms route.
/// - Dark/light mode theme contrast compliance.
/// - Clear accessibility touch targets.
class TermsAcceptanceCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool enabled;

  const TermsAcceptanceCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AcadexColors.darkInkSecondary
        : AcadexColors.inkSecondary;
    final linkColor = isDark ? AcadexColors.primaryHover : AcadexColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              key: const Key('terms_checkbox'),
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AcadexColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: isDark
                    ? AcadexColors.darkHairline
                    : const Color(0xFF94A3B8),
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'I have read and agree to the ',
                  style: AcadexTypography.caption(color: textColor),
                ),
                GestureDetector(
                  key: const Key('terms_link_terms'),
                  onTap: () => context.push('/terms'),
                  child: Text(
                    'Terms & Conditions',
                    style: AcadexTypography.caption(color: linkColor).copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  ' and ',
                  style: AcadexTypography.caption(color: textColor),
                ),
                GestureDetector(
                  key: const Key('terms_link_privacy'),
                  onTap: () => context.push('/terms'),
                  child: Text(
                    'Privacy Policy',
                    style: AcadexTypography.caption(color: linkColor).copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text('.', style: AcadexTypography.caption(color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
