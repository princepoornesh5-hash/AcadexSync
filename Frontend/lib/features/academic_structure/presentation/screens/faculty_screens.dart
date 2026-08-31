import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../providers/academic_providers.dart';
import '../../domain/models/academic_models.dart';
import '../widgets/faculty_assignment_dialog.dart';
import '../widgets/import_data_dialog.dart';

class FacultyListScreen extends ConsumerStatefulWidget {
  const FacultyListScreen({super.key});

  @override
  ConsumerState<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends ConsumerState<FacultyListScreen> {
  void _showImportDialog() {
    showDialog(context: context, builder: (ctx) => const ImportDataDialog(entityName: 'Faculty'));
  }

  void _showAssignmentDialog(Faculty? faculty) {
    FacultyAssignmentDialog.show(context, faculty: faculty);
  }

  @override
  Widget build(BuildContext context) {
    final facultyAsync = ref.watch(facultyProvider(null));
    final deptMap = ref.watch(departmentMapProvider);
    final assignmentsAsync = ref.watch(facultyAssignmentsProvider);
    final allAssignments = assignmentsAsync.valueOrNull ?? [];

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: AcadexPageHeader(
                  title: "Faculty",
                  subtitle: "Manage faculty members and teaching assignments.",
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAssignmentDialog(null),
                    icon: const Icon(LucideIcons.userPlus, size: 16),
                    label: const Text("Assign Classes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/faculty-assignments'),
                    icon: const Icon(LucideIcons.userCheck, size: 16),
                    label: const Text("All Assignments"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _showImportDialog,
                    icon: const Icon(LucideIcons.uploadCloud, size: 16),
                    label: const Text("Import CSV"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Theme.of(context).cardColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          AcadexSearchFilterBar(
            searchHint: "Search faculty by name or employee ID...",
            onSearchChanged: (v) {},
            onActionTap: () => context.push('/academics/faculty/new'),
            actionLabel: "Add Faculty",
          ),
          const SizedBox(height: 24),
          Expanded(
            child: (facultyAsync.isLoading && facultyAsync.items.isEmpty)
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
              : facultyAsync.error != null 
                ? Center(child: Text("Error: ${facultyAsync.error}", style: const TextStyle(color: AcadexColors.warning)))
                : AcadexDataTable(
                    columns: const ["Employee ID", "Name", "Department", "Teaching Assignments", "Status", "Actions"],
                    rows: facultyAsync.items.map((f) {
                      final deptName = deptMap[f.departmentId]?.name ?? (f.departmentId.isNotEmpty ? f.departmentId : 'Unassigned');
                      final facultyAssignments = allAssignments.where((a) => a.facultyId == f.id).toList();
                      final hasAssignments = facultyAssignments.isNotEmpty || f.subjectIds.isNotEmpty || f.sectionIds.isNotEmpty;
                      final assignmentCount = facultyAssignments.isNotEmpty ? facultyAssignments.length : (f.subjectIds.length);

                      return DataRow(cells: [
                        DataCell(Text(f.employeeId, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
                        DataCell(Text(f.name)),
                        DataCell(Text(deptName)),
                        DataCell(
                          !hasAssignments
                            ? const Text("Unassigned", style: TextStyle(color: AcadexColors.warning, fontStyle: FontStyle.italic))
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "$assignmentCount Active Class${assignmentCount == 1 ? '' : 'es'}",
                                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: f.isActive ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.1) ?? AcadexColors.inkMuted.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(f.isActive ? "Active" : "Inactive", style: TextStyle(color: f.isActive ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                tooltip: "Assign Classes / Subjects",
                                icon: Icon(LucideIcons.bookOpen, size: 18, color: Theme.of(context).primaryColor), 
                                onPressed: () => _showAssignmentDialog(f),
                              ),
                              IconButton(
                                tooltip: "Edit Faculty",
                                icon: Icon(LucideIcons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                onPressed: () => context.push('/academics/faculty/edit/${f.id}'),
                              ),
                              IconButton(
                                tooltip: "Deactivate",
                                icon: const Icon(LucideIcons.trash2, size: 18, color: AcadexColors.warning),
                                onPressed: () {},
                              ),
                            ],
                          )
                        ),
                      ]);
                    }).toList(),
                    emptyState: AcadexEmptyState(
                      title: "No Faculty Found",
                      subtitle: "Add faculty members to assign them to subjects.",
                      icon: LucideIcons.user,
                      actionLabel: "Add Faculty",
                      onActionTap: () => context.push('/academics/faculty/new'),
                    ),
                  ),
          )
        ],
      ),
    );
  }
}

class FacultyActivationResultDialog extends StatelessWidget {
  final ProvisionFacultyResult result;
  final String departmentName;

  const FacultyActivationResultDialog({
    super.key,
    required this.result,
    required this.departmentName,
  });

  static Future<void> show(
    BuildContext context,
    ProvisionFacultyResult result, {
    required String departmentName,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FacultyActivationResultDialog(
        result: result,
        departmentName: departmentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expiresAt = result.invitation.expiresAt;
    final expiryFormatted = expiresAt != null
        ? DateFormat('EEEE, MMM d, yyyy • h:mm a').format(expiresAt.toLocal())
        : '7 days from issue';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AcadexColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.circleCheck, color: AcadexColors.success, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty Account Provisioned',
                        style: AcadexTypography.heading3(color: theme.colorScheme.onSurface),
                      ),
                      Text(
                        'Activation credentials generated successfully',
                        style: AcadexTypography.caption(
                          color: theme.textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(context, 'Faculty Name', result.user.name),
                  const SizedBox(height: 8),
                  _buildDetailRow(context, 'Institute ID', result.user.instituteId ?? result.faculty.employeeId),
                  const SizedBox(height: 8),
                  _buildDetailRow(context, 'Email Address', result.user.email),
                  if (result.faculty.employeeId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(context, 'Employee ID', result.faculty.employeeId),
                  ],
                  const SizedBox(height: 8),
                  _buildDetailRow(context, 'Department', departmentName),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Account Status',
                    result.invitation.status.toUpperCase(),
                    badgeColor: AcadexColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AcadexColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'SINGLE-USE ACTIVATION CODE',
                    style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    result.activationCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: AcadexColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        'Expires: $expiryFormatted',
                        style: AcadexTypography.caption(
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AcadexColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.triangleAlert, color: AcadexColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Save this activation code securely. It will not be shown again after leaving this screen.',
                      style: AcadexTypography.caption(
                        color: isDark ? Colors.white70 : const Color(0xFF7C2D12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.activationCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Activation code copied to clipboard'),
                          backgroundColor: AcadexColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: const Text('Copy Activation Code'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AcadexColors.primary.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? badgeColor}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AcadexTypography.caption(color: theme.textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
        ),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        else
          Text(
            value,
            style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

class FacultyFormScreen extends ConsumerStatefulWidget {
  final String? id;
  const FacultyFormScreen({super.key, this.id});

  @override
  ConsumerState<FacultyFormScreen> createState() => _FacultyFormScreenState();
}

class _FacultyFormScreenState extends ConsumerState<FacultyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _instituteIdCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _employeeIdCtrl;
  late TextEditingController _designationCtrl;
  late TextEditingController _qualificationCtrl;
  late TextEditingController _specializationCtrl;

  String? _selectedDepartmentId;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _instituteIdCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _employeeIdCtrl = TextEditingController();
    _designationCtrl = TextEditingController(text: 'Assistant Professor');
    _qualificationCtrl = TextEditingController();
    _specializationCtrl = TextEditingController();

    if (widget.id != null) {
      _loadExistingFaculty();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instituteIdCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _employeeIdCtrl.dispose();
    _designationCtrl.dispose();
    _qualificationCtrl.dispose();
    _specializationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingFaculty() async {
    setState(() => _isLoading = true);
    try {
      final faculty = await ref.read(academicRepositoryProvider).getFacultyById(widget.id!);
      if (faculty != null && mounted) {
        _nameCtrl.text = faculty.name;
        _instituteIdCtrl.text = faculty.employeeId;
        _emailCtrl.text = faculty.email;
        _phoneCtrl.text = faculty.phone;
        _employeeIdCtrl.text = faculty.employeeId;
        _designationCtrl.text = faculty.designation ?? 'Assistant Professor';
        _qualificationCtrl.text = faculty.qualification ?? '';
        _specializationCtrl.text = faculty.specialization ?? '';
        _selectedDepartmentId = faculty.departmentId;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load faculty: $e'), backgroundColor: AcadexColors.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department for this faculty member'),
          backgroundColor: AcadexColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.id == null) {
        // Provisioning Mode
        final request = ProvisionFacultyRequest(
          departmentId: _selectedDepartmentId!,
          name: _nameCtrl.text.trim(),
          instituteId: _instituteIdCtrl.text.trim().toUpperCase(),
          email: _emailCtrl.text.trim().toLowerCase(),
          phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
          employeeId: _employeeIdCtrl.text.trim().isNotEmpty ? _employeeIdCtrl.text.trim() : null,
          designation: _designationCtrl.text.trim().isNotEmpty ? _designationCtrl.text.trim() : 'Assistant Professor',
          qualification: _qualificationCtrl.text.trim().isNotEmpty ? _qualificationCtrl.text.trim() : null,
          specialization: _specializationCtrl.text.trim().isNotEmpty ? _specializationCtrl.text.trim() : null,
        );

        final result = await ref.read(facultyProvisionProvider.notifier).provisionFaculty(request);

        if (mounted) {
          final depts = ref.read(departmentsProvider).valueOrNull ?? [];
          final deptName = depts.firstWhere(
            (d) => d.id == _selectedDepartmentId,
            orElse: () => Department(id: '', collegeId: '', name: 'Department', code: '', hodId: '', description: ''),
          ).name;

          await FacultyActivationResultDialog.show(
            context,
            result,
            departmentName: deptName,
          );

          if (mounted) {
            context.pop();
          }
        }
      } else {
        // Edit Mode
        final updatedFaculty = Faculty(
          id: widget.id!,
          collegeId: '',
          departmentId: _selectedDepartmentId!,
          name: _nameCtrl.text.trim(),
          employeeId: _employeeIdCtrl.text.trim(),
          email: _emailCtrl.text.trim().toLowerCase(),
          phone: _phoneCtrl.text.trim(),
          designation: _designationCtrl.text.trim(),
          qualification: _qualificationCtrl.text.trim(),
          specialization: _specializationCtrl.text.trim(),
        );

        await ref.read(academicRepositoryProvider).updateFaculty(updatedFaculty);
        ref.invalidate(facultyProvider(null));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Faculty profile updated successfully'), backgroundColor: AcadexColors.success),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AcadexColors.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEdit ? "Edit Faculty Profile" : "Provision Faculty Account",
          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AcadexFormCard(
                      title: "Personal Information",
                      icon: LucideIcons.user,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: "Full Name *",
                              hintText: "e.g. Dr. Alan Turing",
                              prefixIcon: Icon(LucideIcons.user),
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'Full Name must be at least 2 characters'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _instituteIdCtrl,
                                  enabled: !isEdit,
                                  decoration: const InputDecoration(
                                    labelText: "Institute ID *",
                                    hintText: "e.g. FAC202601",
                                    prefixIcon: Icon(LucideIcons.fingerprint),
                                  ),
                                  validator: (v) => (v == null || v.trim().length < 2)
                                      ? 'Institute ID is required (min 2 chars)'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _employeeIdCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Employee ID",
                                    hintText: "e.g. EMP001",
                                    prefixIcon: Icon(LucideIcons.hash),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Email Address *",
                                    hintText: "e.g. alan@acadex.edu",
                                    prefixIcon: Icon(LucideIcons.mail),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Email address is required';
                                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Phone Number",
                                    hintText: "e.g. +91 9876543210",
                                    prefixIcon: Icon(LucideIcons.phone),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AcadexFormCard(
                      title: "Academic & Department Assignment",
                      icon: LucideIcons.briefcase,
                      child: Column(
                        children: [
                          departmentsAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (err, _) => Text('Failed to load departments: $err', style: const TextStyle(color: AcadexColors.warning)),
                            data: (depts) {
                              if (_selectedDepartmentId == null && depts.isNotEmpty) {
                                _selectedDepartmentId = depts.first.id;
                              }
                              return DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: "Department *",
                                  prefixIcon: Icon(LucideIcons.building),
                                ),
                                value: _selectedDepartmentId,
                                items: depts
                                    .map((d) => DropdownMenuItem(
                                          value: d.id,
                                          child: Text('${d.name} (${d.code})'),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedDepartmentId = v),
                                validator: (v) => (v == null || v.isEmpty) ? 'Please select a department' : null,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _designationCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Designation",
                                    hintText: "e.g. Associate Professor",
                                    prefixIcon: Icon(LucideIcons.badgeCheck),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _qualificationCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Qualification",
                                    hintText: "e.g. Ph.D., M.Tech",
                                    prefixIcon: Icon(LucideIcons.graduationCap),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _specializationCtrl,
                            decoration: const InputDecoration(
                              labelText: "Specialization / Domain",
                              hintText: "e.g. Machine Learning, Distributed Algorithms",
                              prefixIcon: Icon(LucideIcons.bookOpen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting ? null : () => context.pop(),
                          child: Text(
                            "Cancel",
                            style: AcadexTypography.body(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          ),
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(LucideIcons.userPlus, size: 18),
                          label: Text(
                            _isSubmitting
                                ? "Provisioning..."
                                : isEdit
                                    ? "Save Changes"
                                    : "Provision Faculty",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }
}
