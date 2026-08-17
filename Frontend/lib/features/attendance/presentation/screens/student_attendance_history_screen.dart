import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';
import '../providers/student_attendance_providers.dart';
import '../widgets/student/attendance_history_tile.dart';
import '../widgets/student/attendance_filter_bar.dart';

class StudentAttendanceHistoryScreen extends ConsumerStatefulWidget {
  const StudentAttendanceHistoryScreen({super.key});

  @override
  ConsumerState<StudentAttendanceHistoryScreen> createState() => _StudentAttendanceHistoryScreenState();
}

class _StudentAttendanceHistoryScreenState extends ConsumerState<StudentAttendanceHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(filteredStudentHistoryProvider);
    final subjectsAsync = ref.watch(studentSubjectAttendanceProvider);

    final selectedSub = ref.watch(selectedHistorySubjectProvider);
    final selectedMonth = ref.watch(selectedHistoryMonthProvider);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      appBar: AppBar(
        backgroundColor: DashboardColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: DashboardColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text("Attendance History", style: TextStyle(color: DashboardColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Container(
            color: DashboardColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: subjectsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (subs) {
                return AttendanceFilterBar(
                  subjects: subs.map((e) => e.subjectId).toList(), // Using ID for logic, we could map to names
                  selectedSubject: selectedSub,
                  onSubjectSelected: (val) {
                    ref.read(selectedHistorySubjectProvider.notifier).state = val;
                  },
                  selectedMonth: selectedMonth,
                  onMonthSelected: (val) {
                    ref.read(selectedHistoryMonthProvider.notifier).state = val;
                  },
                );
              },
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
              data: (records) {
                if (records.isEmpty) {
                  return const AcadexEmptyState(
                    title: "No Records Found",
                    subtitle: "No attendance records match your filters.",
                    icon: LucideIcons.calendarOff,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    return AttendanceHistoryTile(record: records[index]);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
