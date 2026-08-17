import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_card.dart';
import '../../domain/models/note_model.dart';

class NotesDashboardScreen extends ConsumerWidget {
  const NotesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    final isFaculty = user.role == AppRole.faculty;

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text(isFaculty ? 'My Notes' : 'Academic Resources', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
        actions: [
          if (isFaculty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/notes/new'),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Create Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context, ref, user.role),
          Expanded(
            child: _NotesList(role: user.role),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, AppRole role) {
    final filters = ref.watch(notesFilterProvider);
    final isStudent = role == AppRole.student;

    return Container(
      padding: const EdgeInsets.all(16),
      color: DashboardColors.surface,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search notes by title or description...',
              prefixIcon: const Icon(LucideIcons.search, size: 20, color: DashboardColors.textSecondary),
              filled: true,
              fillColor: DashboardColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              ref.read(notesFilterProvider.notifier).state = filters.copyWith(searchQuery: val);
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Resource Type Filter
                _FilterChip<ResourceType?>(
                  label: 'All Types',
                  value: filters.resourceType,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Types')),
                    ...ResourceType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))),
                  ],
                  onChanged: (val) {
                    ref.read(notesFilterProvider.notifier).state = filters.copyWith(resourceType: val, clearResourceType: val == null);
                  },
                ),
                const SizedBox(width: 8),

                // Status Filter (Only if not student, as students only see published)
                if (!isStudent) ...[
                  _FilterChip<NoteStatus?>(
                    label: 'All Statuses',
                    value: filters.status,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...NoteStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))),
                    ],
                    onChanged: (val) {
                      ref.read(notesFilterProvider.notifier).state = filters.copyWith(status: val, clearStatus: val == null);
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Subject Filter (using subject dropdown if available, we can just use generic or rely on subject provider)
                Consumer(
                  builder: (context, ref, _) {
                    final subjectsAsync = ref.watch(subjectsProvider);
                    return subjectsAsync.maybeWhen(
                      data: (subjects) => _FilterChip<String?>(
                        label: 'All Subjects',
                        value: filters.subjectId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Subjects')),
                          ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.code))),
                        ],
                        onChanged: (val) {
                          ref.read(notesFilterProvider.notifier).state = filters.copyWith(subjectId: val, clearSubject: val == null);
                        },
                      ),
                      orElse: () => const SizedBox.shrink(),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DashboardColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(label, style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textSecondary)),
          items: items,
          onChanged: onChanged,
          icon: const Icon(LucideIcons.chevronDown, size: 16, color: DashboardColors.textSecondary),
          style: GoogleFonts.inter(fontSize: 13, color: DashboardColors.textPrimary),
          isDense: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}

class _NotesList extends ConsumerWidget {
  final AppRole role;

  const _NotesList({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(filteredNotesProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (notes) {
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.fileX, size: 64, color: DashboardColors.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'No notes found.',
                  style: GoogleFonts.inter(fontSize: 16, color: DashboardColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            
            // Resolve subject for UI
            final subject = subjectsAsync.maybeWhen(
              data: (subjects) => subjects.where((s) => s.id == note.subjectId).firstOrNull,
              orElse: () => null,
            );

            Widget? trailing;
            if (role == AppRole.faculty) {
              trailing = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.edit, size: 18, color: DashboardColors.primary),
                    onPressed: () => context.go('/notes/edit/${note.id}', extra: note),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18, color: DashboardColors.error),
                    onPressed: () => _confirmDelete(context, ref, note.id),
                  ),
                ],
              );
            }

            return NoteCard(
              note: note,
              subject: subject,
              trailing: trailing,
              onTap: () {
                context.go('/notes/${note.id}', extra: note);
              },
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(noteManagementProvider.notifier).deleteNote(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: DashboardColors.error)),
          ),
        ],
      ),
    );
  }
}
