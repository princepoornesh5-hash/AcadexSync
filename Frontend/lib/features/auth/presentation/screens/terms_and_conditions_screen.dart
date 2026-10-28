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

/// Dedicated in-app Terms & Conditions screen.
///
/// Reuses existing approved institutional notices from settings while presenting
/// an honest, professional pending-review status for master legal agreements.
class TermsAndConditionsScreen extends ConsumerWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final mutedInk = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
    final secondaryInk = isDark
        ? AcadexColors.darkInkSecondary
        : AcadexColors.inkSecondary;

    return Scaffold(
      key: const Key('terms_and_conditions_screen'),
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
              key: const Key('terms_header'),
              title: 'Terms & Conditions',
              subtitle:
                  'Institutional usage policies, data governance, and legal notices',
              onBack: () {
                final auth = ref.read(authProvider);
                final fallback = auth is AuthAuthenticated ? '/' : '/login';
                context.safePop(fallbackRoute: fallback);
              },
            ),
            const SizedBox(height: 20),

            // Honest Legal Review Status Card
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
                        label: 'STATUS: UNDER INSTITUTIONAL REVIEW',
                        variant: AcadexBadgeVariant.warning,
                      ),
                      const Spacer(),
                      Icon(
                        LucideIcons.fileClock,
                        size: 18,
                        color: isDark
                            ? AcadexColors.warningLight
                            : AcadexColors.warningDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Legal Disclosure & Pending Documentation',
                    style: AcadexTypography.heading3(color: inkColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ACADEXSYNC Campus Management System is licensed for accredited institutional operations. '
                    'All academic data, student records, and attendance logs are governed by institutional policy '
                    'and applicable data privacy standards.',
                    style: AcadexTypography.body(color: secondaryInk),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Notice: Formal legal approval is currently pending institutional administration and legal counsel review. '
                    'This document presents the active technical governance baseline. Comprehensive contractual terms must be published by the institution owner.',
                    style: AcadexTypography.caption(
                      color: mutedInk,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 1: Accredited Institutional Scope
            _PolicySectionCard(
              isDark: isDark,
              icon: LucideIcons.graduationCap,
              title: '1. Accredited Institutional Scope',
              body:
                  'ACADEXSYNC is provisioned solely for accredited higher education colleges, departments, faculty, and enrolled students. '
                  'Platform access is strictly role-scoped (Super Admin, College Admin, HOD, Faculty, and Student). '
                  'User credentials and access rights are contingent upon verified enrollment or active employment status with the participating institution.',
            ),
            const SizedBox(height: 14),

            // Section 2: Data Privacy & Tenant Isolation
            _PolicySectionCard(
              isDark: isDark,
              icon: LucideIcons.shieldCheck,
              title: '2. Multi-Tenant Data Protection',
              body:
                  'ACADEXSYNC enforces strict multi-tenant isolation and role-based access control. '
                  'Personal data, profile images, and academic evaluations are restricted to authorized campus staff '
                  'and never shared across tenant boundaries.\n\n'
                  'Cryptographic verification, email OTP validation, and secure session tokens protect user authentication and credential security.',
            ),
            const SizedBox(height: 14),

            // Section 3: Consent & Account Activation
            _PolicySectionCard(
              isDark: isDark,
              icon: LucideIcons.userCheck,
              title: '3. Provisioning & User Consent Requirements',
              body:
                  'Navigating to or reading this page does not constitute institutional consent or grant active system privileges. '
                  'Prior to accessing institutional records, students and staff must complete formal identity confirmation, '
                  'contact verification, and password provisioning through the official Account Activation workflow.',
            ),
            const SizedBox(height: 14),

            // Section 4: Specifications Requiring Project Owner Input
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
                          LucideIcons.clipboardList,
                          size: 16,
                          color: AcadexColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '4. Pending Project Owner Legal Specifications',
                          style: AcadexTypography.heading3(color: inkColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The following contractual schedules remain unavailable and must be formally provided by the project owner or college authority:',
                    style: AcadexTypography.bodySmall(color: mutedInk),
                  ),
                  const SizedBox(height: 10),
                  _RequirementItem(
                    isDark: isDark,
                    number: 'A',
                    title: 'Master Service Agreement (MSA)',
                    description:
                        'Detailed uptime guarantees, maintenance windows, and institution-level commercial covenants.',
                  ),
                  _RequirementItem(
                    isDark: isDark,
                    number: 'B',
                    title: 'Campus Acceptable Use Policy (AUP)',
                    description:
                        'Explicit guidelines governing academic computing resources, mobile access, and prohibited conduct.',
                  ),
                  _RequirementItem(
                    isDark: isDark,
                    number: 'C',
                    title: 'Academic Data Retention Schedule',
                    description:
                        'Mandatory statutory timelines for historical marks, exam answers, and student attendance archiving.',
                  ),
                  _RequirementItem(
                    isDark: isDark,
                    number: 'D',
                    title: 'Dispute Resolution & Legal Jurisdiction',
                    description:
                        'Governing judicial forum, arbitration provisions, and designated institutional legal representation.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Footer Copyright
            Center(
              child: Text(
                'Copyright © 2026 com.campusmanagement / ACADEXSYNC Platform. All rights reserved.\nVersion 1.0.0 (Build 42)',
                textAlign: TextAlign.center,
                style: AcadexTypography.caption(
                  color: mutedInk,
                ).copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String body;

  const _PolicySectionCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final secondaryInk = isDark
        ? AcadexColors.darkInkSecondary
        : AcadexColors.inkSecondary;

    return AcadexCard(
      backgroundColor: isDark ? AcadexColors.darkSurface : Colors.white,
      borderColor: isDark ? AcadexColors.darkHairline : const Color(0xFFE2E8F0),
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
                child: Icon(icon, size: 16, color: AcadexColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AcadexTypography.heading3(color: inkColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: AcadexTypography.body(
              color: secondaryInk,
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final bool isDark;
  final String number;
  final String title;
  final String description;

  const _RequirementItem({
    required this.isDark,
    required this.number,
    required this.title,
    required this.description,
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
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: inkColor,
              ),
            ),
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
                Text(
                  description,
                  style: AcadexTypography.caption(color: mutedInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
