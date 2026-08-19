import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_providers.dart';
import '../widgets/user_card.dart';

class UserDirectoryScreen extends ConsumerWidget {
  const UserDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated || authState.user is! UserProfileModel) return const SizedBox.shrink();
    final currentUser = authState.user as UserProfileModel;

    final usersAsync = ref.watch(usersListProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Academic Structure for resolving names in table
    final collegesAsync = ref.watch(collegesProvider);
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.contentMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AcadexPageHeader(
              title: "User Directory",
              subtitle: "Manage platform users, administrative roles, and account statuses.",
              actions: [
                AcadexButton(
                  label: "New User",
                  icon: LucideIcons.plus,
                  onPressed: () => context.go('/users/new'),
                ),
              ],
            ),
            _buildFiltersRow(context, ref, currentUser, isDesktop, isDark),
            const SizedBox(height: 24),
            usersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text('Unable to load users.'),
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const AcadexEmptyState(
                    title: 'No users found',
                    subtitle: 'Try adjusting your search or filters.',
                    icon: LucideIcons.users,
                  );
                }
                
                if (isDesktop) {
                  return _buildDesktopTable(context, users, collegesAsync.value, departmentsAsync.value, isDark);
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 600 ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return UserCard(
                      user: user,
                      onTap: () => context.go('/users/${user.id}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context, WidgetRef ref, UserProfileModel currentUser, bool isDesktop, bool isDark) {
    final children = [
      Expanded(
        child: TextField(
          onChanged: (val) => ref.read(userSearchQueryProvider.notifier).state = val,
          decoration: InputDecoration(
            hintText: 'Search by name, email, or ID...',
            prefixIcon: Icon(LucideIcons.search, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
            filled: true,
            fillColor: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AcadexColors.primary),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      _buildDropdown<AppRole?>(
        value: ref.watch(userRoleFilterProvider),
        hint: 'All Roles',
        isDark: isDark,
        items: [
          const DropdownMenuItem(value: null, child: Text('All Roles')),
          ...AppRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))),
        ],
        onChanged: (val) => ref.read(userRoleFilterProvider.notifier).state = val,
      ),
      const SizedBox(width: 12),
      _buildDropdown<UserStatus?>(
        value: ref.watch(userStatusFilterProvider),
        hint: 'All Statuses',
        isDark: isDark,
        items: [
          const DropdownMenuItem(value: null, child: Text('All Statuses')),
          ...UserStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))),
        ],
        onChanged: (val) => ref.read(userStatusFilterProvider.notifier).state = val,
      ),
    ];

    if (currentUser.role == AppRole.superAdmin) {
      children.add(const SizedBox(width: 12));
      
      final collegesAsync = ref.watch(collegesProvider);
      final colleges = collegesAsync.value ?? [];
      
      children.add(
        _buildDropdown<String?>(
          value: ref.watch(userCollegeFilterProvider),
          hint: 'All Colleges',
          isDark: isDark,
          items: [
            const DropdownMenuItem(value: null, child: Text('All Colleges')),
            ...colleges.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
          ],
          onChanged: (val) => ref.read(userCollegeFilterProvider.notifier).state = val,
        ),
      );
    }
    
    if (currentUser.role == AppRole.superAdmin || currentUser.role == AppRole.collegeAdmin) {
      children.add(const SizedBox(width: 12));
      
      final deptsAsync = ref.watch(departmentsProvider);
      var depts = deptsAsync.value ?? [];
      
      if (currentUser.role == AppRole.collegeAdmin) {
        depts = depts.where((d) => d.collegeId == currentUser.collegeId).toList();
      } else {
        final currentCollegeFilter = ref.watch(userCollegeFilterProvider);
        if (currentCollegeFilter != null) {
          depts = depts.where((d) => d.collegeId == currentCollegeFilter).toList();
        }
      }
      
      children.add(
        _buildDropdown<String?>(
          value: ref.watch(userDeptFilterProvider),
          hint: 'All Departments',
          isDark: isDark,
          items: [
            const DropdownMenuItem(value: null, child: Text('All Departments')),
            ...depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
          ],
          onChanged: (val) => ref.read(userDeptFilterProvider.notifier).state = val,
        ),
      );
    }

    if (isDesktop) {
      return Row(children: children);
    } else {
      return Column(
        children: children.map((c) {
          if (c is Expanded) return c.child;
          if (c is SizedBox) return const SizedBox(height: 12);
          return Row(children: [Expanded(child: c)]);
        }).toList(),
      );
    }
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)),
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<UserProfileModel> users, dynamic colleges, dynamic departments, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
      ),
      child: ClipRRect(
        borderRadius: AcadexRadius.borderRadiusLg,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(isDark ? AcadexColors.darkCanvas : AcadexColors.canvasSoft),
          dataRowMaxHeight: 64,
          dataRowMinHeight: 64,
          columns: [
            DataColumn(label: Text('User', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Role', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('College', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Department', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold))),
          ],
          rows: users.map((user) {
            String collegeName = 'N/A';
            String deptName = 'N/A';
            if (colleges != null && user.collegeId != null) {
              final matches = (colleges as List).where((c) => c.id == user.collegeId);
              if (matches.isNotEmpty) collegeName = matches.first.name;
            }
            if (departments != null && user.departmentId != null) {
              final matches = (departments as List).where((d) => d.id == user.departmentId);
              if (matches.isNotEmpty) deptName = matches.first.name;
            }

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AcadexColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(user.name, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600)),
                          Text(user.email, style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.role.displayName.toUpperCase(),
                      style: AcadexTypography.caption(color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                ),
                DataCell(Text(collegeName, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontSize: 13))),
                DataCell(Text(deptName, style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontSize: 13))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.status == UserStatus.active ? AcadexColors.success.withValues(alpha: 0.1) : AcadexColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: user.status == UserStatus.active ? AcadexColors.success : AcadexColors.error,
                      ),
                    ),
                  )
                ),
                DataCell(
                  TextButton(
                    onPressed: () => context.go('/users/${user.id}'),
                    child: const Text('View Details'),
                  )
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
