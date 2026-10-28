import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../domain/models/auth_state.dart';
import '../providers/auth_provider.dart';

/// Dedicated in-app Contact Us screen.
///
/// Discloses an honest unconfigured status for live support channels
/// rather than inventing fake support email addresses, phone numbers, or promises.
class ContactUsScreen extends ConsumerWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final mutedInk = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
    final secondaryInk = isDark
        ? AcadexColors.darkInkSecondary
        : AcadexColors.inkSecondary;

    return Scaffold(
      key: const Key('contact_us_screen'),
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
        hasAppBar: false,
        hasBottomNav: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Standard Page Header with Back Navigation
            AcadexPageHeader(
              key: const Key('contact_header'),
              title: 'Contact Us',
              subtitle:
                  'Campus support channels, administrative helpdesk, and technical assistance',
              onBack: () {
                final auth = ref.read(authProvider);
                final fallback = auth is AuthAuthenticated ? '/' : '/login';
                context.safePop(fallbackRoute: fallback);
              },
            ),
            const SizedBox(height: 20),

            // Honest Unconfigured State Card
            AcadexCard(
              backgroundColor: isDark
                  ? AcadexColors.warningDarkContainer.withValues(alpha: 0.25)
                  : AcadexColors.warningLight.withValues(alpha: 0.65),
              borderColor: isDark
                  ? AcadexColors.warningDark
                  : AcadexColors.warning.withValues(alpha: 0.35),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AcadexBadge(
                        label: 'STATUS: SUPPORT CHANNELS UNCONFIGURED',
                        variant: AcadexBadgeVariant.warning,
                      ),
                      const Spacer(),
                      Icon(
                        LucideIcons.headset,
                        size: 18,
                        color: isDark
                            ? AcadexColors.warningLight
                            : AcadexColors.warningDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Support Contact Information Pending Configuration',
                    style: AcadexTypography.heading3(color: inkColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Official direct support channels, campus helpdesk hotlines, and operational email endpoints '
                    'have not yet been configured for this ACADEXSYNC deployment.\n\n'
                    'To ensure user transparency and prevent communication failures, unverified phone numbers, '
                    'mock email addresses, and non-functional call actions are intentionally omitted.',
                    style: AcadexTypography.body(color: secondaryInk),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // On-Campus Escalation Guidance
            AcadexCard(
              backgroundColor: isDark ? AcadexColors.darkSurface : Colors.white,
              borderColor: isDark
                  ? AcadexColors.darkHairline
                  : const Color(0xFFE2E8F0),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: AcadexRadius.borderRadiusSm,
                        ),
                        child: const Icon(
                          LucideIcons.building2,
                          size: 16,
                          color: AcadexColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'On-Campus Assistance Guidance',
                          style: AcadexTypography.heading3(color: inkColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _GuidanceRow(
                    isDark: isDark,
                    icon: LucideIcons.graduationCap,
                    roleTitle: 'Enrolled Students',
                    guidance:
                        'If you are having trouble logging in, activating your account, or accessing curriculum resources, '
                        'please visit your department office or speak with your Class In-Charge or Head of Department (HOD) in person.',
                  ),
                  const SizedBox(height: 12),
                  _GuidanceRow(
                    isDark: isDark,
                    icon: LucideIcons.bookOpen,
                    roleTitle: 'Faculty & Academic Staff',
                    guidance:
                        'For timetable scheduling adjustments, attendance register exports, or teaching assignment queries, '
                        'please consult your Department HOD or College IT Coordinator.',
                  ),
                  const SizedBox(height: 12),
                  _GuidanceRow(
                    isDark: isDark,
                    icon: LucideIcons.shieldAlert,
                    roleTitle: 'College Administrators',
                    guidance:
                        'For institutional provisioning, tenant configuration, or system escalations, '
                        'please contact the Campus Super Administrator.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Required Project Owner Support Configuration
            AcadexCard(
              backgroundColor: isDark ? AcadexColors.darkSurface : Colors.white,
              borderColor: isDark
                  ? AcadexColors.darkHairline
                  : const Color(0xFFE2E8F0),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.12),
                          borderRadius: AcadexRadius.borderRadiusSm,
                        ),
                        child: const Icon(
                          LucideIcons.settings2,
                          size: 16,
                          color: AcadexColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Required Project Owner Support Configuration',
                          style: AcadexTypography.heading3(color: inkColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Before releasing this deployment to students and faculty, the project owner or campus administrator must configure the following authoritative support endpoints:',
                    style: AcadexTypography.bodySmall(color: mutedInk),
                  ),
                  const SizedBox(height: 12),
                  _ConfigItem(
                    isDark: isDark,
                    icon: LucideIcons.mail,
                    title: 'Institutional Support Email',
                    detail:
                        'Dedicated organizational inbox (e.g. support@yourinstitution.edu) backed by verified DNS and active routing.',
                  ),
                  _ConfigItem(
                    isDark: isDark,
                    icon: LucideIcons.phone,
                    title: 'Campus IT Helpdesk Phone & Working Hours',
                    detail:
                        'Direct telephone extension and designated support hours (e.g. Mon–Fri 9:00 AM – 5:00 PM).',
                  ),
                  _ConfigItem(
                    isDark: isDark,
                    icon: LucideIcons.mapPin,
                    title: 'Physical Helpdesk Location',
                    detail:
                        'Specific campus building, floor, and room number for walk-in technical support.',
                  ),
                  _ConfigItem(
                    isDark: isDark,
                    icon: LucideIcons.globe,
                    title: 'Support Portal & Ticket Management URL',
                    detail:
                        'Online student self-service helpdesk or grievance redressal portal link.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Default Repository Disclosure Card
            AcadexCard(
              backgroundColor: isDark
                  ? AcadexColors.darkCanvasSoft
                  : AcadexColors.canvasSoft,
              borderColor: isDark
                  ? AcadexColors.darkHairline
                  : const Color(0xFFE2E8F0),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 16,
                    color: isDark
                        ? AcadexColors.darkInkMuted
                        : AcadexColors.inkMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Internal Setting Disclosure: Default addresses found in settings (support@acadex.edu, helpdesk@acadex.edu) '
                      'are repository mock defaults and do not connect to an active external mailbox.',
                      style: AcadexTypography.caption(
                        color: mutedInk,
                      ).copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Footer Copyright
            Center(
              child: Text(
                'ACADEXSYNC Campus Management System · Multi-Tenant Architecture',
                textAlign: TextAlign.center,
                style: AcadexTypography.caption(color: mutedInk),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String roleTitle;
  final String guidance;

  const _GuidanceRow({
    required this.isDark,
    required this.icon,
    required this.roleTitle,
    required this.guidance,
  });

  @override
  Widget build(BuildContext context) {
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final secondaryInk = isDark
        ? AcadexColors.darkInkSecondary
        : AcadexColors.inkSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AcadexColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roleTitle,
                style: AcadexTypography.bodySmall(
                  color: inkColor,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                guidance,
                style: AcadexTypography.caption(
                  color: secondaryInk,
                ).copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfigItem extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String detail;

  const _ConfigItem({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final mutedInk = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? AcadexColors.darkCanvasSoft
                  : AcadexColors.canvasSoft,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark
                    ? AcadexColors.darkHairline
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(icon, size: 12, color: inkColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AcadexTypography.bodySmall(
                    color: inkColor,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(detail, style: AcadexTypography.caption(color: mutedInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
