import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_providers.dart';
import '../widgets/user_activation_result_dialog.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final String? userId; // If null, create mode; otherwise edit mode

  const UserFormScreen({super.key, this.userId});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _instituteIdCtrl;
  late TextEditingController _rollNoCtrl;

  AppRole _selectedRole = AppRole.faculty;
  UserStatus _selectedStatus = UserStatus.active;
  String? _selectedCollegeId;
  String? _selectedDepartmentId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  String? _profilePictureUrl;
  UserProfileModel? _existingUser;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _instituteIdCtrl = TextEditingController();
    _rollNoCtrl = TextEditingController();

    if (widget.userId != null) {
      _loadExistingUser();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _instituteIdCtrl.dispose();
    _rollNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(userRepositoryProvider).getUserById(widget.userId!);
      if (user != null && mounted) {
        _existingUser = user;
        _nameCtrl.text = user.name;
        _emailCtrl.text = user.email;
        _phoneCtrl.text = user.phone;
        _instituteIdCtrl.text = user.employeeId ?? user.instituteId ?? '';
        _rollNoCtrl.text = user.rollNumber ?? '';
        _selectedRole = user.role;
        _selectedStatus = user.status;
        _selectedCollegeId = user.collegeId;
        _selectedDepartmentId = user.departmentId;
        _selectedSectionId = user.sectionId;
        _selectedSemesterId = user.semesterId;
        _profilePictureUrl = user.profilePictureUrl;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load user: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final authState = ref.read(authProvider);
    final currentUser = (authState is AuthAuthenticated) ? authState.user : null;

    final targetCollegeId = _existingUser?.collegeId ?? _selectedCollegeId ?? currentUser?.collegeId;

    final user = UserProfileModel(
      id: widget.userId ?? '',
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
      status: _selectedStatus,
      accountStatus: _existingUser?.accountStatus ?? AccountStatus.active,
      collegeId: targetCollegeId,
      departmentId: _selectedDepartmentId,
      sectionId: _selectedSectionId,
      semesterId: _selectedSemesterId,
      employeeId: _selectedRole != AppRole.student ? _instituteIdCtrl.text.trim() : null,
      rollNumber: _selectedRole == AppRole.student ? _rollNoCtrl.text.trim() : null,
      profilePictureUrl: _profilePictureUrl,
    );

    try {
      if (widget.userId == null) {
        // Provisioning Mode
        final result = await ref.read(userManagementProvider.notifier).createUser(user);
        if (mounted) {
          setState(() => _isSubmitting = false);
          UserActivationResultDialog.show(context, result);
          if (mounted) {
            context.safePop(fallbackRoute: '/users');
          }
        }
      } else {
        // Edit Mode
        await ref.read(userManagementProvider.notifier).updateUser(user);
        if (widget.userId != null) {
          ref.invalidate(userDetailProvider(widget.userId!));
        }
        ref.invalidate(usersListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User profile updated successfully.'),
              backgroundColor: AcadexColors.success,
            ),
          );
          context.safePop(fallbackRoute: '/users');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = (authState is AuthAuthenticated) ? authState.user : null;
    final isSuperAdmin = currentUser?.role == AppRole.superAdmin;
    final isEditMode = widget.userId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final departmentsAsync = ref.watch(departmentsProvider);
    final collegesAsync = isSuperAdmin ? ref.watch(collegesProvider) : null;

    // Allowed roles
    final allowedRoles = <AppRole>[];
    if (isSuperAdmin) {
      allowedRoles.addAll([AppRole.superAdmin, AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student]);
    } else {
      allowedRoles.addAll([AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student]);
    }

    if (!allowedRoles.contains(_selectedRole)) {
      allowedRoles.add(_selectedRole);
    }

    final activeDepts = (departmentsAsync.valueOrNull ?? []).where((d) => d.isActive).toList();
    final hasSelectedDept = _selectedDepartmentId != null && activeDepts.any((d) => d.id == _selectedDepartmentId);
    final deptDropdownValue = hasSelectedDept ? _selectedDepartmentId : null;

    final collegeList = collegesAsync?.valueOrNull ?? [];
    final hasSelectedCollege = _selectedCollegeId != null && collegeList.any((c) => c.id == _selectedCollegeId);
    final collegeDropdownValue = hasSelectedCollege ? _selectedCollegeId : null;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.safePop(fallbackRoute: '/users'),
        ),
        title: Text(
          isEditMode ? 'Edit User Record' : 'Register New User',
          style: AcadexTypography.heading2(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AcadexSpacing.space16),
                        decoration: BoxDecoration(
                          color: AcadexColors.error.withValues(alpha: 0.1),
                          borderRadius: AcadexRadius.borderRadiusMd,
                          border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.circleAlert, color: AcadexColors.error, size: 20),
                            const SizedBox(width: AcadexSpacing.space8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AcadexColors.error, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.space16),
                    ],

                    // Role & Account Type Card
                    AcadexFormCard(
                      title: 'Account Role & Type',
                      icon: LucideIcons.shield,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AcadexFormField(
                            label: 'System Role *',
                            child: DropdownButtonFormField<AppRole>(
                              dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                hintText: 'Select System Role',
                                prefixIcon: Icon(LucideIcons.shieldCheck, size: 18),
                              ),
                              items: allowedRoles.map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.displayName),
                              )).toList(),
                              onChanged: isEditMode ? null : (val) {
                                if (val != null) {
                                  setState(() => _selectedRole = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AcadexSpacing.space16),

                    // Personal Information Card
                    AcadexFormCard(
                      title: 'Personal & Contact Details',
                      icon: LucideIcons.user,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AcadexFormField(
                            label: 'Full Name *',
                            child: TextFormField(
                              controller: _nameCtrl,
                              style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                              decoration: const InputDecoration(
                                hintText: 'e.g. Dr. Jane Smith',
                                prefixIcon: Icon(LucideIcons.user, size: 18),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a full name' : null,
                            ),
                          ),
                          const SizedBox(height: AcadexSpacing.space16),
                          AcadexFormField(
                            label: 'Email Address *',
                            child: TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                              decoration: const InputDecoration(
                                hintText: 'e.g. janesmith@acadex.edu',
                                prefixIcon: Icon(LucideIcons.mail, size: 18),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Please enter an email address';
                                if (!val.contains('@') || !val.contains('.')) return 'Please enter a valid email';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: AcadexSpacing.space16),
                          AcadexFormField(
                            label: 'Phone Number *',
                            child: TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                              decoration: const InputDecoration(
                                hintText: 'e.g. +91 9876543210',
                                prefixIcon: Icon(LucideIcons.phone, size: 18),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a phone number' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AcadexSpacing.space16),

                    // Institutional & Academic Assignment Card
                    AcadexFormCard(
                      title: 'Institutional Assignment',
                      icon: LucideIcons.building,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Super Admin College Selector
                          if (isSuperAdmin && collegesAsync != null && !isEditMode) ...[
                            AcadexFormField(
                              label: 'Assigned College *',
                              child: collegesAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (e, _) => Text('Error loading colleges: $e', style: const TextStyle(color: AcadexColors.error)),
                                data: (colleges) => DropdownButtonFormField<String?>(
                                  dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                  value: collegeDropdownValue,
                                  decoration: const InputDecoration(
                                    hintText: 'Select College',
                                    prefixIcon: Icon(LucideIcons.building, size: 18),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('No College Assignment')),
                                    ...colleges.map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text('${c.name} (${c.code})'),
                                    )),
                                  ],
                                  onChanged: (val) => setState(() => _selectedCollegeId = val),
                                ),
                              ),
                            ),
                            const SizedBox(height: AcadexSpacing.space16),
                          ],

                          if (_selectedRole != AppRole.student)
                            AcadexFormField(
                              label: 'PIN Number / Employee ID *',
                              child: TextFormField(
                                controller: _instituteIdCtrl,
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. FAC-2026-001',
                                  prefixIcon: Icon(LucideIcons.idCard, size: 18),
                                ),
                                validator: (val) => (val == null || val.trim().isEmpty)
                                    ? 'Please enter a PIN Number'
                                    : null,
                              ),
                            )
                          else
                            AcadexFormField(
                              label: 'Student Roll Number / Registration ID *',
                              child: TextFormField(
                                controller: _rollNoCtrl,
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 2026-CSE-042',
                                  prefixIcon: Icon(LucideIcons.hash, size: 18),
                                ),
                                validator: (val) => (val == null || val.trim().isEmpty)
                                    ? 'Please enter a roll number'
                                    : null,
                              ),
                            ),
                          const SizedBox(height: AcadexSpacing.space16),

                          // Department Dropdown for HOD, Faculty, and Student
                          if (_selectedRole != AppRole.superAdmin && _selectedRole != AppRole.collegeAdmin)
                            AcadexFormField(
                              label: 'Assigned Department',
                              child: DropdownButtonFormField<String?>(
                                dropdownColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                                value: deptDropdownValue,
                                decoration: const InputDecoration(
                                  hintText: 'Select Department',
                                  prefixIcon: Icon(LucideIcons.layers, size: 18),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('Select Department')),
                                  ...activeDepts.map((d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text('${d.name} (${d.code})'),
                                  )),
                                ],
                                onChanged: (val) {
                                  setState(() => _selectedDepartmentId = val);
                                },
                                validator: (val) {
                                  if (_selectedRole == AppRole.hod && val == null) {
                                    return 'HOD must be assigned to a department';
                                  }
                                  return null;
                                },
                              ),
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
                          onPressed: _isSubmitting ? null : () => context.safePop(fallbackRoute: '/users'),
                        ),
                        const SizedBox(width: AcadexSpacing.space16),
                        AcadexButton(
                          label: isEditMode ? 'Save Changes' : 'Register User',
                          icon: isEditMode ? LucideIcons.check : LucideIcons.userPlus,
                          variant: AcadexButtonVariant.primary,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _handleSubmit,
                        ),
                      ],
                    ),
                    const SizedBox(height: AcadexSpacing.space32),
                  ],
                ),
              ),
            ),
    );
  }
}
