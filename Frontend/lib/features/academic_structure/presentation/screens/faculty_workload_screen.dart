import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/academic_providers.dart';
import '../widgets/faculty_assignment_dialog.dart';

class FacultyWorkloadScreen extends ConsumerStatefulWidget {
  const FacultyWorkloadScreen({super.key});

  @override
  ConsumerState<FacultyWorkloadScreen> createState() => _FacultyWorkloadScreenState();
}

class _FacultyWorkloadScreenState extends ConsumerState<FacultyWorkloadScreen> {
  String _searchQuery = '';
  String? _selectedFacultyId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isHod = currentUser?.role == AppRole.hod;

    final workloadList = ref.watch(facultyWorkloadListProvider);
    final deptMap = ref.watch(departmentMapProvider);
    final courseMap = ref.watch(courseMapProvider);
    final semMap = ref.watch(semesterMapProvider);
    final secMap = ref.watch(sectionMapProvider);
    final subMap = ref.watch(subjectMapProvider);

    final filtered = workloadList.where((w) {
      if (_searchQuery.isNotEmpty) {
        final nameMatch = w.faculty.name.toLowerCase().contains(_searchQuery);
        final empMatch = w.faculty.employeeId.toLowerCase().contains(_searchQuery);
        if (!nameMatch && !empMatch) return false;
      }
      return true;
    }).toList();

    final totalFaculty = workloadList.length;
    final allocatedFaculty = workloadList.where((w) => w.assignments.isNotEmpty).length;
    final totalWeeklyPeriods = workloadList.fold<int>(0, (sum, w) => sum + w.totalWeeklyPeriods);
    final avgPeriods = totalFaculty > 0 ? (totalWeeklyPeriods / totalFaculty).toStringAsFixed(1) : '0';

    return AcadexPageContainer(
        backgroundColor: Colors.transparent,
        maxWidth: 1600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            AcadexPageHeader(
              title: "Faculty Workload",
              subtitle: isHod
                  ? "Academic teaching load distribution for your department."
                  : "College-wide academic workload oversight and subject allocations.",
              actions: [
                AcadexButton(
                  label: "Assign Classes",
                  icon: LucideIcons.userPlus,
                  onPressed: () => FacultyAssignmentDialog.show(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Metrics Row
            Row(
              children: [
                Expanded(
                  child: AcadexStatCard(
                    title: "Total Faculty",
                    value: "$totalFaculty",
                    icon: LucideIcons.users,
                    iconColor: AcadexColors.primary,
                    subtitle: isHod ? "In your department" : "Across college departments",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AcadexStatCard(
                    title: "Active Allocations",
                    value: "$allocatedFaculty",
                    icon: LucideIcons.userCheck,
                    iconColor: AcadexColors.success,
                    subtitle: "${totalFaculty > 0 ? ((allocatedFaculty / totalFaculty) * 100).toInt() : 0}% faculty assigned",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AcadexStatCard(
                    title: "Avg Weekly Periods",
                    value: avgPeriods,
                    icon: LucideIcons.clock,
                    iconColor: AcadexColors.accentPurple,
                    subtitle: "$totalWeeklyPeriods total class hours/week",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Filter
            AcadexCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search faculty by name or employee ID...",
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AcadexRadius.md)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Workload List
            if (filtered.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: AcadexEmptyState(
                    title: "No Faculty Found",
                    subtitle: "No faculty members match the current search.",
                    icon: LucideIcons.users,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final item = filtered[i];
                  final isExpanded = _selectedFacultyId == item.faculty.id;
                  final deptName = deptMap[item.faculty.departmentId]?.name ?? 'Department';

                  return AcadexCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedFacultyId = isExpanded ? null : item.faculty.id;
                            });
                          },
                          borderRadius: BorderRadius.circular(AcadexRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AcadexColors.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    item.faculty.name.isNotEmpty ? item.faculty.name[0].toUpperCase() : 'F',
                                    style: const TextStyle(color: AcadexColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.faculty.name,
                                        style: AcadexTypography.title(color: theme.colorScheme.onSurface),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.faculty.employeeId} • $deptName • ${item.faculty.email}',
                                        style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _MetricPill(
                                      label: "Subjects",
                                      value: "${item.uniqueSubjectsCount}",
                                      color: AcadexColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    _MetricPill(
                                      label: "Sections",
                                      value: "${item.uniqueSectionsCount}",
                                      color: AcadexColors.accentOrange,
                                    ),
                                    const SizedBox(width: 8),
                                    _MetricPill(
                                      label: "Weekly Classes",
                                      value: "${item.totalWeeklyPeriods}",
                                      color: AcadexColors.success,
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                      size: 20,
                                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expanded Assignment Breakdown
                        if (isExpanded) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Allocated Classes (${item.assignments.length})',
                                style: AcadexTypography.title(color: theme.colorScheme.onSurface).copyWith(fontSize: 14),
                              ),
                              TextButton.icon(
                                icon: const Icon(LucideIcons.plus, size: 14),
                                label: const Text("Add Class"),
                                onPressed: () => FacultyAssignmentDialog.show(context, faculty: item.faculty),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (item.assignments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "No active teaching assignments. Click '+ Add Class' to assign subjects.",
                                style: AcadexTypography.body(color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: item.assignments.map((a) {
                                final sub = subMap[a.subjectId];
                                final crs = courseMap[a.courseId];
                                final sem = semMap[a.semesterId];
                                final sec = secMap[a.sectionId];

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.canvasSoft,
                                    borderRadius: BorderRadius.circular(AcadexRadius.md),
                                    border: Border.all(
                                      color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.bookOpen, color: AcadexColors.primary, size: 18),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sub?.name ?? a.subjectId,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${crs?.code ?? ''} • ${sem?.name ?? ''} • Section ${sec?.name ?? a.sectionId}',
                                            style: AcadexTypography.caption(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AcadexRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
