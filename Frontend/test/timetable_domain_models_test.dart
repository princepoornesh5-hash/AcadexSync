import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';

void main() {
  group('ACADEX Phase 2: Timetable Domain Models & Grid Span Engine Tests', () {
    
    // =========================================================================
    // A & B: Enum Serialization, Display Names & Fallbacks
    // =========================================================================
    group('1. Enums Serialization & Fallback', () {
      test('A. TimetableStatus serialization, display name and fallbacks', () {
        expect(TimetableStatus.draft.name, 'draft');
        expect(TimetableStatus.draft.displayName, 'Draft');
        expect(TimetableStatus.published.displayName, 'Published');
        expect(TimetableStatus.archived.displayName, 'Archived');

        expect(TimetableStatus.fromString('draft'), TimetableStatus.draft);
        expect(TimetableStatus.fromString('PUBLISHED'), TimetableStatus.published);
        expect(TimetableStatus.fromString('archived'), TimetableStatus.archived);
        expect(TimetableStatus.fromString('unknown_status'), TimetableStatus.draft);
        expect(TimetableStatus.fromString(null), TimetableStatus.draft);
      });

      test('B. TimetableTimingMode serialization, display name and fallbacks', () {
        expect(TimetableTimingMode.sameEveryDay.name, 'sameEveryDay');
        expect(TimetableTimingMode.sameEveryDay.displayName, 'Same Timing Every Day');
        expect(TimetableTimingMode.differentPerDay.displayName, 'Different Timing Per Day');

        expect(TimetableTimingMode.fromString('sameEveryDay'), TimetableTimingMode.sameEveryDay);
        expect(TimetableTimingMode.fromString('differentPerDay'), TimetableTimingMode.differentPerDay);
        expect(TimetableTimingMode.fromString('invalid_mode'), TimetableTimingMode.sameEveryDay);
        expect(TimetableTimingMode.fromString(null), TimetableTimingMode.sameEveryDay);
      });

      test('C. TimetableBreakType serialization, display name and fallbacks', () {
        expect(TimetableBreakType.lunch.displayName, 'Lunch Break');
        expect(TimetableBreakType.tea.displayName, 'Tea Break');
        expect(TimetableBreakType.assembly.displayName, 'Assembly');
        expect(TimetableBreakType.custom.displayName, 'Custom Break');

        expect(TimetableBreakType.fromString('lunch'), TimetableBreakType.lunch);
        expect(TimetableBreakType.fromString('tea'), TimetableBreakType.tea);
        expect(TimetableBreakType.fromString('assembly'), TimetableBreakType.assembly);
        expect(TimetableBreakType.fromString('custom'), TimetableBreakType.custom);
        expect(TimetableBreakType.fromString('unknown'), TimetableBreakType.lunch);
        expect(TimetableBreakType.fromString(null), TimetableBreakType.lunch);
      });
    });

    // =========================================================================
    // C: TimetableContainerModel
    // =========================================================================
    group('2. TimetableContainerModel', () {
      final now = DateTime.now();

      test('Container model creation, getters, and copyWith', () {
        final container = TimetableContainerModel(
          id: 'tt-cont-1',
          collegeId: 'col-1',
          departmentId: 'dept-cse',
          courseId: 'crs-btech',
          academicYearId: 'ay-2026',
          semesterId: 'sem-4',
          sectionId: 'sec-a',
          name: 'CSE Sem 4 Sec A',
          status: TimetableStatus.draft,
          version: 1,
          activeDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday, TimetableDay.thursday, TimetableDay.friday],
          timingMode: TimetableTimingMode.sameEveryDay,
          createdAt: now,
          updatedAt: now,
        );

        expect(container.isDraft, isTrue);
        expect(container.isPublished, isFalse);
        expect(container.isArchived, isFalse);

        final published = container.copyWith(
          status: TimetableStatus.published,
          publishedAt: now,
          publishedBy: 'usr-admin-1',
        );

        expect(published.isDraft, isFalse);
        expect(published.isPublished, isTrue);
        expect(published.publishedBy, 'usr-admin-1');

        final reverted = published.copyWith(clearPublished: true, status: TimetableStatus.draft);
        expect(reverted.publishedAt, isNull);
        expect(reverted.publishedBy, isNull);
      });

      test('Container model JSON round-trip serialization', () {
        final container = TimetableContainerModel(
          id: 'tt-cont-1',
          collegeId: 'col-1',
          departmentId: 'dept-cse',
          courseId: 'crs-btech',
          academicYearId: 'ay-2026',
          semesterId: 'sem-4',
          sectionId: 'sec-a',
          name: 'CSE Sem 4 Sec A',
          status: TimetableStatus.published,
          version: 2,
          activeDays: [TimetableDay.monday, TimetableDay.wednesday, TimetableDay.friday],
          timingMode: TimetableTimingMode.differentPerDay,
          createdAt: now,
          updatedAt: now,
          publishedAt: now,
          publishedBy: 'usr-hod-1',
        );

        final json = container.toJson();
        expect(json['id'], 'tt-cont-1');
        expect(json['status'], 'published');
        expect(json['timingMode'], 'differentPerDay');
        expect(json['activeDays'], ['monday', 'wednesday', 'friday']);
        expect(json['publishedBy'], 'usr-hod-1');

        final fromJson = TimetableContainerModel.fromJson(json);
        expect(fromJson.id, container.id);
        expect(fromJson.status, TimetableStatus.published);
        expect(fromJson.timingMode, TimetableTimingMode.differentPerDay);
        expect(fromJson.activeDays.length, 3);
        expect(fromJson.activeDays[0], TimetableDay.monday);
        expect(fromJson.activeDays[1], TimetableDay.wednesday);
        expect(fromJson.activeDays[2], TimetableDay.friday);
        expect(fromJson.publishedBy, 'usr-hod-1');
      });

      test('Container model validation logic', () {
        final validContainer = TimetableContainerModel(
          id: 'tt-1',
          collegeId: 'col-1',
          departmentId: 'dept-1',
          courseId: 'crs-1',
          academicYearId: 'ay-1',
          semesterId: 'sem-1',
          sectionId: 'sec-1',
          name: 'Valid Name',
          createdAt: now,
          updatedAt: now,
        );

        expect(() => validContainer.validate(), returnsNormally);

        final emptyName = validContainer.copyWith(name: '   ');
        expect(() => emptyName.validate(), throwsA(isA<ArgumentError>()));

        final noActiveDays = validContainer.copyWith(activeDays: []);
        expect(() => noActiveDays.validate(), throwsA(isA<ArgumentError>()));

        final invalidVersion = validContainer.copyWith(version: 0);
        expect(() => invalidVersion.validate(), throwsA(isA<ArgumentError>()));
      });
    });

    // =========================================================================
    // D: TimetablePeriodModel
    // =========================================================================
    group('3. TimetablePeriodModel', () {
      test('Period model creation, duration calculation and copyWith', () {
        final period = TimetablePeriodModel(
          id: 'p-1',
          index: 1,
          name: 'Period 1',
          startTime: '09:00',
          endTime: '10:00',
        );

        expect(period.index, 1);
        expect(period.durationInMinutes, 60);
        expect(period.dayOfWeek, isNull);

        final daySpecific = period.copyWith(dayOfWeek: TimetableDay.friday, name: 'Friday P1');
        expect(daySpecific.dayOfWeek, TimetableDay.friday);
        expect(daySpecific.name, 'Friday P1');

        final sharedAgain = daySpecific.copyWith(clearDayOfWeek: true);
        expect(sharedAgain.dayOfWeek, isNull);
      });

      test('Period model JSON round-trip serialization', () {
        final period = TimetablePeriodModel(
          id: 'p-2',
          index: 2,
          name: 'Period 2',
          startTime: '10:00',
          endTime: '11:15',
          dayOfWeek: TimetableDay.monday,
        );

        final json = period.toJson();
        expect(json['id'], 'p-2');
        expect(json['index'], 2);
        expect(json['startTime'], '10:00');
        expect(json['endTime'], '11:15');
        expect(json['dayOfWeek'], 'monday');

        final fromJson = TimetablePeriodModel.fromJson(json);
        expect(fromJson.id, period.id);
        expect(fromJson.index, 2);
        expect(fromJson.durationInMinutes, 75);
        expect(fromJson.dayOfWeek, TimetableDay.monday);
      });

      test('Period model validation constraints', () {
        final validPeriod = TimetablePeriodModel(
          id: 'p-1',
          index: 1,
          name: 'Period 1',
          startTime: '09:00',
          endTime: '10:00',
        );
        expect(() => validPeriod.validate(), returnsNormally);

        // Invalid index
        final invalidIndex = validPeriod.copyWith(index: 0);
        expect(() => invalidIndex.validate(), throwsA(isA<ArgumentError>()));

        // Empty name
        final emptyName = validPeriod.copyWith(name: '  ');
        expect(() => emptyName.validate(), throwsA(isA<ArgumentError>()));

        // Start >= End
        final invalidTimeRange = validPeriod.copyWith(startTime: '10:00', endTime: '09:00');
        expect(() => invalidTimeRange.validate(), throwsA(isA<ArgumentError>()));

        // Equal times
        final equalTimes = validPeriod.copyWith(startTime: '09:00', endTime: '09:00');
        expect(() => equalTimes.validate(), throwsA(isA<ArgumentError>()));

        // Invalid format
        final badFormat = validPeriod.copyWith(startTime: '9:00');
        expect(() => badFormat.validate(), throwsA(isA<ArgumentError>()));
      });
    });

    // =========================================================================
    // E: TimetableBreakModel
    // =========================================================================
    group('4. TimetableBreakModel', () {
      test('Break model multi-day support, duration, and time overlap', () {
        final lunchBreak = TimetableBreakModel(
          id: 'brk-lunch',
          name: 'Lunch Break',
          startTime: '13:00',
          endTime: '14:00',
          appliesToDays: [
            TimetableDay.monday,
            TimetableDay.tuesday,
            TimetableDay.wednesday,
            TimetableDay.thursday,
            TimetableDay.friday,
          ],
          isVerticalSpan: true,
          breakType: TimetableBreakType.lunch,
        );

        expect(lunchBreak.durationInMinutes, 60);
        expect(lunchBreak.appliesTo(TimetableDay.monday), isTrue);
        expect(lunchBreak.appliesTo(TimetableDay.friday), isTrue);
        expect(lunchBreak.appliesTo(TimetableDay.saturday), isFalse);

        // Time overlap checks
        expect(lunchBreak.overlapsWithTime('13:30', '14:30'), isTrue);
        expect(lunchBreak.overlapsWithTime('12:00', '13:30'), isTrue);
        expect(lunchBreak.overlapsWithTime('12:00', '13:00'), isFalse); // adjacent
        expect(lunchBreak.overlapsWithTime('14:00', '15:00'), isFalse); // adjacent
        expect(lunchBreak.overlapsWithTime('09:00', '10:00'), isFalse); // completely before
      });

      test('Break model JSON round-trip serialization', () {
        final teaBreak = TimetableBreakModel(
          id: 'brk-tea',
          name: 'Tea Break',
          startTime: '11:00',
          endTime: '11:15',
          appliesToDays: [TimetableDay.tuesday, TimetableDay.thursday],
          isVerticalSpan: false,
          breakType: TimetableBreakType.tea,
        );

        final json = teaBreak.toJson();
        expect(json['name'], 'Tea Break');
        expect(json['breakType'], 'tea');
        expect(json['appliesToDays'], ['tuesday', 'thursday']);
        expect(json['isVerticalSpan'], isFalse);

        final fromJson = TimetableBreakModel.fromJson(json);
        expect(fromJson.name, teaBreak.name);
        expect(fromJson.durationInMinutes, 15);
        expect(fromJson.breakType, TimetableBreakType.tea);
        expect(fromJson.appliesToDays, [TimetableDay.tuesday, TimetableDay.thursday]);
      });

      test('Break model validation', () {
        final validBreak = TimetableBreakModel(
          id: 'brk-1',
          name: 'Assembly',
          startTime: '08:45',
          endTime: '09:00',
          appliesToDays: [TimetableDay.monday],
        );
        expect(() => validBreak.validate(), returnsNormally);

        final noDays = validBreak.copyWith(appliesToDays: []);
        expect(() => noDays.validate(), throwsA(isA<ArgumentError>()));

        final invalidTimes = validBreak.copyWith(startTime: '09:30', endTime: '09:00');
        expect(() => invalidTimes.validate(), throwsA(isA<ArgumentError>()));
      });
    });

    // =========================================================================
    // F - M: TimetableGridEntryModel & Grid Span Engine
    // =========================================================================
    group('5. TimetableGridEntryModel & Span Engine', () {
      test('G. Single-period span calculation', () {
        final single = TimetableGridEntryModel(
          id: 'e-1',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 1,
          periodSpan: 1,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: 'sub-algo',
          facultyId: 'fac-1',
          roomNumber: 'LH-101',
          sessionType: TimetableSessionType.lecture,
        );

        expect(single.isMergedHorizontal, isFalse);
        expect(single.endPeriodIndex, 1);
        expect(single.occupiedPeriodIndexes, [1]);
        expect(single.occupiesPeriod(1), isTrue);
        expect(single.occupiesPeriod(2), isFalse);
      });

      test('H. Two-period horizontal merged class calculation', () {
        final twoPeriodLab = TimetableGridEntryModel(
          id: 'e-2',
          dayOfWeek: TimetableDay.tuesday,
          startPeriodIndex: 1,
          periodSpan: 2,
          startTime: '09:00',
          endTime: '11:00',
          subjectId: 'sub-dbms-lab',
          facultyId: 'fac-2',
          roomNumber: 'Lab-1',
          sessionType: TimetableSessionType.lab,
        );

        expect(twoPeriodLab.isMergedHorizontal, isTrue);
        expect(twoPeriodLab.startPeriodIndex, 1);
        expect(twoPeriodLab.endPeriodIndex, 2);
        expect(twoPeriodLab.occupiedPeriodIndexes, [1, 2]);
        expect(twoPeriodLab.occupiesPeriod(1), isTrue);
        expect(twoPeriodLab.occupiesPeriod(2), isTrue);
        expect(twoPeriodLab.occupiesPeriod(3), isFalse);
      });

      test('I & J & K. Three-period span calculation and occupied periods', () {
        final threePeriodSeminar = TimetableGridEntryModel(
          id: 'e-3',
          dayOfWeek: TimetableDay.wednesday,
          startPeriodIndex: 2,
          periodSpan: 3,
          startTime: '10:00',
          endTime: '13:00',
          subjectId: 'sub-project',
          facultyId: 'fac-3',
          roomNumber: 'Auditorium',
          sessionType: TimetableSessionType.seminar,
        );

        expect(threePeriodSeminar.isMergedHorizontal, isTrue);
        expect(threePeriodSeminar.startPeriodIndex, 2);
        expect(threePeriodSeminar.periodSpan, 3);
        expect(threePeriodSeminar.endPeriodIndex, 4);
        expect(threePeriodSeminar.occupiedPeriodIndexes, [2, 3, 4]);

        expect(threePeriodSeminar.occupiesPeriod(1), isFalse);
        expect(threePeriodSeminar.occupiesPeriod(2), isTrue);
        expect(threePeriodSeminar.occupiesPeriod(3), isTrue);
        expect(threePeriodSeminar.occupiesPeriod(4), isTrue);
        expect(threePeriodSeminar.occupiesPeriod(5), isFalse);
      });

      test('L. Horizontal overlap detection between grid entries', () {
        final entryA = TimetableGridEntryModel(
          id: 'e-a',
          dayOfWeek: TimetableDay.thursday,
          startPeriodIndex: 1,
          periodSpan: 2, // Periods 1, 2
          startTime: '09:00',
          endTime: '11:00',
          subjectId: 'sub-1',
          facultyId: 'fac-1',
          roomNumber: '101',
          sessionType: TimetableSessionType.lecture,
        );

        final entryB = TimetableGridEntryModel(
          id: 'e-b',
          dayOfWeek: TimetableDay.thursday,
          startPeriodIndex: 2,
          periodSpan: 2, // Periods 2, 3 (overlaps at period 2)
          startTime: '10:00',
          endTime: '12:00',
          subjectId: 'sub-2',
          facultyId: 'fac-2',
          roomNumber: '102',
          sessionType: TimetableSessionType.lecture,
        );

        final entryC = TimetableGridEntryModel(
          id: 'e-c',
          dayOfWeek: TimetableDay.thursday,
          startPeriodIndex: 3,
          periodSpan: 1, // Period 3 (no overlap with entryA)
          startTime: '11:00',
          endTime: '12:00',
          subjectId: 'sub-3',
          facultyId: 'fac-3',
          roomNumber: '103',
          sessionType: TimetableSessionType.lecture,
        );

        final entryDifferentDay = TimetableGridEntryModel(
          id: 'e-diff-day',
          dayOfWeek: TimetableDay.friday,
          startPeriodIndex: 1,
          periodSpan: 2,
          startTime: '09:00',
          endTime: '11:00',
          subjectId: 'sub-4',
          facultyId: 'fac-4',
          roomNumber: '104',
          sessionType: TimetableSessionType.lecture,
        );

        // A (1..2) and B (2..3) overlap at period 2
        expect(entryA.overlapsHorizontallyWith(entryB), isTrue);
        expect(entryB.overlapsHorizontallyWith(entryA), isTrue);

        // A (1..2) and C (3) do not overlap
        expect(entryA.overlapsHorizontallyWith(entryC), isFalse);
        expect(entryC.overlapsHorizontallyWith(entryA), isFalse);

        // B (2..3) and C (3) overlap at period 3
        expect(entryB.overlapsHorizontallyWith(entryC), isTrue);

        // Different day never overlaps horizontally
        expect(entryA.overlapsHorizontallyWith(entryDifferentDay), isFalse);
      });

      test('M. Entry vs Break collision detection', () {
        final lunch = TimetableBreakModel(
          id: 'brk-lunch',
          name: 'Lunch',
          startTime: '13:00',
          endTime: '14:00',
          appliesToDays: [TimetableDay.monday, TimetableDay.tuesday, TimetableDay.wednesday],
        );

        // Overlaps on Monday (12:30 - 13:30)
        final overlappingEntry = TimetableGridEntryModel(
          id: 'e-overlap',
          dayOfWeek: TimetableDay.monday,
          startPeriodIndex: 4,
          periodSpan: 1,
          startTime: '12:30',
          endTime: '13:30',
          subjectId: 'sub-1',
          facultyId: 'fac-1',
          roomNumber: '101',
          sessionType: TimetableSessionType.lecture,
        );
        expect(overlappingEntry.conflictsWithBreak(lunch), isTrue);

        // Same time, but on Thursday (Break does not apply to Thursday)
        final thursdayEntry = overlappingEntry.copyWith(dayOfWeek: TimetableDay.thursday);
        expect(thursdayEntry.conflictsWithBreak(lunch), isFalse);

        // Monday, but morning class (09:00 - 10:00) -> No conflict
        final morningEntry = overlappingEntry.copyWith(startTime: '09:00', endTime: '10:00');
        expect(morningEntry.conflictsWithBreak(lunch), isFalse);
      });

      test('N & O & P. Grid Entry validation rejection rules', () {
        final valid = TimetableGridEntryModel(
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
        );
        expect(() => valid.validate(), returnsNormally);

        // Invalid start period index (< 1)
        final invalidStart = valid.copyWith(startPeriodIndex: 0);
        expect(() => invalidStart.validate(), throwsA(isA<ArgumentError>()));

        // Invalid period span (< 1)
        final invalidSpan = valid.copyWith(periodSpan: 0);
        expect(() => invalidSpan.validate(), throwsA(isA<ArgumentError>()));

        // Invalid time range (startTime >= endTime)
        final invalidTimes = valid.copyWith(startTime: '10:00', endTime: '09:00');
        expect(() => invalidTimes.validate(), throwsA(isA<ArgumentError>()));

        // Invalid time string format
        final badFormat = valid.copyWith(startTime: '9:00 AM');
        expect(() => badFormat.validate(), throwsA(isA<ArgumentError>()));
      });

      test('R. Grid entry JSON round-trip serialization', () {
        final entry = TimetableGridEntryModel(
          id: 'e-roundtrip',
          dayOfWeek: TimetableDay.friday,
          startPeriodIndex: 2,
          periodSpan: 3,
          startTime: '10:00',
          endTime: '13:00',
          subjectId: 'sub-iot',
          facultyId: 'fac-iot',
          roomNumber: 'IoT-Lab',
          building: 'Tech Block',
          sessionType: TimetableSessionType.practical,
        );

        final json = entry.toJson();
        expect(json['id'], 'e-roundtrip');
        expect(json['dayOfWeek'], 'friday');
        expect(json['startPeriodIndex'], 2);
        expect(json['periodSpan'], 3);
        expect(json['isMergedHorizontal'], isTrue);
        expect(json['building'], 'Tech Block');

        final fromJson = TimetableGridEntryModel.fromJson(json);
        expect(fromJson.id, entry.id);
        expect(fromJson.dayOfWeek, TimetableDay.friday);
        expect(fromJson.startPeriodIndex, 2);
        expect(fromJson.periodSpan, 3);
        expect(fromJson.endPeriodIndex, 4);
        expect(fromJson.occupiedPeriodIndexes, [2, 3, 4]);
        expect(fromJson.building, 'Tech Block');
        expect(fromJson.sessionType, TimetableSessionType.practical);
      });
    });

    // =========================================================================
    // S: Legacy TimetableModel Backward Compatibility Verification
    // =========================================================================
    group('6. Legacy TimetableModel Backward Compatibility', () {
      final now = DateTime.now();

      test('Existing TimetableModel remains 100% functional and backward-compatible', () {
        final legacy = TimetableModel(
          id: 'tt-legacy-1',
          collegeId: 'col-1',
          departmentId: 'dept-cse',
          courseId: 'crs-btech',
          academicYearId: 'ay-2026',
          semesterId: 'sem-4',
          sectionId: 'sec-3a',
          subjectId: 'sub-ds',
          facultyId: 'fac-1',
          dayOfWeek: TimetableDay.monday,
          startTime: '09:00',
          endTime: '10:00',
          roomNumber: 'C-204',
          building: 'Main Block',
          sessionType: TimetableSessionType.lecture,
          createdAt: now,
          updatedAt: now,
        );

        final json = legacy.toJson();
        expect(json['id'], 'tt-legacy-1');
        expect(json['dayOfWeek'], 'monday');
        expect(json['sessionType'], 'lecture');

        final reconstructed = TimetableModel.fromJson(json);
        expect(reconstructed.id, legacy.id);
        expect(reconstructed.collegeId, 'col-1');
        expect(reconstructed.subjectId, 'sub-ds');
        expect(reconstructed.startTime, '09:00');
        expect(reconstructed.endTime, '10:00');

        final overlapping = legacy.copyWith(startTime: '09:30', endTime: '10:30');
        expect(legacy.overlapsWith(overlapping), isTrue);

        final nonOverlapping = legacy.copyWith(startTime: '10:00', endTime: '11:00');
        expect(legacy.overlapsWith(nonOverlapping), isFalse);
      });
    });
  });
}
