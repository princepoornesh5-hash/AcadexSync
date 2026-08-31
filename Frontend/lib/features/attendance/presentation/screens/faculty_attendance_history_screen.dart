import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../providers/faculty_history_providers.dart';
import '../widgets/faculty/attendance_record_card.dart';

class FacultyAttendanceHistoryScreen extends ConsumerStatefulWidget {
  const FacultyAttendanceHistoryScreen({super.key});

  @override
  ConsumerState<FacultyAttendanceHistoryScreen> createState() => _FacultyAttendanceHistoryScreenState();
}

class _FacultyAttendanceHistoryScreenState extends ConsumerState<FacultyAttendanceHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(filteredFacultyHistoryProvider);
    final statusFilter = ref.watch(historyStatusFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Colors.white,
          ),
          onPressed: () => context.safePop(fallbackRoute: '/attendance'),
        ),
        title: Text(
          "Attendance Sessions History",
          style: AcadexTypography.title(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AcadexSearchFilterBar(
                  searchHint: "Search by subject, section, or keyword...",
                  onSearchChanged: (val) {
                    ref.read(historySearchQueryProvider.notifier).state = val;
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AcadexChip(
                        label: "All Records",
                        isSelected: statusFilter == null,
                        onSelected: (_) {
                          ref.read(historyStatusFilterProvider.notifier).state = null;
                        },
                      ),
                      const SizedBox(width: 8),
                      AcadexChip(
                        label: "Open",
                        isSelected: statusFilter == 'open',
                        onSelected: (_) {
                          ref.read(historyStatusFilterProvider.notifier).state = 'open';
                        },
                      ),
                      const SizedBox(width: 8),
                      AcadexChip(
                        label: "Locked",
                        isSelected: statusFilter == 'locked',
                        onSelected: (_) {
                          ref.read(historyStatusFilterProvider.notifier).state = 'locked';
                        },
                      ),
                      const SizedBox(width: 8),
                      AcadexChip(
                        label: "Closed",
                        isSelected: statusFilter == 'closed',
                        onSelected: (_) {
                          ref.read(historyStatusFilterProvider.notifier).state = 'closed';
                        },
                      ),
                      const SizedBox(width: 8),
                      AcadexChip(
                        label: "Cancelled",
                        isSelected: statusFilter == 'cancelled',
                        onSelected: (_) {
                          ref.read(historyStatusFilterProvider.notifier).state = 'cancelled';
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(
                child: AcadexLoadingState(message: "Loading past attendance sessions..."),
              ),
              error: (err, stack) => Center(
                child: AcadexErrorState(
                  message: "Unable to load session history: $err",
                  onRetry: () => ref.refresh(facultyHistoryListProvider),
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(
                    child: AcadexEmptyState(
                      title: "No Attendance Sessions Found",
                      subtitle: "No historical sessions match your search query or filter selection.",
                      icon: LucideIcons.calendarOff,
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return AttendanceRecordCard(
                          session: session,
                          onTap: () {
                            ref.read(activeSessionIdProvider.notifier).state = session.id;
                            context.push('/attendance/faculty/detail');
                          },
                        );
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