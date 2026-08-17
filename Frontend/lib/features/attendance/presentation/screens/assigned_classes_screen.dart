import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/attendance_providers.dart';
import '../widgets/assigned_class_card.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_empty_state.dart';

class AssignedClassesScreen extends ConsumerWidget {
  const AssignedClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedClassesAsync = ref.watch(assignedClassesProvider);
    final date = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: DashboardColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Classes",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: DashboardColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.history, color: DashboardColors.primary),
                            tooltip: "View History",
                            onPressed: () => context.push('/attendance/faculty/history'),
                          ),
                          // Mock Date Picker Button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: DashboardColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: DashboardColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, size: 16, color: DashboardColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  "${date.day}/${date.month}",
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: DashboardColors.textPrimary, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select a class to mark attendance.",
                    style: TextStyle(color: DashboardColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          assignedClassesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: DashboardColors.primary)),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text("Error: $err", style: const TextStyle(color: DashboardColors.error))),
            ),
            data: (classes) {
              if (classes.isEmpty) {
                return const SliverFillRemaining(
                  child: AcadexEmptyState(
                    title: "No Classes Today",
                    subtitle: "You don't have any classes scheduled for this date.",
                    icon: LucideIcons.calendarOff,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = classes[index];
                      return AssignedClassCard(
                        assignedClass: c,
                        onTap: () {
                          // Set active class and navigate to mark screen
                          ref.read(activeClassProvider.notifier).state = c;
                          context.push('/attendance/mark');
                        },
                      );
                    },
                    childCount: classes.length,
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
