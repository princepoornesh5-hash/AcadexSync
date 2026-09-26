import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_data_table.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_form_card.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../providers/academic_providers.dart';
import '../providers/department_setup_provider.dart';
import '../../domain/models/academic_models.dart';
import '../widgets/faculty_assignment_dialog.dart';
import '../widgets/import_data_dialog.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FacultyListScreen extends ConsumerStatefulWidget {
  const FacultyListScreen({super.key});

  @override
  ConsumerState<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends ConsumerState<FacultyListScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // 'all' | 'active' | 'pending'

  void _showImportDialog() {
    showDialog(context: context, builder: (ctx) => const ImportDataDialog(entityName: 'Faculty'));
  }

  void _showAssignmentDialog(Faculty? faculty) {
    FacultyAssignmentDialog.show(context, faculty: faculty);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);
    final facultyAsync = ref.watch(facultyProvider(null));
    final deptMap = ref.watch(departmentMapProvider);
    final assignmentsAsync = ref.watch(facultyAssignmentsProvider);
    final allAssignments = assignmentsAsync.valueOrNull ?? [];

    final filteredItems = facultyAsync.items.where((f) {
      if (_filter == 'active' && !f.isActive) return false;
      if (_filter == 'pending' && f.accountStatus != AccountStatus.pendingActivation) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final deptName = (deptMap[f.departmentId]?.name ?? '').toLowerCase();
      return f.name.toLowerCase().contains(q) ||
          f.employeeId.toLowerCase().contains(q) ||
          (f.instituteId ?? '').toLowerCase().contains(q) ||
          f.email.toLowerCase().contains(q) ||
          deptName.contains(q);
    }).toList();

    return AcadexPageContainer(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Row(
              children: [
                const Expanded(
                  child: AcadexPageHeader(
                    title: "Faculty",
                    subtitle: "Manage faculty members and teaching allocations.",
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical, size: 20),
                  onSelected: (val) {
                    if (val == 'assign') _showAssignmentDialog(null);
                    if (val == 'all_assign') context.push('/faculty-assignments');
                    if (val == 'import') _showImportDialog();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(LucideIcons.userPlus, size: 16),
                          SizedBox(width: 8),
                          Text('Assign Classes'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'all_assign',
                      child: Row(
                        children: [
                          Icon(LucideIcons.userCheck, size: 16),
                          SizedBox(width: 8),
                          Text('All Assignments'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(LucideIcons.uploadCloud, size: 16),
                          SizedBox(width: 8),
                          Text('Import CSV'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: AcadexPageHeader(
                    title: "Faculty",
                    subtitle: "Manage faculty members and teaching assignments.",
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showAssignmentDialog(null),
                      icon: const Icon(LucideIcons.userPlus, size: 16),
                      label: const Text("Assign Classes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AcadexColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/faculty-assignments'),
                      icon: const Icon(LucideIcons.userCheck, size: 16),
                      label: const Text("All Assignments"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showImportDialog,
                      icon: const Icon(LucideIcons.uploadCloud, size: 16),
                      label: const Text("Import CSV"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          AcadexSearchFilterBar(
            searchHint: "Search faculty by name, ID, or department...",
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onActionTap: () => context.push('/academics/faculty/new'),
            actionLabel: "Add Faculty",
          ),
          const SizedBox(height: 8),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in [
                  ('all', 'All Faculty'),
                  ('active', 'Active Members'),
                  ('pending', 'Pending Activation'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      onSelected: (_) => setState(() => _filter = f.$1),
                      selectedColor: AcadexColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AcadexColors.primary,
                      labelStyle: TextStyle(
                        color: _filter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                        fontWeight: _filter == f.$1 ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _filter == f.$1 ? AcadexColors.primary : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: (facultyAsync.isLoading && facultyAsync.items.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : facultyAsync.error != null
                    ? Center(
                        child: AcadexErrorState.fromError(
                          error: facultyAsync.error,
                          title: "Unable to load faculty",
                          onRetry: () => ref.read(facultyProvider(null).notifier).refresh(),
                        ),
                      )
                    : filteredItems.isEmpty
                        ? (facultyAsync.items.isEmpty
                            ? AcadexEmptyState(
                                title: "No faculty members have been added yet.",
                                subtitle: "Add faculty members to allocate courses and manage teaching assignments.",
                                icon: LucideIcons.graduationCap,
                                actionLabel: "Add Faculty",
                                onActionTap: () => context.push('/academics/faculty/new'),
                              )
                            : AcadexEmptyState.filterEmpty(
                                filterSummary: _searchQuery.isNotEmpty ? "query '$_searchQuery'" : "selected filter",
                                onClearFilters: () => setState(() {
                                  _searchQuery = '';
                                  _filter = 'all';
                                }),
                              ))
                        : isMobile
                            ? _buildMobileList(filteredItems, deptMap, allAssignments, isDark)
                            : _buildDesktopTable(filteredItems, deptMap, allAssignments),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
    List<Faculty> items,
    Map<String, Department> deptMap,
    List<FacultyAssignment> allAssignments,
    bool isDark,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final f = items[index];
        final deptName = deptMap[f.departmentId]?.name ?? (f.departmentId.isNotEmpty ? f.departmentId : 'Unassigned');
        final facultyAssignments = allAssignments.where((a) => a.facultyId == f.id).toList();
        final assignmentCount = facultyAssignments.isNotEmpty ? facultyAssignments.length : (f.subjectIds.length);
        final isPending = f.accountStatus == AccountStatus.pendingActivation;

        return GestureDetector(
          onTap: () => context.push('/academics/faculty/${f.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
              borderRadius: AcadexRadius.borderRadiusLg,
              border: Border.all(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AcadexColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f.employeeId.isNotEmpty ? f.employeeId : (f.instituteId ?? 'FAC'),
                              style: const TextStyle(
                                color: AcadexColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f.name,
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AcadexColors.warningLight
                            : (f.isActive
                                ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
                                : (isDark ? AcadexColors.darkSurfaceHover : AcadexColors.canvasSoft)),
                        borderRadius: AcadexRadius.borderRadiusFull,
                      ),
                      child: Text(
                        isPending ? "Pending Activation" : (f.isActive ? "Active" : "Inactive"),
                        style: TextStyle(
                          color: isPending ? AcadexColors.warning : (f.isActive ? AcadexColors.success : AcadexColors.inkMuted),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.building2, size: 14, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        deptName,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                        ).copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.mail, size: 13, color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f.email,
                        style: AcadexTypography.caption(
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: assignmentCount > 0
                            ? AcadexColors.primary.withValues(alpha: 0.1)
                            : AcadexColors.warning.withValues(alpha: 0.1),
                        borderRadius: AcadexRadius.borderRadiusSm,
                      ),
                      child: Text(
                        assignmentCount > 0
                            ? "$assignmentCount Active Class${assignmentCount == 1 ? '' : 'es'}"
                            : "No Assignments",
                        style: TextStyle(
                          color: assignmentCount > 0 ? AcadexColors.primary : AcadexColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: "View Profile",
                          icon: const Icon(LucideIcons.arrowRight, size: 18, color: AcadexColors.primary),
                          onPressed: () => context.push('/academics/faculty/${f.id}'),
                        ),
                        IconButton(
                          tooltip: "Edit Faculty",
                          icon: Icon(
                            LucideIcons.edit,
                            size: 18,
                            color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                          ),
                          onPressed: () => context.push('/academics/faculty/edit/${f.id}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(
    List<Faculty> items,
    Map<String, Department> deptMap,
    List<FacultyAssignment> allAssignments,
  ) {
    return AcadexDataTable(
      columns: const ["Employee ID", "Faculty Name", "Department", "Designation", "Teaching Assignments", "Status", "Actions"],
      rows: items.map((f) {
        final deptName = deptMap[f.departmentId]?.name ?? (f.departmentId.isNotEmpty ? f.departmentId : 'Unassigned');
        final facultyAssignments = allAssignments.where((a) => a.facultyId == f.id).toList();
        final hasAssignments = facultyAssignments.isNotEmpty || f.subjectIds.isNotEmpty || f.sectionIds.isNotEmpty;
        final assignmentCount = facultyAssignments.isNotEmpty ? facultyAssignments.length : (f.subjectIds.length);
        final isPending = f.accountStatus == AccountStatus.pendingActivation;

        return DataRow(
          onSelectChanged: (_) => context.push('/academics/faculty/${f.id}'),
          cells: [
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AcadexColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  f.employeeId.isNotEmpty ? f.employeeId : (f.instituteId ?? '—'),
                  style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
            DataCell(Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(deptName)),
            DataCell(Text(f.designation ?? 'Assistant Professor')),
            DataCell(
              !hasAssignments
                  ? const Text("Unassigned", style: TextStyle(color: AcadexColors.warning, fontStyle: FontStyle.italic))
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AcadexColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "$assignmentCount Active Class${assignmentCount == 1 ? '' : 'es'}",
                        style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? AcadexColors.warningLight
                      : (f.isActive ? AcadexColors.successLight : AcadexColors.canvasSoft),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPending ? "Pending Activation" : (f.isActive ? "Active" : "Inactive"),
                  style: TextStyle(
                    color: isPending ? AcadexColors.warning : (f.isActive ? AcadexColors.success : AcadexColors.inkMuted),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.eye, size: 18),
                    tooltip: "View Details",
                    onPressed: () => context.push('/academics/faculty/${f.id}'),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.edit, size: 18),
                    tooltip: "Edit Profile",
                    onPressed: () => context.push('/academics/faculty/edit/${f.id}'),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class FacultyActivationResultDialog extends StatelessWidget {
  final ProvisionFacultyResult result;
  final String departmentName;

  const FacultyActivationResultDialog({
    super.key,
    required this.result,
    required this.departmentName,
  });

  static Future<void> show(
    BuildContext context,
    ProvisionFacultyResult result, {
    required String departmentName,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FacultyActivationResultDialog(
        result: result,
        departmentName: departmentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expiresAt = result.invitation.expiresAt;
    final expiryFormatted = expiresAt != null
        ? DateFormat('EEEE, MMM d, yyyy • h:mm a').format(expiresAt.toLocal())
        : '7 days from issue';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AcadexColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.circleCheck, color: AcadexColors.success, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty Account Provisioned',
                        style: AcadexTypography.heading3(color: theme.colorScheme.onSurface),
                      ),
                      Text(
                        'Activation credentials generated successfully',
                        style: AcadexTypography.caption(
                          color: theme.textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(context, 'Faculty Name', result.user.name),
                  const SizedBox(height: 8),
                  _buildDetailRow(context, 'PIN Number', result.user.instituteId ?? result.faculty.employeeId),
                  const SizedBox(height: 8),
                  _buildDetailRow(context, 'Email Address', result.user.email),
                  if (result.faculty.employeeId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(context, 'Employee ID', result.faculty.employeeId),
                  ],
                  const SizedBox(height: 8),
                  _buildDetailRow(context, 'Department', departmentName),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Account Status',
                    result.invitation.status.toUpperCase(),
                    badgeColor: AcadexColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AcadexColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'SINGLE-USE ACTIVATION CODE',
                    style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    result.activationCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: AcadexColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        'Expires: $expiryFormatted',
                        style: AcadexTypography.caption(
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AcadexColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.triangleAlert, color: AcadexColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Save this activation code securely. It will not be shown again after leaving this screen.',
                      style: AcadexTypography.caption(
                        color: isDark ? Colors.white70 : const Color(0xFF7C2D12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.activationCode));
                      AcadexSnackBar.showSuccess(
                        context,
                        'Activation code copied to clipboard',
                      );
                    },
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: const Text('Copy Activation Code'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AcadexColors.primary.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? badgeColor}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AcadexTypography.caption(color: theme.textTheme.bodySmall?.color ?? AcadexColors.inkMuted),
        ),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        else
          Text(
            value,
            style: AcadexTypography.body(color: theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

class FacultyFormScreen extends ConsumerStatefulWidget {
  final String? id;
  final String? initialDepartmentId;
  const FacultyFormScreen({super.key, this.id, this.initialDepartmentId});

  @override
  ConsumerState<FacultyFormScreen> createState() => _FacultyFormScreenState();
}

class _FacultyFormScreenState extends ConsumerState<FacultyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _instituteIdCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _employeeIdCtrl;
  late TextEditingController _designationCtrl;
  late TextEditingController _qualificationCtrl;
  late TextEditingController _specializationCtrl;

  String? _selectedDepartmentId;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDepartmentId = widget.initialDepartmentId;
    _nameCtrl = TextEditingController();
    _instituteIdCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _employeeIdCtrl = TextEditingController();
    _designationCtrl = TextEditingController(text: 'Assistant Professor');
    _qualificationCtrl = TextEditingController();
    _specializationCtrl = TextEditingController();

    if (widget.id != null) {
      _loadExistingFaculty();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authState = ref.read(authProvider);
        if (authState is AuthAuthenticated && authState.user.role == AppRole.hod) {
          if (authState.user.departmentId != null && authState.user.departmentId!.isNotEmpty) {
            setState(() {
              _selectedDepartmentId = authState.user.departmentId;
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instituteIdCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _employeeIdCtrl.dispose();
    _designationCtrl.dispose();
    _qualificationCtrl.dispose();
    _specializationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingFaculty() async {
    setState(() => _isLoading = true);
    try {
      final faculty = await ref.read(academicRepositoryProvider).getFacultyById(widget.id!);
      if (faculty != null && mounted) {
        _nameCtrl.text = faculty.name;
        _instituteIdCtrl.text = faculty.employeeId;
        _emailCtrl.text = faculty.email;
        _phoneCtrl.text = faculty.phone;
        _employeeIdCtrl.text = faculty.employeeId;
        _designationCtrl.text = faculty.designation ?? 'Assistant Professor';
        _qualificationCtrl.text = faculty.qualification ?? '';
        _specializationCtrl.text = faculty.specialization ?? '';
        _selectedDepartmentId = faculty.departmentId;
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(
          context,
          e,
          fallbackMessage: 'Failed to load faculty details',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null || _selectedDepartmentId!.isEmpty) {
      AcadexSnackBar.showWarning(
        context,
        'Please select a department for this faculty member',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.id == null) {
        // Provisioning Mode
        final request = ProvisionFacultyRequest(
          departmentId: _selectedDepartmentId!,
          name: _nameCtrl.text.trim(),
          instituteId: _instituteIdCtrl.text.trim().toUpperCase(),
          email: _emailCtrl.text.trim().toLowerCase(),
          phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
          employeeId: _employeeIdCtrl.text.trim().isNotEmpty ? _employeeIdCtrl.text.trim() : null,
          designation: _designationCtrl.text.trim().isNotEmpty ? _designationCtrl.text.trim() : 'Assistant Professor',
          qualification: _qualificationCtrl.text.trim().isNotEmpty ? _qualificationCtrl.text.trim() : null,
          specialization: _specializationCtrl.text.trim().isNotEmpty ? _specializationCtrl.text.trim() : null,
        );

        final result = await ref.read(facultyProvisionProvider.notifier).provisionFaculty(request);

        if (mounted) {
          final depts = ref.read(departmentsProvider).valueOrNull ?? [];
          final deptName = depts.firstWhere(
            (d) => d.id == _selectedDepartmentId,
            orElse: () => Department(id: '', collegeId: '', name: 'Department', code: '', hodId: '', description: ''),
          ).name;

          await FacultyActivationResultDialog.show(
            context,
            result,
            departmentName: deptName,
          );

          if (mounted) {
            context.safePop(fallbackRoute: '/academics/faculty');
          }
        }
      } else {
        // Edit Mode
        final updatedFaculty = Faculty(
          id: widget.id!,
          collegeId: '',
          departmentId: _selectedDepartmentId!,
          name: _nameCtrl.text.trim(),
          employeeId: _employeeIdCtrl.text.trim(),
          email: _emailCtrl.text.trim().toLowerCase(),
          phone: _phoneCtrl.text.trim(),
          designation: _designationCtrl.text.trim(),
          qualification: _qualificationCtrl.text.trim(),
          specialization: _specializationCtrl.text.trim(),
        );

        await ref.read(academicRepositoryProvider).updateFaculty(updatedFaculty);
        ref.invalidate(facultyProvider(null));
        ref.invalidate(facultyByIdProvider(widget.id!));
        ref.invalidate(facultySummaryProvider(widget.id!));
        if (_selectedDepartmentId != null) {
          ref.invalidate(facultyProvider(_selectedDepartmentId));
          ref.invalidate(departmentSetupProvider(_selectedDepartmentId!));
        }

        if (mounted) {
          AcadexSnackBar.showSuccess(context, 'Faculty profile updated successfully.');
          context.safePop(fallbackRoute: '/academics/faculty');
        }
      }
    } catch (e) {
      if (mounted) {
        AcadexSnackBar.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    final departmentsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.safePop(fallbackRoute: '/academics/faculty'),
        ),
        title: Text(
          isEdit ? "Edit Faculty" : "Add Faculty",
          style: AcadexTypography.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : AcadexPageContainer(
              maxWidth: AcadexLayout.formMaxWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AcadexFormCard(
                      title: "Personal Information",
                      icon: LucideIcons.user,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: "Full Name *",
                              hintText: "e.g. Dr. Alan Turing",
                              prefixIcon: Icon(LucideIcons.user),
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'Full Name must be at least 2 characters'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _instituteIdCtrl,
                                  enabled: !isEdit,
                                  decoration: const InputDecoration(
                                    labelText: "PIN Number *",
                                    hintText: "e.g. FAC-CSE-014",
                                    prefixIcon: Icon(LucideIcons.fingerprint),
                                  ),
                                  validator: (v) => (v == null || v.trim().length < 2)
                                      ? 'PIN Number is required (min 2 chars)'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _employeeIdCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Employee ID",
                                    hintText: "e.g. EMP001",
                                    prefixIcon: Icon(LucideIcons.hash),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Email Address *",
                                    hintText: "e.g. alan@acadex.edu",
                                    prefixIcon: Icon(LucideIcons.mail),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Email address is required';
                                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                    if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Phone Number",
                                    hintText: "e.g. +91 9876543210",
                                    prefixIcon: Icon(LucideIcons.phone),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AcadexFormCard(
                      title: "Academic & Department Assignment",
                      icon: LucideIcons.briefcase,
                      child: Column(
                        children: [
                          departmentsAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (err, _) => Text('Failed to load departments: $err', style: const TextStyle(color: AcadexColors.warning)),
                            data: (depts) {
                              final authState = ref.watch(authProvider);
                              final isHod = authState is AuthAuthenticated && authState.user.role == AppRole.hod;
                              final hodDeptId = authState is AuthAuthenticated ? authState.user.departmentId : null;

                              if (isHod && hodDeptId != null && _selectedDepartmentId != hodDeptId) {
                                _selectedDepartmentId = hodDeptId;
                              }

                              final availableDepts = isHod && hodDeptId != null
                                  ? depts.where((d) => d.id == hodDeptId).toList()
                                  : depts.where((d) => d.isActive).toList();

                              if (_selectedDepartmentId == null && availableDepts.isNotEmpty) {
                                _selectedDepartmentId = availableDepts.first.id;
                              }

                              return DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: isHod ? "Assigned Department (HOD)" : "Department *",
                                  prefixIcon: const Icon(LucideIcons.building),
                                ),
                                value: _selectedDepartmentId,
                                items: availableDepts
                                    .map((d) => DropdownMenuItem(
                                          value: d.id,
                                          child: Text('${d.name} (${d.code})'),
                                        ))
                                    .toList(),
                                onChanged: (isHod || isEdit) ? null : (v) => setState(() => _selectedDepartmentId = v),
                                validator: (v) => (v == null || v.isEmpty) ? 'Please select a department' : null,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _designationCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Designation",
                                    hintText: "e.g. Associate Professor",
                                    prefixIcon: Icon(LucideIcons.badgeCheck),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _qualificationCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Qualification",
                                    hintText: "e.g. Ph.D., M.Tech",
                                    prefixIcon: Icon(LucideIcons.graduationCap),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _specializationCtrl,
                            decoration: const InputDecoration(
                              labelText: "Specialization / Domain",
                              hintText: "e.g. Machine Learning, Distributed Algorithms",
                              prefixIcon: Icon(LucideIcons.bookOpen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting ? null : () => context.safePop(fallbackRoute: '/academics/faculty'),
                          child: Text(
                            "Cancel",
                            style: AcadexTypography.body(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AcadexColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          ),
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(LucideIcons.userPlus, size: 18),
                          label: Text(
                            _isSubmitting
                                ? (isEdit ? "Saving..." : "Adding Faculty...")
                                : isEdit
                                    ? "Save Changes"
                                    : "Add Faculty",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }
}
