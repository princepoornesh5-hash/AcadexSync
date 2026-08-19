import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
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
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Attendance Sessions History",
          style: AcadexTypography.title(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
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
                Row(
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
                      label: "Locked",
                      isSelected: statusFilter == 'Locked',
                      onSelected: (_) {
                        ref.read(historyStatusFilterProvider.notifier).state = 'Locked';
                      },
                    ),
                    const SizedBox(width: 8),
                    AcadexChip(
                      label: "Drafts",
                      isSelected: statusFilter == 'Draft',
                      onSelected: (_) {
                        ref.read(historyStatusFilterProvider.notifier).state = 'Draft';
                      },
                    ),
                  ],
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