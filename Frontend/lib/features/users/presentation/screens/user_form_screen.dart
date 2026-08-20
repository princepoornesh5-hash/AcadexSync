import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_loading_state.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/app_section_header.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_providers.dart';

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
  String? _selectedDepartmentId;
  String? _selectedSemesterId;
  String? _selectedSectionId;
  String? _profilePictureUrl;

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
      if (user != null) {
        _nameCtrl.text = user.name;
        _emailCtrl.text = user.email;
        _phoneCtrl.text = user.phone;
        _instituteIdCtrl.text = user.employeeId ?? '';
        _rollNoCtrl.text = user.rollNumber ?? '';
        _selectedRole = user.role;
        _selectedStatus = user.status;
        _selectedDepartmentId = user.departmentId;
        _selectedSectionId = user.sectionId;
        _selectedSemesterId = user.semesterId;
        _profilePictureUrl = user.profilePictureUrl;
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load user: $e');
    } finally {
      setState(() => _isLoading = false);
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

    final user = UserProfileModel(
      id: widget.userId ?? '',
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
      status: _selectedStatus,
      collegeId: currentUser?.collegeId,
      departmentId: _selectedDepartmentId,
      sectionId: _selectedSectionId,
      semesterId: _selectedSemesterId,
      employeeId: _selectedRole != AppRole.student ? _instituteIdCtrl.text.trim() : null,
      rollNumber: _selectedRole == AppRole.student ? _rollNoCtrl.text.trim() : null,
      profilePictureUrl: _profilePictureUrl,
    );

    try {
      if (widget.userId == null) {
        await ref.read(userManagementProvider.notifier).createUser(user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User registered successfully.'),
              backgroundColor: AcadexColors.emerald,
            ),
          );
          context.pop();
        }
      } else {
        await ref.read(userManagementProvider.notifier).updateUser(user);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User profile updated successfully.'),
              backgroundColor: AcadexColors.emerald,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = (authState is AuthAuthenticated) ? authState.user : null;
    final isSuperAdmin = currentUser?.role == AppRole.superAdmin;
    final isEditMode = widget.userId != null;

    final departmentsAsync = ref.watch(departmentsProvider);

    // Available role choices for creation
    final allowedRoles = <AppRole>[];
    if (isSuperAdmin) {
      allowedRoles.addAll([AppRole.collegeAdmin, AppRole.hod, AppRole.faculty, AppRole.student]);
    } else {
      allowedRoles.addAll([AppRole.hod, AppRole.faculty, AppRole.student]);
    }

    if (!allowedRoles.contains(_selectedRole)) {
      _selectedRole = allowedRoles.first;
    }

    return AppScaffold(
      title: isEditMode ? 'Edit User Record' : 'Register New User',
      subtitle: isEditMode
          ? 'Update contact details, role assignment, and academic affiliation'
          : 'Create a new institutional user with role and department scoping',
      body: _isLoading
          ? const AppLoadingState(message: 'Loading user data...')
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AcadexSpacing.lg,
                vertical: AcadexSpacing.md,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AcadexSpacing.md),
                        decoration: BoxDecoration(
                          color: AcadexColors.coral.withAlpha(25),
                          borderRadius: BorderRadius.circular(AcadexRadius.md),
                          border: Border.all(color: AcadexColors.coral.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AcadexColors.coral),
                            const SizedBox(width: AcadexSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AcadexColors.coral, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AcadexSpacing.md),
                    ],

                    // Role & Account Type Card
                    AppCard(
                      padding: const EdgeInsets.all(AcadexSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppSectionHeader(title: 'Account Role & Type'),
                          const SizedBox(height: AcadexSpacing.sm),
                          DropdownButtonFormField<AppRole>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'System Role',
                              prefixIcon: Icon(Icons.shield_outlined),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AcadexSpacing.md),

                    // Personal Information Card
                    AppCard(
                      padding: const EdgeInsets.all(AcadexSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppSectionHeader(title: 'Personal & Contact Details'),
                          const SizedBox(height: AcadexSpacing.sm),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'e.g. Dr. Jane Smith',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a full name' : null,
                          ),
                          const SizedBox(height: AcadexSpacing.md),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'e.g. janesmith@acadex.edu',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Please enter an email address';
                              if (!val.contains('@') || !val.contains('.')) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: AcadexSpacing.md),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              hintText: 'e.g. +91 9876543210',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a phone number' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AcadexSpacing.md),

                    // Institutional & Academic Assignment Card
                    AppCard(
                      padding: const EdgeInsets.all(AcadexSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppSectionHeader(title: 'Institutional Assignment'),
                          const SizedBox(height: AcadexSpacing.sm),
                          if (_selectedRole != AppRole.student)
                            TextFormField(
                              controller: _instituteIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Employee / Institutional ID',
                                hintText: 'e.g. FAC-2026-001',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty)
                                  ? 'Please enter an institutional employee ID'
                                  : null,
                            )
                          else
                            TextFormField(
                              controller: _rollNoCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Student Roll Number / Registration ID',
                                hintText: 'e.g. 2026-CSE-042',
                                prefixIcon: Icon(Icons.assignment_ind_outlined),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty)
                                  ? 'Please enter a roll number'
                                  : null,
                            ),
                          const SizedBox(height: AcadexSpacing.md),

                          // Department Dropdown for HOD, Faculty, and Student
                          if (_selectedRole != AppRole.superAdmin && _selectedRole != AppRole.collegeAdmin)
                            DropdownButtonFormField<String?>(
                              value: _selectedDepartmentId,
                              decoration: const InputDecoration(
                                labelText: 'Assigned Department',
                                prefixIcon: Icon(Icons.account_tree_outlined),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Select Department')),
                                ...departmentsAsync.value?.map((d) => DropdownMenuItem(
                                  value: d.id,
                                  child: Text(d.name),
                                )) ?? [],
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AcadexSpacing.xl),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.outline,
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: AcadexSpacing.md),
                        AppButton(
                          label: isEditMode ? 'Save Changes' : 'Register User',
                          icon: isEditMode ? Icons.check : Icons.person_add,
                          isLoading: _isSubmitting,
                          onPressed: _handleSubmit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
