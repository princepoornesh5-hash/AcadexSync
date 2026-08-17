import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/student_attendance_providers.dart';
import '../widgets/student/overall_attendance_card.dart';
import '../widgets/student/subject_attendance_card.dart';

class StudentAttendanceOverviewScreen extends ConsumerWidget {
  const StudentAttendanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallPercAsync = ref.watch(overallAttendancePercentageProvider);
    final subjectsAsync = ref.watch(studentSubjectAttendanceProvider);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Attendance",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.history, color: DashboardColors.primary),
                        tooltip: "View History",
                        onPressed: () {
                          // Clear filters before navigating to global history
                          ref.read(selectedHistorySubjectProvider.notifier).state = null;
                          ref.read(selectedHistoryMonthProvider.notifier).state = null;
                          context.push('/attendance/student/history');
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("Monitor your overall and subject-wise attendance.", style: TextStyle(color: DashboardColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 24),
                  
                  // Overall Card
                  overallPercAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text("Error: $err"),
                    data: (perc) {
                      return subjectsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (subs) {
                          int totalAttended = 0;
                          int totalMissed = 0;
                          for (final s in subs) {
                            totalAttended += s.attendedClasses;
                            totalMissed += s.missedClasses;
                          }
                          return OverallAttendanceCard(
                            percentage: perc,
                            classesAttended: totalAttended,
                            classesMissed: totalMissed,
                            subjectsCount: subs.length,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text("Subjects", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DashboardColors.textPrimary)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Subject List
          subjectsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text("Error: $err"))),
            data: (subjects) {
              if (subjects.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No subjects found.", style: TextStyle(color: DashboardColors.textSecondary))),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subject = subjects[index];
                      return SubjectAttendanceCard(
                        subject: subject,
                        onTap: () {
                          // Filter history to this subject
                          ref.read(selectedHistorySubjectProvider.notifier).state = subject.subjectId;
                          ref.read(selectedHistoryMonthProvider.notifier).state = null;
                          context.push('/attendance/student/history');
                        },
                      );
                    },
                    childCount: subjects.length,
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
