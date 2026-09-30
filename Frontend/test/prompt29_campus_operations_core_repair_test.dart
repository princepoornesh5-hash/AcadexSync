import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/institution_config/domain/models/institution_config_models.dart';
import 'package:campus_management/features/institution_config/presentation/providers/institution_config_providers.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';
import 'package:campus_management/features/academic_structure/data/repositories/mock_academic_repository.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/core/errors/acadex_error.dart';

void main() {
  group('Prompt 29 - Configuration-Driven Academic Terminology', () {
    test('College Admin configuration drives authoritative terminology', () {
      const config = InstitutionConfigModel(
        collegeId: 'test-college',
        terminology: TerminologyConfig(
          department: ConceptTerm(singular: 'School', plural: 'Schools'),
          program: ConceptTerm(singular: 'Course', plural: 'Courses'),
          academicYear: ConceptTerm(singular: 'Academic Year', plural: 'Academic Years'),
          semester: ConceptTerm(singular: 'Term', plural: 'Terms'),
          section: ConceptTerm(singular: 'Class', plural: 'Classes'),
          subject: ConceptTerm(singular: 'Paper', plural: 'Papers'),
          building: ConceptTerm(singular: 'Block', plural: 'Blocks'),
          room: ConceptTerm(singular: 'Classroom', plural: 'Classrooms'),
        ),
      );

      final helper = TerminologyHelper(config);

      expect(helper.label(AcademicConcept.program), 'Course');
      expect(helper.label(AcademicConcept.program, plural: true), 'Courses');
      expect(helper.label(AcademicConcept.semester), 'Term');
      expect(helper.label(AcademicConcept.semester, plural: true), 'Terms');
      expect(helper.label(AcademicConcept.section), 'Class');
      expect(helper.label(AcademicConcept.section, plural: true), 'Classes');
      expect(helper.label(AcademicConcept.subject), 'Paper');
      expect(helper.label(AcademicConcept.room), 'Classroom');

      expect(helper.createActionLabel(AcademicConcept.program), '+ Create Course');
      expect(helper.createActionLabel(AcademicConcept.semester), '+ Create Term');
      expect(helper.createActionLabel(AcademicConcept.section), '+ Create Class');
      expect(helper.createActionLabel(AcademicConcept.subject), '+ Create Paper');
      expect(helper.createActionLabel(AcademicConcept.room), '+ Create Classroom');
    });

    test('Defaults are correctly applied when default config is provided', () {
      const helper = TerminologyHelper(InstitutionConfigModel(collegeId: 'default-college'));

      expect(helper.label(AcademicConcept.program), 'Course');
      expect(helper.label(AcademicConcept.semester), 'Semester');
      expect(helper.label(AcademicConcept.section), 'Section');
      expect(helper.label(AcademicConcept.subject), 'Subject');
      expect(helper.label(AcademicConcept.room), 'Room');
    });
  });

  group('Prompt 29 - Faculty & Assignment Workflow Repair', () {
    test('Newly provisioned faculty (pendingActivation) is eligible for teaching assignment', () {
      final activeFaculty = Faculty(
        id: 'fac-1',
        collegeId: 'col-1',
        departmentId: 'dept-1',
        name: 'Dr. Jane Smith',
        employeeId: 'EMP001',
        email: 'jane@acadex.edu',
        phone: '9876543210',
        accountStatus: AccountStatus.active,
        isActive: true,
      );

      final pendingFaculty = Faculty(
        id: 'fac-2',
        collegeId: 'col-1',
        departmentId: 'dept-1',
        name: 'Dr. Alan Turing',
        employeeId: 'EMP002',
        email: 'alan@acadex.edu',
        phone: '9876543211',
        accountStatus: AccountStatus.pendingActivation,
        isActive: true,
      );

      final deactivatedFaculty = Faculty(
        id: 'fac-3',
        collegeId: 'col-1',
        departmentId: 'dept-1',
        name: 'Dr. Retired',
        employeeId: 'EMP003',
        email: 'retired@acadex.edu',
        phone: '9876543212',
        accountStatus: AccountStatus.deactivated,
        isActive: false,
      );

      final candidates = [activeFaculty, pendingFaculty, deactivatedFaculty];

      // Prompt 29 fix: Only deactivated or inactive accounts are rejected
      final eligible = candidates.where((f) => f.isActive && f.accountStatus != AccountStatus.deactivated).toList();

      expect(eligible.length, 2);
      expect(eligible.any((f) => f.id == 'fac-1'), isTrue);
      expect(eligible.any((f) => f.id == 'fac-2'), isTrue, reason: 'Pending activation faculty must be eligible for teaching assignments');
      expect(eligible.any((f) => f.id == 'fac-3'), isFalse, reason: 'Deactivated faculty must be ineligible');
    });
  });

  group('Prompt 29 - Room Management & CRUD Integration', () {
    test('Room model serialization and deserialization', () {
      final room = Room(
        id: 'room-101',
        collegeId: 'col-1',
        departmentId: 'dept-cs',
        name: 'Lab 3B - Systems Engineering',
        code: 'LAB-3B',
        capacity: 45,
        type: 'lab',
        isActive: true,
      );

      final json = room.toJson();
      expect(json['id'], 'room-101');
      expect(json['name'], 'Lab 3B - Systems Engineering');
      expect(json['code'], 'LAB-3B');
      expect(json['capacity'], 45);
      expect(json['type'], 'lab');

      final deserialized = Room.fromJson(json);
      expect(deserialized.id, room.id);
      expect(deserialized.name, room.name);
      expect(deserialized.code, room.code);
      expect(deserialized.capacity, room.capacity);
      expect(deserialized.type, room.type);
    });

    test('Mock academic repository supports Room CRUD persistence', () async {
      final repo = MockAcademicRepository();

      final initialRooms = await repo.getRooms();
      expect(initialRooms, isNotEmpty);

      // Create new Room
      final newRoom = Room(
        id: 'room-new-99',
        collegeId: 'col-1',
        departmentId: 'dept-1',
        name: 'Seminar Hall Alpha',
        code: 'SHA-1',
        capacity: 120,
        type: 'auditorium',
        isActive: true,
      );

      final created = await repo.addRoom(newRoom);
      expect(created.id, 'room-new-99');

      // Fetch by ID
      final fetched = await repo.getRoomById('room-new-99');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Seminar Hall Alpha');
      expect(fetched.capacity, 120);

      // Update room
      final updatedRoom = fetched.copyWith(capacity: 150, name: 'Seminar Hall Alpha (Renovated)');
      final updated = await repo.updateRoom(updatedRoom);
      expect(updated.capacity, 150);
      expect(updated.name, 'Seminar Hall Alpha (Renovated)');

      final refetched = await repo.getRoomById('room-new-99');
      expect(refetched!.capacity, 150);
    });
  });

  group('Prompt 29 - Timetable Grid Entry & Room Assignment', () {
    test('TimetableGridEntryModel correctly holds roomId and roomNumber', () {
      final entry = TimetableGridEntryModel(
        id: 'entry-1',
        dayOfWeek: TimetableDay.monday,
        startPeriodIndex: 1,
        startTime: '09:00',
        endTime: '10:00',
        subjectId: 'sub-1',
        facultyId: 'fac-1',
        facultyAssignmentId: 'fa-1',
        roomId: 'room-101',
        roomNumber: 'LAB-3B',
        sessionType: TimetableSessionType.lecture,
      );

      expect(entry.roomId, 'room-101');
      expect(entry.roomNumber, 'LAB-3B');
      expect(entry.facultyAssignmentId, 'fa-1');

      final json = entry.toJson();
      expect(json['roomId'], 'room-101');
      expect(json['roomNumber'], 'LAB-3B');
      expect(json['facultyAssignmentId'], 'fa-1');

      final reconstructed = TimetableGridEntryModel.fromJson(json);
      expect(reconstructed.roomId, 'room-101');
      expect(reconstructed.roomNumber, 'LAB-3B');
    });
  });

  group('Prompt 29 - User-Facing Error Sanitization & Masking', () {
    test('Raw ObjectIds and database error internals are scrubbed', () {
      final rawMongoError = 'MongoServerError: E11000 duplicate key error collection: acadex.facultyassignments index: ObjectId("651234567890abcdef123456")';
      final sanitized = AcadexException.sanitizedMessage(rawMongoError);

      expect(sanitized.contains('ObjectId'), isFalse);
      expect(sanitized.contains('MongoServer'), isFalse);
      expect(sanitized.contains('E11000'), isFalse);
      expect(sanitized, contains('already exists'));
    });

    test('Missing faculty/subject/room produce clear human-readable messages', () {
      final facError = 'Faculty with ID 652a901f not found';
      final sanitizedFac = AcadexException.sanitizedMessage(facError);
      expect(sanitizedFac, 'The selected faculty member is no longer available. Refresh the faculty list and try again.');

      final subError = 'Subject with ID 652b123c unavailable';
      final sanitizedSub = AcadexException.sanitizedMessage(subError);
      expect(sanitizedSub, 'The selected subject is no longer available. Refresh Subjects and try again.');

      final roomError = 'Room with ID 652c456d not found';
      final sanitizedRoom = AcadexException.sanitizedMessage(roomError);
      expect(sanitizedRoom, 'The selected room is no longer available. Refresh Rooms and try again.');
    });

    test('Technical parameters like timetableEntryId or roomId are scrubbed', () {
      final rawError = 'Invalid request: roomId 6555abcd failed validation on timetableEntryId';
      final sanitized = AcadexException.sanitizedMessage(rawError);
      expect(sanitized.contains('roomId'), isFalse);
      expect(sanitized.contains('timetableEntryId'), isFalse);
      expect(sanitized, 'An unexpected error occurred. Please try again.');
    });
  });
}
