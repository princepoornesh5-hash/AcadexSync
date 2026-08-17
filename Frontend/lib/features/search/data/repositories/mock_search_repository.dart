import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/search_models.dart';
import '../../../academic_structure/data/repositories/mock_academic_repository.dart';
// import '../../../attendance/data/repositories/mock_attendance_repository.dart';

class MockSearchRepository {
  Future<void> _delay() async => await Future.delayed(const Duration(milliseconds: 300));

  Future<List<SearchResult>> search(String query, UserModel currentUser, {SearchResultType? filterType}) async {
    await _delay();
    
    if (query.trim().isEmpty) return [];

    final lowercaseQuery = query.toLowerCase().trim();
    List<SearchResult> results = [];

    // --- Search Students ---
    if (filterType == null || filterType == SearchResultType.student) {
      final students = await mockAcademicRepo.getStudents();
      for (var student in students) {
        if (_matches(student.name, lowercaseQuery) || _matches(student.rollNumber, lowercaseQuery)) {
          // Role-based filtering for students:
          bool canView = true;
          if (currentUser.role == AppRole.student && student.id != currentUser.id) { // Mock using student.id as userId
            canView = false;
          }
          
          if (canView) {
            results.add(SearchResult(
              id: student.id,
              title: student.name,
              subtitle: student.rollNumber,
              type: SearchResultType.student,
              destinationRoute: '/module/Students', // Assuming we navigate to student list/profile
              relevanceScore: _calculateScore(student.name, student.rollNumber, lowercaseQuery),
            ));
          }
        }
      }
    }

    // --- Search Faculty ---
    if (filterType == null || filterType == SearchResultType.faculty) {
      final faculties = await mockAcademicRepo.getFaculty();
      for (var faculty in faculties) {
        if (_matches(faculty.name, lowercaseQuery) || _matches(faculty.employeeId, lowercaseQuery)) {
          results.add(SearchResult(
            id: faculty.id,
            title: faculty.name,
            subtitle: faculty.employeeId,
            type: SearchResultType.faculty,
            destinationRoute: '/module/Faculty',
            relevanceScore: _calculateScore(faculty.name, faculty.employeeId, lowercaseQuery),
          ));
        }
      }
    }

    // --- Search Subjects ---
    if (filterType == null || filterType == SearchResultType.subject) {
      final subjects = await mockAcademicRepo.getSubjects();
      for (var subject in subjects) {
        if (_matches(subject.name, lowercaseQuery) || _matches(subject.code, lowercaseQuery)) {
          results.add(SearchResult(
            id: subject.id,
            title: subject.name,
            subtitle: subject.code,
            type: SearchResultType.subject,
            destinationRoute: '/module/Subjects',
            relevanceScore: _calculateScore(subject.name, subject.code, lowercaseQuery),
          ));
        }
      }
    }
    
    // --- Search Departments ---
    if (filterType == null || filterType == SearchResultType.department) {
      final departments = await mockAcademicRepo.getDepartments();
      for (var dept in departments) {
        if (_matches(dept.name, lowercaseQuery) || _matches(dept.code, lowercaseQuery)) {
          results.add(SearchResult(
            id: dept.id,
            title: dept.name,
            subtitle: dept.code,
            type: SearchResultType.department,
            destinationRoute: '/module/Departments',
            relevanceScore: _calculateScore(dept.name, dept.code, lowercaseQuery),
          ));
        }
      }
    }

    // Sort by relevance score descending
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  bool _matches(String field, String query) {
    return field.toLowerCase().contains(query);
  }

  int _calculateScore(String primary, String secondary, String query) {
    primary = primary.toLowerCase();
    secondary = secondary.toLowerCase();
    
    if (primary == query || secondary == query) return 100;
    if (primary.startsWith(query) || secondary.startsWith(query)) return 50;
    return 10;
  }
}

final mockSearchRepo = MockSearchRepository();
