import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/design_system/acadex_breakpoints.dart';
import '../../../../core/presentation/design_system/acadex_colors.dart';
import '../../../../core/presentation/design_system/acadex_spacing.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_providers.dart';
import '../widgets/user_list_item.dart';
import '../widgets/user_role_badge.dart';
import '../widgets/user_status_badge.dart';

class UserDirectoryScreen extends ConsumerStatefulWidget {
  const UserDirectoryScreen({super.key});

  @override
  ConsumerState<UserDirectoryScreen> createState() => _UserDirectoryScreenState();
}

class _UserDirectoryScreenState extends ConsumerState<UserDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const AcadexPageContainer(
        child: Center(child: Text('Please log in to access the user directory.')),
      );
    }

    final currentUser = authState.user;
    final isSuperAdmin = currentUser.role == AppRole.superAdmin;
    final isCollegeAdmin = currentUser.role == AppRole.collegeAdmin;
    final isHod = currentUser.role == AppRole.hod;
    final canManageUsers = isSuperAdmin || isCollegeAdmin;

    final usersAsync = ref.watch(usersListProvider);
    final selectedRole = ref.watch(userRoleFilterProvider);
    final selectedStatus = ref.watch(userStatusFilterProvider);
    final selectedDept = ref.watch(userDeptFilterProvider);

    final departmentsAsync = ref.watch(departmentsProvider);

    final isDesktop = AcadexBreakpoints.isDesktop(context);

    // Build role filter options depending on user's role
    final roleFilterNames = <String>['All'];
    if (isSuperAdmin) {
      roleFilterNames.addAll(['College Admin', 'HOD', 'Faculty', 'Student']);
    } else if (isCollegeAdmin) {
      roleFilterNames.addAll(['HOD', 'Faculty', 'Student']);
    } else if (isHod) {
      roleFilterNames.addAll(['Faculty', 'Student']);
    }

    final roleFilterOptions = roleFilterNames.map((name) => AcadexFilterOption<String>(label: name, value: name)).toList();

    String currentRoleFilterLabel = 'All';
    if (selectedRole != null) {
      currentRoleFilterLabel = selectedRole.displayName;
    }

    final pageSubtitle = isSuperAdmin
        ? 'Global platform user directory and administrative accounts'
        : isCollegeAdmin
            ? 'Campus people hub: manage HODs, faculty, and enrolled students'
            : isHod
                ? 'Department directory: faculty and students'
                : 'Campus Directory';

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(usersListProvider);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcadexPageHeader(
            title: 'Users & Roles',
            subtitle: pageSubtitle,
            actions: canManageUsers
                ? [
                    AcadexButton(
                      label: 'Add User',
                      icon: Icons.person_add_outlined,
                      onPressed: () => context.go('/users/new'),
                    ),
                  ]
                : null,
          ),

          // Search & Filter Header
          AcadexSearchBar(
            controller: _searchController,
            hintText: 'Search by name, email, or institutional ID...',
            onChanged: (query) {
              ref.read(userSearchQueryProvider.notifier).state = query;
            },
            onClear: () {
              _searchController.clear();
              ref.read(userSearchQueryProvider.notifier).state = '';
            },
          ),
          const SizedBox(height: AcadexSpacing.sm),

          // Role Tabs Filter
          AcadexFilterBar<String>(
            options: roleFilterOptions,
            selectedValue: currentRoleFilterLabel,
            onSelected: (val) {
              if (val == 'All') {
                ref.read(userRoleFilterProvider.notifier).state = null;
              } else if (val == 'College Admin') {
                ref.read(userRoleFilterProvider.notifier).state = AppRole.collegeAdmin;
              } else if (val == 'HOD') {
                ref.read(userRoleFilterProvider.notifier).state = AppRole.hod;
              } else if (val == 'Faculty') {
                ref.read(userRoleFilterProvider.notifier).state = AppRole.faculty;
              } else if (val == 'Student') {
                ref.read(userRoleFilterProvider.notifier).state = AppRole.student;
              }
            },
          ),
          const SizedBox(height: AcadexSpacing.xs),

          // Status & Department Dropdown Filters
          Wrap(
            spacing: AcadexSpacing.sm,
            runSpacing: AcadexSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: DropdownButton<UserStatus?>(
                  value: selectedStatus,
                  hint: const Text('All Statuses', overflow: TextOverflow.ellipsis),
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: UserStatus.active, child: Text('Active', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: UserStatus.pending, child: Text('Pending Activation', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: UserStatus.deactivated, child: Text('Deactivated', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    ref.read(userStatusFilterProvider.notifier).state = val;
                  },
                ),
              ),
              if (departmentsAsync.value != null && departmentsAsync.value!.isNotEmpty && !isHod)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: DropdownButton<String?>(
                    value: selectedDept,
                    hint: const Text('All Departments', overflow: TextOverflow.ellipsis),
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Departments', overflow: TextOverflow.ellipsis)),
                      ...departmentsAsync.value!.map((d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) {
                      ref.read(userDeptFilterProvider.notifier).state = val;
                    },
                  ),
                ),
              if (selectedRole != null || selectedStatus != null || selectedDept != null || _searchController.text.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Reset Filters'),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(userSearchQueryProvider.notifier).state = '';
                    ref.read(userRoleFilterProvider.notifier).state = null;
                    ref.read(userStatusFilterProvider.notifier).state = null;
                    ref.read(userDeptFilterProvider.notifier).state = null;
                  },
                ),
            ],
          ),
          const SizedBox(height: AcadexSpacing.md),

          // User List Content
          usersAsync.when(
            loading: () => const AcadexLoadingState(message: 'Loading users...'),
            error: (err, _) => AcadexErrorState(
              title: 'Failed to load users',
              message: err.toString(),
              onRetry: () => ref.refresh(usersListProvider),
            ),
            data: (users) {
              if (users.isEmpty) {
                return AcadexEmptyState(
                  title: 'No users found',
                  subtitle: _searchController.text.isNotEmpty || selectedRole != null || selectedStatus != null
                      ? 'No matching users found for the selected filters. Try resetting your search query.'
                      : 'There are currently no registered users in this directory.',
                  icon: Icons.people_outline,
                  actionLabel: canManageUsers ? 'Add User' : null,
                  onActionTap: canManageUsers ? () => context.go('/users/new') : null,
                );
              }

              // Resolve department names helper
              final Map<String, String> deptMap = {
                for (var d in departmentsAsync.value ?? []) d.id: d.name
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AcadexSectionHeader(
                    title: 'Directory Records',
                    count: users.length,
                  ),
                  const SizedBox(height: AcadexSpacing.sm),

                  // Desktop Table View
                  if (isDesktop)
                    _buildDesktopTable(context, users, deptMap)
                  else
                    // Mobile & Tablet List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AcadexSpacing.sm),
                      itemBuilder: (context, index) {
                        final u = users[index];
                        return UserListItem(
                          user: u,
                          departmentName: u.departmentId != null ? deptMap[u.departmentId] : null,
                          onTap: () => context.go('/users/${u.id}'),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<UserProfileModel> users,
    Map<String, String> deptMap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        side: BorderSide(
          color: isDark ? AcadexColors.darkBorder : AcadexColors.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 64,
            dataRowMaxHeight: 72,
            headingRowColor: WidgetStateProperty.all(
              isDark ? AcadexColors.darkSurfaceElevated : AcadexColors.surfaceMuted,
            ),
            columns: const [
              DataColumn(label: Text('Name & ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: users.map((u) {
              final idLabel = u.employeeId ?? u.rollNumber ?? '';
              final deptName = u.departmentId != null ? (deptMap[u.departmentId] ?? '') : '—';

              return DataRow(
                cells: [
                  DataCell(
                    InkWell(
                      onTap: () => context.go('/users/${u.id}'),
                      child: Text(
                        idLabel.isNotEmpty ? '${u.name}\n$idLabel' : u.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  DataCell(UserRoleBadge(role: u.role)),
                  DataCell(Text(u.email.isNotEmpty ? u.email : '—')),
                  DataCell(Text(deptName)),
                  DataCell(UserStatusBadge(status: u.accountStatus)),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      onPressed: () => context.go('/users/${u.id}'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
