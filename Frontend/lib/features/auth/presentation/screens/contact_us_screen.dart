import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../ai_assistant/presentation/providers/ai_providers.dart';
import '../../domain/models/auth_state.dart';
import '../providers/auth_provider.dart';

/// Dedicated in-app Contact Us screen redesign.
///
/// Features:
/// 1. Polished support hub with owner-supplied contact details:
///    - Phone: +91 8686633340 (native dialer action + copy fallback)
///    - Email: ragoorupoornesh@gmail.com (native mail action + copy fallback)
///    - Location: Nehru Nagar, Tirupati, Andhra Pradesh, India (exact, no invented map/hours)
/// 2. Integrated "Ask ACADEXSYNC AI" section with suggested question chips, public privacy guard,
///    and responsive loading, answer, and error retry states.
/// 3. Compact expandable FAQ section covering activation, OTP, roles, recovery, and onboarding.
/// 4. "Register Your College" onboarding form with validation, mailto draft generator to
///    ragoorupoornesh@gmail.com, and clipboard copy fallback.
class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  static const String ownerPhone = '+91 8686633340';
  static const String ownerEmail = 'ragoorupoornesh@gmail.com';
  static const String ownerLocation =
      'Nehru Nagar, Tirupati, Andhra Pradesh, India';

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  // AI Section State
  final TextEditingController _aiQueryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiLoading = false;
  String? _aiResponse;
  String? _aiError;
  String? _lastAskedQuery;

  // FAQ State
  final Map<int, bool> _expandedFaq = {};

  final List<String> _suggestedQuestions = const [
    'How do I activate my account?',
    'How do I sign in using email OTP?',
    'How can my college register?',
    'How do I reset my password?',
    'What can ACADEXSYNC do for my institution?',
    'How do I report a technical problem?',
  ];

  @override
  void dispose() {
    _aiQueryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Native Launchers & Fallbacks ---

  Future<void> _callOwnerPhone() async {
    final uri = Uri.parse('tel:+918686633340');
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        await _copyToClipboard(
          ContactUsScreen.ownerPhone,
          'Phone number copied: ${ContactUsScreen.ownerPhone}',
        );
      }
    } catch (_) {
      await _copyToClipboard(
        ContactUsScreen.ownerPhone,
        'Phone number copied: ${ContactUsScreen.ownerPhone}',
      );
    }
  }

  Future<void> _emailOwner() async {
    final uri = Uri(
      scheme: 'mailto',
      path: ContactUsScreen.ownerEmail,
      queryParameters: {'subject': 'ACADEXSYNC Support & General Inquiry'},
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await _copyToClipboard(
          ContactUsScreen.ownerEmail,
          'Support email copied: ${ContactUsScreen.ownerEmail}',
        );
      }
    } catch (_) {
      await _copyToClipboard(
        ContactUsScreen.ownerEmail,
        'Support email copied: ${ContactUsScreen.ownerEmail}',
      );
    }
  }

  Future<void> _copyToClipboard(String text, String feedbackMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackMessage),
          backgroundColor: AcadexColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // --- AI Assistant Integration ---

  Future<void> _submitAiQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isAiLoading = true;
      _aiError = null;
      _lastAskedQuery = trimmed;
      _aiQueryController.text = trimmed;
    });

    try {
      final repository = ref.read(aiRepositoryProvider);
      final response = await repository.sendPublicSupportQuery(query: trimmed);

      if (mounted) {
        setState(() {
          _aiResponse = response.answer;
          _isAiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiError =
              'Unable to reach ACADEXSYNC AI support at this moment. You can reach out directly via email or phone.';
          _isAiLoading = false;
        });
      }
    }
  }

  void _toggleFaq(int index) {
    setState(() {
      _expandedFaq[index] = !(_expandedFaq[index] ?? false);
    });
  }

  void _openCollegeOnboardingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _CollegeOnboardingDialog(),
    );
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
      key: const Key('contact_us_screen'),
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
        hasAppBar: false,
        hasBottomNav: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              AcadexPageHeader(
                key: const Key('contact_header'),
                title: 'Contact Us',
                subtitle:
                    'Official support hub, instant AI assistance, and college onboarding',
                onBack: () {
                  final auth = ref.read(authProvider);
                  final fallback = auth is AuthAuthenticated ? '/' : '/login';
                  context.safePop(fallbackRoute: fallback);
                },
              ),
              const SizedBox(height: 16),

              // Hero Onboarding CTA Card
              _CollegeOnboardingBanner(
                isDark: isDark,
                onRegisterTap: _openCollegeOnboardingDialog,
              ),
              const SizedBox(height: 16),

              // Official Contact Cards Section
              Text(
                'Authorised Support Contacts',
                style: AcadexTypography.heading3(color: inkColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Reach out directly to the ACADEXSYNC administration team for support, demonstrations, and technical help.',
                style: AcadexTypography.bodySmall(color: mutedInk),
              ),
              const SizedBox(height: 12),

              // Contact Cards
              _ContactCard(
                key: const Key('contact_phone_card'),
                isDark: isDark,
                icon: LucideIcons.phoneCall,
                iconColor: AcadexColors.primary,
                badgeLabel: 'VOICE & WHATSAPP',
                badgeVariant: AcadexBadgeVariant.info,
                title: 'Helpline & Telephone',
                value: ContactUsScreen.ownerPhone,
                description: 'Direct call to campus platform administration.',
                primaryActionLabel: 'Call Now',
                primaryActionIcon: LucideIcons.phone,
                onPrimaryAction: _callOwnerPhone,
                onCopy: () => _copyToClipboard(
                  ContactUsScreen.ownerPhone,
                  'Phone number copied: ${ContactUsScreen.ownerPhone}',
                ),
              ),
              const SizedBox(height: 12),

              _ContactCard(
                key: const Key('contact_email_card'),
                isDark: isDark,
                icon: LucideIcons.mail,
                iconColor: const Color(
                  0xFFE11D48,
                ), // restrained pink/rose accent
                badgeLabel: 'OFFICIAL INBOX',
                badgeVariant: AcadexBadgeVariant.neutral,
                title: 'Email Communications',
                value: ContactUsScreen.ownerEmail,
                description:
                    'Institutional inquiries, bug reports, and verification requests.',
                primaryActionLabel: 'Send Email',
                primaryActionIcon: LucideIcons.send,
                onPrimaryAction: _emailOwner,
                onCopy: () => _copyToClipboard(
                  ContactUsScreen.ownerEmail,
                  'Email address copied: ${ContactUsScreen.ownerEmail}',
                ),
              ),
              const SizedBox(height: 12),

              _ContactCard(
                key: const Key('contact_location_card'),
                isDark: isDark,
                icon: LucideIcons.mapPin,
                iconColor: const Color(
                  0xFFD97706,
                ), // restrained amber/yellow accent
                badgeLabel: 'REGISTERED LOCATION',
                badgeVariant: AcadexBadgeVariant.warning,
                title: 'Operational Location',
                value: ContactUsScreen.ownerLocation,
                description:
                    'Administrative base of ACADEXSYNC campus operations.',
                primaryActionLabel: 'Copy Address',
                primaryActionIcon: LucideIcons.copy,
                onPrimaryAction: () => _copyToClipboard(
                  ContactUsScreen.ownerLocation,
                  'Location copied to clipboard',
                ),
                onCopy: () => _copyToClipboard(
                  ContactUsScreen.ownerLocation,
                  'Location copied to clipboard',
                ),
              ),
              const SizedBox(height: 24),

              // Ask ACADEXSYNC AI Support Section
              _AiSupportSection(
                isDark: isDark,
                suggestedQuestions: _suggestedQuestions,
                queryController: _aiQueryController,
                isLoading: _isAiLoading,
                aiResponse: _aiResponse,
                aiError: _aiError,
                lastAskedQuery: _lastAskedQuery,
                onSelectSuggestion: _submitAiQuery,
                onSubmitQuery: () => _submitAiQuery(_aiQueryController.text),
                onRetry: () {
                  if (_lastAskedQuery != null) {
                    _submitAiQuery(_lastAskedQuery!);
                  }
                },
                onCopyResponse: (text) =>
                    _copyToClipboard(text, 'AI response copied to clipboard'),
              ),
              const SizedBox(height: 24),

              // Frequently Asked Questions Section
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
                      LucideIcons.helpCircle,
                      size: 16,
                      color: AcadexColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frequently Asked Questions',
                          style: AcadexTypography.heading3(color: inkColor),
                        ),
                        Text(
                          'Quick answers to common institutional & activation workflows',
                          style: AcadexTypography.caption(color: mutedInk),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _FaqAccordion(
                isDark: isDark,
                expandedMap: _expandedFaq,
                onToggle: _toggleFaq,
                onAskAi: (q) {
                  _submitAiQuery(q);
                  _scrollController.animateTo(
                    450,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              const SizedBox(height: 28),

              // Institutional Assurance Banner
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
                      LucideIcons.shieldCheck,
                      size: 18,
                      color: AcadexColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tenant Isolation & Privacy: Public inquiries and AI queries never expose student records, attendance logs, or confidential grades. '
                        'Support escalations are addressed by authorized campus administrators.',
                        style: AcadexTypography.caption(
                          color: secondaryInk,
                        ).copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Center(
                child: Text(
                  'ACADEXSYNC Campus Management Main\nNehru Nagar, Tirupati, Andhra Pradesh, India',
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onboarding Banner Widget
// ---------------------------------------------------------------------------
class _CollegeOnboardingBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRegisterTap;

  const _CollegeOnboardingBanner({
    required this.isDark,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return AcadexCard(
      key: const Key('college_onboarding_banner'),
      backgroundColor: isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFFF0F7FF),
      borderColor: isDark
          ? const Color(0xFF334155)
          : AcadexColors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AcadexBadge(
                label: 'INSTITUTIONAL ENROLLMENT',
                variant: AcadexBadgeVariant.info,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: AcadexColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bring ACADEXSYNC to Your College',
            style: AcadexTypography.heading2(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Are you a college dean, principal, or department head? Request institutional onboarding, scheduling setup, and an authorized administrative demo.',
            style: AcadexTypography.bodySmall(
              color: isDark
                  ? AcadexColors.darkInkSecondary
                  : AcadexColors.inkSecondary,
            ).copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          AcadexButton(
            key: const Key('register_college_cta_button'),
            label: 'Register Your College',
            icon: LucideIcons.building2,
            isFullWidth: true,
            onPressed: onRegisterTap,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contact Card Widget
// ---------------------------------------------------------------------------
class _ContactCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String badgeLabel;
  final AcadexBadgeVariant badgeVariant;
  final String title;
  final String value;
  final String description;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final VoidCallback onPrimaryAction;
  final VoidCallback onCopy;

  const _ContactCard({
    super.key,
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.badgeLabel,
    required this.badgeVariant,
    required this.title,
    required this.value,
    required this.description,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final mutedInk = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
    final secondaryInk = isDark
        ? AcadexColors.darkInkSecondary
        : AcadexColors.inkSecondary;

    return AcadexCard(
      backgroundColor: isDark ? AcadexColors.darkSurface : Colors.white,
      borderColor: isDark ? AcadexColors.darkHairline : const Color(0xFFE2E8F0),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AcadexTypography.caption(color: mutedInk),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      value,
                      style: AcadexTypography.heading3(color: inkColor),
                    ),
                  ],
                ),
              ),
              AcadexBadge(label: badgeLabel, variant: badgeVariant),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AcadexTypography.bodySmall(color: secondaryInk),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPrimaryAction,
                  icon: Icon(primaryActionIcon, size: 16),
                  label: Text(primaryActionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcadexColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Copy to clipboard',
                onPressed: onCopy,
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? AcadexColors.darkCanvasSoft
                      : AcadexColors.canvasSoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: AcadexRadius.borderRadiusSm,
                    side: BorderSide(
                      color: isDark
                          ? AcadexColors.darkHairline
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  minimumSize: const Size(42, 42),
                ),
                icon: Icon(
                  LucideIcons.copy,
                  size: 16,
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Support Section Widget
// ---------------------------------------------------------------------------
class _AiSupportSection extends StatelessWidget {
  final bool isDark;
  final List<String> suggestedQuestions;
  final TextEditingController queryController;
  final bool isLoading;
  final String? aiResponse;
  final String? aiError;
  final String? lastAskedQuery;
  final ValueChanged<String> onSelectSuggestion;
  final VoidCallback onSubmitQuery;
  final VoidCallback onRetry;
  final ValueChanged<String> onCopyResponse;

  const _AiSupportSection({
    required this.isDark,
    required this.suggestedQuestions,
    required this.queryController,
    required this.isLoading,
    required this.aiResponse,
    required this.aiError,
    required this.lastAskedQuery,
    required this.onSelectSuggestion,
    required this.onSubmitQuery,
    required this.onRetry,
    required this.onCopyResponse,
  });

  @override
  Widget build(BuildContext context) {
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final mutedInk = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;
    final secondaryInk = isDark
        ? AcadexColors.darkInkSecondary
        : AcadexColors.inkSecondary;

    return AcadexCard(
      key: const Key('ask_ai_section_card'),
      backgroundColor: isDark ? AcadexColors.darkSurface : Colors.white,
      borderColor: isDark ? AcadexColors.darkHairline : const Color(0xFFE2E8F0),
      padding: const EdgeInsets.all(18),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: AcadexRadius.borderRadiusSm,
                ),
                child: const Icon(
                  LucideIcons.bot,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask ACADEXSYNC AI Support',
                      style: AcadexTypography.heading3(color: inkColor),
                    ),
                    Text(
                      'Instant answers for activation, logins, recovery & institutional setup',
                      style: AcadexTypography.caption(color: mutedInk),
                    ),
                  ],
                ),
              ),
              const AcadexBadge(
                label: 'AI ASSISTANT',
                variant: AcadexBadgeVariant.info,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Suggested Question Chips
          Text(
            'Suggested Support Topics:',
            style: AcadexTypography.caption(
              color: mutedInk,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestedQuestions.map((q) {
              return ActionChip(
                key: Key('suggested_chip_${q.hashCode}'),
                backgroundColor: isDark
                    ? AcadexColors.darkCanvasSoft
                    : const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: isDark
                      ? AcadexColors.darkHairline
                      : const Color(0xFFE2E8F0),
                ),
                avatar: const Icon(
                  LucideIcons.messageSquare,
                  size: 14,
                  color: AcadexColors.primary,
                ),
                label: Text(
                  q,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: inkColor,
                  ),
                ),
                onPressed: isLoading ? null : () => onSelectSuggestion(q),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Query Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('ai_query_input_field'),
                  controller: queryController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmitQuery(),
                  decoration: InputDecoration(
                    hintText: 'Type your question or choose a topic above...',
                    hintStyle: AcadexTypography.bodySmall(color: mutedInk),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AcadexColors.darkCanvasSoft
                        : AcadexColors.canvasSoft,
                    border: OutlineInputBorder(
                      borderRadius: AcadexRadius.borderRadiusSm,
                      borderSide: BorderSide(
                        color: isDark
                            ? AcadexColors.darkHairline
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AcadexRadius.borderRadiusSm,
                      borderSide: BorderSide(
                        color: isDark
                            ? AcadexColors.darkHairline
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  key: const Key('ai_query_send_button'),
                  onPressed: isLoading ? null : onSubmitQuery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcadexColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(LucideIcons.arrowRight, size: 18),
                ),
              ),
            ],
          ),

          // Response / Loading / Error Display
          if (isLoading) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AcadexColors.darkCanvasSoft
                    : const Color(0xFFF8FAFC),
                borderRadius: AcadexRadius.borderRadiusSm,
                border: Border.all(
                  color: isDark
                      ? AcadexColors.darkHairline
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ACADEXSYNC AI is preparing your response...',
                    style: AcadexTypography.caption(color: mutedInk),
                  ),
                ],
              ),
            ),
          ] else if (aiError != null) ...[
            const SizedBox(height: 14),
            Container(
              key: const Key('ai_error_card'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AcadexColors.errorDarkContainer.withValues(alpha: 0.25)
                    : AcadexColors.errorLight.withValues(alpha: 0.6),
                borderRadius: AcadexRadius.borderRadiusSm,
                border: Border.all(
                  color: isDark
                      ? AcadexColors.errorDark
                      : AcadexColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 16,
                        color: isDark
                            ? AcadexColors.errorLight
                            : AcadexColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiError!,
                          style: AcadexTypography.bodySmall(color: inkColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw, size: 14),
                    label: const Text(
                      'Retry Query',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (aiResponse != null) ...[
            const SizedBox(height: 14),
            Container(
              key: const Key('ai_response_card'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AcadexColors.darkCanvasSoft
                    : const Color(0xFFF8FAFC),
                borderRadius: AcadexRadius.borderRadiusSm,
                border: Border.all(
                  color: isDark
                      ? AcadexColors.darkHairline
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        size: 16,
                        color: AcadexColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Support Guidance',
                        style: AcadexTypography.caption(
                          color: AcadexColors.primary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Copy response',
                        icon: const Icon(LucideIcons.copy, size: 14),
                        onPressed: () => onCopyResponse(aiResponse!),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  SelectableText(
                    aiResponse!,
                    style: AcadexTypography.body(
                      color: secondaryInk,
                    ).copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Informational guidance. For official grade verification or dispute escalation, contact your department HOD.',
                    style: AcadexTypography.caption(
                      color: mutedInk,
                    ).copyWith(fontStyle: FontStyle.italic, fontSize: 11),
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

// ---------------------------------------------------------------------------
// FAQ Accordion Widget
// ---------------------------------------------------------------------------
class _FaqAccordion extends StatelessWidget {
  final bool isDark;
  final Map<int, bool> expandedMap;
  final ValueChanged<int> onToggle;
  final ValueChanged<String> onAskAi;

  const _FaqAccordion({
    required this.isDark,
    required this.expandedMap,
    required this.onToggle,
    required this.onAskAi,
  });

  static const List<_FaqItemData> items = [
    _FaqItemData(
      question: 'How do I activate my institutional account?',
      answer:
          'ACADEXSYNC supports two activation modes:\n'
          '• Code-First: Enter the unique 8-character invitation code provided by your college admin.\n'
          '• Email-First: Enter your institutional email address to look up pending invitations.\n'
          'After confirming your identity, you will verify a 6-digit OTP sent to your verified email and set your secure password.',
    ),
    _FaqItemData(
      question: 'How does Email OTP authentication work?',
      answer:
          'ACADEXSYNC provides one-time passcode verification for two-factor login and activation.\n'
          'Codes expire after 5 minutes and include a 60-second resend cooldown. '
          'Maximum 5 verification attempts are allowed per code before renewal is required.',
    ),
    _FaqItemData(
      question: 'How can our college or university onboard onto ACADEXSYNC?',
      answer:
          'College administrators can tap "Register Your College" above to generate a formal onboarding request email to ragoorupoornesh@gmail.com. '
          'Our team provisions your tenant database, configures departments, and delivers master admin credentials.',
    ),
    _FaqItemData(
      question: 'How do I reset my account password?',
      answer:
          'On the login screen, select "Forgot Password?". Enter your registered institutional email to receive a password reset token. '
          'Once verified via email OTP, you can establish a new password compliant with password policy requirements.',
    ),
    _FaqItemData(
      question: 'What institutional roles are supported?',
      answer:
          'ACADEXSYNC enforces strict role-based access control (RBAC):\n'
          '• Super Admin: Multi-tenant operations and server management.\n'
          '• College Admin: Campus departments, faculty invitations, and academic calendars.\n'
          '• HOD: Departmental courses, timetable allotment, and performance analytics.\n'
          '• Faculty: Class attendance, marks entry, and assignment grading.\n'
          '• Student: Enrolled course timetables, personal attendance, and evaluation feedback.',
    ),
    _FaqItemData(
      question: 'What should I do if I experience login or technical issues?',
      answer:
          '1. Ensure your device has an active internet connection.\n'
          '2. For OTP issues, check your email spam/junk folder.\n'
          '3. If your account is locked due to repeated attempts, wait 15 minutes or contact your department admin.\n'
          '4. Reach our support desk directly at +91 8686633340 or ragoorupoornesh@gmail.com.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isExpanded = expandedMap[index] ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FaqItemCard(
            key: Key('faq_item_$index'),
            isDark: isDark,
            index: index,
            item: item,
            isExpanded: isExpanded,
            onToggle: () => onToggle(index),
            onAskAi: () => onAskAi(item.question),
          ),
        );
      }),
    );
  }
}

class _FaqItemData {
  final String question;
  final String answer;

  const _FaqItemData({required this.question, required this.answer});
}

class _FaqItemCard extends StatelessWidget {
  final bool isDark;
  final int index;
  final _FaqItemData item;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAskAi;

  const _FaqItemCard({
    super.key,
    required this.isDark,
    required this.index,
    required this.item,
    required this.isExpanded,
    required this.onToggle,
    required this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final secondaryInk = isDark
        ? AcadexColors.darkInkSecondary
        : AcadexColors.inkSecondary;
    final mutedInk = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;

    return AcadexCard(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AcadexColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AcadexColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.question,
                    style: AcadexTypography.body(
                      color: inkColor,
                    ).copyWith(fontWeight: FontWeight.w600),
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
              item.answer,
              style: AcadexTypography.bodySmall(
                color: secondaryInk,
              ).copyWith(height: 1.5),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onAskAi,
                  icon: const Icon(LucideIcons.sparkles, size: 14),
                  label: const Text(
                    'Ask AI More',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// College Onboarding Modal Dialog
// ---------------------------------------------------------------------------
class _CollegeOnboardingDialog extends StatefulWidget {
  const _CollegeOnboardingDialog();

  @override
  State<_CollegeOnboardingDialog> createState() =>
      _CollegeOnboardingDialogState();
}

class _CollegeOnboardingDialogState extends State<_CollegeOnboardingDialog> {
  final _formKey = GlobalKey<FormState>();

  final _collegeNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _designationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentCountController = TextEditingController(text: '1,000 - 3,000');
  final _facultyCountController = TextEditingController(text: '50 - 150');
  final _demoDateController = TextEditingController(
    text: 'Next available working day',
  );
  final _notesController = TextEditingController();

  final Set<String> _selectedModules = {
    'Attendance & Timetable',
    'Grading & Marks',
    'AI Assistant Hub',
  };

  final List<String> _availableModules = const [
    'Attendance & Timetable',
    'Grading & Marks',
    'AI Assistant Hub',
    'Faculty Management',
    'Student Portal',
    'Department Analytics',
  ];

  @override
  void dispose() {
    _collegeNameController.dispose();
    _locationController.dispose();
    _adminNameController.dispose();
    _designationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentCountController.dispose();
    _facultyCountController.dispose();
    _demoDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatEmailBody() {
    final modules = _selectedModules.join(', ');
    return '''
Dear ACADEXSYNC Institutional Onboarding Team,

I would like to request institutional onboarding and a scheduled demonstration of the ACADEXSYNC campus management system.

1. Institution Overview:
• Institution Name: ${_collegeNameController.text.trim()}
• Campus Location & State: ${_locationController.text.trim()}
• Estimated Student Enrollment: ${_studentCountController.text.trim()}
• Estimated Faculty Count: ${_facultyCountController.text.trim()}

2. Primary Administrator Contact:
• Full Name: ${_adminNameController.text.trim()}
• Designation / Title: ${_designationController.text.trim()}
• Official Email: ${_emailController.text.trim()}
• Phone Number: ${_phoneController.text.trim().isEmpty ? 'Not provided' : _phoneController.text.trim()}

3. Desired Modules & Use Cases:
• $modules

4. Preferred Demonstration Schedule:
• ${_demoDateController.text.trim()}

5. Additional Institutional Requirements & Notes:
• ${_notesController.text.trim().isEmpty ? 'None' : _notesController.text.trim()}

Please contact us to discuss institutional deployment, trial provisioning, and departmental onboarding.

Sincerely,
${_adminNameController.text.trim()}
${_designationController.text.trim()}
${_collegeNameController.text.trim()}
''';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final subject =
        'ACADEXSYNC Institutional Onboarding Request – ${_collegeNameController.text.trim()}';
    final body = _formatEmailBody();

    final mailUri = Uri(
      scheme: 'mailto',
      path: ContactUsScreen.ownerEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final launched = await launchUrl(
        mailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await _copyDraftAndNotify(subject, body);
      } else {
        if (mounted) {
          nav.pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Email client opened. Onboarding is confirmed after institutional review.',
              ),
              backgroundColor: AcadexColors.primary,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (_) {
      await _copyDraftAndNotify(subject, body);
    }
  }

  Future<void> _copyDraftAndNotify(String subject, String body) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final fullText =
        'To: ${ContactUsScreen.ownerEmail}\nSubject: $subject\n\n$body';
    Clipboard.setData(ClipboardData(text: fullText));
    if (mounted) {
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Formatted email copied to clipboard! Paste it into your mail application.',
          ),
          backgroundColor: AcadexColors.primary,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkColor = isDark ? AcadexColors.darkInk : AcadexColors.ink;
    final mutedInk = isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted;

    return Dialog(
      key: const Key('college_onboarding_dialog'),
      backgroundColor: isDark ? AcadexColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog Title & Close
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.12),
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: const Icon(
                        LucideIcons.building,
                        size: 18,
                        color: AcadexColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Register Your College',
                            style: AcadexTypography.heading3(color: inkColor),
                          ),
                          Text(
                            'Compose formatted request to ${ContactUsScreen.ownerEmail}',
                            style: AcadexTypography.caption(color: mutedInk),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Form Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Institution Name
                        TextFormField(
                          key: const Key('onboarding_college_name_field'),
                          controller: _collegeNameController,
                          decoration: const InputDecoration(
                            labelText: 'College / Institution Name *',
                            hintText:
                                'e.g. Sri Venkateswara Institute of Technology',
                            prefixIcon: Icon(LucideIcons.school, size: 18),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Please enter your institution name'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Location & State
                        TextFormField(
                          key: const Key('onboarding_location_field'),
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Campus Location & State *',
                            hintText: 'e.g. Tirupati, Andhra Pradesh',
                            prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? 'Please specify city and state'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Admin Name & Designation
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const Key('onboarding_admin_name_field'),
                                controller: _adminNameController,
                                decoration: const InputDecoration(
                                  labelText: "Administrator's Name *",
                                  hintText: 'e.g. Dr. K. Ramesh',
                                  prefixIcon: Icon(LucideIcons.user, size: 18),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                key: const Key('onboarding_designation_field'),
                                controller: _designationController,
                                decoration: const InputDecoration(
                                  labelText: 'Designation *',
                                  hintText: 'e.g. Principal / Dean',
                                  prefixIcon: Icon(
                                    LucideIcons.badgeCheck,
                                    size: 18,
                                  ),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Official Email & Phone
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: const Key('onboarding_email_field'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Official Email *',
                                  hintText: 'dean@svit.edu.in',
                                  prefixIcon: Icon(LucideIcons.mail, size: 18),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (!val.contains('@') ||
                                      !val.contains('.')) {
                                    return 'Invalid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                key: const Key('onboarding_phone_field'),
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone (Optional)',
                                  hintText: '+91 9876543210',
                                  prefixIcon: Icon(LucideIcons.phone, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Student and Faculty Count
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _studentCountController,
                                decoration: const InputDecoration(
                                  labelText: 'Approx. Students',
                                  prefixIcon: Icon(LucideIcons.users, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _facultyCountController,
                                decoration: const InputDecoration(
                                  labelText: 'Approx. Faculty',
                                  prefixIcon: Icon(
                                    LucideIcons.graduationCap,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Modules selection
                        Text(
                          'Required Modules / Use Cases:',
                          style: AcadexTypography.caption(
                            color: mutedInk,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _availableModules.map((module) {
                            final selected = _selectedModules.contains(module);
                            return FilterChip(
                              label: Text(
                                module,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected ? Colors.white : inkColor,
                                ),
                              ),
                              selected: selected,
                              selectedColor: AcadexColors.primary,
                              checkmarkColor: Colors.white,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedModules.add(module);
                                  } else {
                                    _selectedModules.remove(module);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Preferred Demo Date / Time
                        TextFormField(
                          controller: _demoDateController,
                          decoration: const InputDecoration(
                            labelText: 'Preferred Demo Date or Time',
                            prefixIcon: Icon(LucideIcons.calendar, size: 18),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Additional Notes
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Additional Message / Inquiries',
                            hintText:
                                'Any special requirements or existing SIS migrations...',
                            prefixIcon: Icon(LucideIcons.fileText, size: 18),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Transparency Note
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AcadexColors.darkCanvasSoft
                                : AcadexColors.canvasSoft,
                            borderRadius: AcadexRadius.borderRadiusSm,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.info,
                                size: 16,
                                color: AcadexColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Note: Composing or opening the email draft does not automatically register the college. Onboarding is established after institutional verification.',
                                  style: AcadexTypography.caption(
                                    color: mutedInk,
                                  ).copyWith(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Actions: Submit Mailto or Copy Draft
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('copy_email_draft_button'),
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            final subject =
                                'ACADEXSYNC Institutional Onboarding Request – ${_collegeNameController.text.trim()}';
                            final body = _formatEmailBody();
                            _copyDraftAndNotify(subject, body);
                          }
                        },
                        icon: const Icon(LucideIcons.copy, size: 16),
                        label: const Text('Copy Email Draft'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('submit_onboarding_form_button'),
                        onPressed: _submitForm,
                        icon: const Icon(LucideIcons.send, size: 16),
                        label: const Text('Compose Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AcadexColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
