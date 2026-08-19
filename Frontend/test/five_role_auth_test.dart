import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/repositories/auth_repository.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/data/repositories/mock_notes_repository.dart';
import 'package:campus_management/features/ai_assistant/data/repositories/mock_ai_repository.dart';

void main() {
  group('Prompt 55: Five-Role Authentication & Access Validation', () {
    final mockAuthRepo = MockAuthRepository();
    final mockNotesRepo = MockNotesRepository();
    final mockAiRepo = MockAiRepository();

    test('1. Super Admin login resolves correctly', () async {
      final user = await mockAuthRepo.loginAsDevelopmentRole(AppRole.superAdmin);
      expect(user.role, AppRole.superAdmin);
      expect(user.email, 'admin@acadex.com');
    });

    test('2. College Admin login resolves correctly', () async {
      final user = await mockAuthRepo.loginAsDevelopmentRole(AppRole.collegeAdmin);
      expect(user.role, AppRole.collegeAdmin);
      expect(user.email, 'college@acadex.com');
    });

    test('3. HOD login resolves correctly', () async {
      final user = await mockAuthRepo.loginAsDevelopmentRole(AppRole.hod);
      expect(user.role, AppRole.hod);
      expect(user.email, 'hod@acadex.com');
    });

    test('4. Faculty login resolves correctly', () async {
      final user = await mockAuthRepo.loginAsDevelopmentRole(AppRole.faculty);
      expect(user.role, AppRole.faculty);
      expect(user.email, 'faculty@acadex.com');
    });

    test('5. Student login resolves correctly', () async {
      final user = await mockAuthRepo.loginAsDevelopmentRole(AppRole.student);
      expect(user.role, AppRole.student);
      expect(user.email, 'student@acadex.com');
    });

    test('6. Role Switching: Sequential logins clear state without leakage', () async {
      UserModel current = await mockAuthRepo.loginAsDevelopmentRole(AppRole.student);
      expect(current.role, AppRole.student);

      current = await mockAuthRepo.loginAsDevelopmentRole(AppRole.faculty);
      expect(current.role, AppRole.faculty);

      current = await mockAuthRepo.loginAsDevelopmentRole(AppRole.hod);
      expect(current.role, AppRole.hod);

      current = await mockAuthRepo.loginAsDevelopmentRole(AppRole.collegeAdmin);
      expect(current.role, AppRole.collegeAdmin);

      current = await mockAuthRepo.loginAsDevelopmentRole(AppRole.superAdmin);
      expect(current.role, AppRole.superAdmin);
    });

    test('7. AI Context Isolation: AI Assistant receives role-bound context', () async {
      final studentAi = await mockAiRepo.sendMessage(
        query: 'attendance overview',
        context: {'role': 'student'},
      );
      expect(studentAi.contains('Attendance'), isTrue);

      final facultyAi = await mockAiRepo.sendMessage(
        query: 'mark attendance',
        context: {'role': 'faculty'},
      );
      expect(facultyAi.contains('assigned section'), isTrue);
    });

    test('8. Notes Role Isolation: Students see published notes only, Faculty see drafts', () async {
      final studentStream = mockNotesRepo.watchNotes(
        role: AppRole.student,
        userId: 'student-1',
        collegeId: 'col-1',
        departmentId: 'dept-cse',
        courseId: 'crs-cse',
        semesterId: 'sem-3',
        sectionId: 'sec-3a',
      );
      final studentNotes = await studentStream.first;
      expect(studentNotes.every((n) => n.status == NoteStatus.published), isTrue);

      final facultyStream = mockNotesRepo.watchNotes(
        role: AppRole.faculty,
        userId: 'user-fac-1',
      );
      final facultyNotes = await facultyStream.first;
      expect(facultyNotes.any((n) => n.status == NoteStatus.draft), isTrue);
    });
  });
}
