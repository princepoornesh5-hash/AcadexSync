import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart' hide AcadexSpacing;
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/profile_models.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _specializationController;
  late TextEditingController _qualificationController;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _specializationController = TextEditingController();
    _qualificationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _specializationController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  void _populateFromProfile(ComposedProfileModel profile) {
    if (_initialized) return;
    _nameController.text = profile.user.name;
    _phoneController.text = profile.user.phone;
    _bioController.text = profile.user.bio ?? '';

    final faculty = profile.roleProfile.faculty;
    if (faculty != null) {
      _specializationController.text = faculty.specialization ?? '';
      _qualificationController.text = faculty.qualification ?? '';
    }

    _initialized = true;
  }

  Future<void> _handleSave(ComposedProfileModel profile) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'bio': _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
      };

      if (profile.user.role == AppRole.faculty ||
          profile.user.role == AppRole.hod) {
        if (_specializationController.text.trim().isNotEmpty) {
          payload['specialization'] = _specializationController.text.trim();
        }
        if (_qualificationController.text.trim().isNotEmpty) {
          payload['qualification'] = _qualificationController.text.trim();
        }
      }

      await ref
          .read(profileActionNotifierProvider.notifier)
          .updateProfile(payload);

      if (mounted) {
        AcadexSnackBar.showSuccess(context, 'Profile updated successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to update profile. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Container(
      color: DashboardColors.background,
      child: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DashboardColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Error loading profile: $err'),
        ),
        data: (profile) {
          _populateFromProfile(profile);
          final user = profile.user;
          final role = user.role;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AcadexSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Personal Editable Fields Card
                  AcadexCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.pencil,
                                size: 18, color: DashboardColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Editable Information',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: DashboardColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AcadexSpacing.md),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(LucideIcons.user, size: 18),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AcadexSpacing.md),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '+91 98765 43210',
                            prefixIcon: Icon(LucideIcons.phone, size: 18),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val != null &&
                                val.trim().isNotEmpty &&
                                val.trim().length < 5) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AcadexSpacing.md),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            labelText: 'Bio / About',
                            hintText: 'Short professional or academic summary...',
                            prefixIcon: Icon(LucideIcons.fileText, size: 18),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        if (role == AppRole.faculty || role == AppRole.hod) ...[
                          const SizedBox(height: AcadexSpacing.sm),
                          TextFormField(
                            controller: _qualificationController,
                            decoration: const InputDecoration(
                              labelText: 'Qualification',
                              hintText: 'e.g. Ph.D, M.Tech',
                              prefixIcon:
                                  Icon(LucideIcons.graduationCap, size: 18),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: AcadexSpacing.md),
                          TextFormField(
                            controller: _specializationController,
                            decoration: const InputDecoration(
                              labelText: 'Specialization',
                              hintText: 'e.g. Distributed Computing',
                              prefixIcon: Icon(LucideIcons.sparkles, size: 18),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AcadexSpacing.md),

                  // 2. Read-Only / Institution Managed Information Card
                  AcadexCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.lock,
                                size: 18, color: DashboardColors.textSecondary),
                            SizedBox(width: 8),
                            Text(
                              'Managed by Institution',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: DashboardColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'The fields below are official institutional and academic identifiers. Contact administration to request changes.',
                          style: TextStyle(
                              fontSize: 12, color: DashboardColors.textMuted),
                        ),
                        const SizedBox(height: AcadexSpacing.md),
                        _buildReadOnlyField(
                          label: 'Email / Login Identity',
                          value: user.email.isNotEmpty ? user.email : '—',
                          icon: LucideIcons.mail,
                          hint: 'Authentication login identity',
                        ),
                        const SizedBox(height: AcadexSpacing.sm),
                        _buildReadOnlyField(
                          label: 'Account Role',
                          value: user.role.displayName,
                          icon: LucideIcons.shieldCheck,
                          hint: 'System authorization role',
                        ),
                        const SizedBox(height: AcadexSpacing.sm),
                        _buildReadOnlyField(
                          label: 'Institution',
                          value: user.collegeName ?? '—',
                          icon: LucideIcons.school,
                          hint: 'Enrolled institutional tenant',
                        ),
                        if (user.departmentName != null &&
                            user.departmentName != '—') ...[
                          const SizedBox(height: AcadexSpacing.sm),
                          _buildReadOnlyField(
                            label: 'Department',
                            value: user.departmentName!,
                            icon: LucideIcons.layers,
                            hint: 'Academic department',
                          ),
                        ],
                        if (role == AppRole.student &&
                            profile.roleProfile.student?.rollNumber != null) ...[
                          const SizedBox(height: AcadexSpacing.sm),
                          _buildReadOnlyField(
                            label: 'Roll Number',
                            value: profile.roleProfile.student!.rollNumber!,
                            icon: LucideIcons.idCard,
                            hint: 'Official academic roll number',
                          ),
                        ],
                        if ((role == AppRole.faculty || role == AppRole.hod) &&
                            profile.roleProfile.faculty?.employeeId != null) ...[
                          const SizedBox(height: AcadexSpacing.sm),
                          _buildReadOnlyField(
                            label: 'Employee ID',
                            value: profile.roleProfile.faculty!.employeeId!,
                            icon: LucideIcons.idCard,
                            hint: 'Faculty employee identifier',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AcadexSpacing.lg),

                  // 3. Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AcadexButton(
                          label: 'Cancel',
                          variant: AcadexButtonVariant.secondary,
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: AcadexSpacing.md),
                      Expanded(
                        child: AcadexButton(
                          label: 'Save Changes',
                          icon: LucideIcons.check,
                          isLoading: _isSaving,
                          onPressed: () => _handleSave(profile),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AcadexSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: DashboardColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.lock, size: 13, color: DashboardColors.textMuted),
        ],
      ),
    );
  }
}
