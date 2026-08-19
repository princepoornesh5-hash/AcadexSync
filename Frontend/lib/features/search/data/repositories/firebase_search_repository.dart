import '../../../../core/firebase/firebase_services.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/domain/models/role_enum.dart';
import '../../domain/models/search_models.dart';
import '../../domain/repositories/search_repository.dart';

class FirebaseSearchRepository implements SearchRepository {
  final FirestoreService _firestoreService;

  FirebaseSearchRepository(this._firestoreService);

  @override
  Future<List<SearchResult>> search(
    String query,
    UserModel currentUser, {
    SearchResultType? filterType,
    int limit = 10,
  }) async {
    final prefix = query.trim().toLowerCase();
    if (prefix.isEmpty) return [];

    // All queries must be strictly scoped to the user's tenant bounds.
    final tenantFilters = <String, dynamic>{};
    if (currentUser.role != AppRole.superAdmin) {
      if (currentUser.collegeId != null) {
        tenantFilters['collegeId'] = currentUser.collegeId;
      }
    }

    final futures = <Future<List<SearchResult>>>[];

    // --- Search Students ---
    if (filterType == null || filterType == SearchResultType.student) {
      final filters = Map<String, dynamic>.from(tenantFilters);
      filters['role'] = AppRole.student.value;
      
      futures.add(_firestoreService.queryCollectionPrefix(
        'users',
        'nameLower',
        prefix,
        filters: filters,
        limit: limit,
      ).then((docs) => docs.map((d) => SearchResult(
        id: d['id'] ?? '',
        title: d['name'] ?? '',
        subtitle: d['email'] ?? '',
        type: SearchResultType.student,
        destinationRoute: '/module/Students',
      )).toList()));
    }

    // --- Search Faculty ---
    if (filterType == null || filterType == SearchResultType.faculty) {
      final filters = Map<String, dynamic>.from(tenantFilters);
      filters['role'] = AppRole.faculty.value;
      
      futures.add(_firestoreService.queryCollectionPrefix(
        'users',
        'nameLower',
        prefix,
        filters: filters,
        limit: limit,
      ).then((docs) => docs.map((d) => SearchResult(
        id: d['id'] ?? '',
        title: d['name'] ?? '',
        subtitle: d['email'] ?? '',
        type: SearchResultType.faculty,
        destinationRoute: '/module/Faculty',
      )).toList()));
    }

    // --- Search Subjects ---
    if (filterType == null || filterType == SearchResultType.subject) {
      futures.add(_firestoreService.queryCollectionPrefix(
        'subjects',
        'nameLower',
        prefix,
        filters: tenantFilters,
        limit: limit,
      ).then((docs) => docs.map((d) => SearchResult(
        id: d['id'] ?? '',
        title: d['name'] ?? '',
        subtitle: d['code'] ?? '',
        type: SearchResultType.subject,
        destinationRoute: '/module/Subjects',
      )).toList()));
    }

    // --- Search Departments ---
    if (filterType == null || filterType == SearchResultType.department) {
      futures.add(_firestoreService.queryCollectionPrefix(
        'departments',
        'nameLower',
        prefix,
        filters: tenantFilters,
        limit: limit,
      ).then((docs) => docs.map((d) => SearchResult(
        id: d['id'] ?? '',
        title: d['name'] ?? '',
        subtitle: d['code'] ?? '',
        type: SearchResultType.department,
        destinationRoute: '/module/Departments',
      )).toList()));
    }

    // --- Search Notes ---
    if (filterType == null) { // Or add notes to enum in future
      final filters = Map<String, dynamic>.from(tenantFilters);
      if (currentUser.role == AppRole.student) {
        filters['status'] = 'published';
      }
      futures.add(_firestoreService.queryCollectionPrefix(
        'notes',
        'titleLower',
        prefix,
        filters: filters,
        limit: limit,
      ).then((docs) => docs.map((d) => SearchResult(
        id: d['id'] ?? '',
        title: d['title'] ?? '',
        subtitle: d['subjectId'] ?? 'Note',
        type: SearchResultType.academicYear, // Fallback type, ideally should be `notes`
        destinationRoute: '/notes',
      )).toList()));
    }

    final resultsList = await Future.wait(futures);
    final flattened = resultsList.expand((list) => list).toList();
    
    // Sort logic (can be extended)
    flattened.sort((a, b) => a.title.compareTo(b.title));
    
    return flattened.take(limit * 2).toList();
  }
}
