import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../domain/models/note_model.dart';
import '../providers/notes_lookup_providers.dart';
import '../providers/notes_providers.dart';

class NoteDetailScreen extends ConsumerWidget {
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectMap = ref.watch(notesSubjectMapProvider);
    final subject = subjectMap[note.subjectId];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          tooltip: 'Back to Notes',
          onPressed: () => context.safePop(fallbackRoute: '/notes'),
        ),
        title: const Text(
          'Note Details',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (subject != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${subject.code} - ${subject.name}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note.resourceType.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (note.chapter != null && note.chapter!.isNotEmpty) ...[
                  Text(
                    note.chapter!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 16, color: AcadexColors.inkMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Updated ${timeago.format(note.updatedAt)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AcadexColors.inkMuted,
                      ),
                    ),
                    if (note.publishedAt != null) ...[
                      const SizedBox(width: 16),
                      const Icon(LucideIcons.checkCircle2, size: 16, color: AcadexColors.success),
                      const SizedBox(width: 6),
                      const Text(
                        'Published',
                        style: TextStyle(
                          fontSize: 14,
                          color: AcadexColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Description
                if (note.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Content: Text Note
                if (note.resourceType == ResourceType.textNote && note.content != null && note.content!.isNotEmpty) ...[
                  Text(
                    'Content',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: AcadexRadius.borderRadiusLg,
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: SelectableText(
                      note.content!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // Content: External Link
                if (note.resourceType == ResourceType.externalLink &&
                    note.externalUrl != null &&
                    note.externalUrl!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                      borderRadius: AcadexRadius.borderRadiusLg,
                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.externalLink, size: 48, color: Theme.of(context).primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          'External Resource',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This note references an external web resource. Click below to open it in your browser.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _openUrl(context, note.externalUrl!),
                          icon: const Icon(LucideIcons.globe, size: 18),
                          label: const Text('Open Resource'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Content: File Attachment
                if (note.resourceType == ResourceType.fileAttachment && note.fileUrl != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                      borderRadius: AcadexRadius.borderRadiusLg,
                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          note.isPreviewable ? LucideIcons.fileText : LucideIcons.fileArchive,
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          note.fileName ?? 'Attached File',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (note.fileSize != null)
                              Text(
                                '${(note.fileSize! / 1024 / 1024).toStringAsFixed(2)} MB  •  ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: note.isPreviewable
                                    ? AcadexColors.success.withValues(alpha: 0.12)
                                    : (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                note.isPreviewable ? 'Preview Available' : 'Download Required',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: note.isPreviewable
                                      ? AcadexColors.success
                                      : (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _handleFileDownload(context, ref),
                          icon: Icon(note.isPreviewable ? LucideIcons.eye : LucideIcons.download, size: 18),
                          label: Text(note.isPreviewable ? 'Preview / View File' : 'Download File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleFileDownload(BuildContext context, WidgetRef ref) async {
    try {
      String? targetUrl = note.fileUrl;

      // If note has an ID, request fresh short-lived signed download URL from backend
      if (note.id.isNotEmpty && !note.id.startsWith('mock_')) {
        try {
          final repo = ref.read(apiNotesRepositoryProvider);
          final result = await repo.getDownloadUrl(note.id);
          targetUrl = result.downloadUrl;
        } catch (_) {
          // Fall back to stored fileUrl if available
        }
      }

      if (targetUrl == null || targetUrl.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File URL not available')),
          );
        }
        return;
      }

      await _openUrl(context, targetUrl);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open note: $e')),
        );
      }
    }
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    if (urlString.startsWith('mock://')) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Mock Storage'),
            content: const Text('File access is simulated in mock mode.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
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
