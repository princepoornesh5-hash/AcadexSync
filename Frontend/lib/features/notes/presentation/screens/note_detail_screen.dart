import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/note_model.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';

class NoteDetailScreen extends ConsumerWidget {
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final subject = subjectsAsync.maybeWhen(
      data: (subjects) => subjects.where((s) => s.id == note.subjectId).firstOrNull,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text('Note Details', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (subject != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DashboardColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subject.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DashboardColors.surface,
                    border: Border.all(color: DashboardColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.resourceType.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: DashboardColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (note.chapter != null && note.chapter!.isNotEmpty) ...[
              Text(
                note.chapter!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.primary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              note.title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: DashboardColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.calendar, size: 16, color: DashboardColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Updated ${timeago.format(note.updatedAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: DashboardColors.textMuted,
                  ),
                ),
                if (note.publishedAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(LucideIcons.checkCircle2, size: 16, color: DashboardColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Published',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: DashboardColors.success,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Content
            if (note.description.isNotEmpty) ...[
              Text(
                'Description',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                note.description,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: DashboardColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (note.resourceType == ResourceType.textNote && note.content != null && note.content!.isNotEmpty) ...[
              Text(
                'Content',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DashboardColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.border),
                ),
                child: SelectableText(
                  note.content!,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: DashboardColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ],

            if (note.resourceType == ResourceType.externalLink && note.externalUrl != null && note.externalUrl!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DashboardColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.externalLink, size: 48, color: DashboardColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'External Resource',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This note contains an external link. Click below to open it in your browser.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: DashboardColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openUrl(context, note.externalUrl!),
                      icon: const Icon(LucideIcons.globe, size: 18),
                      label: const Text('Open Resource'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (note.resourceType == ResourceType.fileAttachment && note.fileUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DashboardColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.fileArchive, size: 48, color: DashboardColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      note.fileName ?? 'Attached File',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (note.fileSize != null)
                      Text(
                        'Size: ${(note.fileSize! / 1024 / 1024).toStringAsFixed(2)} MB • Type: ${note.fileType?.toUpperCase() ?? 'UNKNOWN'}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: DashboardColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _openUrl(context, note.fileUrl!),
                      icon: const Icon(LucideIcons.download, size: 18),
                      label: const Text('Download / View Original File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DashboardColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    if (urlString.startsWith('mock://')) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Mock Storage Limitation'),
            content: const Text('File download is simulated because Firebase Storage is intentionally deferred for billing reasons. In production with a connected bucket, the original file would download now.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood'),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the URL.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL format.')),
        );
      }
    }
  }
}
