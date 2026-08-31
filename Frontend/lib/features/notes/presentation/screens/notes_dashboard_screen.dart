import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../providers/notes_providers.dart';
import '../providers/notes_lookup_providers.dart';
import '../widgets/note_card.dart';
import '../../domain/models/note_model.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';

class NotesDashboardScreen extends ConsumerWidget {
  const NotesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    final isFaculty = user.role == AppRole.faculty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasEnclosingScaffold = Scaffold.maybeOf(context) != null;

    final bodyContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcadexPageHeader(
                title: isFaculty ? 'My Notes' : 'Academic Resources',
                subtitle: 'Browse, manage, and share subject notes and reference materials.',
                actions: [
                  if (isFaculty)
                    AcadexButton(
                      label: 'Create Note',
                      icon: LucideIcons.plus,
                      variant: AcadexButtonVariant.primary,
                      onPressed: () => context.go('/notes/new'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFilters(context, ref, user.role, isDark),
              const SizedBox(height: 12),
              Expanded(
                child: _NotesList(role: user.role),
              ),
            ],
          ),
        ),
      ),
    );

    if (hasEnclosingScaffold) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: bodyContent),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, AppRole role, bool isDark) {
    final filters = ref.watch(notesFilterProvider);
    final isStudent = role == AppRole.student;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
        boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search notes by title or description...',
              prefixIcon: Icon(
                LucideIcons.search,
                size: 20,
                color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: AcadexRadius.borderRadiusMd,
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AcadexRadius.borderRadiusMd,
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
                    ref.read(notesFilterProvider.notifier).state =
                        filters.copyWith(resourceType: val, clearResourceType: val == null);
                  },
                ),
                const SizedBox(width: 8),

                // Status Filter (Only for non-students)
                if (!isStudent) ...[
                  _FilterChip<NoteStatus?>(
                    label: 'All Statuses',
                    value: filters.status,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...NoteStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))),
                    ],
                    onChanged: (val) {
                      ref.read(notesFilterProvider.notifier).state =
                          filters.copyWith(status: val, clearStatus: val == null);
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Subject Filter using memoized subject list
                Consumer(builder: (context, ref, _) {
                  final subjectsAsync = ref.watch(subjectsProvider);
                  return subjectsAsync.maybeWhen(
                    data: (subjects) => _FilterChip<String?>(
                      label: 'All Subjects',
                      value: filters.subjectId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Subjects')),
                        ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.code} - ${s.name}'))),
                      ],
                      onChanged: (val) {
                        ref.read(notesFilterProvider.notifier).state =
                            filters.copyWith(subjectId: val, clearSubject: val == null);
                      },
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                }),
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
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
            ),
          ),
          items: items,
          onChanged: onChanged,
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
          ),
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
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
    final subjectMap = ref.watch(notesSubjectMapProvider);

    return notesAsync.when(
      loading: () => const AcadexLoadingState(),
      error: (e, st) => AcadexErrorState(
        title: 'Unable to Load Notes',
        message: e.toString(),
        onRetry: () => ref.refresh(userNotesProvider),
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return AcadexEmptyState(
            title: 'No Notes Found',
            subtitle: role == AppRole.student
                ? 'Check back later for newly published academic resources.'
                : 'Get started by creating your first note or chapter resource.',
            icon: LucideIcons.fileSearch,
            actionLabel: role == AppRole.faculty ? 'Create Note' : null,
            onActionTap: role == AppRole.faculty ? () => context.go('/notes/new') : null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            final subject = subjectMap[note.subjectId];

            Widget? trailing;
            if (role == AppRole.faculty || role == AppRole.hod || role == AppRole.collegeAdmin || role == AppRole.superAdmin) {
              trailing = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).primaryColor),
                    tooltip: 'Edit Note',
                    onPressed: () => context.go('/notes/edit/${note.id}', extra: note),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.error),
                    tooltip: 'Delete Note',
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
        content: const Text('Are you sure you want to delete this note and its associated attachments? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(noteManagementProvider.notifier).deleteNote(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
