import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/institution_config/domain/models/institution_config_models.dart';
import 'package:campus_management/features/institution_config/domain/repositories/institution_config_repository.dart';
import 'package:campus_management/features/institution_config/presentation/providers/institution_config_providers.dart';
import 'package:campus_management/features/institution_config/presentation/screens/institution_configuration_screen.dart';
import 'package:campus_management/features/academic_structure/presentation/widgets/context_program_selector.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/academic_structure/presentation/utils/academic_prerequisite_guard.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.initial);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInstitutionConfigRepository implements InstitutionConfigRepository {
  InstitutionConfigModel? configToReturn;
  List<InstitutionPresetModel> presetsToReturn = [
    const InstitutionPresetModel(
      id: InstitutionType.engineering,
      name: 'Engineering College',
      description: 'Department, Program, Semester, Section, Subject',
      suggestedStructure: AcademicStructureConfig(
        program: true,
        academicYear: true,
        semester: true,
        section: true,
        subject: true,
        building: true,
        room: true,
      ),
      suggestedTerminology: TerminologyConfig(
        program: ConceptTerm(singular: 'Degree Program', plural: 'Degree Programs'),
        semester: ConceptTerm(singular: 'Semester', plural: 'Semesters'),
        section: ConceptTerm(singular: 'Class Section', plural: 'Class Sections'),
      ),
    ),
    const InstitutionPresetModel(
      id: InstitutionType.polytechnic,
      name: 'Polytechnic',
      description: 'Diploma programs without section division',
      suggestedStructure: AcademicStructureConfig(
        program: true,
        academicYear: true,
        semester: true,
        section: false,
        subject: true,
        building: false,
        room: false,
      ),
      suggestedTerminology: TerminologyConfig(
        program: ConceptTerm(singular: 'Diploma Course', plural: 'Diploma Courses'),
        semester: ConceptTerm(singular: 'Term', plural: 'Terms'),
      ),
    ),
  ];

  InstitutionType? lastType;
  AcademicStructureConfig? lastStructure;
  TerminologyConfig? lastTerminology;

  @override
  Future<InstitutionConfigModel> getEffectiveConfiguration() async {
    return configToReturn ?? const InstitutionConfigModel(collegeId: 'college-123');
  }

  @override
  Future<InstitutionConfigModel> updateConfiguration({
    InstitutionType? institutionType,
    AcademicStructureConfig? academicStructure,
    TerminologyConfig? terminology,
    AttendanceAlertsConfig? attendanceAlerts,
  }) async {
    lastType = institutionType;
    lastStructure = academicStructure;
    lastTerminology = terminology;
    return configToReturn ?? const InstitutionConfigModel(collegeId: 'college-123');
  }

  @override
  Future<List<InstitutionPresetModel>> getPresets() async {
    return presetsToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prompt 21: Institution Configuration Domain & Terminology', () {
    test('Default configuration preserves canonical labels safely', () {
      const config = InstitutionConfigModel(collegeId: 'col-1');
      final helper = TerminologyHelper(config);

      expect(helper.label(AcademicConcept.department), 'Department');
      expect(helper.label(AcademicConcept.department, plural: true), 'Departments');
      expect(helper.label(AcademicConcept.program), 'Course');
      expect(helper.label(AcademicConcept.program, plural: true), 'Courses');
      expect(helper.label(AcademicConcept.semester), 'Semester');
      expect(helper.label(AcademicConcept.section), 'Section');
      expect(helper.isSectionEnabled, isTrue);
      expect(helper.isBuildingEnabled, isTrue);
      expect(helper.isRoomEnabled, isTrue);
    });

    test('Custom configuration adapts terminology and disabled concepts', () {
      const customConfig = InstitutionConfigModel(
        collegeId: 'col-custom',
        institutionType: InstitutionType.polytechnic,
        academicStructure: AcademicStructureConfig(
          section: false,
          building: false,
          room: false,
        ),
        terminology: TerminologyConfig(
          program: ConceptTerm(singular: 'Diploma', plural: 'Diplomas'),
          semester: ConceptTerm(singular: 'Term', plural: 'Terms'),
          section: ConceptTerm(singular: 'Batch', plural: 'Batches'),
        ),
        isConfigured: true,
      );

      final helper = TerminologyHelper(customConfig);

      expect(helper.label(AcademicConcept.program), 'Diploma');
      expect(helper.label(AcademicConcept.program, plural: true), 'Diplomas');
      expect(helper.label(AcademicConcept.semester), 'Term');
      expect(helper.label(AcademicConcept.semester, plural: true), 'Terms');
      expect(helper.label(AcademicConcept.section), 'Batch');
      expect(helper.isSectionEnabled, isFalse);
      expect(helper.isBuildingEnabled, isFalse);
      expect(helper.isRoomEnabled, isFalse);
    });

    test('formatCompactContext adapts based on whether Section is enabled', () {
      final withSection = TerminologyHelper(const InstitutionConfigModel(
        collegeId: 'c1',
        academicStructure: AcademicStructureConfig(section: true),
      ));

      final withoutSection = TerminologyHelper(const InstitutionConfigModel(
        collegeId: 'c2',
        academicStructure: AcademicStructureConfig(section: false),
      ));

      expect(
        withSection.formatCompactContext(subjectName: 'DBMS', sectionName: 'Class A'),
        'DBMS • Class A',
      );

      // When section is disabled, section name is hidden cleanly without trailing separators
      expect(
        withoutSection.formatCompactContext(subjectName: 'DBMS', sectionName: 'Class A'),
        'DBMS',
      );
      expect(
        withoutSection.formatCompactContext(subjectName: 'DBMS', semesterName: 'Term 3'),
        'DBMS • Term 3',
      );
    });
  });

  group('Prompt 21: Single-Program Auto-Resolution', () {
    testWidgets('Automatically resolves single program and displays auto-resolved banner', (tester) async {
      String? resolvedId;
      final singleCourseList = [
        Course(
          id: 'course-single-1',
          departmentId: 'dept-1',
          collegeId: 'col-1',
          name: 'Diploma in Computer Science',
          code: 'DCS',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContextProgramSelector(
                courses: singleCourseList,
                selectedCourseId: null,
                onCourseChanged: (val) => resolvedId = val,
              ),
            ),
          ),
        ),
      );

      // Trigger post frame callback
      await tester.pumpAndSettle();

      expect(resolvedId, 'course-single-1');
      expect(find.byKey(const Key('single_program_autoresolved_banner')), findsOneWidget);
      expect(find.text('Diploma in Computer Science (DCS)'), findsOneWidget);
      expect(find.textContaining('Auto-resolved'), findsOneWidget);
      expect(find.byKey(const Key('context_program_dropdown')), findsNothing);
    });

    testWidgets('Shows dropdown when multiple programs exist', (tester) async {
      String? selectedId;
      final multiCourses = [
        Course(id: 'c-1', departmentId: 'd-1', collegeId: 'col-1', name: 'Computer Engineering', code: 'CE'),
        Course(id: 'c-2', departmentId: 'd-1', collegeId: 'col-1', name: 'Information Technology', code: 'IT'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContextProgramSelector(
                courses: multiCourses,
                selectedCourseId: selectedId,
                onCourseChanged: (val) => selectedId = val,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('context_program_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('single_program_autoresolved_banner')), findsNothing);
    });
  });

  group('Prompt 21: Guided Institution Configuration Screen', () {
    testWidgets('Renders 4-step wizard with presets, terminology and live preview', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakeRepo = FakeInstitutionConfigRepository();
      final router = GoRouter(
        initialLocation: '/config',
        routes: [
          GoRoute(
            path: '/config',
            builder: (_, __) => const InstitutionConfigurationScreen(),
          ),
          GoRoute(
            path: '/academics',
            builder: (_, __) => const Scaffold(body: Text('Academics Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            institutionConfigRepositoryProvider.overrideWithValue(fakeRepo),
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
                  const AuthAuthenticated(
                    user: UserModel(
                      id: 'admin-1',
                      email: 'admin@college.edu',
                      name: 'Principal Admin',
                      role: AppRole.collegeAdmin,
                      collegeId: 'college-123',
                    ),
                    token: 'mock-jwt-token',
                  ),
                )),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Presets
      expect(find.text('Institution Configuration'), findsOneWidget);
      expect(find.text('College Type'), findsWidgets);
      expect(find.text('Structure'), findsWidgets);
      expect(find.text('Terminology'), findsWidgets);
      expect(find.text('Preview'), findsWidgets);
      expect(find.text('How does your college organize academics?'), findsOneWidget);

      // Select Polytechnic Preset
      final polyCard = find.text('Polytechnic');
      expect(polyCard, findsOneWidget);
      await tester.tap(polyCard);
      await tester.pumpAndSettle();

      // Go to Step 2: Academic Concepts
      final continueBtn = find.text('Continue');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Which academic concepts does your college use?'), findsOneWidget);
      expect(find.text('Section / Class / Batch'), findsOneWidget);

      // Go to Step 3: Terminology
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('What do you call them?'), findsOneWidget);

      // Go to Step 4: Preview
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Review how ACADEX will look for your college'), findsOneWidget);
      expect(find.text('YOUR ACADEMIC HIERARCHY'), findsOneWidget);
      expect(find.text('Save Configuration'), findsOneWidget);

      // Save configuration
      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastType, isNotNull);
    });
  });

  group('Prompt 21: Disabled Concepts Workflow Integration', () {
    test('AcademicPrerequisiteGuard respects isSectionEnabled = false', () {
      final course = Course(
        id: 'c1',
        collegeId: 'col-1',
        departmentId: 'd1',
        name: 'Diploma in Civil',
        code: 'DCIVIL',
      );
      final ay = AcademicYear(
        id: 'ay1',
        collegeId: 'col-1',
        name: '2026-2027',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        isActive: true,
      );
      final semester = Semester(
        id: 'sem1',
        collegeId: 'col-1',
        departmentId: 'd1',
        courseId: 'c1',
        academicYearId: 'ay1',
        number: 1,
        name: 'Semester 1',
        status: 'active',
        isCurrent: true,
      );
      final subject = Subject(
        id: 'sub1',
        collegeId: 'col-1',
        departmentId: 'd1',
        courseId: 'c1',
        semesterId: 'sem1',
        name: 'Mechanics',
        code: 'MEC101',
      );

      // 1. When Section is enabled and no sections exist:
      final decisionWithSection = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.facultyAssignment,
        currentRole: AppRole.collegeAdmin,
        departmentId: 'd1',
        collegeId: 'col-1',
        courses: [course],
        academicYears: [ay],
        semesters: [semester],
        sections: const [],
        subjects: [subject],
        faculty: const [],
        facultyAssignments: const [],
        students: const [],
        timetableCount: 0,
        currentAcademicYear: ay,
        isSectionEnabled: true,
      );
      // Blocked on missing section
      expect(decisionWithSection.isBlocked, isTrue);
      expect(decisionWithSection.missingDependency, AcademicPrerequisiteType.section);

      // 2. When Section is disabled and no sections exist:
      final decisionWithoutSection = AcademicPrerequisiteGuard.resolveMilestoneDecision(
        milestoneId: SetupMilestoneId.facultyAssignment,
        currentRole: AppRole.collegeAdmin,
        departmentId: 'd1',
        collegeId: 'col-1',
        courses: [course],
        academicYears: [ay],
        semesters: [semester],
        sections: const [],
        subjects: [subject],
        faculty: const [],
        facultyAssignments: const [],
        students: const [],
        timetableCount: 0,
        currentAcademicYear: ay,
        isSectionEnabled: false,
      );
      // Not blocked on section! Section requirement was bypassed gracefully
      expect(decisionWithoutSection.missingDependency, isNot(AcademicPrerequisiteType.section));
    });
  });
}
