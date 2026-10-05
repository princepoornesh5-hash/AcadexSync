import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/acadex_avatar.dart';
import '../../../../core/presentation/widgets/acadex_button.dart';
import '../../../../core/presentation/widgets/acadex_card.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_page_container.dart';
import '../../../../core/presentation/widgets/acadex_page_header.dart';
import '../../../../core/presentation/widgets/acadex_search_bar.dart';

import '../../../auth/domain/models/role_enum.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/academic_models.dart';
import '../providers/academic_providers.dart';
import '../providers/department_setup_provider.dart';
import '../../../institution_config/domain/models/institution_config_models.dart';
import '../../../institution_config/presentation/providers/institution_config_providers.dart';

enum AcademicWorkspaceModule {
  departments,
  programs,
  semesters,
  sections,
  subjects,
  faculty,
  rooms,
}

class AcademicStructureHomeScreen extends ConsumerStatefulWidget {
  const AcademicStructureHomeScreen({super.key});

  @override
  ConsumerState<AcademicStructureHomeScreen> createState() =>
      _AcademicStructureHomeScreenState();
}

class _AcademicStructureHomeScreenState
    extends ConsumerState<AcademicStructureHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _lastTabLength = 5;
  int _currentTabIndex = 0;
  String _searchQuery = '';
  String _selectedDepartmentFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!mounted) return;
    if (_currentTabIndex != _tabController.index) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  void _updateTabController(int newLength) {
    if (_lastTabLength != newLength) {
      final oldIndex = _currentTabIndex;
      _tabController.removeListener(_handleTabChange);
      _tabController.dispose();
      final newIndex = oldIndex.clamp(0, newLength - 1);
      _currentTabIndex = newIndex;
      _tabController = TabController(
        length: newLength,
        initialIndex: newIndex,
        vsync: this,
      );
      _tabController.addListener(_handleTabChange);
      _lastTabLength = newLength;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final userRole = currentUser?.role ?? AppRole.student;

    final terminology = ref.watch(terminologyProvider);
    final isSectionEnabled = terminology.isSectionEnabled;
    final isHodOrBelow = userRole == AppRole.hod || userRole == AppRole.faculty || userRole == AppRole.student;
    final tabLength = isHodOrBelow ? (isSectionEnabled ? 6 : 5) : (isSectionEnabled ? 7 : 6);
    _updateTabController(tabLength);

    if (userRole == AppRole.hod && currentUser?.departmentId != null && currentUser!.departmentId!.isNotEmpty) {
      _selectedDepartmentFilter = currentUser.departmentId!;
    }

    final deptsAsync = ref.watch(departmentsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final sectionsAsync = ref.watch(sectionsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final roomsAsync = ref.watch(roomsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AcadexBreakpoints.isMobile(context);

    return AcadexPageContainer(
      onRefresh: () async {
        ref.invalidate(departmentsProvider);
        ref.invalidate(coursesProvider);
        ref.invalidate(semestersProvider);
        ref.invalidate(sectionsProvider);
        ref.invalidate(subjectsProvider);
        ref.invalidate(roomsProvider);
        ref.invalidate(facultyProvider(null));
        if (currentUser?.departmentId != null) {
          ref.invalidate(facultyProvider(currentUser!.departmentId));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcadexPageHeader(
            title: 'Academic Structure',
            subtitle: _getSubtitleForRole(userRole),
            actions: _buildHeaderActions(context, userRole, terminology, isSectionEnabled, isMobile),
          ),

          // 0. Setup Guided Banner (For HOD & College Admin)
          _buildSetupGuidedBanner(context, userRole, currentUser?.departmentId, isDark),

          // 1. Personalized Role-Aware Card (For Faculty / Students)
          if (userRole == AppRole.faculty || userRole == AppRole.student)
            _buildPersonalizedRoleCard(context, currentUser, isDark),

          // 2. Summary KPI Metric Cards Deck
          _buildStatsDeck(
            deptsAsync: deptsAsync,
            coursesAsync: coursesAsync,
            semestersAsync: semestersAsync,
            sectionsAsync: sectionsAsync,
            subjectsAsync: subjectsAsync,
            facultyCount: currentUser?.departmentId != null
                ? ref.watch(facultyProvider(currentUser!.departmentId)).items.length
                : ref.watch(facultyProvider(null)).items.length,
            role: userRole,
            isMobile: isMobile,
            terminology: terminology,
            isSectionEnabled: isSectionEnabled,
          ),
          const SizedBox(height: 14),

          // 3. Search and Department Filter Toolbar
          Row(
            children: [
              Expanded(
                child: AcadexSearchBar(
                  hintText: 'Search academic entities (name, code)...',
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
              ),
              if (!isMobile && !isHodOrBelow) ...[
                const SizedBox(width: 12),
                deptsAsync.maybeWhen(
                  data: (depts) => _buildDepartmentFilterDropdown(depts, isDark, userRole, currentUser),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          if (isMobile) ...[
            // 4. Mobile Category Selector
            _buildMobileCategorySelector(
              context: context,
              terminology: terminology,
              isHodOrBelow: isHodOrBelow,
              isSectionEnabled: isSectionEnabled,
              isDark: isDark,
              currentIndex: _currentTabIndex,
              onSelect: (index) {
                setState(() {
                  _currentTabIndex = index;
                  _tabController.animateTo(index);
                });
              },
            ),
            const SizedBox(height: 16),

            // 5. Mobile Active Tab Content
            _buildActiveTabContent(
              index: _currentTabIndex,
              isHodOrBelow: isHodOrBelow,
              isSectionEnabled: isSectionEnabled,
              coursesAsync: coursesAsync,
              deptsAsync: deptsAsync,
              semestersAsync: semestersAsync,
              sectionsAsync: sectionsAsync,
              subjectsAsync: subjectsAsync,
              roomsAsync: roomsAsync,
              userRole: userRole,
              currentUser: currentUser,
              isDark: isDark,
            ),
          ] else ...[
            // 4. Hierarchical Navigation Tabs (Desktop & Tablet)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
                borderRadius: AcadexRadius.borderRadiusLg,
                border: Border.all(
                  color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AcadexColors.primary,
                unselectedLabelColor: AcadexColors.inkMuted,
                indicatorColor: AcadexColors.primary,
                indicatorWeight: 3,
                onTap: (index) {
                  if (_currentTabIndex != index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  }
                },
                tabs: isHodOrBelow
                    ? [
                        Tab(icon: const Icon(LucideIcons.graduationCap, size: 16), text: terminology.label(AcademicConcept.program, plural: true)),
                        Tab(icon: const Icon(LucideIcons.calendarDays, size: 16), text: terminology.label(AcademicConcept.semester, plural: true)),
                        if (isSectionEnabled)
                          Tab(icon: const Icon(LucideIcons.layoutGrid, size: 16), text: terminology.label(AcademicConcept.section, plural: true)),
                        Tab(icon: const Icon(LucideIcons.bookOpen, size: 16), text: terminology.label(AcademicConcept.subject, plural: true)),
                        const Tab(icon: Icon(LucideIcons.users, size: 16), text: 'Faculty'),
                        Tab(icon: const Icon(LucideIcons.doorClosed, size: 16), text: terminology.label(AcademicConcept.room, plural: true)),
                      ]
                    : [
                        Tab(icon: const Icon(LucideIcons.building2, size: 16), text: terminology.label(AcademicConcept.department, plural: true)),
                        Tab(icon: const Icon(LucideIcons.graduationCap, size: 16), text: terminology.label(AcademicConcept.program, plural: true)),
                        Tab(icon: const Icon(LucideIcons.calendarDays, size: 16), text: terminology.label(AcademicConcept.semester, plural: true)),
                        if (isSectionEnabled)
                          Tab(icon: const Icon(LucideIcons.layoutGrid, size: 16), text: terminology.label(AcademicConcept.section, plural: true)),
                        Tab(icon: const Icon(LucideIcons.bookOpen, size: 16), text: terminology.label(AcademicConcept.subject, plural: true)),
                        const Tab(icon: Icon(LucideIcons.users, size: 16), text: 'Faculty'),
                        Tab(icon: const Icon(LucideIcons.doorClosed, size: 16), text: terminology.label(AcademicConcept.room, plural: true)),
                      ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Tab Content Area (Desktop & Tablet)
            SizedBox(
              height: 600,
              child: TabBarView(
                controller: _tabController,
                children: isHodOrBelow
                    ? [
                        _buildCoursesTab(coursesAsync, deptsAsync, userRole, isDark),
                        _buildSemestersTab(semestersAsync, coursesAsync, userRole, isDark),
                        if (isSectionEnabled)
                          _buildSectionsTab(sectionsAsync, semestersAsync, userRole, isDark),
                        _buildSubjectsTab(subjectsAsync, deptsAsync, userRole, isDark),
                        _buildFacultyTab(currentUser?.departmentId, userRole, isDark),
                        _buildRoomsTab(roomsAsync, userRole, isDark),
                      ]
                    : [
                        _buildDepartmentsTab(deptsAsync, userRole, isDark),
                        _buildCoursesTab(coursesAsync, deptsAsync, userRole, isDark),
                        _buildSemestersTab(semestersAsync, coursesAsync, userRole, isDark),
                        if (isSectionEnabled)
                          _buildSectionsTab(sectionsAsync, semestersAsync, userRole, isDark),
                        _buildSubjectsTab(subjectsAsync, deptsAsync, userRole, isDark),
                        _buildFacultyTab(_selectedDepartmentFilter == 'ALL' ? null : _selectedDepartmentFilter, userRole, isDark),
                        _buildRoomsTab(roomsAsync, userRole, isDark),
                      ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileCategorySelector({
    required BuildContext context,
    required TerminologyHelper terminology,
    required bool isHodOrBelow,
    required bool isSectionEnabled,
    required bool isDark,
    required int currentIndex,
    required ValueChanged<int> onSelect,
  }) {
    final categories = isHodOrBelow
        ? [
            (icon: LucideIcons.graduationCap, label: terminology.label(AcademicConcept.program, plural: true)),
            (icon: LucideIcons.calendarDays, label: terminology.label(AcademicConcept.semester, plural: true)),
            if (isSectionEnabled)
              (icon: LucideIcons.layoutGrid, label: terminology.label(AcademicConcept.section, plural: true)),
            (icon: LucideIcons.bookOpen, label: terminology.label(AcademicConcept.subject, plural: true)),
            (icon: LucideIcons.users, label: 'Faculty'),
            (icon: LucideIcons.doorClosed, label: terminology.label(AcademicConcept.room, plural: true)),
          ]
        : [
            (icon: LucideIcons.building2, label: terminology.label(AcademicConcept.department, plural: true)),
            (icon: LucideIcons.graduationCap, label: terminology.label(AcademicConcept.program, plural: true)),
            (icon: LucideIcons.calendarDays, label: terminology.label(AcademicConcept.semester, plural: true)),
            if (isSectionEnabled)
              (icon: LucideIcons.layoutGrid, label: terminology.label(AcademicConcept.section, plural: true)),
            (icon: LucideIcons.bookOpen, label: terminology.label(AcademicConcept.subject, plural: true)),
            (icon: LucideIcons.users, label: 'Faculty'),
            (icon: LucideIcons.doorClosed, label: terminology.label(AcademicConcept.room, plural: true)),
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(categories.length, (index) {
          final cat = categories[index];
          final isSelected = currentIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelect(index),
              borderRadius: BorderRadius.circular(AcadexRadius.md),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AcadexColors.primary
                      : (isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface),
                  borderRadius: BorderRadius.circular(AcadexRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? AcadexColors.primary
                        : (isDark ? AcadexColors.darkHairline : AcadexColors.hairline),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AcadexColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : (isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? AcadexColors.darkInk : AcadexColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent({
    required int index,
    required bool isHodOrBelow,
    required bool isSectionEnabled,
    required AsyncValue<List<Course>> coursesAsync,
    required AsyncValue<List<Department>> deptsAsync,
    required AsyncValue<List<Semester>> semestersAsync,
    required AsyncValue<List<Section>> sectionsAsync,
    required AsyncValue<List<Subject>> subjectsAsync,
    required AsyncValue<List<Room>> roomsAsync,
    required AppRole userRole,
    required UserModel? currentUser,
    required bool isDark,
  }) {
    if (isHodOrBelow) {
      if (index == 0) return _buildCoursesTab(coursesAsync, deptsAsync, userRole, isDark, true);
      if (index == 1) return _buildSemestersTab(semestersAsync, coursesAsync, userRole, isDark, true);
      if (isSectionEnabled) {
        if (index == 2) return _buildSectionsTab(sectionsAsync, semestersAsync, userRole, isDark, true);
        if (index == 3) return _buildSubjectsTab(subjectsAsync, deptsAsync, userRole, isDark, true);
        if (index == 4) return _buildFacultyTab(currentUser?.departmentId, userRole, isDark, true);
        if (index == 5) return _buildRoomsTab(roomsAsync, userRole, isDark, true);
      } else {
        if (index == 2) return _buildSubjectsTab(subjectsAsync, deptsAsync, userRole, isDark, true);
        if (index == 3) return _buildFacultyTab(currentUser?.departmentId, userRole, isDark, true);
        if (index == 4) return _buildRoomsTab(roomsAsync, userRole, isDark, true);
      }
    } else {
      if (index == 0) return _buildDepartmentsTab(deptsAsync, userRole, isDark, true);
      if (index == 1) return _buildCoursesTab(coursesAsync, deptsAsync, userRole, isDark, true);
      if (index == 2) return _buildSemestersTab(semestersAsync, coursesAsync, userRole, isDark, true);
      if (isSectionEnabled) {
        if (index == 3) return _buildSectionsTab(sectionsAsync, semestersAsync, userRole, isDark, true);
        if (index == 4) return _buildSubjectsTab(subjectsAsync, deptsAsync, userRole, isDark, true);
        if (index == 5) {
          return _buildFacultyTab(
            _selectedDepartmentFilter == 'ALL' ? null : _selectedDepartmentFilter,
            userRole,
            isDark,
            true,
          );
        }
        if (index == 6) return _buildRoomsTab(roomsAsync, userRole, isDark, true);
      } else {
        if (index == 3) return _buildSubjectsTab(subjectsAsync, deptsAsync, userRole, isDark, true);
        if (index == 4) {
          return _buildFacultyTab(
            _selectedDepartmentFilter == 'ALL' ? null : _selectedDepartmentFilter,
            userRole,
            isDark,
            true,
          );
        }
        if (index == 5) return _buildRoomsTab(roomsAsync, userRole, isDark, true);
      }
    }
    return const SizedBox.shrink();
  }

  String _getSubtitleForRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return 'Global academic architecture and multi-institution catalog.';
      case AppRole.collegeAdmin:
        return 'Manage college departments, degree programs, semesters, sections, and subjects.';
      case AppRole.hod:
        return 'Departmental academic structure, curriculum, and class allocations.';
      case AppRole.faculty:
        return 'Academic overview of assigned curriculum, courses, and sections.';
      case AppRole.student:
        return 'Enrolled degree program, current semester, section, and syllabus.';
    }
  }

  List<Widget> _buildHeaderActions(
    BuildContext context,
    AppRole role,
    TerminologyHelper terminology,
    bool isSectionEnabled,
    bool isMobile,
  ) {
    final btnSize = isMobile ? AcadexButtonSize.sm : AcadexButtonSize.md;
    final isHod = role == AppRole.hod;
    final isHodOrBelow = isHod || role == AppRole.faculty || role == AppRole.student;
    final tabIdx = _currentTabIndex.clamp(0, _tabController.length - 1);

    AcademicWorkspaceModule currentModule;
    if (isHodOrBelow) {
      if (tabIdx == 0) {
        currentModule = AcademicWorkspaceModule.programs;
      } else if (tabIdx == 1) {
        currentModule = AcademicWorkspaceModule.semesters;
      } else if (tabIdx == 2) {
        currentModule = isSectionEnabled ? AcademicWorkspaceModule.sections : AcademicWorkspaceModule.subjects;
      } else if (tabIdx == 3) {
        currentModule = isSectionEnabled ? AcademicWorkspaceModule.subjects : AcademicWorkspaceModule.faculty;
      } else if (tabIdx == 4) {
        currentModule = isSectionEnabled ? AcademicWorkspaceModule.faculty : AcademicWorkspaceModule.rooms;
      } else {
        currentModule = AcademicWorkspaceModule.rooms;
      }
    } else {
      if (tabIdx == 0) {
        currentModule = AcademicWorkspaceModule.departments;
      } else if (tabIdx == 1) {
        currentModule = AcademicWorkspaceModule.programs;
      } else if (tabIdx == 2) {
        currentModule = AcademicWorkspaceModule.semesters;
      } else if (tabIdx == 3) {
        currentModule = isSectionEnabled ? AcademicWorkspaceModule.sections : AcademicWorkspaceModule.subjects;
      } else if (tabIdx == 4) {
        currentModule = isSectionEnabled ? AcademicWorkspaceModule.subjects : AcademicWorkspaceModule.faculty;
      } else if (tabIdx == 5) {
        currentModule = isSectionEnabled ? AcademicWorkspaceModule.faculty : AcademicWorkspaceModule.rooms;
      } else {
        currentModule = AcademicWorkspaceModule.rooms;
      }
    }

    if (role == AppRole.collegeAdmin || role == AppRole.superAdmin) {
      Widget dynamicCreateButton;
      switch (currentModule) {
        case AcademicWorkspaceModule.departments:
          dynamicCreateButton = AcadexButton(
            key: const Key('acad_create_dept'),
            label: '+ Create ${terminology.label(AcademicConcept.department)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/departments/new'),
          );
          break;
        case AcademicWorkspaceModule.programs:
          dynamicCreateButton = AcadexButton(
            key: const Key('acad_create_prog'),
            label: '+ Create ${terminology.label(AcademicConcept.program)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/courses/new'),
          );
          break;
        case AcademicWorkspaceModule.semesters:
          dynamicCreateButton = AcadexButton(
            key: const Key('acad_create_sem'),
            label: '+ Create ${terminology.label(AcademicConcept.semester)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/semesters/new'),
          );
          break;
        case AcademicWorkspaceModule.sections:
          dynamicCreateButton = AcadexButton(
            key: const Key('acad_create_sec'),
            label: '+ Create ${terminology.label(AcademicConcept.section)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/sections/new'),
          );
          break;
        case AcademicWorkspaceModule.subjects:
          dynamicCreateButton = AcadexButton(
            key: const Key('acad_create_sub'),
            label: '+ Create ${terminology.label(AcademicConcept.subject)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/subjects/new'),
          );
          break;
        case AcademicWorkspaceModule.faculty:
          dynamicCreateButton = AcadexButton(
            key: const Key('acad_add_fac'),
            label: '+ Add Faculty',
            icon: LucideIcons.userPlus,
            size: btnSize,
            onPressed: () => context.push('/academics/faculty/new'),
          );
          break;
        case AcademicWorkspaceModule.rooms:
          dynamicCreateButton = AcadexButton(
            key: const Key('acad_create_room'),
            label: '+ Add ${terminology.label(AcademicConcept.room)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/rooms/new'),
          );
          break;
      }

      return [
        AcadexButton(
          label: 'Department Setup',
          icon: LucideIcons.compass,
          variant: AcadexButtonVariant.secondary,
          size: btnSize,
          onPressed: () => context.push('/academics/setup'),
        ),
        const SizedBox(width: 8),
        dynamicCreateButton,
        if (!isMobile) ...[
          const SizedBox(width: 8),
          AcadexButton(
            label: 'Academic Config',
            icon: LucideIcons.slidersHorizontal,
            variant: AcadexButtonVariant.secondary,
            size: btnSize,
            onPressed: () => context.push('/academics/configuration'),
          ),
        ],
      ];
    } else if (role == AppRole.hod) {
      Widget dynamicCreateButton;
      switch (currentModule) {
        case AcademicWorkspaceModule.programs:
          dynamicCreateButton = AcadexButton(
            key: const Key('hod_acad_create_prog'),
            label: '+ Create ${terminology.label(AcademicConcept.program)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/courses/new'),
          );
          break;
        case AcademicWorkspaceModule.semesters:
          dynamicCreateButton = AcadexButton(
            key: const Key('hod_acad_create_sem'),
            label: '+ Create ${terminology.label(AcademicConcept.semester)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/semesters/new'),
          );
          break;
        case AcademicWorkspaceModule.sections:
          dynamicCreateButton = AcadexButton(
            key: const Key('hod_acad_create_sec'),
            label: '+ Create ${terminology.label(AcademicConcept.section)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/sections/new'),
          );
          break;
        case AcademicWorkspaceModule.subjects:
          dynamicCreateButton = AcadexButton(
            key: const Key('hod_acad_create_sub'),
            label: '+ Create ${terminology.label(AcademicConcept.subject)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/subjects/new'),
          );
          break;
        case AcademicWorkspaceModule.faculty:
          dynamicCreateButton = AcadexButton(
            key: const Key('hod_acad_add_fac'),
            label: '+ Add Faculty',
            icon: LucideIcons.userPlus,
            size: btnSize,
            onPressed: () => context.push('/academics/faculty/new'),
          );
          break;
        case AcademicWorkspaceModule.rooms:
          dynamicCreateButton = AcadexButton(
            key: const Key('hod_acad_create_room'),
            label: '+ Add ${terminology.label(AcademicConcept.room)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/rooms/new'),
          );
          break;
        default:
          dynamicCreateButton = AcadexButton(
            key: const Key('hod_acad_create_prog_fallback'),
            label: '+ Create ${terminology.label(AcademicConcept.program)}',
            icon: LucideIcons.plus,
            size: btnSize,
            onPressed: () => context.push('/academics/courses/new'),
          );
      }

      return [
        AcadexButton(
          label: 'Department Setup',
          icon: LucideIcons.compass,
          variant: AcadexButtonVariant.secondary,
          size: btnSize,
          onPressed: () => context.push('/academics/setup'),
        ),
        const SizedBox(width: 8),
        dynamicCreateButton,
      ];
    }
    return [];
  }

  Widget _buildSetupGuidedBanner(
    BuildContext context,
    AppRole role,
    String? departmentId,
    bool isDark,
  ) {
    if (role != AppRole.hod && role != AppRole.collegeAdmin) {
      return const SizedBox.shrink();
    }

    final setupAsync = ref.watch(departmentSetupProvider(departmentId));
    return setupAsync.maybeWhen(
      data: (setupState) {
        final isComplete = setupState.isComplete;
        final next = setupState.nextActionableMilestone;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isComplete
                ? (isDark ? AcadexColors.successDarkContainer : AcadexColors.successLight)
                : (isDark ? AcadexColors.primary.withValues(alpha: 0.15) : AcadexColors.primaryLight.withValues(alpha: 0.5)),
            borderRadius: AcadexRadius.borderRadiusLg,
            border: Border.all(
              color: isComplete
                  ? AcadexColors.success.withValues(alpha: 0.4)
                  : AcadexColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isComplete ? AcadexColors.success : AcadexColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isComplete ? LucideIcons.checkCheck : LucideIcons.compass,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isComplete ? 'Department Setup Complete' : 'Academic Onboarding in Progress',
                            style: AcadexTypography.body(
                              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                            ).copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AcadexBadge(
                          label: '${setupState.completedCount}/8 Milestones',
                          variant: isComplete ? AcadexBadgeVariant.success : AcadexBadgeVariant.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isComplete
                          ? 'All academic milestones are configured. Structure and timetable are operational.'
                          : (next != null
                              ? 'Next: ${next.title} — ${next.description}'
                              : 'Complete remaining milestones to unlock operational timetable and classes.'),
                      style: AcadexTypography.caption(
                        color: isDark ? AcadexColors.darkInkSecondary : AcadexColors.inkSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AcadexButton(
                label: isComplete ? 'Setup Workspace' : 'Continue Setup',
                icon: LucideIcons.arrowRight,
                size: AcadexButtonSize.sm,
                variant: isComplete ? AcadexButtonVariant.secondary : AcadexButtonVariant.primary,
                onPressed: () => context.push('/academics/setup'),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildPersonalizedRoleCard(
      BuildContext context, dynamic currentUser, bool isDark) {
    final isFaculty = currentUser?.role == AppRole.faculty;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AcadexColors.primary.withValues(alpha: 0.15)
            : AcadexColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: AcadexRadius.borderRadiusLg,
        border: Border.all(
          color: AcadexColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AcadexColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFaculty ? LucideIcons.briefcase : LucideIcons.graduationCap,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFaculty
                      ? 'Faculty Workload & Class Roster'
                      : 'Student Curriculum & Schedule',
                  style: AcadexTypography.heading3(
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFaculty
                      ? 'Quickly jump to your assigned sections, timetable, and attendance marking.'
                      : 'View your course subjects, study resources, and academic timetable.',
                  style: AcadexTypography.bodySmall(
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AcadexButton(
            label: isFaculty ? 'My Workload' : 'My Timetable',
            variant: AcadexButtonVariant.secondary,
            icon: isFaculty ? LucideIcons.activity : LucideIcons.calendar,
            onPressed: () {
              if (isFaculty) {
                context.push('/faculty-workload');
              } else {
                context.push('/timetable');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDeck({
    required AsyncValue<List<Department>> deptsAsync,
    required AsyncValue<List<Course>> coursesAsync,
    required AsyncValue<List<Semester>> semestersAsync,
    required AsyncValue<List<Section>> sectionsAsync,
    required AsyncValue<List<Subject>> subjectsAsync,
    required int facultyCount,
    required AppRole role,
    required bool isMobile,
    required TerminologyHelper terminology,
    required bool isSectionEnabled,
  }) {
    String formatVal<T>(AsyncValue<List<T>> asyncVal) {
      if (asyncVal.isLoading) return '…';
      if (asyncVal.hasError) return '—';
      return (asyncVal.valueOrNull?.length ?? 0).toString();
    }

    final isHod = role == AppRole.hod;
    final deptVal = isHod ? facultyCount.toString() : formatVal(deptsAsync);
    final courseVal = formatVal(coursesAsync);
    final semVal = formatVal(semestersAsync);
    final sectionVal = formatVal(sectionsAsync);
    final subjectVal = formatVal(subjectsAsync);

    final stats = [
      (
        title: isHod ? 'Faculty' : terminology.label(AcademicConcept.department, plural: true),
        value: deptVal,
        icon: isHod ? LucideIcons.users : LucideIcons.building2,
        subtitle: isHod ? 'Department Staff' : 'Active Units',
      ),
      (
        title: terminology.label(AcademicConcept.program, plural: true),
        value: courseVal,
        icon: LucideIcons.graduationCap,
        subtitle: 'Degree Programs',
      ),
      (
        title: terminology.label(AcademicConcept.semester, plural: true),
        value: semVal,
        icon: LucideIcons.calendarDays,
        subtitle: 'Academic Terms',
      ),
      if (isSectionEnabled)
        (
          title: terminology.label(AcademicConcept.section, plural: true),
          value: sectionVal,
          icon: LucideIcons.layoutGrid,
          subtitle: 'Classrooms / Batches',
        ),
      (
        title: terminology.label(AcademicConcept.subject, plural: true),
        value: subjectVal,
        icon: LucideIcons.bookOpen,
        subtitle: 'Curriculum Items',
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: AcadexTypography.heading3(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ).copyWith(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width > 900 ? stats.length : (width > 560 ? 3 : 2);
          final ratio = width > 900 ? 2.4 : (width > 560 ? 2.5 : 2.2);

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: ratio,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            itemBuilder: (context, i) {
              final s = stats[i];
              return _buildCompactOverviewTile(
                context: context,
                title: s.title,
                value: s.value,
                icon: s.icon,
                subtitle: s.subtitle,
                isDark: isDark,
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildCompactOverviewTile({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: BorderRadius.circular(AcadexRadius.md),
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : const Color(0x0607111F),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AcadexColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AcadexRadius.sm),
            ),
            child: Center(
              child: Icon(icon, size: 16, color: AcadexColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentFilterDropdown(
    List<Department> depts,
    bool isDark,
    AppRole role,
    dynamic currentUser,
  ) {
    if (role == AppRole.hod) {
      final deptName = depts
          .firstWhere(
            (d) => d.id == currentUser?.departmentId,
            orElse: () => depts.firstWhere(
              (d) => d.id == _selectedDepartmentFilter,
              orElse: () => Department(
                id: currentUser?.departmentId ?? '',
                name: 'Your Department',
                code: '',
                collegeId: '',
                hodId: '',
                description: '',
                isActive: true,
              ),
            ),
          )
          .name;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
          borderRadius: AcadexRadius.borderRadiusMd,
          border: Border.all(
            color: AcadexColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.building2, size: 14, color: AcadexColors.primary),
            const SizedBox(width: 8),
            Text(
              deptName,
              style: AcadexTypography.body(
                color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AcadexColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'YOUR DEPARTMENT',
                style: AcadexTypography.caption(color: AcadexColors.primary).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
        borderRadius: AcadexRadius.borderRadiusMd,
        border: Border.all(
          color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDepartmentFilter,
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          style: AcadexTypography.body(
            color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
          ),
          dropdownColor:
              isDark ? AcadexColors.darkSurfaceCard : AcadexColors.surface,
          items: [
            const DropdownMenuItem(
              value: 'ALL',
              child: Text('All Departments'),
            ),
            ...depts.map((d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(d.name),
                )),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedDepartmentFilter = val);
            }
          },
        ),
      ),
    );
  }

  // --- TAB 1: DEPARTMENTS ---
  Widget _buildDepartmentsTab(
      AsyncValue<List<Department>> deptsAsync, AppRole role, bool isDark, [bool isMobile = false]) {
    return deptsAsync.when(
      loading: () => const AcadexLoadingState(message: 'Loading departments...'),
      error: (e, _) => AcadexErrorState.fromError(
        error: e,
        title: 'Unable to load departments',
        onRetry: () => ref.invalidate(departmentsProvider),
      ),
      data: (depts) {
        final filtered = depts.where((d) {
          final matchesQuery = _searchQuery.isEmpty ||
              d.name.toLowerCase().contains(_searchQuery) ||
              d.code.toLowerCase().contains(_searchQuery);
          final matchesDept = _selectedDepartmentFilter == 'ALL' ||
              d.id == _selectedDepartmentFilter;
          return matchesQuery && matchesDept;
        }).toList();

        if (filtered.isEmpty) {
          return AcadexEmptyState(
            title: 'No Departments Found',
            subtitle: 'No departments found matching your criteria.',
            icon: LucideIcons.building2,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.superAdmin)
                ? 'Create Department'
                : null,
            onActionTap: () => context.push('/academics/departments/new'),
          );
        }

        return ListView.separated(
          physics: isMobile ? const NeverScrollableScrollPhysics() : null,
          shrinkWrap: isMobile,
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final dept = filtered[index];
            return AcadexCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: AcadexAvatar(
                    name: dept.name,
                    size: 40,
                  ),
                  title: Text(
                    dept.name,
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Code: ${dept.code} • ${dept.description}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AcadexBadge(
                        label: dept.isActive ? 'Active' : 'Inactive',
                        variant: dept.isActive
                            ? AcadexBadgeVariant.success
                            : AcadexBadgeVariant.neutral,
                      ),
                      const SizedBox(width: 8),
                      if (role == AppRole.collegeAdmin || role == AppRole.superAdmin)
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          tooltip: 'Edit Department',
                          onPressed: () =>
                              context.push('/academics/departments/edit/${dept.id}'),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/academics/departments'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 2: COURSES & PROGRAMS ---
  Widget _buildCoursesTab(AsyncValue<List<Course>> coursesAsync,
      AsyncValue<List<Department>> deptsAsync, AppRole role, bool isDark, [bool isMobile = false]) {
    return coursesAsync.when(
      loading: () => const AcadexLoadingState(message: 'Loading courses...'),
      error: (e, _) => AcadexErrorState.fromError(
        error: e,
        title: 'Unable to load courses',
        onRetry: () => ref.invalidate(coursesProvider),
      ),
      data: (courses) {
        final filtered = courses.where((c) {
          final matchesQuery = _searchQuery.isEmpty ||
              c.name.toLowerCase().contains(_searchQuery) ||
              c.code.toLowerCase().contains(_searchQuery);
          final matchesDept = _selectedDepartmentFilter == 'ALL' ||
              c.departmentId == _selectedDepartmentFilter;
          return matchesQuery && matchesDept;
        }).toList();

        if (filtered.isEmpty) {
          return AcadexEmptyState(
            title: 'No Courses Found',
            subtitle: 'No courses available for this academic context.',
            icon: LucideIcons.graduationCap,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.hod)
                ? 'Create Course'
                : null,
            onActionTap: () => context.push('/academics/courses/new'),
          );
        }

        return ListView.separated(
          physics: isMobile ? const NeverScrollableScrollPhysics() : null,
          shrinkWrap: isMobile,
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final course = filtered[index];
            return AcadexCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AcadexColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.bookOpenCheck,
                        color: AcadexColors.primary, size: 20),
                  ),
                  title: Text(
                    course.name,
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Code: ${course.code}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AcadexBadge(
                        label: course.isActive ? 'Active' : 'Inactive',
                        variant: course.isActive
                            ? AcadexBadgeVariant.success
                            : AcadexBadgeVariant.neutral,
                      ),
                      const SizedBox(width: 8),
                      if (role == AppRole.collegeAdmin || role == AppRole.hod)
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          tooltip: 'Edit Course',
                          onPressed: () =>
                              context.push('/academics/courses/edit/${course.id}'),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/academics/courses'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 3: SEMESTERS ---
  Widget _buildSemestersTab(AsyncValue<List<Semester>> semestersAsync,
      AsyncValue<List<Course>> coursesAsync, AppRole role, bool isDark, [bool isMobile = false]) {
    return semestersAsync.when(
      loading: () => const AcadexLoadingState(message: 'Loading semesters...'),
      error: (e, _) => AcadexErrorState.fromError(
        error: e,
        title: 'Unable to load semesters',
        onRetry: () => ref.invalidate(semestersProvider),
      ),
      data: (semesters) {
        final filtered = semesters.where((s) {
          return _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery) ||
              s.number.toString().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return AcadexEmptyState(
            title: 'No Semesters Found',
            subtitle: 'No academic terms or semesters configured.',
            icon: LucideIcons.calendarDays,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.hod)
                ? 'Create Semester'
                : null,
            onActionTap: () => context.push('/academics/semesters/new'),
          );
        }

        return ListView.separated(
          physics: isMobile ? const NeverScrollableScrollPhysics() : null,
          shrinkWrap: isMobile,
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sem = filtered[index];
            return AcadexCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AcadexColors.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'S${sem.number}',
                        style: AcadexTypography.body(
                          color: AcadexColors.secondary,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  title: Text(
                    sem.name,
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Semester ${sem.number} • Status: ${sem.status.toUpperCase()}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AcadexBadge(
                        label: sem.status.toUpperCase(),
                        variant: sem.status == 'active'
                            ? AcadexBadgeVariant.success
                            : AcadexBadgeVariant.neutral,
                      ),
                      const SizedBox(width: 8),
                      if (role == AppRole.collegeAdmin || role == AppRole.hod)
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          tooltip: 'Edit Semester',
                          onPressed: () =>
                              context.push('/academics/semesters/edit/${sem.id}'),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/academics/semesters'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 4: SECTIONS ---
  Widget _buildSectionsTab(AsyncValue<List<Section>> sectionsAsync,
      AsyncValue<List<Semester>> semestersAsync, AppRole role, bool isDark, [bool isMobile = false]) {
    return sectionsAsync.when(
      loading: () => const AcadexLoadingState(message: 'Loading sections...'),
      error: (e, _) => AcadexErrorState.fromError(
        error: e,
        title: 'Unable to load sections',
        onRetry: () => ref.invalidate(sectionsProvider),
      ),
      data: (sections) {
        final filtered = sections.where((s) {
          return _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return AcadexEmptyState(
            title: 'No Sections Found',
            subtitle: 'No classroom sections configured.',
            icon: LucideIcons.layoutGrid,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.hod)
                ? 'Create Section'
                : null,
            onActionTap: () => context.push('/academics/sections/new'),
          );
        }

        return ListView.separated(
          physics: isMobile ? const NeverScrollableScrollPhysics() : null,
          shrinkWrap: isMobile,
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sec = filtered[index];
            return AcadexCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AcadexColors.accentSky.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        sec.name.substring(0, sec.name.length.clamp(0, 2)),
                        style: AcadexTypography.body(
                          color: AcadexColors.accentSky,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  title: Text(
                    'Section ${sec.name}',
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Capacity: ${sec.capacity} students • Status: ${sec.status.toUpperCase()}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AcadexButton(
                        label: 'Timetable',
                        variant: AcadexButtonVariant.secondary,
                        icon: LucideIcons.calendar,
                        onPressed: () => context.push('/timetable'),
                      ),
                      const SizedBox(width: 8),
                      if (role == AppRole.collegeAdmin || role == AppRole.hod)
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          tooltip: 'Edit Section',
                          onPressed: () =>
                              context.push('/academics/sections/edit/${sec.id}'),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/academics/sections'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 5: SUBJECTS ---
  Widget _buildSubjectsTab(AsyncValue<List<Subject>> subjectsAsync,
      AsyncValue<List<Department>> deptsAsync, AppRole role, bool isDark, [bool isMobile = false]) {
    return subjectsAsync.when(
      loading: () => const AcadexLoadingState(message: 'Loading subjects...'),
      error: (e, _) => AcadexErrorState.fromError(
        error: e,
        title: 'Unable to load subjects',
        onRetry: () => ref.invalidate(subjectsProvider),
      ),
      data: (subjects) {
        final filtered = subjects.where((s) {
          final matchesQuery = _searchQuery.isEmpty ||
              s.name.toLowerCase().contains(_searchQuery) ||
              s.code.toLowerCase().contains(_searchQuery);
          final matchesDept = _selectedDepartmentFilter == 'ALL' ||
              s.departmentId == _selectedDepartmentFilter;
          return matchesQuery && matchesDept;
        }).toList();

        if (filtered.isEmpty) {
          return AcadexEmptyState(
            title: 'No Subjects Found',
            subtitle: 'Create the first subject for this course and academic period.',
            icon: LucideIcons.bookOpen,
            actionLabel: (role == AppRole.collegeAdmin || role == AppRole.hod)
                ? 'Create Subject'
                : null,
            onActionTap: () => context.push('/academics/subjects/new'),
          );
        }

        return ListView.separated(
          physics: isMobile ? const NeverScrollableScrollPhysics() : null,
          shrinkWrap: isMobile,
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sub = filtered[index];
            return AcadexCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AcadexColors.accentGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.bookOpen,
                        color: AcadexColors.accentGreen, size: 20),
                  ),
                  title: Text(
                    sub.name,
                    style: AcadexTypography.heading3(
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Code: ${sub.code} • ${sub.credits} Credits • ${sub.type.toUpperCase()}',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AcadexButton(
                        label: 'Notes',
                        variant: AcadexButtonVariant.secondary,
                        icon: LucideIcons.fileText,
                        onPressed: () => context.push('/notes'),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.chevronRight, size: 16, color: AcadexColors.inkMuted),
                    ],
                  ),
                  onTap: () => context.push('/academics/subjects/${sub.id}'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 6: FACULTY ---
  Widget _buildFacultyTab(String? departmentId, AppRole role, bool isDark, [bool isMobile = false]) {
    final facultyState = ref.watch(facultyProvider(departmentId));
    if (facultyState.isLoading && facultyState.items.isEmpty) {
      return const AcadexLoadingState(message: 'Loading department faculty...');
    }
    if (facultyState.error != null && facultyState.items.isEmpty) {
      return AcadexErrorState.fromError(
        error: facultyState.error,
        title: 'Unable to load faculty',
        onRetry: () => ref.read(facultyProvider(departmentId).notifier).refresh(),
      );
    }

    final filtered = facultyState.items.where((f) {
      final matchesQuery = _searchQuery.isEmpty ||
          f.name.toLowerCase().contains(_searchQuery) ||
          f.email.toLowerCase().contains(_searchQuery) ||
          (f.designation?.toLowerCase().contains(_searchQuery) ?? false);
      return matchesQuery;
    }).toList();

    if (filtered.isEmpty) {
      return AcadexEmptyState(
        title: 'No Faculty Found',
        subtitle: 'No faculty members found for this department.',
        icon: LucideIcons.users,
        actionLabel: (role == AppRole.collegeAdmin || role == AppRole.hod)
            ? 'Add Faculty'
            : null,
        onActionTap: () => context.push('/academics/faculty/new'),
      );
    }

    return ListView.separated(
      physics: isMobile ? const NeverScrollableScrollPhysics() : null,
      shrinkWrap: isMobile,
      padding: const EdgeInsets.only(top: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fac = filtered[index];
        return AcadexCard(
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: AcadexAvatar(
                name: fac.name,
                size: 40,
              ),
              title: Text(
                fac.name,
                style: AcadexTypography.heading3(
                  color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                ),
              ),
              subtitle: Text(
                '${(fac.designation != null && fac.designation!.isNotEmpty) ? fac.designation! : "Faculty"} • ${fac.email}',
                style: AcadexTypography.bodySmall(
                  color: isDark
                      ? AcadexColors.darkInkMuted
                      : AcadexColors.inkMuted,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AcadexBadge(
                    label: fac.isActive ? 'Active' : 'Inactive',
                    variant: fac.isActive
                        ? AcadexBadgeVariant.success
                        : AcadexBadgeVariant.neutral,
                  ),
                  const SizedBox(width: 8),
                  if (role == AppRole.collegeAdmin || role == AppRole.hod)
                    AcadexButton(
                      label: 'Assign',
                      variant: AcadexButtonVariant.secondary,
                      icon: LucideIcons.userCheck,
                      onPressed: () => context.push('/faculty-assignments'),
                    ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.chevronRight, size: 16, color: AcadexColors.inkMuted),
                ],
              ),
              onTap: () => context.push('/academics/faculty/${fac.id}'),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 7: ROOMS ---
  Widget _buildRoomsTab(
    AsyncValue<List<Room>> roomsAsync,
    AppRole role,
    bool isDark, [
    bool isMobile = false,
  ]) {
    final deptMap = ref.watch(departmentMapProvider);
    final terminology = ref.watch(terminologyProvider);
    final roomLabel = terminology.roomName();
    final roomsLabel = terminology.roomName(plural: true);
    final canManage = role == AppRole.collegeAdmin || role == AppRole.superAdmin || role == AppRole.hod;

    return roomsAsync.when(
      loading: () => AcadexLoadingState(message: 'Loading $roomsLabel...'),
      error: (e, _) => AcadexErrorState.fromError(
        error: e,
        title: 'Unable to load $roomsLabel',
        onRetry: () => ref.invalidate(roomsProvider),
      ),
      data: (rooms) {
        final filtered = rooms.where((r) {
          final matchesQuery = _searchQuery.isEmpty ||
              r.name.toLowerCase().contains(_searchQuery) ||
              r.code.toLowerCase().contains(_searchQuery) ||
              r.type.toLowerCase().contains(_searchQuery);
          final matchesDept = _selectedDepartmentFilter == 'ALL' ||
              r.departmentId == null ||
              r.departmentId!.isEmpty ||
              r.departmentId == _selectedDepartmentFilter;
          return matchesQuery && matchesDept;
        }).toList();

        if (filtered.isEmpty) {
          return AcadexEmptyState(
            title: 'No $roomsLabel Found',
            subtitle: 'Establish classrooms, laboratories, and lecture halls for timetable scheduling.',
            icon: LucideIcons.doorClosed,
            actionLabel: canManage ? '+ Add $roomLabel' : null,
            onActionTap: () => context.push('/academics/rooms/new'),
          );
        }

        return ListView.separated(
          physics: isMobile ? const NeverScrollableScrollPhysics() : null,
          shrinkWrap: isMobile,
          padding: const EdgeInsets.only(top: 8),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final room = filtered[index];
            final deptName = room.departmentId != null && room.departmentId!.isNotEmpty
                ? (deptMap[room.departmentId]?.name ?? 'Department')
                : 'Campus Shared';

            return AcadexCard(
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AcadexColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.doorClosed,
                        color: AcadexColors.primary, size: 20),
                  ),
                  title: Row(
                    children: [
                      Text(
                        room.name,
                        style: AcadexTypography.heading3(
                          color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AcadexColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          room.code,
                          style: const TextStyle(
                            color: AcadexColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Capacity: ${room.capacity} seats • Type: ${room.type.toUpperCase()} • $deptName',
                    style: AcadexTypography.bodySmall(
                      color: isDark
                          ? AcadexColors.darkInkMuted
                          : AcadexColors.inkMuted,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AcadexBadge(
                        label: room.isActive ? 'Active' : 'Inactive',
                        variant: room.isActive ? AcadexBadgeVariant.success : AcadexBadgeVariant.neutral,
                      ),
                      if (canManage) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.edit, size: 16),
                          tooltip: 'Edit $roomLabel',
                          onPressed: () => context.push('/academics/rooms/edit/${room.id}'),
                        ),
                      ],
                    ],
                  ),
                  onTap: canManage ? () => context.push('/academics/rooms/edit/${room.id}') : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
