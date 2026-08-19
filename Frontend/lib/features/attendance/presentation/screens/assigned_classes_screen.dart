import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/attendance_providers.dart';
import '../widgets/assigned_class_card.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';

class AssignedClassesScreen extends ConsumerWidget {
  const AssignedClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedClassesAsync = ref.watch(assignedClassesProvider);
    final date = ref.watch(selectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(date);

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
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
                      label: "Attendance History",
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
                      return const Center(
                        child: AcadexEmptyState(
                          title: "No Scheduled Classes",
                          subtitle: "You don't have any teaching sessions scheduled for this date.",
                          icon: LucideIcons.calendarOff,
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
