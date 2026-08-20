import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/note_model.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../providers/notes_lookup_providers.dart';

class NoteCard extends ConsumerStatefulWidget {
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
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final isLink = note.resourceType == ResourceType.externalLink;
    final isFile = note.resourceType == ResourceType.fileAttachment;

    final subjectMap = ref.watch(notesSubjectMapProvider);
    final effectiveSubject = widget.subject ?? subjectMap[note.subjectId];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: AcadexMotion.micro,
      margin: const EdgeInsets.only(bottom: 12),
      transform: _isHovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: _isHovered
              ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (hovering) {
            if (_isHovered != hovering) {
              setState(() => _isHovered = hovering);
            }
          },
          borderRadius: AcadexRadius.borderRadiusLg,
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
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.12)
                            : isLink
                                ? (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)
                                    .withValues(alpha: 0.1)
                                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: AcadexRadius.borderRadiusMd,
                      ),
                      child: Icon(
                        isFile
                            ? LucideIcons.paperclip
                            : (isLink ? LucideIcons.link : LucideIcons.fileText),
                        color: isFile
                            ? Theme.of(context).primaryColor
                            : (isLink
                                ? (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)
                                : Theme.of(context).primaryColor),
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 8),
                      widget.trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (effectiveSubject != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: AcadexRadius.borderRadiusXs,
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(
                          effectiveSubject.code,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                    if (note.fileType != null && note.fileType!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: AcadexRadius.borderRadiusXs,
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(
                          note.fileType!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                          ),
                        ),
                      ),
                    ],
                    if (isFile) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: note.isPreviewable
                              ? AcadexColors.success.withValues(alpha: 0.1)
                              : (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)
                                  .withValues(alpha: 0.08),
                          borderRadius: AcadexRadius.borderRadiusXs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              note.isPreviewable ? LucideIcons.eye : LucideIcons.download,
                              size: 12,
                              color: note.isPreviewable
                                  ? AcadexColors.success
                                  : (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note.isPreviewable ? 'Preview' : 'Download',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: note.isPreviewable
                                    ? AcadexColors.success
                                    : (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _buildStatusBadge(note),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.clock, size: 13, color: AcadexColors.inkMuted),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(note.updatedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AcadexColors.inkMuted,
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
    );
  }

  Widget _buildStatusBadge(NoteModel note) {
    Color color;
    switch (note.status) {
      case NoteStatus.published:
        color = AcadexColors.success;
        break;
      case NoteStatus.draft:
        color = AcadexColors.warning;
        break;
      case NoteStatus.unpublished:
        color = AcadexColors.error;
        break;
      case NoteStatus.archived:
        color = AcadexColors.inkMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AcadexRadius.borderRadiusXs,
      ),
      child: Text(
        note.status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
