import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
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
import '../../../../features/storage/domain/models/file_category.dart';
import '../../../../features/storage/presentation/providers/storage_providers.dart';

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

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _descController = TextEditingController(text: widget.existingNote?.description ?? '');
    _chapterController = TextEditingController(text: widget.existingNote?.chapter ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _urlController = TextEditingController(text: widget.existingNote?.externalUrl ?? '');

    if (widget.existingNote != null) {
      _resourceType = widget.existingNote!.resourceType;
      _status = widget.existingNote!.status;
      _selectedSubjectId = widget.existingNote!.subjectId;
      _selectedSectionId = widget.existingNote!.sectionId;
      _selectedCourseId = widget.existingNote!.courseId;
      _selectedSemesterId = widget.existingNote!.semesterId;
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
          title: const Text("Notes Management"),
          backgroundColor: Theme.of(context).colorScheme.surface,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.bookOpen, size: 48, color: AcadexColors.primary),
                const SizedBox(height: 16),
                Text(
                  "Notes are Teaching Material",
                  style: AcadexTypography.heading3(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  "Lesson notes and study materials are authored and published directly by Faculty members for their assigned subjects and sections.",
                  textAlign: TextAlign.center,
                  style: AcadexTypography.body(color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.existingNote == null ? 'Create Note' : 'Edit Note',
          style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: (facultyAsync.isLoading ||
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
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: _inputDecoration('Title'),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          decoration: _inputDecoration('Description'),
                          maxLines: 2,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
                                  onChanged: (val) => setState(() => _resourceType = val!),
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
                                  onChanged: (val) => setState(() => _resourceType = val!),
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
                                  onChanged: (val) => setState(() => _resourceType = val!),
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
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          )
                        else if (_resourceType == ResourceType.externalLink)
                          TextFormField(
                            controller: _urlController,
                            decoration: _inputDecoration('External URL (https://...)'),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (!Uri.tryParse(val)!.hasAbsolutePath) return 'Enter a valid URL';
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
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedFile == null && widget.existingNote?.fileName == null)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Column(
                                        children: [
                                          Icon(
                                            LucideIcons.uploadCloud,
                                            size: 40,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: _pickFile,
                                            icon: const Icon(LucideIcons.folderOpen, size: 18),
                                            label: const Text('Select File (.pdf, .jpg, .png, .ppt, .doc)'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Max file size: ${NoteMimeHelper.maxFileSizeMb}MB',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
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
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                          borderRadius: AcadexRadius.borderRadiusMd,
                                        ),
                                        child: Icon(LucideIcons.file, color: Theme.of(context).primaryColor, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedFile?.name ?? widget.existingNote?.fileName ?? 'Unknown File',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Theme.of(context).colorScheme.onSurface,
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
                                                color: (Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, color: AcadexColors.error, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _selectedFile = null;
                                          });
                                        },
                                      ),
                                      OutlinedButton(
                                        onPressed: _pickFile,
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                                        ),
                                        child: const Text('Replace'),
                                      )
                                    ],
                                  ),
                              ],
                            ),
                          )
                        ],
                        const SizedBox(height: 24),

                        _buildSectionTitle('Academic Context'),
                        Builder(
                          builder: (context) {
                            List<Subject> availableSubjects = subjectsAsync.value ?? [];
                            List<Section> availableSections = sectionsAsync.value ?? [];

                            if (user.role == AppRole.faculty) {
                              availableSubjects = ref.watch(facultyAssignedSubjectsProvider(user.id));
                              if (availableSubjects.isEmpty) {
                                final myAssignments = ref.watch(myFacultyAssignmentsProvider);
                                final assignedSubIds = myAssignments.map((a) => a.subjectId).toSet();
                                availableSubjects = (subjectsAsync.value ?? []).where((s) => assignedSubIds.contains(s.id)).toList();
                              }

                              if (_selectedSubjectId != null) {
                                availableSections = ref.watch(facultyAssignedSectionsProvider((facultyId: user.id, subjectId: _selectedSubjectId)));
                                if (availableSections.isEmpty) {
                                  final myAssignments = ref.watch(myFacultyAssignmentsProvider);
                                  final matchingSecIds = myAssignments
                                      .where((a) => a.subjectId == _selectedSubjectId)
                                      .map((a) => a.sectionId)
                                      .toSet();
                                  availableSections = (sectionsAsync.value ?? []).where((s) => matchingSecIds.contains(s.id)).toList();
                                }
                              } else {
                                availableSections = ref.watch(facultyAssignedSectionsProvider((facultyId: user.id, subjectId: null)));
                              }
                            } else if (user.role == AppRole.hod && user.departmentId != null) {
                              availableSubjects = availableSubjects.where((s) => s.departmentId == user.departmentId).toList();
                              availableSections = availableSections.where((s) => s.departmentId == user.departmentId).toList();
                            }

                            // Automatically select if only 1 option
                            if (!_isInit && widget.existingNote == null) {
                              if (availableSubjects.length == 1) _selectedSubjectId = availableSubjects.first.id;
                              if (availableSections.length == 1) _selectedSectionId = availableSections.first.id;
                              _isInit = true;
                            }

                            return Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: _inputDecoration('Subject *'),
                                  initialValue: _selectedSubjectId,
                                  items: availableSubjects
                                      .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.code} - ${s.name}')))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedSubjectId = val;
                                      _selectedSectionId = null;
                                      if (val != null) {
                                        final subj = (subjectsAsync.value ?? []).where((s) => s.id == val).firstOrNull;
                                        if (subj != null) {
                                          _selectedSemesterId = subj.semesterId;
                                          final sem = (semestersAsync.value ?? []).where((s) => s.id == subj.semesterId).firstOrNull;
                                          if (sem != null) {
                                            _selectedCourseId = sem.courseId;
                                          }
                                        }
                                      }
                                    });
                                  },
                                  validator: (val) => val == null ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: _inputDecoration('Section *'),
                                  initialValue: _selectedSectionId,
                                  items: availableSections
                                      .map((s) => DropdownMenuItem(value: s.id, child: Text("Section ${s.name}")))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedSectionId = val;
                                      if (val != null && _selectedSemesterId == null) {
                                        final sect = (sectionsAsync.value ?? []).where((s) => s.id == val).firstOrNull;
                                        if (sect != null) {
                                          _selectedSemesterId = sect.semesterId;
                                        }
                                      }
                                    });
                                  },
                                  validator: (val) => val == null ? 'Required' : null,
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
                              .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
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
                              shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                            ),
                            onPressed: _isUploading ? null : _saveNote,
                            child: _isUploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    widget.existingNote == null ? 'Create Note' : 'Update Note',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

    String? uploadedUrl = widget.existingNote?.fileUrl;
    String? uploadedName = widget.existingNote?.fileName;
    int? uploadedSize = widget.existingNote?.fileSize;
    String? uploadedType = widget.existingNote?.fileType;
    String? newlyUploadedStoragePath;
    final oldStoragePath = widget.existingNote?.storagePath;

    try {
      if (_resourceType == ResourceType.fileAttachment && _selectedFile != null && _selectedFile!.bytes != null) {
        final storageRepo = ref.read(fileStorageRepositoryProvider);
        final mime = NoteMimeHelper.resolveMimeType(_selectedFile!.name);
        final stored = await storageRepo.uploadFile(
          bytes: _selectedFile!.bytes!,
          fileName: _selectedFile!.name,
          contentType: mime,
          category: FileCategory.noteAttachment,
          ownerUid: user.id,
          collegeId: user.collegeId,
          departmentId: user.departmentId,
          facultyUid: user.id,
        );
        uploadedUrl = stored.downloadUrl;
        uploadedName = stored.fileName;
        uploadedSize = stored.sizeBytes;
        uploadedType = _selectedFile!.extension ?? 'unknown';
        newlyUploadedStoragePath = stored.storagePath;
      }

      final note = NoteModel(
        id: widget.existingNote?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        chapter: _chapterController.text.trim(),
        content: _resourceType == ResourceType.textNote ? _contentController.text.trim() : null,
        externalUrl: _resourceType == ResourceType.externalLink ? _urlController.text.trim() : null,
        resourceType: _resourceType,
        fileName: _resourceType == ResourceType.fileAttachment ? uploadedName : null,
        fileSize: _resourceType == ResourceType.fileAttachment ? uploadedSize : null,
        fileType: _resourceType == ResourceType.fileAttachment ? uploadedType : null,
        fileUrl: _resourceType == ResourceType.fileAttachment ? uploadedUrl : null,
        storagePath: _resourceType == ResourceType.fileAttachment ? (newlyUploadedStoragePath ?? oldStoragePath) : null,
        subjectId: _selectedSubjectId!,
        sectionId: _selectedSectionId!,
        courseId: _selectedCourseId!,
        departmentId: user.departmentId ?? widget.existingNote?.departmentId ?? '',
        collegeId: user.collegeId ?? widget.existingNote?.collegeId ?? '',
        semesterId: _selectedSemesterId!,
        facultyId: user.role == AppRole.faculty ? user.id : widget.existingNote?.facultyId ?? user.id,
        authorUserId: user.id,
        status: _status,
        publishedAt: widget.existingNote?.publishedAt,
        createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final notifier = ref.read(noteManagementProvider.notifier);
      if (widget.existingNote == null) {
        await notifier.createNote(note);
      } else {
        await notifier.updateNote(note);

        // Delete old replaced storage file if a new file was uploaded successfully
        if (newlyUploadedStoragePath != null && oldStoragePath != null && oldStoragePath != newlyUploadedStoragePath) {
          try {
            final storageRepo = ref.read(fileStorageRepositoryProvider);
            await storageRepo.deleteFile(oldStoragePath);
          } catch (_) {}
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      // Failure compensation: Clean up freshly uploaded storage file if metadata write failed
      if (newlyUploadedStoragePath != null) {
        try {
          final storageRepo = ref.read(fileStorageRepositoryProvider);
          await storageRepo.deleteFile(newlyUploadedStoragePath);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
        setState(() => _isUploading = false);
      }
    }
  }
}
