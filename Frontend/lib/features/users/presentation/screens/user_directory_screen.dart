import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../domain/models/user_profile_model.dart';
import '../../domain/models/user_status_enum.dart';
import '../providers/user_providers.dart';
import '../widgets/user_card.dart';
import '../../../dashboard/presentation/widgets/acadex_app_bar.dart';

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

    // Academic Structure for resolving names in table
    final collegesAsync = ref.watch(collegesProvider);
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: const AcadexAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/users/new'),
        backgroundColor: DashboardColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text('New User', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Directory',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: DashboardColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage users, roles, and account statuses.',
                    style: GoogleFonts.inter(fontSize: 14, color: DashboardColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  
                  // Search & Filters
                  _buildFiltersRow(context, ref, currentUser, isDesktop),
                ],
              ),
            ),
          ),
          usersAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Unable to load users.')),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const SliverFillRemaining(
                  child: AcadexEmptyState(
                    title: 'No users found',
                    subtitle: 'Try adjusting your search or filters.',
                    icon: LucideIcons.users,
                  ),
                );
              }
              
              if (isDesktop) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildDesktopTable(context, users, collegesAsync.value, departmentsAsync.value),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 600 ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = users[index];
                      return UserCard(
                        user: user,
                        onTap: () => context.go('/users/${user.id}'),
                      );
                    },
                    childCount: users.length,
                  ),
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildFiltersRow(BuildContext context, WidgetRef ref, UserProfileModel currentUser, bool isDesktop) {
    final children = [
      Expanded(
        child: TextField(
          onChanged: (val) => ref.read(userSearchQueryProvider.notifier).state = val,
          decoration: InputDecoration(
            hintText: 'Search by name, email, or ID...',
            prefixIcon: const Icon(LucideIcons.search, color: DashboardColors.textMuted),
            filled: true,
            fillColor: DashboardColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: DashboardColors.primary)),
          ),
        ),
      ),
      const SizedBox(width: 12),
      _buildDropdown<AppRole?>(
        value: ref.watch(userRoleFilterProvider),
        hint: 'All Roles',
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
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DashboardColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: GoogleFonts.inter(color: DashboardColors.textSecondary, fontSize: 14)),
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context, List<UserProfileModel> users, dynamic colleges, dynamic departments) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(DashboardColors.background),
          dataRowMaxHeight: 64,
          dataRowMinHeight: 64,
          columns: [
            DataColumn(label: Text('User', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Role', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('College', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Department', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
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
                        backgroundColor: DashboardColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(color: DashboardColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(user.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          Text(user.email, style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: DashboardColors.border, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      user.role.displayName.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: DashboardColors.textSecondary),
                    ),
                  )
                ),
                DataCell(Text(collegeName, style: GoogleFonts.inter(fontSize: 13))),
                DataCell(Text(deptName, style: GoogleFonts.inter(fontSize: 13))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.status == UserStatus.active ? DashboardColors.success.withValues(alpha: 0.1) : DashboardColors.errorLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.status.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: user.status == UserStatus.active ? DashboardColors.success : DashboardColors.error,
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
