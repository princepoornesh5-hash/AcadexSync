import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../academic_structure/domain/models/academic_models.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../auth/presentation/providers/activation_providers.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_providers.dart';
import '../widgets/user_header.dart';
import '../widgets/user_detail_card.dart';
import '../widgets/assignment_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  bool _isGenerating = false;

  Future<void> _generateActivationCode(Student student) async {
    setState(() => _isGenerating = true);
    try {
      final code = await ref.read(activationRepositoryProvider).generateActivationCode(student);
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        _showActivationDialog(code);
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate code: $e'), backgroundColor: AcadexColors.error));
      }
    }
  }

  void _showActivationDialog(String code) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        title: Text('Activation Code Generated', style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this code with the student safely. It will only be shown once.', style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
              ),
              alignment: Alignment.center,
              child: SelectableText(
                code,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: AcadexColors.primary),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDetailProvider(widget.userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Academic resolving providers
    final collegesAsync = ref.watch(collegesProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final studentsAsync = ref.watch(studentsProvider((departmentId: null, sectionId: null)));

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AcadexColors.darkInk : AcadexColors.ink),
          onPressed: () => context.pop(),
        ),
        title: Text('User Details', style: AcadexTypography.title(color: isDark ? AcadexColors.darkInk : AcadexColors.ink)),
        elevation: 0,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) return const Center(child: Text('User not found.'));

          // Resolve Academic Names
          String collegeName = 'N/A';
          String deptName = 'N/A';
          if (collegesAsync.value != null && user.collegeId != null) {
            final matches = collegesAsync.value!.where((c) => c.id == user.collegeId);
            if (matches.isNotEmpty) collegeName = matches.first.name;
          }
          if (deptsAsync.value != null && user.departmentId != null) {
            final matches = deptsAsync.value!.where((d) => d.id == user.departmentId);
            if (matches.isNotEmpty) deptName = matches.first.name;
          }

          String courseName = 'N/A';
          String semesterName = 'N/A';
          String sectionName = 'N/A';
          Student? resolvedStudent;

          if (user.role == AppRole.student) {
            final studentsList = studentsAsync.items;
            resolvedStudent = studentsList.where((s) => s.id == user.id || s.email == user.email).firstOrNull;
            if (resolvedStudent != null) {
               if (coursesAsync.value != null) {
                 final c = coursesAsync.value!.where((c) => c.id == resolvedStudent!.courseId);
                 if (c.isNotEmpty) courseName = c.first.name;
               }
               if (semestersAsync.value != null) {
                 final sems = semestersAsync.value!.where((s) => s.id == resolvedStudent!.semesterId);
                 if (sems.isNotEmpty) semesterName = sems.first.name;
               }
               if (sectionsAsync.value != null) {
                 final sec = sectionsAsync.value!.where((s) => s.id == resolvedStudent!.sectionId);
                 if (sec.isNotEmpty) sectionName = sec.first.name;
               }
             }
          }

          return AcadexPageContainer(
            maxWidth: AcadexLayout.contentMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserHeader(user: user),
                const SizedBox(height: 24),
                
                // Contact Info
                UserDetailCard(
                  title: 'Contact Information',
                  data: {
                    'Email Address': user.email,
                    'Phone Number': user.phone.isNotEmpty ? user.phone : 'Not provided',
                  },
                ),
                const SizedBox(height: 16),

                // Academic/Professional Info
                UserDetailCard(
                  title: 'Academic Details',
                  data: {
                    'College': collegeName,
                    if (user.role != AppRole.superAdmin) 'Department': deptName,
                    if (user.role == AppRole.student) 'Course': courseName,
                    if (user.role == AppRole.student) 'Semester': semesterName,
                    if (user.role == AppRole.student) 'Section': sectionName,
                    if (user.role == AppRole.student) 'Roll Number': user.rollNumber ?? '',
                    if (user.role != AppRole.student && user.role != AppRole.superAdmin) 'Employee ID': user.employeeId ?? '',
                  },
                ),
                const SizedBox(height: 16),

                // Account Information
                UserDetailCard(
                  title: 'Account Information',
                  data: {
                    'Created At': user.createdAt != null ? user.createdAt!.toLocal().toString().split('.')[0] : 'N/A',
                    'Last Login': user.lastLoginAt != null ? user.lastLoginAt!.toLocal().toString().split('.')[0] : 'Never',
                  },
                ),
                const SizedBox(height: 24),

                // Assignments
                if (user.assignedSubjects.isNotEmpty || user.assignedClasses.isNotEmpty) ...[
                  Text('Assignments', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ...user.assignedSubjects.map((s) => AssignmentCard(title: s, icon: LucideIcons.bookOpen)),
                      ...user.assignedClasses.map((c) => AssignmentCard(title: c, icon: LucideIcons.users)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Activation Actions for students
                if (user.role == AppRole.student && resolvedStudent != null) ...[
                  Text('Activation Status', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.key, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Student Activation', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600)),
                              Text('Generate a new activation code for this student.', style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary.withValues(alpha: 0.1), foregroundColor: AcadexColors.primary, elevation: 0),
                          onPressed: _isGenerating ? null : () => _generateActivationCode(resolvedStudent!),
                          child: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate Code'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Danger Zone
                Text('Account Actions', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shieldAlert, color: AcadexColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.status == UserStatus.active ? 'Deactivate Account' : 'Reactivate Account', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600)),
                            Text('Change the access status of this user.', style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.status == UserStatus.active ? AcadexColors.error.withValues(alpha: 0.1) : AcadexColors.success.withValues(alpha: 0.1),
                          foregroundColor: user.status == UserStatus.active ? AcadexColors.error : AcadexColors.success,
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (user.status == UserStatus.active) {
                            ref.read(userManagementProvider.notifier).deactivateUser(user.id);
                          } else {
                            ref.read(userManagementProvider.notifier).reactivateUser(user.id);
                          }
                        },
                        child: Text(user.status == UserStatus.active ? 'Deactivate' : 'Reactivate'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
