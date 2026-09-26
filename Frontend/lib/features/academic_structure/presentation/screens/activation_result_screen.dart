import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../domain/models/academic_models.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';

class ActivationResultScreen extends StatefulWidget {
  final ProvisionAdminResult result;

  const ActivationResultScreen({super.key, required this.result});

  @override
  State<ActivationResultScreen> createState() => _ActivationResultScreenState();
}

class _ActivationResultScreenState extends State<ActivationResultScreen> {
  bool _copied = false;
  bool _allCopied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.result.activationCode));
    setState(() => _copied = true);
    AcadexSnackBar.showSuccess(context, 'Activation code copied to clipboard!');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _copyAllCredentials() {
    final res = widget.result;
    final buf = StringBuffer();
    buf.writeln('=== ACADEX COLLEGE ADMIN CREDENTIALS ===');
    buf.writeln('Name: ${res.adminName}');
    buf.writeln('Role: College Administrator');
    if (res.collegeName.isNotEmpty) {
      buf.writeln('College: ${res.collegeName} (${res.collegeCode})');
    }
    buf.writeln('College Code: ${res.collegeCode}');
    buf.writeln('PIN Number: ${res.adminInstituteId}');
    if (res.adminEmail?.isNotEmpty == true) {
      buf.writeln('Email: ${res.adminEmail}');
    }
    buf.writeln('Activation Code: ${res.activationCode}');
    buf.writeln('Activate at: /#/activate');
    buf.writeln('========================================');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    setState(() => _allCopied = true);
    AcadexSnackBar.showSuccess(context, 'All credentials copied to clipboard!');
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _allCopied = false);
    });
  }

  void _handleDone() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/academics');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = widget.result;
    final expiryFormatted = DateFormat('MMM dd, yyyy • hh:mm a').format(res.expiresAt.toLocal());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: _handleDone,
        ),
        title: Text(
          'Provisioning Result',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: AcadexPageContainer(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success header icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AcadexColors.successLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AcadexColors.success.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(LucideIcons.circleCheck, color: AcadexColors.success, size: 34),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'College Admin Provisioned',
              textAlign: TextAlign.center,
              style: AcadexTypography.heading1(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'An invitation has been created. Provide the activation code below to the administrator to complete setup.',
              textAlign: TextAlign.center,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ).copyWith(fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Activation Code Box (Primary Hero)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusLg,
                border: Border.all(
                  color: AcadexColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: isDark ? AcadexShadows.darkMd : AcadexShadows.lightMd,
              ),
              child: Column(
                children: [
                  Text(
                    'ACTIVATION CODE',
                    style: AcadexTypography.eyebrow(
                      color: AcadexColors.primary,
                    ).copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft,
                      borderRadius: AcadexRadius.borderRadiusMd,
                      border: Border.all(
                        color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      ),
                    ),
                    child: SelectableText(
                      res.activationCode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                        color: AcadexColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.clock, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Expires: $expiryFormatted',
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AcadexButton(
                    label: _copied ? 'Copied to Clipboard!' : 'Copy Activation Code',
                    icon: _copied ? LucideIcons.check : LucideIcons.copy,
                    variant: _copied ? AcadexButtonVariant.secondary : AcadexButtonVariant.primary,
                    isFullWidth: true,
                    onPressed: _copyToClipboard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Administrator Details Card
            AcadexCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administrator Details',
                    style: AcadexTypography.body(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    isDark,
                    icon: LucideIcons.user,
                    label: 'Full Name',
                    value: res.adminName,
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    context,
                    isDark,
                    icon: LucideIcons.idCard,
                    label: 'PIN Number',
                    value: res.adminInstituteId,
                    isMonospace: true,
                  ),
                  if (res.collegeName.isNotEmpty || res.collegeCode.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      context,
                      isDark,
                      icon: LucideIcons.building,
                      label: 'College Code',
                      value: res.collegeName.isNotEmpty
                          ? '${res.collegeName} (${res.collegeCode})'
                          : res.collegeCode,
                    ),
                  ],
                  if (res.adminEmail != null && res.adminEmail!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      context,
                      isDark,
                      icon: LucideIcons.mail,
                      label: 'Email',
                      value: res.adminEmail!,
                    ),
                  ],
                  if (res.adminPhone != null && res.adminPhone!.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow(
                      context,
                      isDark,
                      icon: LucideIcons.phone,
                      label: 'Phone',
                      value: res.adminPhone!,
                    ),
                  ],
                  const Divider(height: 16),
                  _buildDetailRow(
                    context,
                    isDark,
                    icon: LucideIcons.shieldCheck,
                    label: 'Status',
                    value: 'Pending Activation',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Security Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.shieldAlert, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security Notice',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'This activation code is displayed only once and is not stored in plaintext. If lost, you will need to re-issue the invitation.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF92400E) : const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AcadexButton(
                    label: _allCopied ? 'Copied All!' : 'Copy All Credentials',
                    icon: _allCopied ? LucideIcons.check : LucideIcons.copy,
                    variant: AcadexButtonVariant.secondary,
                    onPressed: _copyAllCredentials,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AcadexButton(
                    label: 'Done',
                    icon: LucideIcons.check,
                    variant: AcadexButtonVariant.primary,
                    onPressed: _handleDone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
        const SizedBox(width: 10),
        Text(
          label,
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}
