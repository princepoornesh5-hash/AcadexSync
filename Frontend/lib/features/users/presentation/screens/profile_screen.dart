import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/design_system/acadex_typography.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/models/user_profile_model.dart';
import '../providers/user_providers.dart';
import '../widgets/user_role_badge.dart';
import '../widgets/user_status_badge.dart';

import '../providers/user_profile_providers.dart';

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
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final notifier = ref.read(profileImageUploadProvider.notifier);
          await notifier.uploadProfileImage(
            targetUserId: userId,
            bytes: file.bytes!,
            fileName: file.name,
          );

          ref.invalidate(authProvider);
          ref.invalidate(usersListProvider);
          ref.invalidate(userDetailProvider(userId));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: AcadexColors.present,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AcadexColors.absent,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (user is UserProfileModel) {
        await ref.read(userProfileRepositoryProvider).saveUserProfile(updatedUser as UserProfileModel);
      }
      ref.read(authProvider.notifier).updateCurrentUser(updatedUser);

      ref.invalidate(authProvider);
      ref.invalidate(usersListProvider);
      ref.invalidate(userDetailProvider(user.id));

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated: ${updatedUser.name}'),
            backgroundColor: AcadexColors.present,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const AcadexPageContainer(
        child: Center(child: Text('Please log in to view your profile.')),
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

    return AcadexPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcadexPageHeader(
            title: 'My Profile',
            subtitle: 'Manage your personal account details and profile picture',
            actions: [
              if (!_isEditing)
                AcadexButton(
                  label: 'Edit Profile',
                  icon: Icons.edit_outlined,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => setState(() => _isEditing = true),
                )
              else ...[
                AcadexButton(
                  label: 'Cancel',
                  variant: AcadexButtonVariant.ghost,
                  onPressed: () => setState(() => _isEditing = false),
                ),
                const SizedBox(width: AcadexSpacing.xs),
                AcadexButton(
                  label: 'Save Changes',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: () => _saveProfile(user),
                ),
              ],
            ],
          ),
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
          AcadexCard(
            padding: const EdgeInsets.all(AcadexSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    AcadexAvatar(
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
                          color: isDark ? Colors.white : AcadexColors.textPrimaryLight,
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
          AcadexCard(
            padding: const EdgeInsets.all(AcadexSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AcadexSectionHeader(title: 'Personal & Contact Information'),
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

                  const AcadexSectionHeader(title: 'Academic & Institutional Record'),
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
