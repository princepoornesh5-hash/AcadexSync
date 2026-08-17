import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/models/note_model.dart';
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

    // We only allow Faculty, College Admin, HOD, Super Admin to create notes.
    if (user.role == AppRole.student) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final facultyAsync = ref.watch(facultyProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: Text(widget.existingNote == null ? 'Create Note' : 'Edit Note', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: DashboardColors.textPrimary)),
        backgroundColor: DashboardColors.surface,
        iconTheme: const IconThemeData(color: DashboardColors.textPrimary),
      ),
      body: (facultyAsync.isLoading || subjectsAsync.isLoading || sectionsAsync.isLoading || coursesAsync.isLoading || semestersAsync.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: DashboardColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedFile == null && widget.existingNote?.fileName == null)
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _pickFile,
                                  icon: Icon(LucideIcons.uploadCloud, size: 20),
                                  label: const Text('Select File (.pdf, .doc, .ppt, .jpg)'),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Icon(LucideIcons.file, color: DashboardColors.primary, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedFile?.name ?? widget.existingNote?.fileName ?? 'Unknown File',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          _selectedFile != null
                                              ? '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB'
                                              : '${((widget.existingNote?.fileSize ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB',
                                          style: GoogleFonts.inter(color: DashboardColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(LucideIcons.trash2, color: DashboardColors.error),
                                    onPressed: () {
                                      setState(() {
                                        _selectedFile = null;
                                        // note: we do not clear existingNote fields here, just handle it on save if needed.
                                      });
                                    },
                                  ),
                                  ElevatedButton(
                                    onPressed: _pickFile,
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
                          final me = facultyAsync.value?.where((f) => f.id == user.id).firstOrNull;
                          if (me != null) {
                            availableSubjects = availableSubjects.where((s) => me.subjectIds.contains(s.id)).toList();
                            availableSections = availableSections.where((s) => me.sectionIds.contains(s.id)).toList();
                          }
                        }
                        
                        // Automatically select if only 1 option
                        if (!_isInit && widget.existingNote == null) {
                           if (availableSubjects.length == 1) _selectedSubjectId = availableSubjects.first.id;
                           if (availableSections.length == 1) _selectedSectionId = availableSections.first.id;
                           _isInit = true;
                        }

                        // Auto-fill course/semester based on subject or section if not set
                        if (_selectedSubjectId != null && _selectedCourseId == null) {
                           final subj = availableSubjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
                           if (subj != null) {
                              final sem = (semestersAsync.value ?? []).where((s) => s.id == subj.semesterId).firstOrNull;
                              if (sem != null) {
                                 _selectedCourseId = sem.courseId;
                              }
                           }
                        }
                        if (_selectedSectionId != null && _selectedSemesterId == null) {
                           final sect = availableSections.where((s) => s.id == _selectedSectionId).firstOrNull;
                           if (sect != null) {
                              _selectedSemesterId = sect.semesterId;
                           }
                        }

                        return Column(
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Subject'),
                              value: _selectedSubjectId,
                              items: availableSubjects.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.code} - ${s.name}'))).toList(),
                              onChanged: (val) => setState(() => _selectedSubjectId = val),
                              validator: (val) => val == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Section'),
                              value: _selectedSectionId,
                              items: availableSections.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                              onChanged: (val) => setState(() => _selectedSectionId = val),
                              validator: (val) => val == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            // Course and Semester are often implicit but we might need them
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Course'),
                              value: _selectedCourseId,
                              items: (coursesAsync.value ?? []).map((c) => DropdownMenuItem(value: c.id, child: Text(c.code))).toList(),
                              onChanged: (val) => setState(() => _selectedCourseId = val),
                              validator: (val) => val == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Semester'),
                              value: _selectedSemesterId,
                              items: (semestersAsync.value ?? []).map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                              onChanged: (val) => setState(() => _selectedSemesterId = val),
                              validator: (val) => val == null ? 'Required' : null,
                            ),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Publishing Status'),
                    DropdownButtonFormField<NoteStatus>(
                      decoration: _inputDecoration('Status'),
                      value: _status,
                      items: NoteStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(),
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isUploading ? null : _saveNote,
                        child: _isUploading 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(widget.existingNote == null ? 'Create Note' : 'Update Note', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
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
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: DashboardColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: DashboardColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: DashboardColors.border),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'pdf', 'ppt', 'pptx', 'doc', 'docx'],
      withData: true,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) { // 10MB limit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File must be under 10MB')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file to upload.')));
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

    try {
      if (_resourceType == ResourceType.fileAttachment && _selectedFile != null && _selectedFile!.bytes != null) {
        final storageRepo = ref.read(fileStorageRepositoryProvider);
        final stored = await storageRepo.uploadFile(
          bytes: _selectedFile!.bytes!,
          fileName: _selectedFile!.name,
          contentType: _selectedFile!.extension ?? 'unknown',
          category: FileCategory.noteAttachment,
          ownerUid: user.id,
          collegeId: user.collegeId,
          departmentId: user.departmentId,
          facultyUid: user.id,
        );
        uploadedUrl = stored.downloadUrl;
        uploadedName = stored.fileName;
        uploadedSize = stored.sizeBytes;
        uploadedType = stored.contentType;
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
      }
      
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
        setState(() => _isUploading = false);
      }
    }
  }
}
