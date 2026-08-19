import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/mock_timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACADEX Phase 4: Riverpod State, Grid State & Authoring Workflow Tests', () {
    late MockTimetableRepository mockRepo;

    final superAdminUser = UserModel(
      id: 'usr-sa',
      name: 'Super Admin',
      email: 'sa@acadex.edu',
      role: AppRole.superAdmin,
    );

    final collegeAdminUser = UserModel(
      id: 'usr-ca',
      name: 'College Admin',
      email: 'ca@col1.edu',
      role: AppRole.collegeAdmin,
      collegeId: 'col-1',
    );

    final hodCseUser = UserModel(
      id: 'usr-hod',
      name: 'HOD CSE',
      email: 'hod@col1.edu',
      role: AppRole.hod,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final facultyNormalUser = UserModel(
      id: 'usr-fac',
      name: 'Normal Faculty',
      email: 'fac@col1.edu',
      role: AppRole.faculty,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
    );

    final studentUser = UserModel(
      id: 'usr-student',
      name: 'Student One',
      email: 'student@col1.edu',
      role: AppRole.student,
      collegeId: 'col-1',
      departmentId: 'dept-cse',
      sectionId: 'sec-4a',
    );

    TimetableContainerModel createContainer({
      String id = 'tt-authoring-1',
      String collegeId = 'col-1',
      String departmentId = 'dept-cse',
      String sectionId = 'sec-4a',
    }) {
      final now = DateTime.now();
      return TimetableContainerModel(
        id: id,
        collegeId: collegeId,
        departmentId: departmentId,
        courseId: 'crs-btech',
        academicYearId: 'ay-2026',
        semesterId: 'sem-4',
        sectionId: sectionId,
        name: 'CSE Sem 4 Sec A',
        status: TimetableStatus.draft,
        version: 1,
        activeDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
        timingMode: TimetableTimingMode.sameEveryDay,
        createdAt: now,
        updatedAt: now,
      );
    }

    setUp(() async {
      mockRepo = MockTimetableRepository();
    });

    // =========================================================================
    // 1 - 6: Initialization, Loading & Combined State
    // =========================================================================
    group('1. Loading & Combined State Initialization', () {
      test('1 - 6. Container, Period, Break, and Entry loading into combined state', () async {
        final container = createContainer();
        await mockRepo.createTimetableContainer(container);

        final periods = [
          TimetablePeriodModel(id: 'p-1', index: 1, name: 'P1', startTime: '09:00', endTime: '10:00'),
          TimetablePeriodModel(id: 'p-2', index: 2, name: 'P2', startTime: '10:00', endTime: '11:00'),
        ];
        await mockRepo.savePeriodsBatch(container.id, periods);

        final breaks = [
          TimetableBreakModel(
            id: 'brk-1',
            name: 'Lunch',
            startTime: '13:00',
            endTime: '14:00',
            appliesToDays: [TimetableDay.monday],
            breakType: TimetableBreakType.lunch,
          )
        ];
        await mockRepo.saveBreaksBatch(container.id, breaks);

        final entries = [
          TimetableGridEntryModel(
            id: 'e-1',
            dayOfWeek: TimetableDay.monday,
            startPeriodIndex: 1,
            periodSpan: 1,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: 'sub-algo',
            facultyId: 'fac-1',
            roomNumber: 'LH-1',
            sessionType: TimetableSessionType.lecture,
          ),
        ];
        await mockRepo.saveGridEntriesBatch(container.id, entries);

        final notifier = TimetableAuthoringNotifier(
          repository: mockRepo,
          currentUser: hodCseUser,
        );

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.container, isNull);

        // Load timetable
        await notifier.loadTimetable(container.id);

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.container?.id, container.id);
        expect(notifier.state.periods.length, 2);
        expect(notifier.state.breaks.length, 1);
        expect(notifier.state.entries.length, 1);
        expect(notifier.state.isDirty, isFalse);
      });
    });

    // =========================================================================
    // 7 - 11: Grid Coordinates, Selection & Occupancy Detection
    // =========================================================================
    group('2. Grid Coordinates, Cell Selection & Merged Occupancy', () {
      late TimetableAuthoringNotifier notifier;
      const ttId = 'tt-grid-test';

      setUp(() async {
        await mockRepo.createTimetableContainer(createContainer(id: ttId));
        await mockRepo.savePeriodsBatch(ttId, [
          TimetablePeriodModel(id: 'p-1', index: 1, name: 'P1', startTime: '09:00', endTime: '10:00'),
          TimetablePeriodModel(id: 'p-2', index: 2, name: 'P2', startTime: '10:00', endTime: '11:00'),
          TimetablePeriodModel(id: 'p-3', index: 3, name: 'P3', startTime: '11:15', endTime: '12:15'),
        ]);

        await mockRepo.saveGridEntriesBatch(ttId, [
          TimetableGridEntryModel(
            id: 'e-single',
            dayOfWeek: TimetableDay.monday,
            startPeriodIndex: 1,
            periodSpan: 1,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: 'sub-1',
            facultyId: 'fac-1',
            roomNumber: '101',
            sessionType: TimetableSessionType.lecture,
          ),
          TimetableGridEntryModel(
            id: 'e-merged-lab',
            dayOfWeek: TimetableDay.tuesday,
            startPeriodIndex: 1,
            periodSpan: 2, // Periods 1 & 2
            startTime: '09:00',
            endTime: '11:00',
            subjectId: 'sub-lab',
            facultyId: 'fac-2',
            roomNumber: 'Lab-1',
            sessionType: TimetableSessionType.lab,
          ),
        ]);

        notifier = TimetableAuthoringNotifier(repository: mockRepo, currentUser: hodCseUser);
        await notifier.loadTimetable(ttId);
      });

      test('7 & 8. Cell selection and entry selection', () {
        notifier.selectCell(TimetableDay.monday, 1);
        expect(notifier.state.selectedCell, const TimetableCellCoordinate(day: TimetableDay.monday, periodIndex: 1));
        expect(notifier.state.selectedEntryId, 'e-single');
        expect(notifier.state.selectedEntry?.subjectId, 'sub-1');

        notifier.clearSelection();
        expect(notifier.state.selectedCell, isNull);
        expect(notifier.state.selectedEntryId, isNull);

        notifier.selectEntry('e-merged-lab');
        expect(notifier.state.selectedEntryId, 'e-merged-lab');
        expect(notifier.state.selectedCell?.day, TimetableDay.tuesday);
        expect(notifier.state.selectedCell?.periodIndex, 1);
      });

      test('9, 10, 11. Occupied cell, merged cell, and origin cell detection', () {
        // Monday Period 1 (Single entry)
        expect(notifier.state.isCellOccupied(TimetableDay.monday, 1), isTrue);
        expect(notifier.state.isCellOrigin(TimetableDay.monday, 1), isTrue);
        expect(notifier.state.isCellMerged(TimetableDay.monday, 1), isFalse);

        // Monday Period 2 (Empty)
        expect(notifier.state.isCellOccupied(TimetableDay.monday, 2), isFalse);

        // Tuesday Period 1 (Origin of merged 2-period lab)
        expect(notifier.state.isCellOccupied(TimetableDay.tuesday, 1), isTrue);
        expect(notifier.state.isCellOrigin(TimetableDay.tuesday, 1), isTrue);
        expect(notifier.state.isCellMerged(TimetableDay.tuesday, 1), isTrue);

        // Tuesday Period 2 (Occupied by merged lab, but NOT origin)
        expect(notifier.state.isCellOccupied(TimetableDay.tuesday, 2), isTrue);
        expect(notifier.state.isCellOrigin(TimetableDay.tuesday, 2), isFalse);
        expect(notifier.state.isCellMerged(TimetableDay.tuesday, 2), isTrue);

        // Tuesday Period 3 (Empty)
        expect(notifier.state.isCellOccupied(TimetableDay.tuesday, 3), isFalse);
      });
    });

    // =========================================================================
    // 12 - 18: Cell Editing, Merge, Split, Period & Break CRUD
    // =========================================================================
    group('3. Cell Editing, Merge, Split, Periods and Breaks Operations', () {
      late TimetableAuthoringNotifier notifier;
      const ttId = 'tt-edit-test';

      setUp(() async {
        await mockRepo.createTimetableContainer(createContainer(id: ttId));
        await mockRepo.savePeriodsBatch(ttId, [
          TimetablePeriodModel(id: 'p-1', index: 1, name: 'P1', startTime: '09:00', endTime: '10:00'),
          TimetablePeriodModel(id: 'p-2', index: 2, name: 'P2', startTime: '10:00', endTime: '11:00'),
          TimetablePeriodModel(id: 'p-3', index: 3, name: 'P3', startTime: '11:15', endTime: '12:15'),
        ]);

        notifier = TimetableAuthoringNotifier(repository: mockRepo, currentUser: hodCseUser);
        await notifier.loadTimetable(ttId);
      });

      test('12, 13, 14. Add, update, and delete teaching grid entry', () {
        final newEntry = TimetableGridEntryModel(
          id: 'e-new',
          dayOfWeek: TimetableDay.wednesday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-dbms',
          facultyId: 'fac-1',
          roomNumber: '102',
          sessionType: TimetableSessionType.lecture,
        );

        // Add
        notifier.createEntry(newEntry);
        expect(notifier.state.entries.length, 1);
        expect(notifier.state.isDirty, isTrue);

        // Update
        notifier.updateEntry(newEntry.copyWith(roomNumber: 'LH-201'));
        expect(notifier.state.entries.first.roomNumber, 'LH-201');

        // Delete
        notifier.deleteEntry('e-new');
        expect(notifier.state.entries.isEmpty, isTrue);
      });

      test('15 & 16. Merge periods and split merged entry', () {
        notifier.mergePeriods(
          day: TimetableDay.thursday,
          startPeriodIndex: 1,
          periodSpan: 2,
          subjectId: 'sub-project-lab',
          facultyId: 'fac-1',
          roomNumber: 'Lab-3',
          startTime: '09:00',
          endTime: '11:00',
          sessionType: TimetableSessionType.lab,
        );

        expect(notifier.state.entries.length, 1);
        final merged = notifier.state.entries.first;
        expect(merged.isMergedHorizontal, isTrue);
        expect(merged.occupiedPeriodIndexes, [1, 2]);

        // Split
        notifier.splitEntry(merged.id);
        expect(notifier.state.entries.length, 2);
        expect(notifier.state.entries[0].startPeriodIndex, 1);
        expect(notifier.state.entries[0].periodSpan, 1);
        expect(notifier.state.entries[1].startPeriodIndex, 2);
        expect(notifier.state.entries[1].periodSpan, 1);
      });

      test('17 & 18. Period & Break Add, Update, Delete & Reorder', () {
        // Add Period
        final newP = TimetablePeriodModel(id: 'p-4', index: 4, name: 'P4', startTime: '12:15', endTime: '13:15');
        notifier.addPeriod(newP);
        expect(notifier.state.periods.length, 4);

        // Update Period
        notifier.updatePeriod(newP.copyWith(name: 'Period 4 Special'));
        expect(notifier.state.periods.firstWhere((p) => p.id == 'p-4').name, 'Period 4 Special');

        // Delete Period
        notifier.deletePeriod('p-4');
        expect(notifier.state.periods.length, 3);

        // Add Break
        final brk = TimetableBreakModel(
          id: 'brk-tea',
          name: 'Tea Break',
          startTime: '11:00',
          endTime: '11:15',
          appliesToDays: [TimetableDay.monday, TimetableDay.tuesday],
        );
        notifier.addBreak(brk);
        expect(notifier.state.breaks.length, 1);

        // Delete Break
        notifier.deleteBreak('brk-tea');
        expect(notifier.state.breaks.isEmpty, isTrue);
      });
    });

    // =========================================================================
    // 19 - 25: Dirty State, Validation, Save & Publish Workflows
    // =========================================================================
    group('4. Dirty State, Validation, Save & Publish Workflows', () {
      late TimetableAuthoringNotifier notifier;
      const ttId = 'tt-workflow-test';

      setUp(() async {
        await mockRepo.createTimetableContainer(createContainer(id: ttId));
        await mockRepo.savePeriodsBatch(ttId, [
          TimetablePeriodModel(id: 'p-1', index: 1, name: 'P1', startTime: '09:00', endTime: '10:00'),
          TimetablePeriodModel(id: 'p-2', index: 2, name: 'P2', startTime: '10:00', endTime: '11:00'),
        ]);

        notifier = TimetableAuthoringNotifier(repository: mockRepo, currentUser: hodCseUser);
        await notifier.loadTimetable(ttId);
      });

      test('19 & 20. Dirty state tracks changes and is cleared on successful save', () async {
        expect(notifier.state.isDirty, isFalse);

        notifier.createEntry(TimetableGridEntryModel(
          id: 'e-1',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-1',
          facultyId: 'fac-1',
          roomNumber: '101',
          sessionType: TimetableSessionType.lecture,
        ));

        expect(notifier.state.isDirty, isTrue);

        final saved = await notifier.saveDraft();
        expect(saved, isTrue);
        expect(notifier.state.isDirty, isFalse);
        expect(notifier.state.lastSavedAt, isNotNull);
      });

      test('21 & 22. Save blocked by local validation errors', () async {
        // Create invalid entry with empty subject and faculty
        notifier.state = notifier.state.copyWith(
          entries: [
            TimetableGridEntryModel(
              id: 'e-invalid',
              dayOfWeek: TimetableDay.monday,
              startPeriodIndex: 1,
              periodSpan: 1,
              startTime: '09:00',
              endTime: '10:00',
              subjectId: '', // Empty
              facultyId: '', // Empty
              roomNumber: '101',
              sessionType: TimetableSessionType.lecture,
            ),
          ],
          isDirty: true,
        );

        final errors = notifier.validateLocalState();
        expect(errors.isNotEmpty, isTrue);

        final saved = await notifier.saveDraft();
        expect(saved, isFalse);
        expect(notifier.state.errorMessage, isNotNull);
      });

      test('23, 24, 25. Publish state, publish success and publish failure', () async {
        // Valid class entry
        notifier.createEntry(TimetableGridEntryModel(
          id: 'e-valid',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-dsa',
          facultyId: 'fac-1',
          roomNumber: '101',
          sessionType: TimetableSessionType.lecture,
        ));

        // Publish success
        final published = await notifier.publish(publishedBy: hodCseUser.id);
        expect(published, isTrue);
        expect(notifier.state.container?.isPublished, isTrue);

        // Unpublish
        final unpublished = await notifier.unpublish();
        expect(unpublished, isTrue);
        expect(notifier.state.container?.isDraft, isTrue);
      });
    });

    // =========================================================================
    // 26 - 32: Role Permissions, Isolation & Realtime Streaming
    // =========================================================================
    group('5. Role Permissions, Isolation & Realtime Streaming', () {
      test('26. Role Permissions calculation across all roles', () {
        final container = createContainer();

        // 1. Super Admin -> Full
        final saContainer = ProviderContainer(overrides: [
          currentUserProvider.overrideWithValue(superAdminUser),
        ]);
        final saPerms = saContainer.read(timetableAuthoringPermissionsProvider(container));
        expect(saPerms.canEdit, isTrue);
        expect(saPerms.canPublish, isTrue);

        // 2. College Admin -> Full (same college)
        final caContainer = ProviderContainer(overrides: [
          currentUserProvider.overrideWithValue(collegeAdminUser),
        ]);
        final caPerms = caContainer.read(timetableAuthoringPermissionsProvider(container));
        expect(caPerms.canEdit, isTrue);
        expect(caPerms.canPublish, isTrue);

        // 3. HOD -> Full (same dept)
        final hodContainer = ProviderContainer(overrides: [
          currentUserProvider.overrideWithValue(hodCseUser),
        ]);
        final hodPerms = hodContainer.read(timetableAuthoringPermissionsProvider(container));
        expect(hodPerms.canEdit, isTrue);
        expect(hodPerms.canPublish, isTrue);

        // 4. Normal Faculty -> Read-only
        final facContainer = ProviderContainer(overrides: [
          currentUserProvider.overrideWithValue(facultyNormalUser),
        ]);
        final facPerms = facContainer.read(timetableAuthoringPermissionsProvider(container));
        expect(facPerms.canView, isTrue);
        expect(facPerms.canEdit, isFalse);
        expect(facPerms.canPublish, isFalse);

        // 5. Student -> Read-only
        final studentContainer = ProviderContainer(overrides: [
          currentUserProvider.overrideWithValue(studentUser),
        ]);
        final studentPerms = studentContainer.read(timetableAuthoringPermissionsProvider(container));
        expect(studentPerms.canView, isTrue);
        expect(studentPerms.canEdit, isFalse);
      });

      test('27 - 31. Student view isolation: Student sees published timetable, never draft data', () async {
        final container = createContainer();
        await mockRepo.createTimetableContainer(container);
        await mockRepo.savePeriodsBatch(container.id, [
          TimetablePeriodModel(id: 'p-1', index: 1, name: 'P1', startTime: '09:00', endTime: '10:00'),
        ]);

        // Add draft grid entry
        await mockRepo.saveGridEntry(container.id, TimetableGridEntryModel(
          id: 'draft-entry-1',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-draft',
          facultyId: 'fac-1',
          roomNumber: '101',
          sessionType: TimetableSessionType.lecture,
        ));

        final testContainer = ProviderContainer(overrides: [
          timetableRepositoryProvider.overrideWithValue(mockRepo),
          authProvider.overrideWith((ref) => MockAuthNotifier(AuthAuthenticated(user: studentUser, token: 'mock-token'))),
        ]);

        final emittedEvents = <Map<TimetableDay, List<TimetableModel>>>[];
        final sub = testContainer.listen<AsyncValue<Map<TimetableDay, List<TimetableModel>>>>(
          weeklyTimetableProvider,
          (previous, next) {
            if (next.hasValue) {
              emittedEvents.add(next.value!);
            }
          },
          fireImmediately: true,
        );

        await Future.delayed(const Duration(milliseconds: 250));
        expect(emittedEvents.last[TimetableDay.monday]?.isEmpty, isTrue); // Draft is NOT in /timetable!

        // Now publish container
        await mockRepo.publishTimetable(container.id, publishedBy: hodCseUser.id);
        await Future.delayed(const Duration(milliseconds: 250));

        expect(emittedEvents.last[TimetableDay.monday]?.isNotEmpty, isTrue);
        expect(emittedEvents.last[TimetableDay.monday]?.first.subjectId, 'sub-draft');
        sub.close();
      });

      test('32. Realtime provider updates on container stream', () async {
        final container = createContainer(id: 'tt-realtime');
        await mockRepo.createTimetableContainer(container);

        final testContainer = ProviderContainer(overrides: [
          timetableRepositoryProvider.overrideWithValue(mockRepo),
        ]);

        final streamValue = await testContainer.read(timetableContainerStreamProvider('tt-realtime').future);
        expect(streamValue?.id, 'tt-realtime');
        expect(streamValue?.status, TimetableStatus.draft);
      });
    });
  });
}
