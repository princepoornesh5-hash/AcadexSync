import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_status.dart';
import 'certificate_type_badge.dart';

class CertificateCard extends StatelessWidget {
  final Certificate certificate;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showStudentName;

  const CertificateCard({
    super.key,
    required this.certificate,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showStudentName = false,
  });

  Color _statusColor(CertificateStatus s) {
    switch (s) {
      case CertificateStatus.verified: return DashboardColors.success;
      case CertificateStatus.pendingVerification: return DashboardColors.warning;
      case CertificateStatus.archived: return DashboardColors.textSecondary;
      default: return DashboardColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = certificate;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: DashboardColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DashboardColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: CertificateTypeBadge(type: c.type)),
                  if (c.isVerified)
                    const Icon(LucideIcons.badgeCheck, size: 18, color: DashboardColors.success),
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.ellipsisVertical, size: 18, color: DashboardColors.textSecondary),
                    itemBuilder: (_) => [
                      if (onEdit != null)
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (onDelete != null)
                        const PopupMenuItem(value: 'delete', child: Text('Remove')),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                c.title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(LucideIcons.building, size: 13, color: DashboardColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      c.issuer,
                      style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (showStudentName) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.user, size: 13, color: DashboardColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      c.studentName,
                      style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 13, color: DashboardColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(c.issueDate),
                    style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textMuted),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(c.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.status.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(c.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.file, size: 13, color: DashboardColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${c.fileType.toUpperCase()} · ${c.fileSizeDisplay}',
                    style: GoogleFonts.inter(fontSize: 11, color: DashboardColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
