import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/certificate.dart';
import '../../domain/models/certificate_status.dart';
import 'certificate_type_badge.dart';

class CertificateCard extends StatefulWidget {
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

  @override
  State<CertificateCard> createState() => _CertificateCardState();
}

class _CertificateCardState extends State<CertificateCard> {
  bool _isHovered = false;

  Color _statusColor(CertificateStatus s, bool isDark) {
    if (widget.certificate.isVerified) {
      return AcadexColors.success;
    }
    switch (s) {
      case CertificateStatus.verified:
        return AcadexColors.success;
      case CertificateStatus.pendingVerification:
        return AcadexColors.warning;
      case CertificateStatus.archived:
        return AcadexColors.inkMuted;
      case CertificateStatus.removed:
        return AcadexColors.error;
      default:
        return AcadexColors.primary;
    }
  }

  String _statusLabel(CertificateStatus s) {
    if (widget.certificate.isVerified) return 'Verified ✓';
    switch (s) {
      case CertificateStatus.verified:
        return 'Verified ✓';
      case CertificateStatus.pendingVerification:
        return 'Pending Verification';
      case CertificateStatus.archived:
        return 'Archived';
      case CertificateStatus.removed:
        return 'Removed';
      default:
        return 'Active';
    }
  }

  bool get _isPreviewable {
    final ext = widget.certificate.fileType.toLowerCase();
    return ext == 'pdf' || ext == 'jpg' || ext == 'jpeg' || ext == 'png';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.certificate;
    final statusColor = _statusColor(c.status, isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AcadexMotion.micro,
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        transform: _isHovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
          borderRadius: BorderRadius.circular(AcadexRadius.lg),
          border: Border.all(
            color: _isHovered
                ? AcadexColors.primary.withValues(alpha: 0.4)
                : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AcadexRadius.lg),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AcadexRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: Type badge + Status + Optional popup menu
                  Row(
                    children: [
                      CertificateTypeBadge(type: c.type),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? statusColor.withValues(alpha: 0.18) : statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AcadexRadius.full),
                          border: Border.all(
                            color: isDark ? statusColor.withValues(alpha: 0.35) : statusColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (c.isVerified) ...[
                              Icon(LucideIcons.badgeCheck, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              _statusLabel(c.status),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (widget.onEdit != null || widget.onDelete != null)
                        PopupMenuButton<String>(
                          icon: Icon(
                            LucideIcons.ellipsisVertical,
                            size: 18,
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                          color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                          itemBuilder: (_) => [
                            if (widget.onEdit != null)
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.pencil, size: 15),
                                    const SizedBox(width: 8),
                                    Text('Edit Details', style: GoogleFonts.inter(fontSize: 13)),
                                  ],
                                ),
                              ),
                            if (widget.onDelete != null)
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.trash2, size: 15, color: AcadexColors.error),
                                    const SizedBox(width: 8),
                                    Text('Remove', style: GoogleFonts.inter(fontSize: 13, color: AcadexColors.error)),
                                  ],
                                ),
                              ),
                          ],
                          onSelected: (v) {
                            if (v == 'edit') widget.onEdit?.call();
                            if (v == 'delete') widget.onDelete?.call();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Student Name (if shown for Faculty view)
                  if (widget.showStudentName && c.studentName.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          LucideIcons.user,
                          size: 13,
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${c.studentName} (${c.studentId})',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Title
                  Text(
                    c.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Issuer
                  Row(
                    children: [
                      Icon(
                        LucideIcons.building,
                        size: 13,
                        color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          c.issuer,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bottom metadata bar: Issue date, Format pill, Preview/Download badge
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 12,
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Issued: ${DateFormat('dd MMM yyyy').format(c.issueDate)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : AcadexColors.secondaryLight,
                          borderRadius: BorderRadius.circular(AcadexRadius.xs),
                        ),
                        child: Text(
                          c.fileType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                      ),
                      Text(
                        c.fileSizeDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPreviewable ? LucideIcons.eye : LucideIcons.download,
                            size: 11,
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _isPreviewable ? 'Preview' : 'Download',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
