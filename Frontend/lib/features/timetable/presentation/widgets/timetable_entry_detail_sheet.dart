import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/acadex_entity_formatters.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../attendance/domain/models/assigned_class.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../domain/models/timetable_models.dart';
import '../providers/timetable_lookup_providers.dart';
import 'timetable_widgets.dart';

class TimetableEntryDetailSheet extends ConsumerWidget {
  final TimetableModel entry;
  final DateTime? selectedDate;

  const TimetableEntryDetailSheet({
    super.key,
    required this.entry,
    this.selectedDate,
  });

  static Future<void> show(
    BuildContext context,
    TimetableModel entry, {
    DateTime? selectedDate,
  }) async {
    final isMobile = AcadexBreakpoints.isMobile(context);

    if (isMobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => TimetableEntryDetailSheet(
          entry: entry,
          selectedDate: selectedDate,
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusXl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TimetableEntryDetailSheet(
              entry: entry,
              selectedDate: selectedDate,
            ),
          ),
        ),
      );
    }
  }

  void _onMarkAttendance(
    BuildContext context,
    WidgetRef ref,
    String subjectName,
    String sectionName,
  ) {
    Navigator.of(context).pop();

    final dateToUse = selectedDate ?? DateTime.now();
    final assignedClass = AssignedClass(
      id: entry.id,
      timetableId: entry.timetableId,
      timetableEntryId: entry.id,
      facultyId: entry.facultyId,
      facultyAssignmentId: entry.facultyAssignmentId,
      subjectId: entry.subjectId,
      subjectName: subjectName,
      sectionId: entry.sectionId,
      sectionName: sectionName,
      semester: entry.semesterId,
      timeSlot: '${entry.startTime} – ${entry.endTime}',
      startTime: entry.startTime,
      endTime: entry.endTime,
      roomNumber: entry.roomNumber,
      building: entry.building,
      date: dateToUse,
    );

    ref.read(activeClassProvider.notifier).state = assignedClass;
    context.push('/attendance/mark');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final role = user?.role ?? AppRole.student;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjectMap = ref.watch(timetableSubjectMapProvider);
    final facultyMap = ref.watch(timetableFacultyMapProvider);
    final sectionMap = ref.watch(timetableSectionMapProvider);

    final subject = subjectMap[entry.subjectId];
    final faculty = facultyMap[entry.facultyId];
    final section = sectionMap[entry.sectionId];

    final subjectName = AcadexEntityFormatters.formatSubjectLabel(
      entry.subjectName ?? subject?.name,
      code: entry.subjectCode ?? subject?.code,
      rawId: entry.subjectId,
    );
    final subjectCode = entry.subjectCode ?? subject?.code ?? '';
    final facultyName = AcadexEntityFormatters.formatFacultyLabel(
      entry.facultyName ?? faculty?.name,
      rawId: entry.facultyId,
    );
    final sectionName = AcadexEntityFormatters.formatSectionLabel(
      entry.sectionName ?? section?.name,
      rawId: entry.sectionId,
      prefix: false,
    );

    final sessionColor = getSessionTypeColor(entry.sessionType);
    final status = getEntryStatus(entry);

    String? academicContext = entry.contextualDescription;
    if (academicContext == null || academicContext.isEmpty) {
      final parts = <String>[];
      if (entry.cohort != null && entry.cohort!.isNotEmpty) parts.add(entry.cohort!);
      if (entry.academicStage != null && entry.academicStage!.isNotEmpty) parts.add(entry.academicStage!);
      if (entry.semesterName != null && entry.semesterName!.isNotEmpty) parts.add(entry.semesterName!);
      if (parts.isNotEmpty) {
        academicContext = parts.join(' · ');
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: AcadexRadius.borderRadiusXl,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle for bottom sheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row: Session Type Icon + Subject Title + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sessionColor.withValues(alpha: 0.12),
                  borderRadius: AcadexRadius.borderRadiusMd,
                ),
                child: Icon(
                  getSessionTypeIcon(entry.sessionType),
                  size: 22,
                  color: sessionColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      style: AcadexTypography.heading3(
                        color: Theme.of(context).colorScheme.onSurface,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subjectCode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subjectCode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sessionColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status == TimetableEntryStatus.now) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AcadexColors.error.withValues(alpha: 0.12),
                    borderRadius: AcadexRadius.borderRadiusSm,
                    border: Border.all(color: AcadexColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'LIVE NOW',
                    style: TextStyle(
                      color: AcadexColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ] else if (status == TimetableEntryStatus.upNext) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AcadexColors.primary.withValues(alpha: 0.12),
                    borderRadius: AcadexRadius.borderRadiusSm,
                    border: Border.all(color: AcadexColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'UP NEXT',
                    style: TextStyle(
                      color: AcadexColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),

          // Substitution notice if applicable
          if (entry.isSubstituted) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AcadexColors.warning.withValues(alpha: 0.12),
                borderRadius: AcadexRadius.borderRadiusMd,
                border: Border.all(color: AcadexColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 18, color: AcadexColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Teacher Substitution Active for this session.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AcadexColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Details grid
          _buildDetailItem(
            context,
            icon: LucideIcons.tag,
            label: 'Session Type',
            value: entry.sessionType.displayName,
          ),
          const SizedBox(height: 10),
          _buildDetailItem(
            context,
            icon: LucideIcons.calendar,
            label: 'Day & Time',
            value: '${entry.dayOfWeek.displayName} · ${entry.startTime} – ${entry.endTime}',
          ),
          const SizedBox(height: 10),
          _buildDetailItem(
            context,
            icon: LucideIcons.layoutGrid,
            label: 'Section',
            value: 'Section $sectionName',
          ),
          const SizedBox(height: 10),
          _buildDetailItem(
            context,
            icon: LucideIcons.user,
            label: 'Faculty',
            value: facultyName,
          ),
          if (entry.roomNumber.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildDetailItem(
              context,
              icon: LucideIcons.mapPin,
              label: 'Venue',
              value: entry.building != null && entry.building!.isNotEmpty
                  ? '${entry.building} · Room ${entry.roomNumber}'
                  : 'Room ${entry.roomNumber}',
            ),
          ],
          if (academicContext != null && academicContext.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildDetailItem(
              context,
              icon: LucideIcons.graduationCap,
              label: 'Academic Context',
              value: academicContext,
            ),
          ],

          const SizedBox(height: 20),

          // Contextual Role-Based Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Faculty: Mark Attendance
              if (role == AppRole.faculty) ...[
                ElevatedButton.icon(
                  onPressed: () => _onMarkAttendance(context, ref, subjectName, sectionName),
                  icon: const Icon(LucideIcons.clipboardCheck, size: 16),
                  label: const Text('Mark Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcadexColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/notes');
                  },
                  icon: const Icon(LucideIcons.fileText, size: 16),
                  label: const Text('Notes'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/assignments');
                  },
                  icon: const Icon(LucideIcons.bookOpen, size: 16),
                  label: const Text('Assignments'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                  ),
                ),
              ],

              // Student: View Attendance & Notes
              if (role == AppRole.student) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/attendance');
                  },
                  icon: const Icon(LucideIcons.pieChart, size: 16),
                  label: const Text('My Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcadexColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/notes');
                  },
                  icon: const Icon(LucideIcons.fileText, size: 16),
                  label: const Text('Subject Notes'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                  ),
                ),
              ],

              // HOD / Admin: Manage & View
              if (role == AppRole.hod || role == AppRole.collegeAdmin || role == AppRole.superAdmin) ...[
                if (entry.facultyAssignmentId != null && entry.facultyAssignmentId!.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/faculty-assignments');
                    },
                    icon: const Icon(LucideIcons.userCheck, size: 16),
                    label: const Text('Faculty Assignment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcadexColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                    ),
                  ),
                ],
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/academics/sections');
                  },
                  icon: const Icon(LucideIcons.layoutGrid, size: 16),
                  label: const Text('Section Overview'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: AcadexRadius.borderRadiusMd),
                  ),
                ),
              ],

              // Close button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: Theme.of(context).textTheme.bodySmall?.color ?? AcadexColors.inkMuted,
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
