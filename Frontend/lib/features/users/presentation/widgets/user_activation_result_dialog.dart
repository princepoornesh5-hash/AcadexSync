import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../data/repositories/api_user_repository.dart';

class UserActivationResultDialog extends StatefulWidget {
  final CreateUserResult result;
  final bool isReissue;

  const UserActivationResultDialog({
    super.key,
    required this.result,
    this.isReissue = false,
  });

  static Future<void> show(
    BuildContext context,
    CreateUserResult result, {
    bool isReissue = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserActivationResultDialog(
        result: result,
        isReissue: isReissue,
      ),
    );
  }

  @override
  State<UserActivationResultDialog> createState() => _UserActivationResultDialogState();
}

class _UserActivationResultDialogState extends State<UserActivationResultDialog> {
  bool _codeCopied = false;
  bool _allCopied = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.result.activationCode));
    setState(() => _codeCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.check, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Activation code copied!'),
          ],
        ),
        backgroundColor: AcadexColors.success,
        duration: Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  void _copyAll() {
    final user = widget.result.user;
    final pin = user.employeeId?.isNotEmpty == true
        ? user.employeeId!
        : (user.rollNumber?.isNotEmpty == true ? user.rollNumber! : user.id);
    final collegeCode = widget.result.collegeCode ?? '';
    final buf = StringBuffer();
    buf.writeln('=== ACADEX ACTIVATION CREDENTIALS ===');
    buf.writeln('Name: ${user.name}');
    buf.writeln('Role: ${user.role.displayName}');
    if (collegeCode.isNotEmpty) buf.writeln('College Code: $collegeCode');
    buf.writeln('PIN Number: $pin');
    if (user.email.isNotEmpty) buf.writeln('Email: ${user.email}');
    buf.writeln('Activation Code: ${widget.result.activationCode}');
    buf.writeln('Activate at: /#/activate');
    buf.writeln('======================================');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    setState(() => _allCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.check, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('All credentials copied!'),
          ],
        ),
        backgroundColor: AcadexColors.success,
        duration: Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _allCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.result.user;
    final pin = user.employeeId?.isNotEmpty == true
        ? user.employeeId!
        : (user.rollNumber?.isNotEmpty == true ? user.rollNumber! : user.id);
    final collegeCode = widget.result.collegeCode;
    final expiresAt = widget.result.expiresAt;
    final expiryFormatted = expiresAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(expiresAt.toLocal())
        : '48 hours from issuance';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusLg),
      backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AcadexColors.successLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AcadexColors.success.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(LucideIcons.circleCheck,
                        color: AcadexColors.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isReissue
                              ? 'Activation Code Reissued'
                              : 'User Provisioned Successfully',
                          style: AcadexTypography.heading2(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Share these credentials with the user to activate their account.',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Activation Code Hero Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(
                    color: AcadexColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SINGLE-USE ACTIVATION CODE',
                          style: AcadexTypography.eyebrow(color: AcadexColors.primary)
                              .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
                        ),
                        InkWell(
                          onTap: _copyCode,
                          borderRadius: AcadexRadius.borderRadiusSm,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _codeCopied ? LucideIcons.check : LucideIcons.copy,
                                  size: 14,
                                  color: _codeCopied
                                      ? AcadexColors.success
                                      : AcadexColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _codeCopied ? 'Copied' : 'Copy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _codeCopied
                                        ? AcadexColors.success
                                        : AcadexColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AcadexColors.darkSurfaceCard
                            : AcadexColors.surface,
                        borderRadius: AcadexRadius.borderRadiusSm,
                        border: Border.all(
                          color: isDark
                              ? AcadexColors.darkHairline
                              : AcadexColors.hairline,
                        ),
                      ),
                      child: SelectableText(
                        widget.result.activationCode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.0,
                          color: AcadexColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.clock,
                            size: 13,
                            color: isDark
                                ? AcadexColors.darkInkMuted
                                : AcadexColors.inkMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Expires: $expiryFormatted',
                          style: AcadexTypography.caption(
                            color: isDark
                                ? AcadexColors.darkInkMuted
                                : AcadexColors.inkMuted,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Account Details
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AcadexColors.darkCanvasSoft
                      : AcadexColors.canvas,
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
                child: Column(
                  children: [
                    _row(isDark, 'Full Name', user.name),
                    const Divider(height: 14),
                    _row(isDark, 'Role', user.role.displayName),
                    const Divider(height: 14),
                    _row(isDark, 'PIN Number', pin, mono: true),
                    if (collegeCode != null && collegeCode.isNotEmpty) ...[
                      const Divider(height: 14),
                      _row(isDark, 'College Code', collegeCode, mono: true),
                    ],
                    if (user.email.isNotEmpty) ...[
                      const Divider(height: 14),
                      _row(isDark, 'Email', user.email),
                    ],
                    const Divider(height: 14),
                    _row(isDark, 'Status', 'Pending Activation', badge: true),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AcadexColors.warning.withValues(alpha: 0.08),
                  borderRadius: AcadexRadius.borderRadiusMd,
                  border: Border.all(
                    color: AcadexColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.shieldAlert,
                        color: AcadexColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This code is shown ONCE and cannot be recovered. Copy it now before closing.',
                        style: AcadexTypography.caption(
                          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AcadexButton(
                      label: _allCopied ? 'Copied!' : 'Copy All Credentials',
                      icon: _allCopied ? LucideIcons.check : LucideIcons.copy,
                      variant: AcadexButtonVariant.secondary,
                      onPressed: _copyAll,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AcadexButton(
                      label: 'Done',
                      icon: LucideIcons.check,
                      variant: AcadexButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(bool isDark, String label, String value,
      {bool mono = false, bool badge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AcadexTypography.caption(
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        badge
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AcadexColors.warning.withValues(alpha: 0.15),
                  borderRadius: AcadexRadius.borderRadiusXs,
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AcadexColors.warning,
                  ),
                ),
              )
            : Flexible(
                child: SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: mono ? 'monospace' : null,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
      ],
    );
  }
}
