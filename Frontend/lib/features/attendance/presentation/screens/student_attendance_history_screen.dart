import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Colors.white,
          ),
          onPressed: () => context.safePop(fallbackRoute: '/attendance'),
        ),
        title: Text(
          "Attendance History",
          style: AcadexTypography.title(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar Container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
              borderRadius: AcadexRadius.borderRadiusLg,
              border: Border.all(
                color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
              ),
              boxShadow: isDark ? AcadexShadows.darkSm : AcadexShadows.lightSm,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: subjectsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (subs) {
                return AttendanceFilterBar(
                  subjects: subs.map((e) => e.subjectName).toList(),
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
          Divider(
            height: 1,
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          ),
          
          // History Log List
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(
                child: AcadexLoadingState(message: "Loading attendance records..."),
              ),
              error: (err, stack) => Center(
                child: AcadexErrorState(
                  message: "Unable to load attendance log: $err",
                  onRetry: () => ref.refresh(studentHistoryProvider),
                ),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return const Center(
                    child: AcadexEmptyState(
                      title: "No Attendance Records",
                      subtitle: "No attendance entries match your selected subject or month filters.",
                      icon: LucideIcons.calendarOff,
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        return AttendanceHistoryTile(record: records[index]);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
