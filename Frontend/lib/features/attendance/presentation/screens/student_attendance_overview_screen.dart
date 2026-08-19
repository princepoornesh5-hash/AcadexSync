import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../providers/student_attendance_providers.dart';
import '../widgets/student/overall_attendance_card.dart';
import '../widgets/student/subject_attendance_card.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class StudentAttendanceOverviewScreen extends ConsumerWidget {
  const StudentAttendanceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallPercAsync = ref.watch(overallAttendancePercentageProvider);
    final subjectsAsync = ref.watch(studentSubjectAttendanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        maxWidth: AcadexLayout.contentMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AcadexPageHeader(
                  title: "My Attendance",
                  subtitle: "Track your semester standing, subject metrics, and absence records.",
                  actions: [
                    AcadexButton(
                      label: "Attendance History",
                      icon: LucideIcons.history,
                      variant: AcadexButtonVariant.secondary,
                      onPressed: () {
                        ref.read(selectedHistorySubjectProvider.notifier).state = null;
                        ref.read(selectedHistoryMonthProvider.notifier).state = null;
                        context.push('/attendance/student/history');
                      },
                    ),
                  ],
                ),

                // Overall Gauge Card
                overallPercAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: AcadexLoadingState(message: "Calculating overall attendance standing..."),
                    ),
                  ),
                  error: (err, stack) => AcadexErrorState(
                    message: "Unable to load attendance summary: $err",
                    onRetry: () => ref.refresh(studentSubjectAttendanceProvider),
                  ),
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

                const AcadexSectionHeader(title: "Course Subjects"),
                const SizedBox(height: 12),

                // Subject List / Grid
                subjectsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text("Error: $err", style: TextStyle(color: AcadexColors.error)),
                  ),
                  data: (subjects) {
                    if (subjects.isEmpty) {
                      return const Center(
                        child: AcadexEmptyState(
                          title: "No Course Subjects Found",
                          subtitle: "You are not currently enrolled in any active course subjects.",
                          icon: LucideIcons.bookX,
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
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              final subject = subjects[index];
                              return SubjectAttendanceCard(
                                subject: subject,
                                onTap: () {
                                  ref.read(selectedHistorySubjectProvider.notifier).state = subject.subjectId;
                                  ref.read(selectedHistoryMonthProvider.notifier).state = null;
                                  context.push('/attendance/student/history');
                                },
                              );
                            },
                          );
                        }

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: subjects.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 2.1,
                          ),
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            return SubjectAttendanceCard(
                              subject: subject,
                              onTap: () {
                                ref.read(selectedHistorySubjectProvider.notifier).state = subject.subjectId;
                                ref.read(selectedHistoryMonthProvider.notifier).state = null;
                                context.push('/attendance/student/history');
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
