import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/auth_state.dart';
import '../../domain/models/role_enum.dart';
import '../../domain/models/workspace_model.dart';
import '../providers/auth_provider.dart';
import '../providers/workspace_providers.dart';

Future<void> showWorkspaceSelectorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const WorkspaceSelectorDialog(),
  );
}

class WorkspaceSelectorDialog extends ConsumerWidget {
  const WorkspaceSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final workspacesAsync = ref.watch(userWorkspacesProvider);
    final activeWorkspaceId = ref.watch(activeWorkspaceIdProvider);
    final isSwitching = ref.watch(isSwitchingWorkspaceProvider);

    final isSuperAdmin = authState is AuthAuthenticated &&
        authState.user.role == AppRole.superAdmin;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AcadexRadius.borderRadiusLg,
        side: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 460,
          maxHeight: 560,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AcadexColors.primary.withValues(alpha: 0.12),
                      borderRadius: AcadexRadius.borderRadiusSm,
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.building2,
                        size: 18,
                        color: AcadexColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Switch Workspace',
                          style: AcadexTypography.heading3(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select an authorized institutional workspace',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ),
                    onPressed: isSwitching ? null : () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Super Admin Platform Banner if applicable
              if (isSuperAdmin) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AcadexColors.warning.withValues(alpha: 0.08),
                    borderRadius: AcadexRadius.borderRadiusMd,
                    border: Border.all(
                      color: AcadexColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck, size: 18, color: AcadexColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Platform Super Admin session: You hold unrestricted oversight across all active campuses.',
                          style: AcadexTypography.caption(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Workspace Content List
              Flexible(
                child: workspacesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          SizedBox(height: 12),
                          Text('Loading authorized workspaces...', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.alertTriangle, size: 32, color: AcadexColors.error),
                        const SizedBox(height: 8),
                        Text(
                          'Unable to load workspaces',
                          style: AcadexTypography.body(color: AcadexColors.error),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => ref.refresh(userWorkspacesProvider),
                          icon: const Icon(LucideIcons.refreshCw, size: 14),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                  data: (workspaces) {
                    if (workspaces.isEmpty && !isSuperAdmin) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.building, size: 36, color: AcadexColors.inkMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No Active Workspaces Found',
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your canonical account does not currently hold active memberships in any college workspace. Contact your administrator or log out.',
                              textAlign: TextAlign.center,
                              style: AcadexTypography.caption(
                                color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await ref.read(authProvider.notifier).logout();
                              },
                              icon: const Icon(LucideIcons.logOut, size: 14),
                              label: const Text('Log Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcadexColors.error,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: workspaces.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ws = workspaces[index];
                        final isCurrent = ws.collegeId == activeWorkspaceId;

                        return _WorkspaceItemTile(
                          workspace: ws,
                          isCurrent: isCurrent,
                          isSwitching: isSwitching,
                          onSelect: () async {
                            if (isCurrent || isSwitching) return;
                            try {
                              final success = await ref
                                  .read(workspaceSwitchControllerProvider)
                                  .switchWorkspace(ws.collegeId);
                              if (context.mounted && success) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Switched to ${ws.collegeName}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not switch workspace: $e'),
                                    backgroundColor: AcadexColors.error,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Multi-Tenant Isolation Active',
                    style: AcadexTypography.caption(
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    ).copyWith(fontSize: 11),
                  ),
                  TextButton(
                    onPressed: isSwitching ? null : () => Navigator.of(context).pop(),
                    child: const Text('Done'),
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

class _WorkspaceItemTile extends StatelessWidget {
  final WorkspaceMembershipModel workspace;
  final bool isCurrent;
  final bool isSwitching;
  final VoidCallback onSelect;

  const _WorkspaceItemTile({
    required this.workspace,
    required this.isCurrent,
    required this.isSwitching,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isCurrent
        ? AcadexColors.primary
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final bgColor = isCurrent
        ? (isDark
            ? AcadexColors.primary.withValues(alpha: 0.15)
            : AcadexColors.primary.withValues(alpha: 0.05))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));

    return InkWell(
      onTap: isSwitching ? null : onSelect,
      borderRadius: AcadexRadius.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AcadexRadius.borderRadiusMd,
          border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
        ),
        child: Row(
          children: [
            // College Code Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrent
                    ? AcadexColors.primary
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                borderRadius: AcadexRadius.borderRadiusSm,
              ),
              child: Center(
                child: Text(
                  workspace.collegeCode.isNotEmpty
                      ? workspace.collegeCode.substring(0, workspace.collegeCode.length.clamp(1, 3)).toUpperCase()
                      : 'COL',
                  style: TextStyle(
                    color: isCurrent ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // College Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workspace.collegeName,
                          style: AcadexTypography.body(
                            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                          ).copyWith(
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AcadexColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Role Badges
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          workspace.primaryRole.displayName,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (workspace.instituteId != null && workspace.instituteId!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'PIN: ${workspace.instituteId}',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (workspace.departmentName != null && workspace.departmentName!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${workspace.departmentName}',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Action Indicator
            if (isCurrent)
              const Icon(LucideIcons.check, size: 18, color: AcadexColors.primary)
            else
              const Icon(LucideIcons.chevronRight, size: 16, color: AcadexColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
