import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_back_button.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/models/note_model.dart';
import '../../domain/utils/note_mime_helper.dart';
import '../providers/notes_providers.dart';

class NoteFormScreen extends ConsumerStatefulWidget {
  final NoteModel? existingNote;

  const NoteFormScreen({super.key, this.existingNote});

  @override
  ConsumerState<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends ConsumerState<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _chapterController;
  late TextEditingController _contentController;
  late TextEditingController _urlController;

  PlatformFile? _selectedFile;
  bool _isUploading = false;

  ResourceType _resourceType = ResourceType.textNote;
  NoteStatus _status = NoteStatus.draft;

  String? _selectedSubjectId;
  String? _selectedSectionId;
  String? _selectedCourseId;
  String? _selectedSemesterId;
  String? _selectedFacultyAssignmentId;

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );
    _descController = TextEditingController(
      text: widget.existingNote?.description ?? '',
    );
    _chapterController = TextEditingController(
      text: widget.existingNote?.chapter ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
    _urlController = TextEditingController(
      text: widget.existingNote?.externalUrl ?? '',
    );

    if (widget.existingNote != null) {
      _resourceType = widget.existingNote!.resourceType;
      _status = widget.existingNote!.status;
      _selectedSubjectId = widget.existingNote!.subjectId;
      _selectedSectionId = widget.existingNote!.sectionId;
      _selectedCourseId = widget.existingNote!.courseId;
      _selectedSemesterId = widget.existingNote!.semesterId;
      _selectedFacultyAssignmentId = widget.existingNote!.facultyAssignmentId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _chapterController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;

    // Students and College Admins do not author notes directly
    if (user.role == AppRole.student) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'Unauthorized to manage notes',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    }

    if (user.role == AppRole.collegeAdmin) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: const AcadexBackButton(fallbackRoute: '/notes'),
          title: const Text("Notes Management"),
          backgroundColor: Theme.of(context).colorScheme.surface,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.bookOpen,
                  size: 48,
                  color: AcadexColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  "Notes are Teaching Material",
                  style: AcadexTypography.heading3(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Lesson notes and study materials are authored and published directly by Faculty members for their assigned subjects and sections.",
                  textAlign: TextAlign.center,
                  style: AcadexTypography.body(
                    color:
                        Theme.of(context).textTheme.bodySmall?.color ??
                        AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 20),
                AcadexButton(
                  label: "Back to Notes Overview",
                  icon: LucideIcons.arrowLeft,
                  onPressed: () => context.go('/notes'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final facultyAsync = ref.watch(facultyProvider(null));
    final subjectsAsync = ref.watch(subjectsProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          tooltip: 'Back to Notes',
          onPressed: () => context.safePop(fallbackRoute: '/notes'),
        ),
        title: Text(
          widget.existingNote == null ? 'Create Note' : 'Edit Note',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          (facultyAsync.isLoading ||
              subjectsAsync.isLoading ||
              sectionsAsync.isLoading ||
              coursesAsync.isLoading ||
              semestersAsync.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Basic Details'),
                        TextFormField(
                          controller: _chapterController,
                          decoration: _inputDecoration('Chapter / Topic'),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: _inputDecoration('Title'),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          decoration: _inputDecoration('Description'),
                          maxLines: 2,
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Resource Type'),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<ResourceType>(
                                  value: ResourceType.textNote,
                                  groupValue: _resourceType,
                                  onChanged: (val) =>
                                      setState(() => _resourceType = val!),
                                ),
                                const Text('Text Note'),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<ResourceType>(
                                  value: ResourceType.externalLink,
                                  groupValue: _resourceType,
                                  onChanged: (val) =>
                                      setState(() => _resourceType = val!),
                                ),
                                const Text('External Link'),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<ResourceType>(
                                  value: ResourceType.fileAttachment,
                                  groupValue: _resourceType,
                                  onChanged: (val) =>
                                      setState(() => _resourceType = val!),
                                ),
                                const Text('File Attachment'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_resourceType == ResourceType.textNote)
                          TextFormField(
                            controller: _contentController,
                            decoration: _inputDecoration('Note Content'),
                            maxLines: 10,
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          )
                        else if (_resourceType == ResourceType.externalLink)
                          TextFormField(
                            controller: _urlController,
                            decoration: _inputDecoration(
                              'External URL (https://...)',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (!Uri.tryParse(val)!.hasAbsolutePath)
                                return 'Enter a valid URL';
                              return null;
                            },
                          )
                        else ...[
                          // File Upload UI
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: AcadexRadius.borderRadiusMd,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedFile == null &&
                                    widget.existingNote?.fileName == null)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            LucideIcons.uploadCloud,
                                            size: 40,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: _pickFile,
                                            icon: const Icon(
                                              LucideIcons.folderOpen,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Select File (.pdf, .jpg, .png, .ppt, .doc)',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(
                                                context,
                                              ).primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    AcadexRadius.borderRadiusMd,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Max file size: ${NoteMimeHelper.maxFileSizeMb}MB',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  (Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color ??
                                                  AcadexColors.inkMuted),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.1),
                                          borderRadius:
                                              AcadexRadius.borderRadiusMd,
                                        ),
                                        child: Icon(
                                          LucideIcons.file,
                                          color: Theme.of(context).primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedFile?.name ??
                                                  widget
                                                      .existingNote
                                                      ?.fileName ??
                                                  'Unknown File',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _selectedFile != null
                                                  ? '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB'
                                                  : '${((widget.existingNote?.fileSize ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB',
                                              style: TextStyle(
                                                color:
                                                    (Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color ??
                                                    AcadexColors.inkMuted),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          LucideIcons.trash2,
                                          color: AcadexColors.error,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _selectedFile = null;
                                          });
                                        },
                                      ),
                                      OutlinedButton(
                                        onPressed: _pickFile,
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                AcadexRadius.borderRadiusMd,
                                          ),
                                        ),
                                        child: const Text('Replace'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        _buildSectionTitle('Academic Context'),
                        Builder(
                          builder: (context) {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            final subjects = subjectsAsync.value ?? [];
                            final sections = sectionsAsync.value ?? [];
                            final semesters = semestersAsync.value ?? [];

                            if (user.role == AppRole.faculty) {
                              final assignmentsAsync = ref.watch(
                                myFacultyAssignmentsAsyncProvider,
                              );
                              final syncAssignments = ref.watch(
                                myFacultyAssignmentsProvider,
                              );
                              final Set<String> seenIds = {};
                              final List<FacultyAssignment> rawAssignments =
                                  syncAssignments.isNotEmpty
                                  ? syncAssignments
                                  : (assignmentsAsync.valueOrNull ?? []);
                              final myAssignments = rawAssignments
                                  .where((a) => seenIds.add(a.id))
                                  .toList();

                              final isLoading =
                                  assignmentsAsync.isLoading &&
                                  myAssignments.isEmpty;
                              final hasError =
                                  assignmentsAsync.hasError &&
                                  myAssignments.isEmpty;

                              if (isLoading) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              }

                              if (hasError) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AcadexColors.darkSurfaceCard
                                        : AcadexColors.surface,
                                    borderRadius: AcadexRadius.borderRadiusMd,
                                    border: Border.all(
                                      color: AcadexColors.error.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        LucideIcons.alertTriangle,
                                        color: AcadexColors.error,
                                        size: 36,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "Failed to load teaching assignments",
                                        style: AcadexTypography.heading3(
                                          color: isDark
                                              ? AcadexColors.darkInk
                                              : AcadexColors.ink,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Unable to retrieve your teaching allocations from the server. Please check your connection and retry.",
                                        style: AcadexTypography.caption(
                                          color: isDark
                                              ? AcadexColors.darkInkMuted
                                              : AcadexColors.inkMuted,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ref.invalidate(
                                            myFacultyAssignmentsAsyncProvider,
                                          );
                                          ref.invalidate(
                                            myFacultyAssignmentsProvider,
                                          );
                                        },
                                        icon: const Icon(
                                          LucideIcons.refreshCw,
                                          size: 14,
                                        ),
                                        label: const Text("Retry"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AcadexColors.primary,
                                          foregroundColor: Colors.white,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (myAssignments.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AcadexColors.darkSurfaceCard
                                        : AcadexColors.surface,
                                    borderRadius: AcadexRadius.borderRadiusMd,
                                    border: Border.all(
                                      color: isDark
                                          ? AcadexColors.darkHairline
                                          : AcadexColors.hairline,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        LucideIcons.alertCircle,
                                        color: AcadexColors.warning,
                                        size: 36,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "No active teaching assignments are available for your account.",
                                        style: AcadexTypography.heading3(
                                          color: isDark
                                              ? AcadexColors.darkInk
                                              : AcadexColors.ink,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Teaching assignments must be allocated by your Head of Department before you can author and publish course study notes.",
                                        style: AcadexTypography.caption(
                                          color: isDark
                                              ? AcadexColors.darkInkMuted
                                              : AcadexColors.inkMuted,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Auto-select if only 1 assignment or match existing
                              if (!_isInit && widget.existingNote == null) {
                                _isInit = true;
                                if (myAssignments.length == 1) {
                                  final a = myAssignments.first;
                                  _selectedFacultyAssignmentId = a.id;
                                  _selectedSubjectId = a.subjectId;
                                  _selectedSectionId = a.sectionId;
                                  _selectedSemesterId = a.semesterId;
                                  _selectedCourseId = a.courseId;
                                }
                              } else if (_selectedFacultyAssignmentId == null &&
                                  _selectedSubjectId != null) {
                                final match = myAssignments
                                    .where(
                                      (a) =>
                                          a.subjectId == _selectedSubjectId &&
                                          (_selectedSectionId == null ||
                                              a.sectionId ==
                                                  _selectedSectionId),
                                    )
                                    .firstOrNull;
                                if (match != null) {
                                  _selectedFacultyAssignmentId = match.id;
                                }
                              }

                              final currentAssignment = myAssignments
                                  .where(
                                    (a) => a.id == _selectedFacultyAssignmentId,
                                  )
                                  .firstOrNull;
                              final resolvedSubject = currentAssignment != null
                                  ? subjects
                                        .where(
                                          (s) =>
                                              s.id ==
                                              currentAssignment.subjectId,
                                        )
                                        .firstOrNull
                                  : null;
                              final resolvedSection =
                                  currentAssignment != null &&
                                      currentAssignment.sectionId != null
                                  ? sections
                                        .where(
                                          (s) =>
                                              s.id ==
                                              currentAssignment.sectionId,
                                        )
                                        .firstOrNull
                                  : null;
                              final resolvedSemester = currentAssignment != null
                                  ? semesters
                                        .where(
                                          (s) =>
                                              s.id ==
                                              currentAssignment.semesterId,
                                        )
                                        .firstOrNull
                                  : null;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      'Teaching Assignment / Class *',
                                    ),
                                    value: _selectedFacultyAssignmentId,
                                    items: myAssignments.map((a) {
                                      final subj = subjects
                                          .where((s) => s.id == a.subjectId)
                                          .firstOrNull;
                                      final sec = sections
                                          .where((s) => s.id == a.sectionId)
                                          .firstOrNull;
                                      final sem = semesters
                                          .where((s) => s.id == a.semesterId)
                                          .firstOrNull;
                                      final subTitle = subj != null
                                          ? '${subj.name} (${subj.code})'
                                          : 'Subject ${a.subjectId}';
                                      final secTitle = sec != null
                                          ? 'Section ${sec.name}'
                                          : (a.sectionId != null
                                                ? 'Section ${a.sectionId}'
                                                : 'All Sections');
                                      final semTitle = sem != null
                                          ? 'Sem ${sem.name}'
                                          : '';
                                      return DropdownMenuItem(
                                        value: a.id,
                                        child: Text(
                                          '$subTitle • $secTitle${semTitle.isNotEmpty ? ' • $semTitle' : ''}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedFacultyAssignmentId = val;
                                        final match = myAssignments
                                            .where((a) => a.id == val)
                                            .firstOrNull;
                                        if (match != null) {
                                          _selectedSubjectId = match.subjectId;
                                          _selectedSectionId = match.sectionId;
                                          _selectedSemesterId =
                                              match.semesterId;
                                          _selectedCourseId = match.courseId;
                                          if (_selectedCourseId == null ||
                                              _selectedCourseId!.isEmpty) {
                                            final subj = subjects
                                                .where(
                                                  (s) =>
                                                      s.id == match.subjectId,
                                                )
                                                .firstOrNull;
                                            _selectedCourseId = subj?.courseId;
                                          }
                                        }
                                      });
                                    },
                                    validator: (val) => val == null
                                        ? 'Please select a teaching assignment'
                                        : null,
                                  ),
                                  if (currentAssignment != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AcadexColors.darkCanvasSoft
                                            : AcadexColors.canvasSoft,
                                        borderRadius:
                                            AcadexRadius.borderRadiusMd,
                                        border: Border.all(
                                          color: isDark
                                              ? AcadexColors.darkHairline
                                              : AcadexColors.hairline,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.checkCircle2,
                                            size: 16,
                                            color: AcadexColors.success,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Verified Teaching Scope: ${resolvedSubject?.name ?? "Subject"} • ${resolvedSection != null ? "Section ${resolvedSection.name}" : "All Sections"}${resolvedSemester != null ? " • Sem ${resolvedSemester.name}" : ""}',
                                              style:
                                                  AcadexTypography.caption(
                                                    color: isDark
                                                        ? AcadexColors.darkInk
                                                        : AcadexColors.ink,
                                                  ).copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }

                            // HOD / Admin fallback
                            var availableSubjects = subjects;
                            var availableSections = sections;
                            if (user.role == AppRole.hod &&
                                user.departmentId != null) {
                              availableSubjects = availableSubjects
                                  .where(
                                    (s) => s.departmentId == user.departmentId,
                                  )
                                  .toList();
                              availableSections = availableSections
                                  .where(
                                    (s) => s.departmentId == user.departmentId,
                                  )
                                  .toList();
                            }

                            if (!_isInit && widget.existingNote == null) {
                              if (availableSubjects.length == 1)
                                _selectedSubjectId = availableSubjects.first.id;
                              if (availableSections.length == 1)
                                _selectedSectionId = availableSections.first.id;
                              _isInit = true;
                            }

                            return Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: _inputDecoration('Subject *'),
                                  value: _selectedSubjectId,
                                  items: availableSubjects
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s.id,
                                          child: Text('${s.code} - ${s.name}'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedSubjectId = val;
                                      _selectedSectionId = null;
                                      if (val != null) {
                                        final subj = subjects
                                            .where((s) => s.id == val)
                                            .firstOrNull;
                                        if (subj != null) {
                                          _selectedSemesterId = subj.semesterId;
                                          final sem = semesters
                                              .where(
                                                (s) => s.id == subj.semesterId,
                                              )
                                              .firstOrNull;
                                          if (sem != null) {
                                            _selectedCourseId = sem.courseId;
                                          }
                                        }
                                      }
                                    });
                                  },
                                  validator: (val) =>
                                      val == null ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: _inputDecoration('Section *'),
                                  value: _selectedSectionId,
                                  items: availableSections
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s.id,
                                          child: Text("Section ${s.name}"),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedSectionId = val;
                                      if (val != null &&
                                          _selectedSemesterId == null) {
                                        final sect = sections
                                            .where((s) => s.id == val)
                                            .firstOrNull;
                                        if (sect != null) {
                                          _selectedSemesterId = sect.semesterId;
                                        }
                                      }
                                    });
                                  },
                                  validator: (val) =>
                                      val == null ? 'Required' : null,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        _buildSectionTitle('Publishing Status'),
                        DropdownButtonFormField<NoteStatus>(
                          decoration: _inputDecoration('Status'),
                          initialValue: _status,
                          items: NoteStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => _status = val!),
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: AcadexRadius.borderRadiusMd,
                              ),
                            ),
                            onPressed: _isUploading ? null : _saveNote,
                            child: _isUploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    widget.existingNote == null
                                        ? 'Create Note'
                                        : 'Update Note',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: AcadexRadius.borderRadiusMd,
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AcadexRadius.borderRadiusMd,
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: NoteMimeHelper.allowedExtensions,
      withData: true,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (!NoteMimeHelper.isFileSizeValid(file.size)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File must be under 25MB')),
          );
        }
        return;
      }
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    if (_resourceType == ResourceType.fileAttachment) {
      if (_selectedFile == null && widget.existingNote?.fileName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file to upload.')),
        );
        return;
      }
    }

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    setState(() => _isUploading = true);

    try {
      final notifier = ref.read(noteManagementProvider.notifier);

      if (_resourceType == ResourceType.fileAttachment &&
          _selectedFile != null &&
          _selectedFile!.bytes != null) {
        await notifier.uploadAndPublishNote(
          subjectId: _selectedSubjectId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          chapter: _chapterController.text.trim().isNotEmpty
              ? _chapterController.text.trim()
              : null,
          fileName: _selectedFile!.name,
          fileBytes: _selectedFile!.bytes!,
          semesterId: _selectedSemesterId,
          courseId: _selectedCourseId,
          departmentId: user.departmentId,
          sectionId: _selectedSectionId,
          facultyAssignmentId: _selectedFacultyAssignmentId,
        );
      } else {
        final note = NoteModel(
          id: widget.existingNote?.id ?? '',
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          chapter: _chapterController.text.trim().isNotEmpty
              ? _chapterController.text.trim()
              : null,
          content: _resourceType == ResourceType.textNote
              ? _contentController.text.trim()
              : null,
          externalUrl: _resourceType == ResourceType.externalLink
              ? _urlController.text.trim()
              : null,
          resourceType: _resourceType,
          subjectId: _selectedSubjectId!,
          sectionId: _selectedSectionId ?? '',
          courseId: _selectedCourseId ?? '',
          departmentId:
              user.departmentId ?? widget.existingNote?.departmentId ?? '',
          collegeId: user.collegeId ?? widget.existingNote?.collegeId ?? '',
          semesterId: _selectedSemesterId!,
          facultyAssignmentId: _selectedFacultyAssignmentId,
          facultyId: user.role == AppRole.faculty
              ? user.id
              : widget.existingNote?.facultyId ?? user.id,
          authorUserId: user.id,
          status: _status,
          publishedAt: widget.existingNote?.publishedAt,
          createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.existingNote == null) {
          await notifier.createNote(note);
        } else {
          await notifier.updateNote(note);
        }
      }

      if (mounted) context.safePop(fallbackRoute: '/notes');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
        setState(() => _isUploading = false);
      }
    }
  }
}
