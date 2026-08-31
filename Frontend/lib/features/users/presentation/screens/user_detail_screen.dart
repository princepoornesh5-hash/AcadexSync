import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/design_system/acadex_typography.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/models/user_profile_model.dart';
import '../providers/user_providers.dart';
import '../widgets/user_role_badge.dart';
import '../widgets/user_status_badge.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  bool _isActionInProgress = false;

  Future<void> _handleDeactivateReactivate(UserProfileModel user) async {
    final isDeactivated = user.accountStatus.name.toLowerCase().contains('deactivat') ||
        user.accountStatus.name.toLowerCase().contains('inactive');

    final actionName = isDeactivated ? 'Reactivate' : 'Deactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName User Account'),
        content: Text(
          isDeactivated
              ? 'Are you sure you want to reactivate ${user.name}\'s account? They will regain access to ACADEX.'
              : 'Are you sure you want to deactivate ${user.name}\'s account? Their sessions will be suspended.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivated ? AcadexColors.emerald : AcadexColors.coral,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionName),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isActionInProgress = true);
      try {
        if (isDeactivated) {
          await ref.read(userManagementProvider.notifier).reactivateUser(user.id);
        } else {
          await ref.read(userManagementProvider.notifier).deactivateUser(user.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User account ${isDeactivated ? 'reactivated' : 'deactivated'} successfully.'),
              backgroundColor: AcadexColors.emerald,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update account status: $e'),
              backgroundColor: AcadexColors.coral,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isActionInProgress = false);
      }
    }
  }

  Future<void> _generateOrReissueActivationCode(UserProfileModel user) async {
    // Confirm before reissuing, since the old code is invalidated
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reissue Activation Code?'),
        content: const Text(
          'This will INVALIDATE the existing pending activation code and generate a new one. '
          'The previous code will no longer work. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reissue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isActionInProgress = true);
    try {
      final code = await ref.read(userManagementProvider.notifier).reissueActivationCode(user.id);
      if (mounted) {
        _showActivationCodeDialog(code, user.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reissue activation code: $e'),
            backgroundColor: AcadexColors.coral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  void _showActivationCodeDialog(String code, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activation Code Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this activation code with $userName for initial account setup:'),
            const SizedBox(height: AcadexSpacing.md),
            Container(
              padding: const EdgeInsets.all(AcadexSpacing.md),
              decoration: BoxDecoration(
                color: AcadexColors.navy.withAlpha(20),
                borderRadius: BorderRadius.circular(AcadexRadius.md),
                border: Border.all(color: AcadexColors.navy.withAlpha(50)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    code,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: AcadexColors.navy,
                    ),
                  ),
                  const SizedBox(width: AcadexSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy Code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Activation code copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadProfileImage(UserProfileModel targetUser) async {
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

      setState(() => _isActionInProgress = true);
      try {
        await ref.read(profileImageUploadProvider.notifier).uploadProfileImage(
          fileName: file.name,
          bytes: file.bytes!,
          targetUserId: targetUser.id,
        );

        ref.invalidate(userDetailProvider(widget.userId));
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
              content: Text('Failed to upload image: $e'),
              backgroundColor: AcadexColors.coral,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isSuperAdmin = currentUser?.role == AppRole.superAdmin;
    final isCollegeAdmin = currentUser?.role == AppRole.collegeAdmin;
    final isSelf = currentUser?.id == widget.userId;
    final canManage = isSuperAdmin || isCollegeAdmin;

    final userAsync = ref.watch(userDetailProvider(widget.userId));
    final departmentsAsync = ref.watch(departmentsProvider);
    final collegesAsync = isSuperAdmin ? ref.watch(collegesProvider) : const AsyncValue.data([]);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AcadexPageContainer(
      child: userAsync.when(
        loading: () => const AcadexLoadingState(message: 'Loading user details...'),
        error: (err, _) => AcadexErrorState(
          title: 'Failed to load user profile',
          message: err.toString(),
          onRetry: () => ref.refresh(userDetailProvider(widget.userId)),
        ),
        data: (user) {
          if (user == null) {
            return const AcadexErrorState(
              title: 'User not found',
              message: 'The requested user record could not be found or has been removed.',
            );
          }

          // Department & College name resolvers
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

          final isPending = user.accountStatus.name.toLowerCase().contains('pending');
          final isDeactivated = user.accountStatus.name.toLowerCase().contains('deactivat') ||
              user.accountStatus.name.toLowerCase().contains('inactive');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcadexPageHeader(
                title: 'User Profile',
                subtitle: 'Institutional identity, contact records, and role permissions',
                onBack: () => context.safePop(fallbackRoute: '/users'),
              ),

              // Header Card with Avatar, Name, Badges & Action Buttons
              AcadexCard(
                padding: const EdgeInsets.all(AcadexSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            AcadexAvatar(
                              name: user.name,
                              imageUrl: user.profilePictureUrl,
                              size: 84,
                            ),
                            if (canManage || isSelf)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Material(
                                  color: AcadexColors.navy,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: _isActionInProgress
                                        ? null
                                        : () => _pickAndUploadProfileImage(user),
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
                        const SizedBox(width: AcadexSpacing.md),
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
                                  if (deptName != '—')
                                    Chip(
                                      label: Text(deptName, style: const TextStyle(fontSize: 12)),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                              const SizedBox(height: AcadexSpacing.xs),
                              Text(
                                'Institutional ID: ${user.employeeId ?? user.rollNumber ?? user.id}',
                                style: AcadexTypography.caption.copyWith(
                                  color: isDark ? Colors.white70 : AcadexColors.textSecondaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (canManage) ...[
                      const Divider(height: AcadexSpacing.xl),
                      Wrap(
                        spacing: AcadexSpacing.sm,
                        runSpacing: AcadexSpacing.xs,
                        alignment: WrapAlignment.end,
                        children: [
                          AcadexButton(
                            label: 'Edit User',
                            icon: Icons.edit_outlined,
                            variant: AcadexButtonVariant.secondary,
                            onPressed: () => context.go('/users/edit/${user.id}'),
                          ),
                          if (isPending)
                            AcadexButton(
                              label: 'Reissue Code',
                              icon: Icons.vpn_key_outlined,
                              variant: AcadexButtonVariant.soft,
                              isLoading: _isActionInProgress,
                              onPressed: () => _generateOrReissueActivationCode(user),
                            ),
                          AcadexButton(
                            label: isDeactivated ? 'Reactivate Account' : 'Deactivate Account',
                            icon: isDeactivated ? Icons.check_circle_outline : Icons.block_outlined,
                            variant: isDeactivated ? AcadexButtonVariant.primary : AcadexButtonVariant.danger,
                            isLoading: _isActionInProgress,
                            onPressed: () => _handleDeactivateReactivate(user),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AcadexSpacing.lg),

              // Details Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;

                  final card1 = AcadexCard(
                    padding: const EdgeInsets.all(AcadexSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AcadexSectionHeader(title: 'Identity & Contact'),
                        const SizedBox(height: AcadexSpacing.sm),
                        _buildInfoRow('Full Name', user.name),
                        _buildInfoRow('Email Address', user.email.isNotEmpty ? user.email : '—'),
                        _buildInfoRow('Phone Number', user.phone.isNotEmpty ? user.phone : '—'),
                        _buildInfoRow('Account Role', user.role.displayName),
                        _buildInfoRow('Status', user.accountStatus.name.toUpperCase()),
                      ],
                    ),
                  );

                  final card2 = AcadexCard(
                    padding: const EdgeInsets.all(AcadexSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AcadexSectionHeader(title: 'Academic & System Record'),
                        const SizedBox(height: AcadexSpacing.sm),
                        if (isSuperAdmin) _buildInfoRow('College / Campus', collegeName),
                        _buildInfoRow('Department', deptName),
                        if (user.role == AppRole.student && user.rollNumber != null)
                          _buildInfoRow('Roll Number', user.rollNumber!),
                        if (user.createdAt != null)
                          _buildInfoRow('Account Created', user.createdAt!.toLocal().toString().substring(0, 16)),
                        if (user.lastLoginAt != null)
                          _buildInfoRow('Last Login', user.lastLoginAt!.toLocal().toString().substring(0, 16)),
                      ],
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        card1,
                        const SizedBox(height: AcadexSpacing.md),
                        card2,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: card1),
                      const SizedBox(width: AcadexSpacing.md),
                      Expanded(child: card2),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AcadexSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
