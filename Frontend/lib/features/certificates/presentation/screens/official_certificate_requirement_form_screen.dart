import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/official_certificate_models.dart';
import '../providers/official_certificate_providers.dart';

class OfficialCertificateRequirementFormScreen extends ConsumerStatefulWidget {
  final String? requirementId;
  final OfficialCertificateRequirement? requirement;

  const OfficialCertificateRequirementFormScreen({
    super.key,
    this.requirementId,
    this.requirement,
  });

  @override
  ConsumerState<OfficialCertificateRequirementFormScreen> createState() =>
      _OfficialCertificateRequirementFormScreenState();
}

class _OfficialCertificateRequirementFormScreenState
    extends ConsumerState<OfficialCertificateRequirementFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;

  RequirementApplicability _applicableTo = RequirementApplicability.college;
  RequirementStatus _status = RequirementStatus.active;

  String? _selectedDepartmentId;
  String? _selectedCourseId;
  String? _selectedSemesterId;
  String? _selectedSectionId;

  bool _isRequired = true;
  bool _isVerificationRequired = true;
  List<String> _allowedFileTypes = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
  int _maxFileSizeMB = 10;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final req = widget.requirement;
    _nameController = TextEditingController(text: req?.name ?? '');
    _descriptionController = TextEditingController(text: req?.description ?? '');
    _categoryController = TextEditingController(text: req?.category ?? 'General');

    if (req != null) {
      _applicableTo = req.applicableTo;
      _status = req.status;
      _selectedDepartmentId = req.departmentId;
      _selectedCourseId = req.courseId;
      _selectedSemesterId = req.semesterId;
      _selectedSectionId = req.sectionId;
      _isRequired = req.required;
      _isVerificationRequired = req.verificationRequired;
      _allowedFileTypes = List.from(req.allowedFileTypes);
      _maxFileSizeMB = req.maxFileSizeBytes ~/ (1024 * 1024);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    // HOD auto-scoping
    if (user.role == AppRole.hod) {
      _applicableTo = RequirementApplicability.department;
      _selectedDepartmentId = user.departmentId;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(officialCertificateRepositoryProvider);
      final isEditing = widget.requirement != null;
      final reqId = isEditing ? widget.requirement!.id : const Uuid().v4();

      final requirement = OfficialCertificateRequirement(
        id: reqId,
        collegeId: user.collegeId ?? 'default',
        departmentId: _selectedDepartmentId,
        courseId: _selectedCourseId,
        semesterId: _selectedSemesterId,
        sectionId: _selectedSectionId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'General',
        required: _isRequired,
        verificationRequired: _isVerificationRequired,
        allowedFileTypes: _allowedFileTypes,
        maxFileSizeBytes: _maxFileSizeMB * 1024 * 1024,
        applicableTo: _applicableTo,
        status: _status,
        createdBy: user.name,
        createdAt: isEditing ? widget.requirement!.createdAt : DateTime.now(),
        updatedAt: isEditing ? DateTime.now() : null,
      );

      if (isEditing) {
        await repo.updateRequirement(requirement);
      } else {
        await repo.createRequirement(requirement);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Requirement updated successfully!' : 'Requirement created successfully!'),
            backgroundColor: AcadexColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.requirement != null;

    final authState = ref.watch(authProvider);
    final isHod = authState is AuthAuthenticated && authState.user.role == AppRole.hod;

    final departments = ref.watch(departmentsProvider).valueOrNull ?? [];
    final courses = ref.watch(coursesProvider).valueOrNull ?? [];
    final semesters = ref.watch(semestersProvider).valueOrNull ?? [];
    final sections = ref.watch(sectionsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AcadexSpacing.space48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcadexPageHeader(
                  title: isEditing ? 'Edit Certificate Requirement' : 'New Certificate Requirement',
                  subtitle: 'Define official college document requirements and upload rules for students.',
                ),
                const SizedBox(height: AcadexSpacing.space16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AcadexSpacing.space16),
                    decoration: BoxDecoration(
                      color: AcadexColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AcadexRadius.md),
                      border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AcadexTypography.bodyMedium(color: AcadexColors.error),
                    ),
                  ),
                  const SizedBox(height: AcadexSpacing.space16),
                ],

                // SECTION 1: BASIC INFORMATION
                AcadexCard(
                  padding: const EdgeInsets.all(AcadexSpacing.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Basic Information',
                        style: AcadexTypography.heading3(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Certificate Name *',
                          hintText: 'e.g. Transfer Certificate, Study Certificate, Birth Certificate',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Certificate name is required' : null,
                      ),
                      const SizedBox(height: AcadexSpacing.space16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Provide instructions for the student regarding what document to upload.',
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'e.g. Admission, Academic, General, Disciplinary',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AcadexSpacing.space16),

                // SECTION 2: APPLICABILITY SCOPE
                AcadexCard(
                  padding: const EdgeInsets.all(AcadexSpacing.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Applicability Scope',
                        style: AcadexTypography.heading3(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space16),

                      if (isHod) ...[
                        Text(
                          'Scoped to your Department: ${authState.user.departmentId?.toUpperCase() ?? 'HOD'}',
                          style: AcadexTypography.bodyMedium(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                      ] else ...[
                        DropdownButtonFormField<RequirementApplicability>(
                          value: _applicableTo,
                          decoration: const InputDecoration(labelText: 'Apply To *'),
                          items: RequirementApplicability.values.map((a) {
                            return DropdownMenuItem(value: a, child: Text(a.displayName));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _applicableTo = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: AcadexSpacing.space16),

                        if (_applicableTo != RequirementApplicability.college) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedDepartmentId,
                            decoration: const InputDecoration(labelText: 'Department'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Departments')),
                              ...departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                            ],
                            onChanged: (val) => setState(() => _selectedDepartmentId = val),
                          ),
                          const SizedBox(height: AcadexSpacing.space16),
                        ],

                        if (_applicableTo == RequirementApplicability.course ||
                            _applicableTo == RequirementApplicability.semester ||
                            _applicableTo == RequirementApplicability.section) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedCourseId,
                            decoration: const InputDecoration(labelText: 'Course'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Courses')),
                              ...courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                            ],
                            onChanged: (val) => setState(() => _selectedCourseId = val),
                          ),
                          const SizedBox(height: AcadexSpacing.space16),
                        ],

                        if (_applicableTo == RequirementApplicability.semester ||
                            _applicableTo == RequirementApplicability.section) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedSemesterId,
                            decoration: const InputDecoration(labelText: 'Semester'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Semesters')),
                              ...semesters.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                            ],
                            onChanged: (val) => setState(() => _selectedSemesterId = val),
                          ),
                          const SizedBox(height: AcadexSpacing.space16),
                        ],

                        if (_applicableTo == RequirementApplicability.section) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedSectionId,
                            decoration: const InputDecoration(labelText: 'Section'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Sections')),
                              ...sections.map((sec) => DropdownMenuItem(value: sec.id, child: Text(sec.name))),
                            ],
                            onChanged: (val) => setState(() => _selectedSectionId = val),
                          ),
                          const SizedBox(height: AcadexSpacing.space16),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AcadexSpacing.space16),

                // SECTION 3: SUBMISSION RULES
                AcadexCard(
                  padding: const EdgeInsets.all(AcadexSpacing.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3. Submission Rules',
                        style: AcadexTypography.heading3(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space16),
                      SwitchListTile(
                        title: const Text('Mandatory Document'),
                        subtitle: const Text('Students must submit this document to complete requirements.'),
                        value: _isRequired,
                        onChanged: (val) => setState(() => _isRequired = val),
                      ),
                      SwitchListTile(
                        title: const Text('Verification Required'),
                        subtitle: const Text('Requires Admin/HOD review and approval after student submission.'),
                        value: _isVerificationRequired,
                        onChanged: (val) => setState(() => _isVerificationRequired = val),
                      ),
                      const SizedBox(height: AcadexSpacing.space16),
                      Text(
                        'Accepted File Formats',
                        style: AcadexTypography.title(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space8),
                      Wrap(
                        spacing: 8,
                        children: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'].map((ext) {
                          final isSelected = _allowedFileTypes.contains(ext);
                          return FilterChip(
                            label: Text(ext.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _allowedFileTypes.add(ext);
                                } else {
                                  if (_allowedFileTypes.length > 1) {
                                    _allowedFileTypes.remove(ext);
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AcadexSpacing.space16),

                // SECTION 4: STATUS
                AcadexCard(
                  padding: const EdgeInsets.all(AcadexSpacing.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '4. Status',
                        style: AcadexTypography.heading3(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space16),
                      DropdownButtonFormField<RequirementStatus>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Requirement Status'),
                        items: RequirementStatus.values.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AcadexSpacing.space24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AcadexButton(
                      label: 'Cancel',
                      variant: AcadexButtonVariant.secondary,
                      onPressed: _isSubmitting ? null : () => context.pop(),
                    ),
                    const SizedBox(width: AcadexSpacing.space16),
                    AcadexButton(
                      label: _isSubmitting
                          ? 'Saving...'
                          : (isEditing ? 'Save Changes' : 'Create Requirement'),
                      icon: LucideIcons.check,
                      variant: AcadexButtonVariant.primary,
                      onPressed: _isSubmitting ? null : _save,
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
}
