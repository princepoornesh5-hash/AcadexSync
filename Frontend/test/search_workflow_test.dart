import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/search/data/repositories/firebase_search_repository.dart';
import 'package:campus_management/features/search/domain/models/search_models.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/core/firebase/firebase_services.dart';

class FakeFirestoreService implements FirestoreService {
  final Map<String, Map<String, dynamic>> _db = {};

  @override
  Future<void> setDocument(String collection, String id, Map<String, dynamic> data) async {
    final path = '$collection/$id';
    if (_db.containsKey(path)) {
      _db[path]!.addAll(data);
    } else {
      _db[path] = data;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollectionPrefix(
      String collection, String searchField, String prefix,
      {Map<String, dynamic>? filters, int limit = 20}) async {
      
    final allDocs = _db.entries
        .where((e) => e.key.startsWith('$collection/'))
        .map((e) => e.value)
        .toList();

    return allDocs.where((doc) {
      if (filters != null) {
        for (final entry in filters.entries) {
          if (doc[entry.key] != entry.value) return false;
        }
      }
      final fieldValue = doc[searchField]?.toString().toLowerCase() ?? '';
      return fieldValue.startsWith(prefix.toLowerCase());
    }).take(limit).toList();
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Prompt 63: Global Search Security & Isolation Workflow', () {
    late FakeFirestoreService firestoreService;
    late FirebaseSearchRepository searchRepo;

    setUp(() {
      firestoreService = FakeFirestoreService();
      searchRepo = FirebaseSearchRepository(firestoreService);
    });

    test('1. Cross-Tenant Isolation (College A cannot search College B)', () async {
      // Seed Student A in College A
      await firestoreService.setDocument('users', 'studentA', {
        'id': 'studentA',
        'name': 'Alice Smith',
        'nameLower': 'alice smith',
        'email': 'alice@colA.com',
        'role': 'STUDENT',
        'collegeId': 'colA',
      });

      // Seed Student B in College B
      await firestoreService.setDocument('users', 'studentB', {
        'id': 'studentB',
        'name': 'Alice Johnson',
        'nameLower': 'alice johnson',
        'email': 'alice@colB.com',
        'role': 'STUDENT',
        'collegeId': 'colB',
      });

      // User in College A
      final userA = UserModel(
        id: 'uA',
        name: 'Admin A',
        email: 'admin@colA.com',
        role: AppRole.collegeAdmin,
        collegeId: 'colA',
      );

      // Search for "Alice"
      final results = await searchRepo.search('Alice', userA);

      // Should only return Alice from colA
      expect(results.length, 1);
      expect(results.first.id, 'studentA');
      expect(results.first.title, 'Alice Smith');
    });

    test('2. Role Isolation & Prefix Search', () async {
      // Seed Subjects
      await firestoreService.setDocument('subjects', 'subj1', {
        'id': 'subj1',
        'name': 'Data Structures',
        'nameLower': 'data structures',
        'code': 'CS201',
        'collegeId': 'colX',
      });
      await firestoreService.setDocument('subjects', 'subj2', {
        'id': 'subj2',
        'name': 'Database Systems',
        'nameLower': 'database systems',
        'code': 'CS202',
        'collegeId': 'colX',
      });
      
      final studentX = UserModel(
        id: 'stuX',
        name: 'Student X',
        email: 'stu@colX.com',
        role: AppRole.student,
        collegeId: 'colX',
      );

      // Prefix query "Dat" should return Data Structures and Database Systems
      final results = await searchRepo.search('Dat', studentX, filterType: SearchResultType.subject);
      
      expect(results.length, 2);
      expect(results.any((r) => r.id == 'subj1'), isTrue);
      expect(results.any((r) => r.id == 'subj2'), isTrue);
    });

    test('3. Draft Notes Exclusion for Students', () async {
      await firestoreService.setDocument('notes', 'note_published', {
        'id': 'note_published',
        'title': 'Operating Systems Ch 1',
        'titleLower': 'operating systems ch 1',
        'collegeId': 'colY',
        'status': 'published',
      });

      await firestoreService.setDocument('notes', 'note_draft', {
        'id': 'note_draft',
        'title': 'Operating Systems Ch 2',
        'titleLower': 'operating systems ch 2',
        'collegeId': 'colY',
        'status': 'draft', // Unauthorized for students
      });

      final studentY = UserModel(
        id: 'stuY',
        name: 'Student Y',
        email: 'stu@colY.com',
        role: AppRole.student,
        collegeId: 'colY',
      );

      final results = await searchRepo.search('Operating', studentY);
      
      expect(results.length, 1);
      expect(results.first.id, 'note_published');
    });

    test('4. Empty Query / Missing Permissions', () async {
      final user = UserModel(
        id: 'u',
        name: 'User',
        email: 'u@test.com',
        role: AppRole.student,
        collegeId: 'testCol',
      );

      // Empty queries should return empty list without network calls
      final emptyResults = await searchRepo.search('   ', user);
      expect(emptyResults.isEmpty, true);
    });
  });
}
