import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/design_system/acadex_typography.dart';
import '../../../../core/presentation/widgets/app_avatar.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/app_section_header.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_providers.dart';
import '../widgets/user_role_badge.dart';
import '../widgets/user_status_badge.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;

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

  void _populateFields(UserModel user) {
    if (_nameController.text.isEmpty) {
      _nameController.text = user.name;
    }
    if (_phoneController.text.isEmpty && user is UserProfileModel) {
      _phoneController.text = user.phone;
    }
  }

  Future<void> _pickAndUploadProfileImage(String userId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ProfileRepository.allowedImageExtensions,
      withData: true,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes == null) return;

      if (file.size > ProfileRepository.maxProfileImageSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image must be under 5MB (JPG, PNG, or WebP)'),
              backgroundColor: AcadexColors.coral,
            ),
          );
        }
        return;
      }

      try {
        await ref.read(profileImageUploadProvider.notifier).uploadProfileImage(
          fileName: file.name,
          bytes: file.bytes!,
          targetUserId: userId,
        );

        ref.invalidate(userDetailProvider(userId));
        ref.invalidate(usersListProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully via ImageKit'),
              backgroundColor: AcadexColors.emerald,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload profile picture: $e'),
              backgroundColor: AcadexColors.coral,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveProfile(UserModel currentUser) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedProfile = UserProfileModel(
        id: currentUser.id,
        name: _nameController.text.trim(),
        email: currentUser.email,
        phone: _phoneController.text.trim(),
        role: currentUser.role,
        status: UserStatus.active,
        collegeId: currentUser.collegeId,
        departmentId: currentUser.departmentId,
        sectionId: currentUser.sectionId,
        semesterId: currentUser.semesterId,
        accountStatus: currentUser.accountStatus,
        profilePictureUrl: currentUser.profilePictureUrl,
      );

      await ref.read(userManagementProvider.notifier).updateUser(updatedProfile);

      // Update in-memory auth state
      ref.read(authProvider.notifier).updateCurrentUser(updatedProfile);

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile details updated successfully.'),
            backgroundColor: AcadexColors.emerald,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const AppScaffold(
        title: 'My Profile',
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }

    final user = authState.user;
    _populateFields(user);

    final uploadState = ref.watch(profileImageUploadProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final collegesAsync = ref.watch(collegesProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String deptName = '—';
    final depts = departmentsAsync.value;
    if (depts != null && user.departmentId != null) {
      for (var d in depts) {
        if (d.id == user.departmentId) {
          deptName = d.name;
          break;
        }
      }
    }

    String collegeName = '—';
    final colleges = collegesAsync.value;
    if (colleges != null && user.collegeId != null) {
      for (var c in colleges) {
        if (c.id == user.collegeId) {
          collegeName = c.name;
          break;
        }
      }
    }

    return AppScaffold(
      title: 'My Profile',
      subtitle: 'Manage your personal account details and profile picture',
      topBarActions: [
        if (!_isEditing)
          AppButton(
            label: 'Edit Profile',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.outline,
            onPressed: () => setState(() => _isEditing = true),
          )
        else ...[
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.text,
            onPressed: () => setState(() => _isEditing = false),
          ),
          const SizedBox(width: AcadexSpacing.xs),
          AppButton(
            label: 'Save Changes',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: () => _saveProfile(user),
          ),
        ],
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AcadexSpacing.lg,
          vertical: AcadexSpacing.md,
        ),
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

            // Profile Header Card
            AppCard(
              padding: const EdgeInsets.all(AcadexSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      AppAvatar(
                        name: user.name,
                        imageUrl: user.profilePictureUrl,
                        size: 80,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: AcadexColors.navy,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: uploadState.isUploading
                                ? null
                                : () => _pickAndUploadProfileImage(user.id),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AcadexSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AcadexTypography.h2.copyWith(
                            color: isDark ? AcadexColors.darkTextPrimary : AcadexColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AcadexSpacing.xs),
                        Wrap(
                          spacing: AcadexSpacing.xs,
                          runSpacing: AcadexSpacing.xxs,
                          children: [
                            UserRoleBadge(role: user.role),
                            UserStatusBadge(status: user.accountStatus),
                          ],
                        ),
                        if (uploadState.isUploading) ...[
                          const SizedBox(height: AcadexSpacing.sm),
                          Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: AcadexSpacing.xs),
                              Text(
                                'Uploading to ImageKit: ${(uploadState.progress * 100).toInt()}%',
                                style: AcadexTypography.caption,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AcadexSpacing.lg),

            // Profile Form / Details Card
            AppCard(
              padding: const EdgeInsets.all(AcadexSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(title: 'Personal & Contact Information'),
                    const SizedBox(height: AcadexSpacing.md),
                    if (_isEditing) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Name cannot be empty' : null,
                      ),
                      const SizedBox(height: AcadexSpacing.md),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Phone cannot be empty' : null,
                      ),
                    ] else ...[
                      _buildDetailRow('Email Address', user.email),
                      _buildDetailRow('Phone Number', (user is UserProfileModel && user.phone.isNotEmpty) ? user.phone : '—'),
                    ],
                    const Divider(height: AcadexSpacing.xl),

                    const AppSectionHeader(title: 'Academic & Institutional Record'),
                    const SizedBox(height: AcadexSpacing.sm),
                    _buildDetailRow('Institutional Role', user.role.displayName),
                    if (collegeName != '—') _buildDetailRow('College / Campus', collegeName),
                    if (deptName != '—') _buildDetailRow('Department', deptName),
                    _buildDetailRow('Account Status', user.accountStatus.name.toUpperCase()),
                    if (user.createdAt != null)
                      _buildDetailRow('Member Since', user.createdAt!.toLocal().toString().substring(0, 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AcadexSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: AcadexTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AcadexTypography.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
