import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
            backgroundColor: DashboardColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: DashboardColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        backgroundColor: DashboardColors.background,
        body: Center(child: Text('Authentication required')),
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
    final studentsAsync = ref.watch(studentsProvider);
    final facultyAsync = ref.watch(facultyProvider);

    // Resolve Student academic details
    dynamic resolvedStudent;
    if (profile.role == AppRole.student && studentsAsync.value != null) {
      final matches = studentsAsync.value!.where((s) => s.email == profile.email || s.id == profile.id);
      if (matches.isNotEmpty) {
        resolvedStudent = matches.first;
      }
    }

    // Resolve Faculty/HOD details
    dynamic resolvedFaculty;
    if ((profile.role == AppRole.faculty || profile.role == AppRole.hod) && facultyAsync.value != null) {
      final matches = facultyAsync.value!.where((f) => f.email == profile.email || f.id == profile.id);
      if (matches.isNotEmpty) {
        resolvedFaculty = matches.first;
      }
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
      // Fallback lookup using profile values directly
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
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: DashboardColors.surface,
        foregroundColor: DashboardColors.textPrimary,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(LucideIcons.edit3),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DashboardColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: DashboardColors.primary.withValues(alpha: 0.2),
                      foregroundImage: profile.profilePictureUrl != null
                          ? NetworkImage(profile.profilePictureUrl!)
                          : null,
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: DashboardColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.name,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.role.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: DashboardColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: DashboardColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        profile.accountStatus.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: DashboardColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DashboardColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    if (_isEditing) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(LucideIcons.user),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(LucideIcons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ] else ...[
                      _buildDetailRow('Full Name', profile.name, LucideIcons.user),
                      const Divider(height: 24),
                      _buildDetailRow('Email Address', profile.email, LucideIcons.mail),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Phone Number',
                        profile.phone.isNotEmpty ? profile.phone : 'Not Added',
                        LucideIcons.phone,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Academic Information Section
              _buildSectionTitle('Academic Details'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DashboardColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('College / Institution', collegeName, LucideIcons.school),
                    if (profile.role != AppRole.superAdmin) ...[
                      const Divider(height: 24),
                      _buildDetailRow('Department', departmentName, LucideIcons.building),
                    ],
                    if (profile.role == AppRole.student) ...[
                      const Divider(height: 24),
                      _buildDetailRow('Course', courseName, LucideIcons.book),
                      const Divider(height: 24),
                      _buildDetailRow('Semester', semesterName, LucideIcons.calendar),
                      const Divider(height: 24),
                      _buildDetailRow('Section', sectionName, LucideIcons.users),
                      const Divider(height: 24),
                      _buildDetailRow('Roll Number', rollNumber, LucideIcons.hash),
                    ],
                    if (profile.role == AppRole.faculty || profile.role == AppRole.hod) ...[
                      const Divider(height: 24),
                      _buildDetailRow('Employee / Faculty ID', employeeId, LucideIcons.creditCard),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Edit Actions
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DashboardColors.textPrimary,
                          side: const BorderSide(color: DashboardColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _nameController.text = profile.name;
                            _phoneController.text = profile.phone;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _saveProfile(profile),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardColors.errorLight,
                    foregroundColor: DashboardColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.logOut),
                  label: const Text('Logout from Acadex'),
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: DashboardColors.textPrimary,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DashboardColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: DashboardColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: DashboardColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
