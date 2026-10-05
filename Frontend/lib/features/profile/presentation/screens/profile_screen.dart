import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../app/theme/app_theme.dart' hide AcadexSpacing;
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/profile_models.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _pickAndUploadAvatar(String userId) async {
    final uploadState = ref.read(profileImageUploadProvider);
    if (uploadState.isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ProfileRepository.allowedImageExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          AcadexSnackBar.showWarning(context, 'Unable to read the selected file.');
        }
        return;
      }

      if (!ProfileRepository.isImageExtensionSupported(file.name)) {
        if (mounted) {
          AcadexSnackBar.showWarning(
              context, 'Unsupported image format. Allowed: JPG, PNG, WebP.');
        }
        return;
      }

      if (file.size > ProfileRepository.maxProfileImageSizeBytes) {
        if (mounted) {
          AcadexSnackBar.showWarning(
              context, 'Image size exceeds maximum limit of 5MB.');
        }
        return;
      }

      if (mounted) {
        AcadexSnackBar.showInfo(context, 'Uploading profile picture...');
      }

      await ref.read(profileImageUploadProvider.notifier).uploadProfileImage(
            fileName: file.name,
            bytes: file.bytes!,
            targetUserId: userId,
          );

      if (mounted) {
        AcadexSnackBar.showSuccess(context, 'Profile picture updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to update profile picture',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final uploadState = ref.watch(profileImageUploadProvider);

    return Container(
      color: DashboardColors.background,
      child: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DashboardColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AcadexSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.circleAlert,
                    size: 48, color: DashboardColors.error),
                const SizedBox(height: AcadexSpacing.md),
                const Text(
                  'Failed to load profile',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DashboardColors.textPrimary),
                ),
                const SizedBox(height: AcadexSpacing.xs),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: DashboardColors.textSecondary),
                ),
                const SizedBox(height: AcadexSpacing.lg),
                AcadexButton(
                  label: 'Retry',
                  icon: LucideIcons.refreshCw,
                  onPressed: () => ref.invalidate(profileProvider),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          final user = profile.user;
          final role = user.role;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AcadexSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Card (Avatar, Identity, Role Badge, Completion)
                _buildHeaderCard(profile, uploadState),
                const SizedBox(height: AcadexSpacing.md),

                // 2. Contact & Identity Information
                _buildContactCard(user),
                const SizedBox(height: AcadexSpacing.md),

                // 3. Role-Aware Dynamic Context Card
                _buildRoleContextCard(profile),
                const SizedBox(height: AcadexSpacing.md),

                // 4. Role-Specific Quick Navigation Actions
                _buildQuickActions(role),
                const SizedBox(height: AcadexSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
      ComposedProfileModel profile, ProfileImageUploadState uploadState) {
    final user = profile.user;
    final completion = profile.completion;

    return AcadexCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  AcadexAvatar(
                    imageUrl: user.profilePictureUrl,
                    name: user.name,
                    size: 72,
                  ),
                  if (uploadState.isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _pickAndUploadAvatar(user.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: DashboardColors.primary,
                        ),
                        child: const Icon(LucideIcons.camera,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AcadexSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.instituteId.isNotEmpty ? user.instituteId : user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: DashboardColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DashboardColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                DashboardColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        user.role.displayName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: DashboardColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AcadexSpacing.sm),
              AcadexButton(
                label: 'Edit',
                icon: LucideIcons.pencil,
                size: AcadexButtonSize.sm,
                variant: AcadexButtonVariant.secondary,
                onPressed: () => context.push('/profile/edit'),
              ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AcadexSpacing.sm),
          // Completion Progress Bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile Completion',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DashboardColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${completion.percentage}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: DashboardColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completion.percentage / 100.0,
                        backgroundColor: DashboardColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            DashboardColors.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BaseUserProfileModel user) {
    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.user, size: 18, color: DashboardColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Personal & Contact Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.md),
          _buildInfoRow(
            icon: LucideIcons.mail,
            label: 'Email',
            value: user.email.isNotEmpty ? user.email : '—',
            isReadOnly: true,
            tooltip: 'Authentication identity managed by institution',
          ),
          const SizedBox(height: AcadexSpacing.sm),
          _buildInfoRow(
            icon: LucideIcons.phone,
            label: 'Phone',
            value: user.phone.isNotEmpty ? user.phone : 'Not provided',
          ),
          const SizedBox(height: AcadexSpacing.sm),
          _buildInfoRow(
            icon: LucideIcons.school,
            label: 'Institution',
            value: user.collegeName ?? '—',
            isReadOnly: true,
          ),
          if (user.departmentName != null && user.departmentName != '—') ...[
            const SizedBox(height: AcadexSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.layers,
              label: 'Department',
              value: user.departmentName!,
              isReadOnly: true,
            ),
          ],
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: AcadexSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.fileText,
              label: 'Bio',
              value: user.bio!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleContextCard(ComposedProfileModel profile) {
    final role = profile.user.role;

    if (role == AppRole.student) {
      return _buildStudentContext(profile.roleProfile.student);
    } else if (role == AppRole.faculty) {
      return _buildFacultyContext(profile.roleProfile.faculty);
    } else if (role == AppRole.hod) {
      return _buildHodContext(profile.roleProfile.hod);
    } else if (role == AppRole.collegeAdmin) {
      return _buildCollegeAdminContext(profile.roleProfile.collegeAdmin);
    } else {
      return _buildSuperAdminContext(profile.roleProfile.superAdmin);
    }
  }

  Widget _buildStudentContext(StudentRoleProfileModel? student) {
    if (student == null) {
      return const AcadexCard(
        child: Text('Student profile data not linked.'),
      );
    }

    final enrollment = student.currentEnrollment;

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.graduationCap,
                  size: 18, color: DashboardColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Academic Context',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.md),
          if (student.rollNumber != null)
            _buildInfoRow(
              icon: LucideIcons.idCard,
              label: 'Roll Number',
              value: student.rollNumber!,
              isReadOnly: true,
            ),
          const SizedBox(height: AcadexSpacing.sm),
          if (student.isEnrollmentAvailable && enrollment != null) ...[
            _buildInfoRow(
              icon: LucideIcons.bookOpen,
              label: 'Program / Course',
              value: '${enrollment.courseName} (${enrollment.courseCode})',
              isReadOnly: true,
            ),
            const SizedBox(height: AcadexSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.calendar,
              label: 'Semester',
              value: enrollment.semesterName,
              isReadOnly: true,
            ),
            const SizedBox(height: AcadexSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.clock,
              label: 'Academic Year',
              value: enrollment.academicYearName,
              isReadOnly: true,
            ),
            if (enrollment.sectionName != null) ...[
              const SizedBox(height: AcadexSpacing.sm),
              _buildInfoRow(
                icon: LucideIcons.users,
                label: 'Section',
                value: enrollment.sectionName!,
                isReadOnly: true,
              ),
            ],
            if (enrollment.academicStage != null) ...[
              const SizedBox(height: AcadexSpacing.sm),
              _buildInfoRow(
                icon: LucideIcons.award,
                label: 'Stage / Cohort',
                value: '${enrollment.academicStage} (${enrollment.cohort ?? "—"})',
                isReadOnly: true,
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AcadexSpacing.md),
              decoration: BoxDecoration(
                color: DashboardColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: DashboardColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.info,
                      size: 20, color: DashboardColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current academic enrollment is not available.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFacultyContext(FacultyRoleProfileModel? faculty) {
    if (faculty == null) {
      return const AcadexCard(child: Text('Faculty profile data not linked.'));
    }

    final assignments = faculty.activeAssignments;

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.briefcase,
                  size: 18, color: DashboardColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Professional & Teaching Profile',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.md),
          if (faculty.designation != null)
            _buildInfoRow(
              icon: LucideIcons.badgeCheck,
              label: 'Designation',
              value: faculty.designation!,
            ),
          if (faculty.employeeId != null) ...[
            const SizedBox(height: AcadexSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.idCard,
              label: 'Employee ID',
              value: faculty.employeeId!,
              isReadOnly: true,
            ),
          ],
          if (faculty.qualification != null &&
              faculty.qualification!.isNotEmpty) ...[
            const SizedBox(height: AcadexSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.graduationCap,
              label: 'Qualification',
              value: faculty.qualification!,
            ),
          ],
          if (faculty.specialization != null &&
              faculty.specialization!.isNotEmpty) ...[
            const SizedBox(height: AcadexSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.sparkles,
              label: 'Specialization',
              value: faculty.specialization!,
            ),
          ],
          const SizedBox(height: AcadexSpacing.md),
          const Text(
            'Active Teaching Assignments',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DashboardColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          if (assignments.isEmpty)
            const Text('No active teaching assignments currently scheduled.',
                style: TextStyle(
                    fontSize: 12, color: DashboardColors.textMuted))
          else
            ...assignments.map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: DashboardColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DashboardColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.bookMarked,
                        size: 16, color: DashboardColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${a.subjectName} (${a.subjectCode}) • ${a.sectionName ?? a.semesterName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHodContext(HodRoleProfileModel? hod) {
    if (hod == null) {
      return const AcadexCard(child: Text('HOD profile context not linked.'));
    }

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.shieldCheck,
                  size: 18, color: DashboardColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Department Leadership Scope',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.md),
          _buildInfoRow(
            icon: LucideIcons.building,
            label: 'Department',
            value: '${hod.departmentName} (${hod.departmentCode})',
            isReadOnly: true,
          ),
          const SizedBox(height: AcadexSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Programs',
                  value: hod.programsCount.toString(),
                  icon: LucideIcons.folderKanban,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Faculty',
                  value: hod.facultyCount.toString(),
                  icon: LucideIcons.userCheck,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Students',
                  value: hod.studentsCount.toString(),
                  icon: LucideIcons.users,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeAdminContext(CollegeAdminRoleProfileModel? admin) {
    if (admin == null) {
      return const AcadexCard(child: Text('Admin scope context not linked.'));
    }

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.building2,
                  size: 18, color: DashboardColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Administrative Scope',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.md),
          _buildInfoRow(
            icon: LucideIcons.landmark,
            label: 'College',
            value: admin.collegeName,
            isReadOnly: true,
          ),
          const SizedBox(height: AcadexSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Departments',
                  value: admin.departmentsCount.toString(),
                  icon: LucideIcons.layers,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Faculty',
                  value: admin.facultyCount.toString(),
                  icon: LucideIcons.userCheck,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Students',
                  value: admin.studentsCount.toString(),
                  icon: LucideIcons.users,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuperAdminContext(SuperAdminRoleProfileModel? superAdmin) {
    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.globe, size: 18, color: DashboardColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Platform Identity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DashboardColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.sm),
          _buildInfoRow(
            icon: LucideIcons.shieldAlert,
            label: 'Scope',
            value: 'Global Multi-Tenant Root Scope',
            isReadOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: DashboardColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: DashboardColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: DashboardColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isReadOnly = false,
    String? tooltip,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: DashboardColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DashboardColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DashboardColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isReadOnly)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: tooltip ?? 'Institutional managed field',
                    child: const Icon(LucideIcons.lock,
                        size: 12, color: DashboardColors.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(AppRole role) {
    final actions = <Map<String, dynamic>>[];

    if (role == AppRole.student) {
      actions.addAll([
        {'label': 'Academic Records', 'icon': LucideIcons.bookOpen, 'route': '/academic-records'},
        {'label': 'Attendance', 'icon': LucideIcons.checkSquare, 'route': '/attendance'},
        {'label': 'Assignments', 'icon': LucideIcons.fileSpreadsheet, 'route': '/assignments'},
        {'label': 'Practicals', 'icon': LucideIcons.flaskConical, 'route': '/practicals'},
        {'label': 'Assessments', 'icon': LucideIcons.penTool, 'route': '/assessments'},
        {'label': 'Official Results', 'icon': LucideIcons.award, 'route': '/academic-results'},
        {'label': 'Calendar', 'icon': LucideIcons.calendarDays, 'route': '/calendar'},
        {'label': 'Requests', 'icon': LucideIcons.inbox, 'route': '/requests'},
      ]);
    } else if (role == AppRole.faculty) {
      actions.addAll([
        {'label': 'Teaching Assignments', 'icon': LucideIcons.fileSpreadsheet, 'route': '/assignments'},
        {'label': 'Attendance Session', 'icon': LucideIcons.checkSquare, 'route': '/attendance'},
        {'label': 'Practicals', 'icon': LucideIcons.flaskConical, 'route': '/practicals'},
        {'label': 'Assessments', 'icon': LucideIcons.penTool, 'route': '/assessments'},
        {'label': 'Calendar', 'icon': LucideIcons.calendarDays, 'route': '/calendar'},
        {'label': 'Requests', 'icon': LucideIcons.inbox, 'route': '/requests'},
      ]);
    } else if (role == AppRole.hod) {
      actions.addAll([
        {'label': 'Department Timetable', 'icon': LucideIcons.calendar, 'route': '/timetable'},
        {'label': 'Attendance Oversight', 'icon': LucideIcons.checkSquare, 'route': '/attendance'},
        {'label': 'Academic Calendar', 'icon': LucideIcons.calendarDays, 'route': '/calendar'},
        {'label': 'Incoming Requests', 'icon': LucideIcons.inbox, 'route': '/requests'},
        {'label': 'Announcements', 'icon': LucideIcons.megaphone, 'route': '/announcements'},
      ]);
    } else if (role == AppRole.collegeAdmin) {
      actions.addAll([
        {'label': 'Institution Config', 'icon': LucideIcons.settings2, 'route': '/institution-config'},
        {'label': 'Academic Calendar', 'icon': LucideIcons.calendarDays, 'route': '/calendar'},
        {'label': 'Announcements', 'icon': LucideIcons.megaphone, 'route': '/announcements'},
        {'label': 'Requests Center', 'icon': LucideIcons.inbox, 'route': '/requests'},
      ]);
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return AcadexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Academic Navigation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: DashboardColors.textPrimary,
            ),
          ),
          const SizedBox(height: AcadexSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((act) {
              return InkWell(
                onTap: () => context.push(act['route'] as String),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: DashboardColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DashboardColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(act['icon'] as IconData,
                          size: 15, color: DashboardColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        act['label'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
