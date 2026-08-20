import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Phase 5E: Timetable Publishing, Versioning & Attendance Integration Tests', () {
    late MockTimetableRepository repo;

    final sampleContainer = TimetableContainerModel(
      id: 'tt-pub-container-1',
      collegeId: 'c1',
      departmentId: 'dept-cs',
      courseId: 'crs-btech',
      academicYearId: 'ay-2026',
      semesterId: 'sem-4',
      sectionId: 'sec-4a',
      name: 'CSE Sem 4 Sec A Master Timetable',
      status: TimetableStatus.draft,
      version: 1,
      activeDays: [
        TimetableDay.monday,
        TimetableDay.tuesday,
        TimetableDay.wednesday,
        TimetableDay.thursday,
        TimetableDay.friday,
      ],
      timingMode: TimetableTimingMode.sameEveryDay,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    final samplePeriods = [
      TimetablePeriodModel(id: 'p1', index: 1, name: 'Period 1', startTime: '09:00', endTime: '10:00'),
      TimetablePeriodModel(id: 'p2', index: 2, name: 'Period 2', startTime: '10:00', endTime: '11:00'),
      TimetablePeriodModel(id: 'p3', index: 3, name: 'Period 3', startTime: '11:00', endTime: '12:00'),
      TimetablePeriodModel(id: 'p4', index: 4, name: 'Period 4', startTime: '12:00', endTime: '13:00'),
      TimetablePeriodModel(id: 'p5', index: 5, name: 'Period 5', startTime: '14:00', endTime: '15:00'),
    ];

    final sampleBreaks = [
      TimetableBreakModel(
        id: 'brk-lunch',
        name: 'Lunch Break',
        breakType: TimetableBreakType.lunch,
        startTime: '13:00',
        endTime: '14:00',
        appliesToDays: [
          TimetableDay.monday,
          TimetableDay.tuesday,
          TimetableDay.wednesday,
          TimetableDay.thursday,
          TimetableDay.friday,
        ],
      ),
    ];

    final sampleEntries = [
      TimetableGridEntryModel(
        id: 'entry-dbms-1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        periodSpan: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-dbms',
        facultyId: 'fac-alan',
        roomNumber: 'LH-101',
        building: 'CS Block',
        sessionType: TimetableSessionType.lecture,
      ),
      TimetableGridEntryModel(
        id: 'entry-os-lab',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 2,
        periodSpan: 2,
        startTime: '10:00',
        endTime: '12:00',
        subjectId: 'sub-os-lab',
        facultyId: 'fac-grace',
        roomNumber: 'Lab-201',
        building: 'CS Block',
        sessionType: TimetableSessionType.lab,
      ),
    ];

    setUp(() {
      repo = MockTimetableRepository();
    });

    // =========================================================================
    // 1. DRAFT ISOLATION FROM LIVE /timetable
    // =========================================================================
    test('1. Draft creation, period, break and entry saves remain strictly isolated from /timetable', () async {
      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveBreaksBatch(sampleContainer.id, sampleBreaks);
      await repo.saveGridEntriesBatch(sampleContainer.id, sampleEntries);

      // Draft container exists in authoring plane
      final draft = await repo.getTimetableContainer(sampleContainer.id);
      expect(draft, isNotNull);
      expect(draft!.status, equals(TimetableStatus.draft));
      expect(draft.version, equals(1));

      // Live legacy /timetable projection is completely empty (0 entries)
      final liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      expect(liveLegacy.isEmpty, isTrue);
    });

    // =========================================================================
    // 2. ATOMIC PUBLISH & PROJECTION CREATION
    // =========================================================================
    test('2. Publishing a valid draft transitions status, increments version, and creates projected documents', () async {
      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveBreaksBatch(sampleContainer.id, sampleBreaks);
      await repo.saveGridEntriesBatch(sampleContainer.id, sampleEntries);

      // Execute Publish
      await repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs');

      // 1. Container status updated to published & version incremented to 2
      final publishedContainer = await repo.getTimetableContainer(sampleContainer.id);
      expect(publishedContainer!.status, equals(TimetableStatus.published));
      expect(publishedContainer.version, equals(2));
      expect(publishedContainer.publishedBy, equals('usr-hod-cs'));
      expect(publishedContainer.publishedAt, isNotNull);

      // 2. Live legacy /timetable collection now has projected entries
      final liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      expect(liveLegacy.length, equals(2));

      // Deterministic IDs: pub_{timetableId}_{entryId}
      expect(liveLegacy.map((e) => e.id).toList(), containsAll([
        'pub_${sampleContainer.id}_entry-dbms-1',
        'pub_${sampleContainer.id}_entry-os-lab',
      ]));
    });

    // =========================================================================
    // 3. INVALID DRAFT PRE-FLIGHT REJECTION (NO PERIODS)
    // =========================================================================
    test('3. Publishing a draft with no defined periods is rejected', () async {
      await repo.createTimetableContainer(sampleContainer);
      // No periods saved

      expect(
        () => repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs'),
        throwsA(isA<ArgumentError>()),
      );

      final container = await repo.getTimetableContainer(sampleContainer.id);
      expect(container!.status, equals(TimetableStatus.draft));
      expect(container.version, equals(1));
    });

    // =========================================================================
    // 4. SECTION & BREAK CONFLICT PRE-FLIGHT REJECTION
    // =========================================================================
    test('4. Section conflict or Break conflict rejects publishing without altering live data', () async {
      final conflictEntries = [
        TimetableGridEntryModel(
          id: 'entry-c1',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-dbms',
          facultyId: 'fac-alan',
          roomNumber: 'LH-101',
          sessionType: TimetableSessionType.lecture,
        ),
        TimetableGridEntryModel(
          id: 'entry-c2',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 1, // Collides with entry-c1
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-os',
          facultyId: 'fac-grace',
          roomNumber: 'LH-102',
          sessionType: TimetableSessionType.lecture,
        ),
      ];

      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveBreaksBatch(sampleContainer.id, sampleBreaks);
      await repo.saveGridEntriesBatch(sampleContainer.id, conflictEntries);

      expect(
        () => repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs'),
        throwsA(isA<TimetableConflictException>()),
      );

      // Live projection remains empty
      final liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      expect(liveLegacy.isEmpty, isTrue);
    });

    // =========================================================================
    // 5. BREAKS EXCLUDED FROM PROJECTION
    // =========================================================================
    test('5. Breaks are never projected to legacy /timetable collection', () async {
      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveBreaksBatch(sampleContainer.id, sampleBreaks);
      await repo.saveGridEntriesBatch(sampleContainer.id, sampleEntries);

      await repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs');

      final liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      // Only 2 teaching entries projected, lunch break is NOT in legacy /timetable
      expect(liveLegacy.length, equals(2));
      expect(liveLegacy.any((e) => e.subjectId.contains('Lunch') || e.subjectId.contains('brk')), isFalse);
    });

    // =========================================================================
    // 6. MULTI-PERIOD MERGED CLASS IS ONE LIVE PROJECTION
    // =========================================================================
    test('6. Merged multi-period class produces ONE projected /timetable entry with aggregated timing', () async {
      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveBreaksBatch(sampleContainer.id, sampleBreaks);
      await repo.saveGridEntriesBatch(sampleContainer.id, sampleEntries);

      await repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs');

      final liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      final osLab = liveLegacy.firstWhere((e) => e.subjectId == 'sub-os-lab');

      expect(osLab.startTime, equals('10:00'));
      expect(osLab.endTime, equals('12:00'));
      expect(osLab.sessionType, equals(TimetableSessionType.lab));
    });

    // =========================================================================
    // 7. REPUBLISHING ATOMICALLY REPLACES PREVIOUS PROJECTIONS
    // =========================================================================
    test('7. Editing draft and republishing replaces previous projections and increments version to v3', () async {
      // 1. Initial Publish (v2)
      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveBreaksBatch(sampleContainer.id, sampleBreaks);
      await repo.saveGridEntriesBatch(sampleContainer.id, sampleEntries);
      await repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs');

      var liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      expect(liveLegacy.length, equals(2));

      // 2. Modify draft: Replace OS Lab with Mathematics
      final updatedEntries = [
        sampleEntries[0], // DBMS
        TimetableGridEntryModel(
          id: 'entry-math-1',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 2,
          periodSpan: 1,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: 'sub-math',
          facultyId: 'fac-euler',
          roomNumber: 'LH-103',
          sessionType: TimetableSessionType.lecture,
        ),
      ];
      // Save to authoring plane (draft edits)
      await repo.deleteGridEntry(sampleContainer.id, 'entry-os-lab');
      await repo.saveGridEntry(sampleContainer.id, updatedEntries[1]);

      // Before republishing, live /timetable still has previous OS Lab
      liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      expect(liveLegacy.any((e) => e.subjectId == 'sub-os-lab'), isTrue);

      // 3. Republish
      await repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs');

      final repubContainer = await repo.getTimetableContainer(sampleContainer.id);
      expect(repubContainer!.version, equals(3));

      // Live /timetable now has Mathematics and NO LONGER has OS Lab
      liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      expect(liveLegacy.length, equals(2));
      expect(liveLegacy.any((e) => e.subjectId == 'sub-os-lab'), isFalse);
      expect(liveLegacy.any((e) => e.subjectId == 'sub-math'), isTrue);
    });

    // =========================================================================
    // 8. UNPUBLISH PURGES LIVE SCHEDULE & PRESERVES DRAFT
    // =========================================================================
    test('8. Unpublishing removes live projection and restores draft status while preserving authoring data', () async {
      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveBreaksBatch(sampleContainer.id, sampleBreaks);
      await repo.saveGridEntriesBatch(sampleContainer.id, sampleEntries);
      await repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs');

      // Live has 2 entries
      var liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      expect(liveLegacy.length, equals(2));

      // Unpublish
      await repo.unpublishTimetable(sampleContainer.id);

      // 1. Live projection is purged
      liveLegacy = await repo.getTimetable(collegeId: 'c1', sectionId: 'sec-4a');
      expect(liveLegacy.isEmpty, isTrue);

      // 2. Authoring container is back to draft
      final container = await repo.getTimetableContainer(sampleContainer.id);
      expect(container!.status, equals(TimetableStatus.draft));

      // 3. Authoring periods, breaks and entries remain intact
      final periods = await repo.getPeriods(sampleContainer.id);
      final breaks = await repo.getBreaks(sampleContainer.id);
      final entries = await repo.getGridEntries(sampleContainer.id);
      expect(periods.length, equals(5));
      expect(breaks.length, equals(1));
      expect(entries.length, equals(2));
    });

    // =========================================================================
    // 9. ATTENDANCE QUERY INTEGRATION
    // =========================================================================
    test('9. Attendance faculty and student schedule queries reflect only published state', () async {
      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveBreaksBatch(sampleContainer.id, sampleBreaks);
      await repo.saveGridEntriesBatch(sampleContainer.id, sampleEntries);

      // Faculty Alan queries assigned classes before publish -> Empty
      var alanClasses = await repo.getTimetable(facultyId: 'fac-alan', collegeId: 'c1');
      expect(alanClasses.isEmpty, isTrue);

      // Publish
      await repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs');

      // Faculty Alan queries assigned classes after publish -> Finds DBMS
      alanClasses = await repo.getTimetable(facultyId: 'fac-alan', collegeId: 'c1');
      expect(alanClasses.length, equals(1));
      expect(alanClasses.first.subjectId, equals('sub-dbms'));

      // Student Bob queries section timetable -> Finds DBMS & OS Lab
      final studentSchedule = await repo.getTimetable(sectionId: 'sec-4a', collegeId: 'c1');
      expect(studentSchedule.length, equals(2));
    });

    // =========================================================================
    // 10. FACULTY CONFLICT BLOCKS PUBLISHING
    // =========================================================================
    test('10. Faculty conflict on same day/period blocks publishing', () async {
      final conflictEntries = [
        TimetableGridEntryModel(
          id: 'e1',
          dayOfWeek: TimetableDay.tuesday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-dbms',
          facultyId: 'fac-alan',
          roomNumber: 'LH-101',
          sessionType: TimetableSessionType.lecture,
        ),
        TimetableGridEntryModel(
          id: 'e2',
          dayOfWeek: TimetableDay.tuesday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-os',
          facultyId: 'fac-alan', // Same faculty
          roomNumber: 'LH-102',
          sessionType: TimetableSessionType.lecture,
        ),
      ];

      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveGridEntriesBatch(sampleContainer.id, conflictEntries);

      expect(
        () => repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs'),
        throwsA(isA<TimetableConflictException>()),
      );
    });

    // =========================================================================
    // 11. ROOM CONFLICT BLOCKS PUBLISHING
    // =========================================================================
    test('11. Room conflict on same day/period blocks publishing', () async {
      final conflictEntries = [
        TimetableGridEntryModel(
          id: 'e1',
          dayOfWeek: TimetableDay.wednesday,
          startPeriodIndex: 2,
          periodSpan: 1,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: 'sub-dbms',
          facultyId: 'fac-alan',
          roomNumber: 'LH-201',
          sessionType: TimetableSessionType.lecture,
        ),
        TimetableGridEntryModel(
          id: 'e2',
          dayOfWeek: TimetableDay.wednesday,
          startPeriodIndex: 2,
          periodSpan: 1,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: 'sub-os',
          facultyId: 'fac-grace',
          roomNumber: 'LH-201', // Same room
          sessionType: TimetableSessionType.lecture,
        ),
      ];

      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveGridEntriesBatch(sampleContainer.id, conflictEntries);

      expect(
        () => repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs'),
        throwsA(isA<TimetableConflictException>()),
      );
    });

    // =========================================================================
    // 12. REALTIME WATCH TIMETABLE EMITS PUBLISHED STATE
    // =========================================================================
    test('12. watchTimetable stream emits updated schedule on publish without requiring restart', () async {
      await repo.createTimetableContainer(sampleContainer);
      await repo.savePeriodsBatch(sampleContainer.id, samplePeriods);
      await repo.saveGridEntriesBatch(sampleContainer.id, sampleEntries);

      final stream = repo.watchTimetable(userId: 'usr-student-bob', role: AppRole.student, collegeId: 'c1', sectionId: 'sec-4a');

      expect(
        stream,
        emitsInOrder([
          isEmpty, // Initial state before publish
          hasLength(2), // Emits 2 entries after publish
        ]),
      );

      // Trigger Publish
      await repo.publishTimetable(sampleContainer.id, publishedBy: 'usr-hod-cs');
    });
  });
}
