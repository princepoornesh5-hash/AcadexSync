import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_back_button.dart';
import '../../../../core/presentation/widgets/acadex_badge.dart';
import '../../../../core/presentation/widgets/acadex_snackbar.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/internal_assessment_models.dart';
import '../providers/assessment_providers.dart';
import '../widgets/create_assessment_wizard_dialog.dart';

class ExamsAssessmentsScreen extends ConsumerStatefulWidget {
  const ExamsAssessmentsScreen({super.key});

  @override
  ConsumerState<ExamsAssessmentsScreen> createState() =>
      _ExamsAssessmentsScreenState();
}

class _ExamsAssessmentsScreenState extends ConsumerState<ExamsAssessmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedType = 'ALL';
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateWizard() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateAssessmentWizardDialog(
        onCreated: () {
          ref.invalidate(assessmentsListProvider);
          ref.invalidate(examTimetableProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    final isStudent =
        authState is AuthAuthenticated &&
        authState.user.role == AppRole.student;

    if (isStudent) {
      return _buildStudentView(isDark);
    }

    return _buildStaffAdminView(isDark);
  }

  // -------------------------------------------------------------
  // STAFF / HOD / ADMIN VIEW
  // -------------------------------------------------------------
  Widget _buildStaffAdminView(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header Bar
            _buildStaffHeader(isDark),
            const SizedBox(height: 20),

            // KPI Overview Banner
            _buildKpiOverview(isDark),
            const SizedBox(height: 20),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AcadexColors.darkSurfaceCard
                    : AcadexColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AcadexColors.darkHairline
                      : AcadexColors.hairline,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AcadexColors.primary,
                indicatorWeight: 3,
                labelColor: AcadexColors.primary,
                unselectedLabelColor: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(LucideIcons.calendarDays, size: 16),
                    text: 'Overview & Upcoming',
                  ),
                  Tab(
                    icon: Icon(LucideIcons.clock, size: 16),
                    text: 'Exam Schedule & Timetable',
                  ),
                  Tab(
                    icon: Icon(LucideIcons.fileText, size: 16),
                    text: 'Conduct Assessments / Marks Entry',
                  ),
                  Tab(
                    icon: Icon(LucideIcons.flaskConical, size: 16),
                    text: 'Lab & Practical Evaluations',
                  ),
                  Tab(
                    icon: Icon(LucideIcons.award, size: 16),
                    text: 'Results & Publication',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabOverview(isDark),
                  _buildTabTimetable(isDark),
                  _buildTabAssessmentsList(isDark),
                  _buildTabLabEvaluations(isDark),
                  _buildTabResultsPublication(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const AcadexBackButton(fallbackRoute: '/dashboard'),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exams & Assessments Hub',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scheduling, multi-department common exams, marks entry workflows & official results',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? AcadexColors.darkInkMuted
                            : AcadexColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _openCreateWizard,
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Create Assessment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AcadexColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiOverview(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Assessments',
            '14',
            LucideIcons.bookOpen,
            AcadexColors.primary,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Scheduled Exams',
            '6',
            LucideIcons.calendarCheck,
            AcadexColors.info,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'In Marks Entry',
            '4',
            LucideIcons.edit3,
            AcadexColors.warning,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Lab Evals Active',
            '3',
            LucideIcons.flaskConical,
            AcadexColors.secondary,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Published & Locked',
            '8',
            LucideIcons.lock,
            AcadexColors.success,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AcadexColors.darkInkMuted
                        : AcadexColors.inkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: OVERVIEW & UPCOMING
  Widget _buildTabOverview(bool isDark) {
    final listAsync = ref.watch(assessmentsListProvider(const {}));

    return listAsync.when(
      data: (assessments) {
        final upcoming = assessments
            .where(
              (a) =>
                  a.status == InternalAssessmentStatus.scheduled ||
                  a.status == InternalAssessmentStatus.open ||
                  a.status == InternalAssessmentStatus.draft,
            )
            .toList();

        return ListView(
          children: [
            Text(
              'Upcoming Scheduled Examinations & Tasks',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            if (upcoming.isEmpty)
              _buildEmptyPlaceholder(
                'No upcoming assessments scheduled yet.',
                'Tap "+ Create Assessment" above to schedule an examination or practical evaluation.',
                isDark,
              )
            else
              ...upcoming.map(
                (assessment) => _buildUpcomingExamCard(assessment, isDark),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildEmptyPlaceholder(
        'Offline / Ready to Create Assessments',
        'Use the "+ Create Assessment" wizard to schedule multi-department exams.',
        isDark,
      ),
    );
  }

  Widget _buildUpcomingExamCard(InternalAssessmentModel a, bool isDark) {
    final isCommon = a.isCommonExam || a.academicScopes.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date icon box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AcadexColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  a.assessmentDate != null ? '${a.assessmentDate!.day}' : '25',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AcadexColors.primary,
                  ),
                ),
                Text(
                  a.assessmentDate != null
                      ? _monthName(a.assessmentDate!.month)
                      : 'NOV',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AcadexColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Main details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isCommon) ...[
                      const AcadexBadge(
                        label: 'Common Exam',
                        variant: AcadexBadgeVariant.warning,
                      ),
                      const SizedBox(width: 8),
                    ],
                    AcadexBadge(
                      label: a.status.label,
                      variant: a.status == InternalAssessmentStatus.scheduled
                          ? AcadexBadgeVariant.info
                          : AcadexBadgeVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Assessment Type: ${a.assessmentType.replaceAll('_', ' ')} • Maximum Marks: ${a.maximumMarks.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AcadexColors.darkInkMuted
                        : AcadexColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 8),

                // Scopes / Sections
                if (a.academicScopes.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: a.academicScopes.map((scope) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AcadexColors.darkSurface
                              : AcadexColors.canvasSoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? AcadexColors.darkHairline
                                : AcadexColors.hairline,
                          ),
                        ),
                        child: Text(
                          '${scope.departmentName ?? 'Dept'} - ${scope.sectionName ?? 'Sec'}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/assessments/entry?assessmentId=${a.id ?? ''}');
                },
                icon: const Icon(LucideIcons.edit3, size: 14),
                label: const Text('Enter Marks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcadexColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (!a.isPublishedToStudents)
                OutlinedButton.icon(
                  onPressed: () async {
                    if (a.id != null) {
                      await ref
                          .read(assessmentRepositoryProvider)
                          .publishAssessmentExam(a.id!);
                      ref.invalidate(assessmentsListProvider);
                      AcadexSnackBar.showSuccess(
                        context,
                        'Exam published to students with notifications!',
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.send, size: 14),
                  label: const Text('Publish Exam'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AcadexColors.secondary,
                    side: const BorderSide(color: AcadexColors.secondary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: EXAM TIMETABLE
  Widget _buildTabTimetable(bool isDark) {
    final timetableAsync = ref.watch(examTimetableProvider(const {}));

    return timetableAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyPlaceholder(
            'No exams scheduled in timetable yet.',
            'Schedule assessments using the "+ Create Assessment" wizard to generate timetable schedules.',
            isDark,
          );
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AcadexColors.darkSurfaceCard
                    : AcadexColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AcadexColors.darkHairline
                      : AcadexColors.hairline,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 140,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AcadexColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.dateString.isNotEmpty
                              ? item.dateString
                              : '${item.date.day}/${item.date.month}/${item.date.year}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 12,
                              color: AcadexColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.startTime} - ${item.endTime}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AcadexColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.roomName ?? 'Venue: Main Auditorium',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invigilator: ${item.invigilatorName ?? 'Assigned Faculty'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AcadexColors.darkInkMuted
                                : AcadexColors.inkMuted,
                          ),
                        ),
                        if (item.instructions != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Instructions: ${item.instructions}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AcadexBadge(
                    label: item.status,
                    variant: AcadexBadgeVariant.success,
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyPlaceholder(
        'Exam Schedule & Timetable Ready',
        'Create assessments and schedule slots to populate the chronological exam calendar.',
        isDark,
      ),
    );
  }

  // TAB 3: CONDUCT ASSESSMENTS / MARKS ENTRY
  Widget _buildTabAssessmentsList(bool isDark) {
    final listAsync = ref.watch(
      assessmentsListProvider({
        if (_selectedType != 'ALL') 'assessmentType': _selectedType,
        if (_selectedStatus != 'ALL') 'status': _selectedStatus,
      }),
    );

    return Column(
      children: [
        // Filter row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText:
                      'Search assessments by title, subject, or department...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  filled: true,
                  fillColor: isDark
                      ? AcadexColors.darkSurfaceCard
                      : AcadexColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? AcadexColors.darkHairline
                          : AcadexColors.hairline,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _selectedType,
              dropdownColor: isDark
                  ? AcadexColors.darkSurfaceCard
                  : AcadexColors.surface,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Types')),
                DropdownMenuItem(
                  value: 'INTERNAL',
                  child: Text('Internal Exams'),
                ),
                DropdownMenuItem(value: 'SLIP_TEST', child: Text('Slip Tests')),
                DropdownMenuItem(
                  value: 'SEMESTER_EXAM',
                  child: Text('Semester End Exams'),
                ),
                DropdownMenuItem(
                  value: 'LAB_INTERNAL',
                  child: Text('Lab Internals'),
                ),
                DropdownMenuItem(value: 'VIVA_VOCE', child: Text('Viva Voce')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _selectedStatus,
              dropdownColor: isDark
                  ? AcadexColors.darkSurfaceCard
                  : AcadexColors.surface,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                DropdownMenuItem(value: 'SCHEDULED', child: Text('Scheduled')),
                DropdownMenuItem(value: 'OPEN', child: Text('Open for Entry')),
                DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted')),
                DropdownMenuItem(
                  value: 'PUBLISHED',
                  child: Text('Published & Locked'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        Expanded(
          child: listAsync.when(
            data: (assessments) {
              final filtered = assessments.where((a) {
                if (_searchQuery.isEmpty) return true;
                return a.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
              }).toList();

              if (filtered.isEmpty) {
                return _buildEmptyPlaceholder(
                  'No assessments match your current filters.',
                  'Clear filters or tap "+ Create Assessment" to get started.',
                  isDark,
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final a = filtered[index];
                  return _buildAssessmentEntryCard(a, isDark);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildEmptyPlaceholder(
              'No Assessments Registered',
              'Use the "+ Create Assessment" button above to create one.',
              isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentEntryCard(InternalAssessmentModel a, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      a.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (a.isCommonExam)
                      const AcadexBadge(
                        label: 'Common Exam',
                        variant: AcadexBadgeVariant.warning,
                      ),
                    const SizedBox(width: 6),
                    AcadexBadge(
                      label: a.status.label,
                      variant: AcadexBadgeVariant.info,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Max Marks: ${a.maximumMarks.toStringAsFixed(0)} • Type: ${a.assessmentType.replaceAll('_', ' ')} • Scopes: ${a.academicScopes.length} targets',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AcadexColors.darkInkMuted
                        : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/assessments/entry?assessmentId=${a.id ?? ''}');
            },
            icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
            label: const Text('Open Marks Entry Sheet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcadexColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 4: LAB EVALUATIONS
  Widget _buildTabLabEvaluations(bool isDark) {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practical & Laboratory Continuous Evaluations',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Per-experiment observation scores, record notebooks, viva voce, and internal practicals',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AcadexColors.darkInkMuted
                        : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                AcadexSnackBar.showSuccess(
                  context,
                  'Lab experiment sync initiated.',
                );
              },
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Sync Lab Marks to IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AcadexColors.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildLabExperimentCard(
          'Experiment 1: Matrix Inversion & Gaussian Elimination',
          'Max: 20',
          '60 Submissions',
          isDark,
        ),
        _buildLabExperimentCard(
          'Experiment 2: Differential Equations Simulation in MATLAB',
          'Max: 20',
          '58 Submissions',
          isDark,
        ),
        _buildLabExperimentCard(
          'Experiment 3: Numerical Integration & Simpson Rule',
          'Max: 20',
          '60 Submissions',
          isDark,
        ),
      ],
    );
  }

  Widget _buildLabExperimentCard(
    String title,
    String marks,
    String submissions,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AcadexColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.flaskConical,
                  color: AcadexColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$marks • $submissions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton(
            onPressed: () {
              AcadexSnackBar.showInfo(
                context,
                'Opening lab grading rubric matrix.',
              );
            },
            child: const Text('Evaluate Rubric'),
          ),
        ],
      ),
    );
  }

  // TAB 5: RESULTS & PUBLICATION
  Widget _buildTabResultsPublication(bool isDark) {
    return ListView(
      children: [
        Text(
          'Official Results Publication & Lock Status',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Published assessments are cryptographically locked. Unlocking requires HOD or Admin audit reason.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
        ),
        const SizedBox(height: 16),

        _buildResultPublicationItem(
          'Continuous Internal Assessment I (Engineering Math III)',
          'Published on 15 Oct 2026',
          true,
          isDark,
        ),
        _buildResultPublicationItem(
          'Slip Test 1 (Data Structures)',
          'Published on 20 Oct 2026',
          true,
          isDark,
        ),
        _buildResultPublicationItem(
          'Lab Practical Mid-Term',
          'Marks Entry Complete • Pending HOD Review',
          false,
          isDark,
        ),
      ],
    );
  }

  Widget _buildResultPublicationItem(
    String title,
    String subtitle,
    bool isPublished,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isPublished ? LucideIcons.lock : LucideIcons.unlock,
                color: isPublished
                    ? AcadexColors.success
                    : AcadexColors.warning,
                size: 20,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AcadexBadge(
            label: isPublished ? 'Published & Locked' : 'Pending Publication',
            variant: isPublished
                ? AcadexBadgeVariant.success
                : AcadexBadgeVariant.warning,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STUDENT EXPERIENCE VIEW
  // -------------------------------------------------------------
  Widget _buildStudentView(bool isDark) {
    final marksAsync = ref.watch(studentMarksProvider(null));

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: AcadexPageContainer(
        child: ListView(
          children: [
            const SizedBox(height: 16),
            Text(
              'My Examinations & Assessments',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'View upcoming exam schedules, hall venues, and published academic marks',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AcadexColors.darkInkMuted
                    : AcadexColors.inkMuted,
              ),
            ),
            const SizedBox(height: 20),

            // Student upcoming exam card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AcadexColors.primary.withOpacity(0.12),
                    AcadexColors.secondary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AcadexColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.calendarCheck2,
                    size: 28,
                    color: AcadexColors.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Scheduled Exam: Engineering Mathematics III',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Date: 25 Nov 2026 • 10:00 AM - 12:00 PM • Venue: Auditorium Hall 101',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Instructions: Scientific calculators permitted. Bring valid ID card.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? AcadexColors.darkInkMuted
                                : AcadexColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Official Published Assessment Marks',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            marksAsync.when(
              data: (marks) {
                if (marks.isEmpty) {
                  return _buildEmptyPlaceholder(
                    'No published marks available yet.',
                    'Marks are held securely and will appear here as soon as they are officially published by your department.',
                    isDark,
                  );
                }

                return Column(
                  children: marks.map((m) {
                    final subjectName =
                        m.subject['name']?.toString() ?? 'Subject';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AcadexColors.darkSurfaceCard
                            : AcadexColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AcadexColors.darkHairline
                              : AcadexColors.hairline,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subjectName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${m.status.label}',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            '${m.totalMarks.toStringAsFixed(1)} Marks',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AcadexColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildEmptyPlaceholder(
                'Marks Portal Active',
                'Internal assessment marks will appear here once officially published.',
                isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String title, String subtitle, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.fileQuestion,
            size: 40,
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return 'NOV';
  }
}
