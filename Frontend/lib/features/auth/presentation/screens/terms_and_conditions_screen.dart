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

/// Terms & Conditions screen presenting the 15-section draft institutional terms,
/// statutory references (DPDPA 2023, DPDP Rules 2025, Consumer Protection Act 2019),
/// system limitations, and grievance redressal channels.
class TermsAndConditionsScreen extends ConsumerStatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  ConsumerState<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState
    extends ConsumerState<TermsAndConditionsScreen> {
  final Map<int, bool> _expandedSections = {};

  void _toggleSection(int index) {
    setState(() {
      _expandedSections[index] = !(_expandedSections[index] ?? false);
    });
  }

  void _expandAll() {
    setState(() {
      for (var i = 1; i <= 15; i++) {
        _expandedSections[i] = true;
      }
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedSections.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  'Draft institutional agreement, acceptable use, and data protection policies',
              onBack: () {
                final auth = ref.read(authProvider);
                final fallback = auth is AuthAuthenticated ? '/' : '/login';
                context.safePop(fallbackRoute: fallback);
              },
            ),
            const SizedBox(height: 16),

            // Draft Status and Legal Notice Banner
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: AcadexBadge(
                          label: 'DRAFT VERSION: 2026.1-draft',
                          variant: AcadexBadgeVariant.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.scale,
                        size: 20,
                        color: isDark
                            ? AcadexColors.warningLight
                            : AcadexColors.warningDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Subject to Formal Owner & Legal Counsel Review',
                    style: AcadexTypography.heading3(color: inkColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This document is an organised working draft prepared for the ACADEXSYNC platform. '
                    'It reflects implemented platform architecture and technical controls, but does not constitute '
                    'a finalised commercial agreement until authorised by the institutional owner and legal counsel. '
                    'Statutory consumer protections under applicable law remain unaffected.',
                    style: AcadexTypography.body(color: secondaryInk),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Statutory Reference: Digital Personal Data Protection Act, 2023 (including phased commencement under Section 1(3)), '
                    'Digital Personal Data Protection Rules, 2025, and Consumer Protection Act, 2019.',
                    style: AcadexTypography.caption(
                      color: mutedInk,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Controls row: Expand / Collapse All
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '15 Agreement Sections',
                  style: AcadexTypography.title(color: inkColor),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      key: const Key('terms_expand_all_button'),
                      onPressed: _expandAll,
                      icon: const Icon(LucideIcons.chevronsUpDown, size: 14),
                      label: const Text(
                        'Expand All',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('terms_collapse_all_button'),
                      onPressed: _collapseAll,
                      icon: const Icon(LucideIcons.minimize2, size: 14),
                      label: const Text(
                        'Collapse',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Section 1: Purpose & Scope
            _ExpandableSectionCard(
              index: 1,
              isDark: isDark,
              isExpanded: _expandedSections[1] ?? true,
              onToggle: () => _toggleSection(1),
              icon: LucideIcons.compass,
              title: '1. Purpose & Scope of ACADEXSYNC',
              summary:
                  'Higher-education multi-tenant academic and campus management platform.',
              content:
                  'ACADEXSYNC provides an integrated digital campus operating system designed for accredited colleges, universities, and educational departments. '
                  'The platform orchestrates student information, course scheduling, attendance logging, grade entry, and institutional analytics. '
                  'Access is limited strictly to authorized institutional members and is contingent on active institutional onboarding and tenancy.',
            ),
            const SizedBox(height: 12),

            // Section 2: Account Registration, Activation & Security
            _ExpandableSectionCard(
              index: 2,
              isDark: isDark,
              isExpanded: _expandedSections[2] ?? false,
              onToggle: () => _toggleSection(2),
              icon: LucideIcons.keyRound,
              title: '2. Account Registration, Activation & Security',
              summary:
                  'Mandatory cryptographic activation tokens, email OTP validation, and credential security.',
              content:
                  'Accounts are provisioned via institutional invitation codes or administrator pre-enrollment. '
                  'Users must complete multi-step identity confirmation, two-factor email OTP verification, password provisioning, and affirmative Terms acceptance prior to access. '
                  'Users are responsible for safeguarding passwords and device sessions. Sharing credentials across individuals or using automated credential-stuffing tools is prohibited.',
            ),
            const SizedBox(height: 12),

            // Section 3: Institutional Roles & Permissions
            _ExpandableSectionCard(
              index: 3,
              isDark: isDark,
              isExpanded: _expandedSections[3] ?? false,
              onToggle: () => _toggleSection(3),
              icon: LucideIcons.shieldAlert,
              title: '3. Institutional Roles & Permissions',
              summary:
                  'Role-based access control across Super Admin, College Admin, HOD, Faculty, and Student.',
              content:
                  'The platform enforces granular Role-Based Access Control (RBAC). '
                  'Super Admins manage overall platform health; College Admins configure departments, academic calendars, and invitations; '
                  'HODs oversee departmental curricula and faculty assignments; Faculty manage attendance and marks for allotted subjects; '
                  'Students view only their own enrolled courses, attendance records, and approved evaluations. '
                  'Privilege escalation, unauthorized role probing, or bypassing tenant isolation is strictly audited and denied.',
            ),
            const SizedBox(height: 12),

            // Section 4: Acceptable Use & Prohibited Activities
            _ExpandableSectionCard(
              index: 4,
              isDark: isDark,
              isExpanded: _expandedSections[4] ?? false,
              onToggle: () => _toggleSection(4),
              icon: LucideIcons.ban,
              title: '4. Acceptable Use & Prohibited Activities',
              summary:
                  'Academic integrity, prohibition of scraping, malicious injections, and unauthorized testing.',
              content:
                  'Users agree to use ACADEXSYNC solely for authorized educational purposes. '
                  'Prohibited activities include: reverse-engineering, decompiling, or intercepting API communications; '
                  'injecting malicious payloads or SQL/script exploits; automated scraping of student or faculty directories; '
                  'falsifying attendance geofences or proxy logins; and transmitting harassing, defamatory, or unlawful content through campus messaging.',
            ),
            const SizedBox(height: 12),

            // Section 5: Institutional Responsibility for User Access & Data
            _ExpandableSectionCard(
              index: 5,
              isDark: isDark,
              isExpanded: _expandedSections[5] ?? false,
              onToggle: () => _toggleSection(5),
              icon: LucideIcons.building,
              title: '5. Institutional Responsibility for Access & Data',
              summary:
                  'Colleges act as Data Fiduciaries; ACADEXSYNC operates as Data Processor.',
              content:
                  'Participating institutions remain the Data Fiduciaries / Controllers of all institutional data imported into or generated within ACADEXSYNC. '
                  'Institutions are responsible for ensuring that student and faculty details uploaded to the platform have been lawfully collected. '
                  'Institutions must promptly revoke access upon student graduation or faculty separation from the institution.',
            ),
            const SizedBox(height: 12),

            // Section 6: Academic Records, Attendance & Data Accuracy
            _ExpandableSectionCard(
              index: 6,
              isDark: isDark,
              isExpanded: _expandedSections[6] ?? false,
              onToggle: () => _toggleSection(6),
              icon: LucideIcons.bookCheck,
              title: '6. Academic Records, Attendance & Data Accuracy',
              summary:
                  'Marks and attendance entered by authorized faculty; institutional dispute mechanisms.',
              content:
                  'ACADEXSYNC records and stores academic evaluations and attendance logs submitted by designated faculty. '
                  'The platform does not determine academic policies, passing thresholds, or disciplinary actions. '
                  'Discrepancies in attendance percentages, exam scores, or enrollment rosters must be resolved directly with the relevant institutional department or exam controller.',
            ),
            const SizedBox(height: 12),

            // Section 7: Privacy, Data Processing & DPDPA Compliance
            _ExpandableSectionCard(
              index: 7,
              isDark: isDark,
              isExpanded: _expandedSections[7] ?? false,
              onToggle: () => _toggleSection(7),
              icon: LucideIcons.lock,
              title: '7. Privacy, Personal-Data Processing & Rights',
              summary:
                  'Aligned with DPDPA 2023, DPDP Rules 2025, data minimization, and privacy contacts.',
              content:
                  'Personal data (names, email addresses, phone numbers, enrollment numbers, academic history) is processed exclusively for campus management operations in accordance with the Digital Personal Data Protection Act, 2023 and the DPDP Rules, 2025. '
                  'Data is isolated per tenant and encrypted in transit (TLS) and at rest. '
                  'Users have rights to access summaries of processed personal data and request correction of inaccurate records through their institutional administrator. '
                  'Privacy requests and grievances may be addressed to: ragoorupoornesh@gmail.com.',
            ),
            const SizedBox(height: 12),

            // Section 8: Service Availability, Sync Delays & Maintenance
            _ExpandableSectionCard(
              index: 8,
              isDark: isDark,
              isExpanded: _expandedSections[8] ?? false,
              onToggle: () => _toggleSection(8),
              icon: LucideIcons.activity,
              title: '8. Service Availability, Sync Delays & Maintenance',
              summary:
                  'Operational availability, planned downtime, network latency, and offline state caveats.',
              content:
                  'ACADEXSYNC strives for continuous availability but does not warrant 100% uninterrupted uptime. '
                  'The platform may occasionally experience scheduled maintenance windows, network latency, third-party infrastructure interruptions, or background synchronization delays. '
                  'Users are advised to submit time-critical grade entries or fee submissions with reasonable lead time prior to statutory institutional deadlines.',
            ),
            const SizedBox(height: 12),

            // Section 9: Data Backup, Retention, Export & Recovery
            _ExpandableSectionCard(
              index: 9,
              isDark: isDark,
              isExpanded: _expandedSections[9] ?? false,
              onToggle: () => _toggleSection(9),
              icon: LucideIcons.databaseBackup,
              title: '9. Data Backup, Retention, Export & Recovery',
              summary:
                  'Automated database backups, institutional export facilities, and recovery limitations.',
              content:
                  'Automated point-in-time database snapshots are maintained on the host infrastructure. '
                  'Institutions may export student and course rosters in standard CSV/PDF formats through administrative consoles. '
                  'In the event of accidental tenant data deletion requested by an administrator, restoration is limited to the nearest available backup snapshot and may require manual reconciliation.',
            ),
            const SizedBox(height: 12),

            // Section 10: AI Assistant Limitations & Verification
            _ExpandableSectionCard(
              index: 10,
              isDark: isDark,
              isExpanded: _expandedSections[10] ?? false,
              onToggle: () => _toggleSection(10),
              icon: LucideIcons.sparkles,
              title: '10. AI Assistant Limitations & Mandatory Verification',
              summary:
                  'AI responses are informational; critical academic decisions require official verification.',
              content:
                  'The integrated ACADEXSYNC AI assistant provides operational assistance, schedule queries, and administrative summaries based on natural language processing. '
                  'AI responses are generative and must not be treated as definitive legal, regulatory, or academic decrees. '
                  'Public/unauthenticated AI interactions are strictly barred from accessing private student records or marks. '
                  'Staff and students must independently verify grades, attendance eligibility, and official institutional announcements through official departmental channels.',
            ),
            const SizedBox(height: 12),

            // Section 11: Third-Party Services & Infrastructure
            _ExpandableSectionCard(
              index: 11,
              isDark: isDark,
              isExpanded: _expandedSections[11] ?? false,
              onToggle: () => _toggleSection(11),
              icon: LucideIcons.cloudCog,
              title: '11. Third-Party Services & Infrastructure',
              summary:
                  'Cloud hosting, transactional email delivery (Resend/SMTP), and external dependencies.',
              content:
                  'ACADEXSYNC relies on reputable cloud hosting and infrastructure providers for database hosting, file storage, and transactional email/SMS delivery (e.g. Resend, SMTP relays). '
                  'Delivery speeds for verification codes may depend on downstream telecommunication networks and mail filtering rules beyond direct platform control.',
            ),
            const SizedBox(height: 12),

            // Section 12: Suspension, Termination & Institutional Offboarding
            _ExpandableSectionCard(
              index: 12,
              isDark: isDark,
              isExpanded: _expandedSections[12] ?? false,
              onToggle: () => _toggleSection(12),
              icon: LucideIcons.userX,
              title: '12. Suspension, Termination & Offboarding',
              summary:
                  'Account deactivation for policy violations, institutional contract conclusion, and data disposition.',
              content:
                  'ACADEXSYNC reserves the right to suspend accounts engaged in security tampering, abuse, or unauthorized exploitation. '
                  'Upon formal conclusion of an institution’s subscription or contract, a grace period is provided for final data export, followed by secure archiving or cryptographic deletion in line with statutory guidelines.',
            ),
            const SizedBox(height: 12),

            // Section 13: Support & Grievance Redressal
            _ExpandableSectionCard(
              index: 13,
              isDark: isDark,
              isExpanded: _expandedSections[13] ?? true,
              onToggle: () => _toggleSection(13),
              icon: LucideIcons.headset,
              title: '13. Support & Grievance Redressal Procedure',
              summary:
                  'Designated channels for technical support, academic disputes, and privacy grievances.',
              content:
                  'For technical support, account activation assistance, or grievance redressal, contact:\n\n'
                  '• Support & Grievance Email: ragoorupoornesh@gmail.com\n'
                  '• Support Helpline: +91 8686633340\n'
                  '• Campus / Operations Address: Nehru Nagar, Tirupati, Andhra Pradesh, India\n\n'
                  'Technical support queries receive an initial assessment within standard business working periods.',
            ),
            const SizedBox(height: 12),

            // Section 14: Changes to Terms & Version History
            _ExpandableSectionCard(
              index: 14,
              isDark: isDark,
              isExpanded: _expandedSections[14] ?? false,
              onToggle: () => _toggleSection(14),
              icon: LucideIcons.history,
              title: '14. Changes to Terms & Version History',
              summary:
                  'Protocol for policy updates, material change notifications, and re-consent workflows.',
              content:
                  'When material updates are made to these terms, registered users will be notified via in-app prompts or email. '
                  'Significant amendments may require renewed explicit consent upon login or activation.\n\n'
                  'Version History:\n'
                  '• Version 2026.1-draft (Current Draft, October 2026): Comprehensive institutional draft with DPDPA 2023 and CPA 2019 statutory alignments.\n'
                  '• Version 1.0.0-initial: Baseline technical governance.',
            ),
            const SizedBox(height: 12),

            // Section 15: Applicable Law & Reasonable Liability Limitations
            _ExpandableSectionCard(
              index: 15,
              isDark: isDark,
              isExpanded: _expandedSections[15] ?? false,
              onToggle: () => _toggleSection(15),
              icon: LucideIcons.gavel,
              title: '15. Applicable Law & Reasonable Liability Limitations',
              summary:
                  'Governing law in India, dispute resolution, and balanced liability limits.',
              content:
                  'These terms are formulated in accordance with the laws of India, including the Consumer Protection Act, 2019 and the Digital Personal Data Protection Act, 2023. '
                  'Nothing in these terms seeks to exclude or limit liability that cannot lawfully be excluded under Indian consumer protection statutes. '
                  'To the extent permitted by law, liability for indirect, incidental, or consequential damages arising from unforeseen system outages or third-party carrier faults is limited to the fees paid for the relevant service tier during the preceding term, subject to formal institutional agreement.',
            ),
            const SizedBox(height: 24),

            // Footer Copyright
            Center(
              child: Text(
                'ACADEXSYNC Campus Management Main • Terms Version 2026.1-draft\nNehru Nagar, Tirupati, Andhra Pradesh, India',
                textAlign: TextAlign.center,
                style: AcadexTypography.caption(
                  color: mutedInk,
                ).copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ExpandableSectionCard extends StatelessWidget {
  final int index;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggle;
  final IconData icon;
  final String title;
  final String summary;
  final String content;

  const _ExpandableSectionCard({
    required this.index,
    required this.isDark,
    required this.isExpanded,
    required this.onToggle,
    required this.icon,
    required this.title,
    required this.summary,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final secondaryInk = isDark
        ? AcadexColors.darkInkSecondary
        : AcadexColors.inkSecondary;
    final mutedInk = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;

    return AcadexCard(
      key: Key('terms_section_$index'),
      backgroundColor: isDark ? AcadexColors.darkSurface : Colors.white,
      borderColor: isDark ? AcadexColors.darkHairline : const Color(0xFFE2E8F0),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: AcadexRadius.borderRadiusSm,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AcadexColors.primary.withValues(alpha: 0.12),
                    borderRadius: AcadexRadius.borderRadiusSm,
                  ),
                  child: Icon(icon, size: 18, color: AcadexColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AcadexTypography.heading3(color: inkColor),
                      ),
                      if (!isExpanded) ...[
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: AcadexTypography.caption(color: mutedInk),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                  color: mutedInk,
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              content,
              style: AcadexTypography.body(
                color: secondaryInk,
              ).copyWith(height: 1.55),
            ),
          ],
        ],
      ),
    );
  }
}
