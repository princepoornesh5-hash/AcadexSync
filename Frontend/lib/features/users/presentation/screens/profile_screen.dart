import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_profile_providers.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_form_controls.dart';
import '../../../../core/presentation/widgets/acadex_dialogs.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateControllers(UserModel user) {
    if (_nameController.text.isEmpty) {
      _nameController.text = user.name;
    }
    if (_phoneController.text.isEmpty && user is UserProfileModel) {
      _phoneController.text = user.phone;
    }
  }

  Future<void> _saveProfile(UserProfileModel currentProfile) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final updatedProfile = currentProfile.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        updatedAt: DateTime.now(),
      );

      // Save to repository
      await ref.read(userProfileRepositoryProvider).saveUserProfile(updatedProfile);

      // Update state in AuthProvider
      ref.read(authProvider.notifier).updateCurrentUser(updatedProfile);

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AcadexColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AcadexColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
        body: const Center(child: Text('Authentication required')),
      );
    }

    final user = authState.user;
    
    // Cast to UserProfileModel or create one if the type is base UserModel
    final UserProfileModel profile = user is UserProfileModel
        ? user
        : UserProfileModel(
            id: user.id,
            firebaseUid: user.firebaseUid,
            name: user.name,
            email: user.email,
            role: user.role,
            profilePictureUrl: user.profilePictureUrl,
            collegeId: user.collegeId,
            departmentId: user.departmentId,
            accountStatus: user.accountStatus,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            lastLoginAt: user.lastLoginAt,
            status: UserStatus.active,
            phone: '',
          );

    _populateControllers(profile);

    // Watch academic structure lists to resolve names
    final collegesAsync = ref.watch(collegesProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final studentsAsync = ref.watch(studentsProvider((departmentId: null, sectionId: null)));
    final facultyAsync = ref.watch(facultyProvider(null));

    // Resolve Student academic details
    dynamic resolvedStudent;
    if (user.role == AppRole.student) {
      final studentsList = studentsAsync.items;
      resolvedStudent = studentsList.where((s) => s.id == user.id).firstOrNull;
    }

    // Resolve Faculty/HOD details
    dynamic resolvedFaculty;
    if (user.role == AppRole.faculty || user.role == AppRole.hod) {
      final facultyList = facultyAsync.items;
      resolvedFaculty = facultyList.where((f) => f.id == user.id).firstOrNull;
    }

    String collegeName = profile.collegeId ?? 'Not Assigned';
    String departmentName = profile.departmentId ?? 'Not Assigned';
    String courseName = 'Not Assigned';
    String semesterName = 'Not Assigned';
    String sectionName = 'Not Assigned';
    String rollNumber = 'Not Assigned';
    String employeeId = 'Not Assigned';

    if (resolvedStudent != null) {
      if (collegesAsync.value != null) {
        final matches = collegesAsync.value!.where((c) => c.id == resolvedStudent.collegeId);
        if (matches.isNotEmpty) collegeName = matches.first.name;
      }
      if (departmentsAsync.value != null) {
        final matches = departmentsAsync.value!.where((d) => d.id == resolvedStudent.departmentId);
        if (matches.isNotEmpty) departmentName = matches.first.name;
      }
      if (coursesAsync.value != null) {
        final matches = coursesAsync.value!.where((c) => c.id == resolvedStudent.courseId);
        if (matches.isNotEmpty) courseName = matches.first.name;
      }
      if (semestersAsync.value != null) {
        final matches = semestersAsync.value!.where((s) => s.id == resolvedStudent.semesterId);
        if (matches.isNotEmpty) semesterName = matches.first.name;
      }
      if (sectionsAsync.value != null) {
        final matches = sectionsAsync.value!.where((s) => s.id == resolvedStudent.sectionId);
        if (matches.isNotEmpty) sectionName = matches.first.name;
      }
      rollNumber = resolvedStudent.rollNumber;
    } else if (resolvedFaculty != null) {
      if (collegesAsync.value != null) {
        final matches = collegesAsync.value!.where((c) => c.id == profile.collegeId);
        if (matches.isNotEmpty) collegeName = matches.first.name;
      }
      if (departmentsAsync.value != null) {
        final matches = departmentsAsync.value!.where((d) => d.id == resolvedFaculty.departmentId);
        if (matches.isNotEmpty) departmentName = matches.first.name;
      }
      employeeId = resolvedFaculty.employeeId;
    } else {
      if (collegesAsync.value != null && profile.collegeId != null) {
        final matches = collegesAsync.value!.where((c) => c.id == profile.collegeId);
        if (matches.isNotEmpty) collegeName = matches.first.name;
      }
      if (departmentsAsync.value != null && profile.departmentId != null) {
        final matches = departmentsAsync.value!.where((d) => d.id == profile.departmentId);
        if (matches.isNotEmpty) departmentName = matches.first.name;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.formMaxWidth,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AcadexPageHeader(
                    title: 'My Profile',
                    subtitle: 'Manage your institutional profile and personal contact details.',
                    actions: [
                      if (!_isEditing)
                        AcadexButton(
                          label: 'Edit Profile',
                          icon: LucideIcons.edit3,
                          variant: AcadexButtonVariant.secondary,
                          onPressed: () => setState(() => _isEditing = true),
                        ),
                    ],
                  ),

                  // Header Profile Card
                  AcadexCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        AcadexAvatar(
                          name: profile.name,
                          size: 72,
                          imageUrl: profile.profilePictureUrl,
                          isOnline: true,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.name,
                          style: AcadexTypography.heading2(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: AcadexTypography.bodySmall(
                            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AcadexBadge(
                              label: profile.role.displayName,
                              variant: AcadexBadgeVariant.primary,
                            ),
                            const SizedBox(width: 8),
                            AcadexBadge(
                              label: profile.accountStatus.name.toUpperCase(),
                              variant: AcadexBadgeVariant.success,
                              icon: LucideIcons.checkCircle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Information Section
                  const AcadexSectionHeader(title: 'Personal Information'),
                  AcadexCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (_isEditing) ...[
                          AcadexTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            prefixIcon: LucideIcons.user,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AcadexTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            prefixIcon: LucideIcons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                        ] else ...[
                          _buildDetailRow('Full Name', profile.name, LucideIcons.user, isDark),
                          Divider(height: 20, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          _buildDetailRow('Email Address', profile.email, LucideIcons.mail, isDark),
                          Divider(height: 20, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          _buildDetailRow(
                            'Phone Number',
                            profile.phone.isNotEmpty ? profile.phone : 'Not Added',
                            LucideIcons.phone,
                            isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Academic Details Section
                  const AcadexSectionHeader(title: 'Academic Details'),
                  AcadexCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDetailRow('College / Institution', collegeName, LucideIcons.school, isDark),
                        if (profile.role != AppRole.superAdmin) ...[
                          Divider(height: 20, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          _buildDetailRow('Department', departmentName, LucideIcons.building, isDark),
                        ],
                        if (profile.role == AppRole.student) ...[
                          Divider(height: 20, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          _buildDetailRow('Course', courseName, LucideIcons.book, isDark),
                          Divider(height: 20, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          _buildDetailRow('Semester', semesterName, LucideIcons.calendar, isDark),
                          Divider(height: 20, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          _buildDetailRow('Section', sectionName, LucideIcons.users, isDark),
                          Divider(height: 20, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          _buildDetailRow('Roll Number', rollNumber, LucideIcons.hash, isDark),
                        ],
                        if (profile.role == AppRole.faculty || profile.role == AppRole.hod) ...[
                          Divider(height: 20, color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                          _buildDetailRow('Employee / Faculty ID', employeeId, LucideIcons.creditCard, isDark),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Edit Actions
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: AcadexButton(
                            label: 'Cancel',
                            variant: AcadexButtonVariant.secondary,
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _nameController.text = profile.name;
                                _phoneController.text = profile.phone;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AcadexButton(
                            label: 'Save Changes',
                            icon: LucideIcons.check,
                            onPressed: () => _saveProfile(profile),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Sign Out Button
                  AcadexButton(
                    label: 'Sign Out from Acadex',
                    icon: LucideIcons.logOut,
                    variant: AcadexButtonVariant.danger,
                    isFullWidth: true,
                    onPressed: () async {
                      final confirmed = await AcadexConfirmationDialog.show(
                        context: context,
                        title: 'Sign Out',
                        message: 'Are you sure you want to sign out of Acadex?',
                        confirmLabel: 'Sign Out',
                        isDestructive: true,
                      );
                      if (confirmed == true && context.mounted) {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft,
            borderRadius: AcadexRadius.borderRadiusMd,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AcadexTypography.caption(
                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AcadexTypography.body(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
