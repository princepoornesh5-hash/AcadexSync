import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/presentation/utils/academic_prerequisite_guard.dart';
import 'package:campus_management/features/institution_config/domain/models/institution_config_models.dart';
import 'package:campus_management/features/institution_config/presentation/providers/institution_config_providers.dart';

void main() {
  group('PROMPT 34 — Focused Verification: Academic Foundation & Terminology', () {
    // ----------------------------------------------------
    // 1. SCENARIO A: Course / Semester / Section
    // ----------------------------------------------------
    test('Scenario A: College configured with Course, Semester, Section', () {
      final configA = InstitutionConfigModel(
        collegeId: 'col_a',
        academicStructure: const AcademicStructureConfig(
          program: true,
          academicYear: true,
          semester: true,
          section: true,
          subject: true,
          building: true,
          room: true,
        ),
        terminology: const TerminologyConfig(
          program: ConceptTerm(singular: 'Course', plural: 'Courses'),
          semester: ConceptTerm(singular: 'Semester', plural: 'Semesters'),
          section: ConceptTerm(singular: 'Section', plural: 'Sections'),
          subject: ConceptTerm(singular: 'Subject', plural: 'Subjects'),
          academicYear: ConceptTerm(singular: 'Academic Year', plural: 'Academic Years'),
        ),
      );

      final helperA = TerminologyHelper(configA);

      expect(helperA.programName(), 'Course');
      expect(helperA.programName(plural: true), 'Courses');
      expect(helperA.createLabel(AcademicConcept.program), 'Create Course');
      expect(helperA.semesterName(), 'Semester');
      expect(helperA.semesterName(plural: true), 'Semesters');
      expect(helperA.sectionName(), 'Section');
      expect(helperA.sectionName(plural: true), 'Sections');
      expect(helperA.isSectionEnabled, isTrue);
    });

    // ----------------------------------------------------
    // 2. SCENARIO B: Program / Term / Class
    // ----------------------------------------------------
    test('Scenario B: College configured with Program, Term, Class', () {
      final configB = InstitutionConfigModel(
        collegeId: 'col_b',
        academicStructure: const AcademicStructureConfig(
          program: true,
          academicYear: true,
          semester: true,
          section: false, // Class/Section disabled
          subject: true,
          building: false,
          room: false,
        ),
        terminology: const TerminologyConfig(
          program: ConceptTerm(singular: 'Program', plural: 'Programs'),
          semester: ConceptTerm(singular: 'Term', plural: 'Terms'),
          section: ConceptTerm(singular: 'Class', plural: 'Classes'),
          subject: ConceptTerm(singular: 'Course Module', plural: 'Course Modules'),
          academicYear: ConceptTerm(singular: 'Academic Session', plural: 'Academic Sessions'),
        ),
      );

      final helperB = TerminologyHelper(configB);

      expect(helperB.programName(), 'Program');
      expect(helperB.programName(plural: true), 'Programs');
      expect(helperB.createLabel(AcademicConcept.program), 'Create Program');
      expect(helperB.semesterName(), 'Term');
      expect(helperB.semesterName(plural: true), 'Terms');
      expect(helperB.sectionName(), 'Class');
      expect(helperB.sectionName(plural: true), 'Classes');
      expect(helperB.isSectionEnabled, isFalse);
    });

    // ----------------------------------------------------
    // 3. AY vs Cohort vs Stage vs Period Semantic Distinctions
    // ----------------------------------------------------
    test('Format progression context strictly distinguishes Stage, Period, Cohort, and Academic Year', () {
      final helper = TerminologyHelper.fallback();
      final line = helper.formatProgressionContext(
        stage: '3rd Year',
        period: 'Semester 5',
        cohort: '2024–27',
        academicYear: '2026–27',
      );

      expect(line, '3rd Year • Semester 5 • Cohort: 2024–27 • AY: 2026–27');
    });

    // ----------------------------------------------------
    // 4. Section Optionality in Prerequisite Engine
    // ----------------------------------------------------
    test('Prerequisite engine does not block on section when section concept is disabled', () {
      final mockCourse = Course(
        id: 'c1',
        collegeId: 'col1',
        departmentId: 'd1',
        name: 'Computer Engineering',
        code: 'CSE',
        duration: 3,
        isActive: true,
      );
      final mockAcademicYear = AcademicYear(
        id: 'ay1',
        collegeId: 'col1',
        name: '2026-27',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2027, 5, 31),
        isActive: true,
      );
      final mockSemester = Semester(
        id: 'sem1',
        collegeId: 'col1',
        departmentId: 'd1',
        courseId: 'c1',
        academicYearId: 'ay1',
        name: 'Semester 1',
        number: 1,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 11, 30),
        isActive: true,
      );
      final mockSubject = Subject(
        id: 'sub1',
        collegeId: 'col1',
        departmentId: 'd1',
        courseId: 'c1',
        semesterId: 'sem1',
        name: 'Computer Systems',
        code: 'CS101',
        credits: 4,
        type: 'Theory',
        isActive: true,
      );
      final mockFaculty = Faculty(
        id: 'f1',
        collegeId: 'col1',
        departmentId: 'd1',
        name: 'Prof Turing',
        employeeId: 'EMP001',
        email: 'turing@acadex.edu',
        phone: '1234567890',
        isActive: true,
        accountStatus: AccountStatus.active,
      );

      // Teaching assignment with NO section
      final mockAssignmentWithoutSection = FacultyAssignment(
        id: 'fa1',
        collegeId: 'col1',
        departmentId: 'd1',
        courseId: 'c1',
        semesterId: 'sem1',
        sectionId: '', // Empty because section is disabled
        subjectId: 'sub1',
        facultyId: 'f1',
        facultyName: 'Prof Turing',
        academicYearId: 'ay1',
        isActive: true,
      );

      // Section is disabled: checkFacultyAssignmentPrerequisites passes with zero sections
      final assignCheck = AcademicPrerequisiteGuard.checkFacultyAssignmentPrerequisites(
        courses: [mockCourse],
        semesters: [mockSemester],
        sections: [], // No sections
        subjects: [mockSubject],
        faculty: [mockFaculty],
        isSectionEnabled: false,
      );
      expect(assignCheck.isAllowed, isTrue);

      // Section is disabled: checkTimetablePrerequisites passes with zero sections
      final timetableCheck = AcademicPrerequisiteGuard.checkTimetablePrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
        semesters: [mockSemester],
        sections: [], // No sections
        subjects: [mockSubject],
        facultyAssignments: [mockAssignmentWithoutSection],
        rooms: [],
        isSectionEnabled: false,
        isRoomRequired: false,
      );
      expect(timetableCheck.isAllowed, isTrue);
    });

    // ----------------------------------------------------
    // 5. Unrelated Optionality: No Rooms Does Not Block Academics
    // ----------------------------------------------------
    test('Absence of rooms never blocks Subject or Course creation', () {
      final mockCourse = Course(
        id: 'c1',
        collegeId: 'col1',
        departmentId: 'd1',
        name: 'Computer Engineering',
        code: 'CSE',
        duration: 3,
        isActive: true,
      );
      final mockAcademicYear = AcademicYear(
        id: 'ay1',
        collegeId: 'col1',
        name: '2026-27',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2027, 5, 31),
        isActive: true,
      );

      final semPrereq = AcademicPrerequisiteGuard.checkSemesterPrerequisites(
        courses: [mockCourse],
        academicYears: [mockAcademicYear],
      );
      expect(semPrereq.isAllowed, isTrue);

      final subPrereq = AcademicPrerequisiteGuard.checkSubjectPrerequisites(
        courses: [mockCourse],
        semesters: [
          Semester(
            id: 's1',
            collegeId: 'col1',
            departmentId: 'd1',
            courseId: 'c1',
            academicYearId: 'ay1',
            name: 'Sem 1',
            number: 1,
            startDate: DateTime(2026, 6, 1),
            endDate: DateTime(2026, 11, 30),
            isActive: true,
          ),
        ],
      );
      expect(subPrereq.isAllowed, isTrue);
    });
  });
}
