import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/attendance_providers.dart';
import '../widgets/assigned_class_card.dart';
import '../../domain/models/assigned_class.dart';
import '../../../academic_structure/presentation/providers/academic_providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class AssignedClassesScreen extends ConsumerWidget {
  const AssignedClassesScreen({super.key});

  Future<void> _showQuickTakeAttendanceDialog(BuildContext context, WidgetRef ref, DateTime date) async {
    final sections = ref.read(sectionsProvider).valueOrNull ?? [];
    final subjects = ref.read(subjectsProvider).valueOrNull ?? [];

    if (sections.isEmpty || subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please ensure sections and subjects are configured for your department.'),
          backgroundColor: AcadexColors.warning,
        ),
      );
      return;
    }

    String? selectedSectionId = sections.first.id;
    String? selectedSubjectId = subjects.first.id;
    String timeSlot = '09:00 - 10:00';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Take Attendance", style: AcadexTypography.heading3()),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select section and subject to open the live student roster.", style: AcadexTypography.caption()),
                    const SizedBox(height: 16),
                    Text("Section", style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedSectionId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusMd),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: sections.map((sec) => DropdownMenuItem(value: sec.id, child: Text(sec.name))).toList(),
                      onChanged: (val) => setDialogState(() => selectedSectionId = val),
                    ),
                    const SizedBox(height: 14),
                    Text("Subject", style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedSubjectId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusMd),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: subjects.map((sub) => DropdownMenuItem(value: sub.id, child: Text("${sub.name} (${sub.code})"))).toList(),
                      onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                    ),
                    const SizedBox(height: 14),
                    Text("Time Slot", style: AcadexTypography.caption().copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: timeSlot,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: AcadexRadius.borderRadiusMd),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: '08:00 - 09:00', child: Text('08:00 - 09:00')),
                        DropdownMenuItem(value: '09:00 - 10:00', child: Text('09:00 - 10:00')),
                        DropdownMenuItem(value: '10:00 - 11:00', child: Text('10:00 - 11:00')),
                        DropdownMenuItem(value: '11:15 - 12:15', child: Text('11:15 - 12:15')),
                        DropdownMenuItem(value: '12:15 - 01:15', child: Text('12:15 - 01:15')),
                        DropdownMenuItem(value: '02:00 - 03:00', child: Text('02:00 - 03:00')),
                        DropdownMenuItem(value: '03:00 - 04:00', child: Text('03:00 - 04:00')),
                      ],
                      onChanged: (val) => setDialogState(() => timeSlot = val ?? '09:00 - 10:00'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AcadexColors.primary),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Open Roster", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && selectedSectionId != null && selectedSubjectId != null) {
      final sec = sections.firstWhere((s) => s.id == selectedSectionId);
      final sub = subjects.firstWhere((s) => s.id == selectedSubjectId);
      ref.read(activeClassProvider.notifier).state = AssignedClass(
        id: 'adhoc_${sec.id}_${sub.id}_${date.millisecondsSinceEpoch}',
        subjectId: sub.id,
        subjectName: sub.name,
        sectionId: sec.id,
        sectionName: sec.name,
        semester: sec.semesterId.isNotEmpty ? sec.semesterId : 'Current Semester',
        timeSlot: timeSlot,
        date: date,
        isAttendanceMarked: false,
      );
      if (context.mounted) {
        context.push('/attendance/mark');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedClassesAsync = ref.watch(assignedClassesProvider);
    final date = ref.watch(selectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AcadexPageContainer(
        backgroundColor: Colors.white,
        maxWidth: AcadexLayout.contentMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header with History Action
            AcadexPageHeader(
              title: "Today's Classes",
              subtitle: "Manage assigned sections, timetable slots, and student attendance rosters.",
              actions: [
                AcadexButton(
                  label: "Take Attendance",
                  icon: LucideIcons.userCheck,
                  variant: AcadexButtonVariant.primary,
                  onPressed: () => _showQuickTakeAttendanceDialog(context, ref, date),
                ),
                const SizedBox(width: 8),
                AcadexButton(
                  label: "History",
                  icon: LucideIcons.history,
                  variant: AcadexButtonVariant.secondary,
                  onPressed: () => context.push('/attendance/faculty/history'),
                ),
              ],
            ),

            // Date Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusLg,
                border: Border.all(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  width: 1,
                ),
                boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
              ),
              child: Row(
                children: [
                  // Previous Day
                  IconButton(
                    icon: Icon(
                      LucideIcons.chevronLeft,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      size: 18,
                    ),
                    tooltip: "Previous Day",
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          date.subtract(const Duration(days: 1));
                    },
                  ),
                  
                  // Today Button
                  if (!isToday)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AcadexButton(
                        label: "Today",
                        variant: AcadexButtonVariant.secondary,
                        onPressed: () {
                          ref.read(selectedDateProvider.notifier).state = DateTime.now();
                        },
                      ),
                    ),

                  // Current Date Display
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          ref.read(selectedDateProvider.notifier).state = picked;
                        }
                      },
                      borderRadius: AcadexRadius.borderRadiusMd,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: AcadexColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: AcadexTypography.body(
                                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Next Day
                  IconButton(
                    icon: Icon(
                      LucideIcons.chevronRight,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      size: 18,
                    ),
                    tooltip: "Next Day",
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          date.add(const Duration(days: 1));
                    },
                  ),
                ],
              ),
            ),

            // Classes Content List / Grid
            assignedClassesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: AcadexLoadingState(message: "Loading scheduled classes..."),
                ),
              ),
              error: (err, stack) => Center(
                child: AcadexErrorState(
                  message: "Unable to load today's classes: $err",
                  onRetry: () => ref.refresh(assignedClassesProvider),
                ),
              ),
              data: (classes) {
                if (classes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AcadexEmptyState(
                          title: "No Scheduled Classes",
                          subtitle: "You don't have any teaching sessions scheduled for this date.",
                          icon: LucideIcons.calendarOff,
                        ),
                        const SizedBox(height: 16),
                        AcadexButton(
                          label: "Take Attendance Now",
                          icon: LucideIcons.userCheck,
                          variant: AcadexButtonVariant.primary,
                          onPressed: () => _showQuickTakeAttendanceDialog(context, ref, date),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 900 ? 2 : 1;

                    if (crossAxisCount == 1) {
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final c = classes[index];
                          return AssignedClassCard(
                            assignedClass: c,
                            onTap: () {
                              ref.read(activeClassProvider.notifier).state = c;
                              context.push('/attendance/mark');
                            },
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: classes.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.3,
                      ),
                      itemBuilder: (context, index) {
                        final c = classes[index];
                        return AssignedClassCard(
                          assignedClass: c,
                          onTap: () {
                            ref.read(activeClassProvider.notifier).state = c;
                            context.push('/attendance/mark');
                          },
                        );
                      },
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
}
