import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/note_model.dart';
import '../../../academic_structure/domain/models/academic_models.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final Widget? trailing;
  final Subject? subject;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.trailing,
    this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final isLink = note.resourceType == ResourceType.externalLink;
    final isFile = note.resourceType == ResourceType.fileAttachment;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DashboardColors.border),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isFile 
                            ? DashboardColors.primary.withValues(alpha: 0.15)
                            : isLink 
                                ? DashboardColors.textSecondary.withValues(alpha: 0.1)
                                : DashboardColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isFile ? LucideIcons.paperclip : (isLink ? LucideIcons.link : LucideIcons.fileText),
                        color: isFile ? DashboardColors.primary : (isLink ? DashboardColors.textSecondary : DashboardColors.primary),
                        size: 20,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.chapter != null && note.chapter!.isNotEmpty) ...[
                          Text(
                            note.chapter!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DashboardColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          note.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DashboardColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: DashboardColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (subject != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DashboardColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: DashboardColors.border),
                      ),
                      child: Text(
                        subject!.code,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: DashboardColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (note.fileType != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DashboardColors.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: DashboardColors.border),
                      ),
                      child: Text(
                        note.fileType!.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildStatusBadge(),
                  const Spacer(),
                  Icon(LucideIcons.clock, size: 14, color: DashboardColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(note.updatedAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: DashboardColors.textMuted,
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

  Widget _buildStatusBadge() {
    Color color;
    switch (note.status) {
      case NoteStatus.published:
        color = DashboardColors.success;
        break;
      case NoteStatus.draft:
        color = DashboardColors.warning;
        break;
      case NoteStatus.unpublished:
        color = DashboardColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        note.status.displayName,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
