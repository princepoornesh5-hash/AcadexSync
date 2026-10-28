import 'dart:developer' as developer;
import '../../../../core/firebase/firebase_services.dart';
import '../../../../core/presentation/navigation/acadex_nav_item.dart';
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

    final results = <SearchResult>[];

    // --- Search Navigation Destinations ---
    // If user typed "students", "timetable", "attendance", etc., immediately resolve
    // to authorized destination modules
    if (filterType == null || filterType == SearchResultType.navigation) {
      final navResults = AcadexNavigationService.searchNavigationDestinations(
        query,
        currentUser.role,
      );
      results.addAll(navResults);
    }

    // All entity queries must be strictly scoped to the user's tenant bounds.
    final tenantFilters = <String, dynamic>{};
    if (currentUser.role != AppRole.superAdmin) {
      if (currentUser.collegeId != null && currentUser.collegeId!.isNotEmpty) {
        tenantFilters['collegeId'] = currentUser.collegeId;
      }
    }

    final futures = <Future<List<SearchResult>>>[];

    Future<List<SearchResult>> runSafe(
      String collectionName,
      Future<List<SearchResult>> queryFuture,
    ) async {
      try {
        return await queryFuture;
      } catch (e) {
        developer.log(
          'Search collection error for $collectionName: $e',
          name: 'Acadex.Search',
        );
        return [];
      }
    }

    // --- Search Students ---
    // Only roles authorized to read the student roster (SuperAdmin, CollegeAdmin, HOD, Faculty)
    if ((filterType == null || filterType == SearchResultType.student) &&
        currentUser.role != AppRole.student) {
      final filters = Map<String, dynamic>.from(tenantFilters);
      filters['role'] = AppRole.student.value;
      if (currentUser.role == AppRole.hod && currentUser.departmentId != null) {
        filters['departmentId'] = currentUser.departmentId;
      }

      futures.add(
        runSafe(
          'users_students',
          _firestoreService
              .queryCollectionPrefix(
                'users',
                'nameLower',
                prefix,
                filters: filters,
                limit: limit,
              )
              .then(
                (docs) => docs
                    .map(
                      (d) => SearchResult(
                        id: d['id'] ?? '',
                        title: d['name'] ?? '',
                        subtitle:
                            d['email'] ??
                            (d['rollNumber'] != null
                                ? 'Roll No: ${d['rollNumber']}'
                                : 'Student'),
                        type: SearchResultType.student,
                        destinationRoute: '/academics/students/${d['id']}',
                      ),
                    )
                    .toList(),
              ),
        ),
      );
    }

    // --- Search Faculty ---
    // Only roles authorized to read faculty list (SuperAdmin, CollegeAdmin, HOD, Faculty)
    if ((filterType == null || filterType == SearchResultType.faculty) &&
        currentUser.role != AppRole.student) {
      final filters = Map<String, dynamic>.from(tenantFilters);
      filters['role'] = AppRole.faculty.value;

      futures.add(
        runSafe(
          'users_faculty',
          _firestoreService
              .queryCollectionPrefix(
                'users',
                'nameLower',
                prefix,
                filters: filters,
                limit: limit,
              )
              .then(
                (docs) => docs
                    .map(
                      (d) => SearchResult(
                        id: d['id'] ?? '',
                        title: d['name'] ?? '',
                        subtitle:
                            d['email'] ??
                            (d['employeeId'] != null
                                ? 'Faculty ID: ${d['employeeId']}'
                                : 'Faculty'),
                        type: SearchResultType.faculty,
                        destinationRoute: '/academics/faculty/${d['id']}',
                      ),
                    )
                    .toList(),
              ),
        ),
      );
    }

    // --- Search Subjects ---
    if (filterType == null || filterType == SearchResultType.subject) {
      futures.add(
        runSafe(
          'subjects',
          _firestoreService
              .queryCollectionPrefix(
                'subjects',
                'nameLower',
                prefix,
                filters: tenantFilters,
                limit: limit,
              )
              .then(
                (docs) => docs
                    .map(
                      (d) => SearchResult(
                        id: d['id'] ?? '',
                        title: d['name'] ?? '',
                        subtitle: d['code'] != null
                            ? 'Code: ${d['code']}'
                            : 'Subject',
                        type: SearchResultType.subject,
                        destinationRoute: '/academics/subjects/${d['id']}',
                      ),
                    )
                    .toList(),
              ),
        ),
      );
    }

    // --- Search Departments ---
    if (filterType == null || filterType == SearchResultType.department) {
      futures.add(
        runSafe(
          'departments',
          _firestoreService
              .queryCollectionPrefix(
                'departments',
                'nameLower',
                prefix,
                filters: tenantFilters,
                limit: limit,
              )
              .then(
                (docs) => docs
                    .map(
                      (d) => SearchResult(
                        id: d['id'] ?? '',
                        title: d['name'] ?? '',
                        subtitle: d['code'] != null
                            ? 'Code: ${d['code']}'
                            : 'Department',
                        type: SearchResultType.department,
                        destinationRoute: '/academics/departments/${d['id']}',
                      ),
                    )
                    .toList(),
              ),
        ),
      );
    }

    // --- Search Courses ---
    if (filterType == null || filterType == SearchResultType.course) {
      futures.add(
        runSafe(
          'courses',
          _firestoreService
              .queryCollectionPrefix(
                'courses',
                'nameLower',
                prefix,
                filters: tenantFilters,
                limit: limit,
              )
              .then(
                (docs) => docs
                    .map(
                      (d) => SearchResult(
                        id: d['id'] ?? '',
                        title: d['name'] ?? '',
                        subtitle: d['code'] != null
                            ? 'Code: ${d['code']}'
                            : 'Program/Course',
                        type: SearchResultType.course,
                        destinationRoute: '/academics/courses/${d['id']}',
                      ),
                    )
                    .toList(),
              ),
        ),
      );
    }

    // --- Search Notes ---
    if (filterType == null) {
      final filters = Map<String, dynamic>.from(tenantFilters);
      // Strictly observe Firestore security rules for notes collection:
      // HOD rule requires matching departmentId
      if (currentUser.role == AppRole.hod && currentUser.departmentId != null) {
        filters['departmentId'] = currentUser.departmentId;
      }
      // Student & Faculty read rules require published status for general browsing
      if (currentUser.role == AppRole.student ||
          currentUser.role == AppRole.faculty) {
        filters['status'] = 'published';
      }

      futures.add(
        runSafe(
          'notes',
          _firestoreService
              .queryCollectionPrefix(
                'notes',
                'titleLower',
                prefix,
                filters: filters,
                limit: limit,
              )
              .then(
                (docs) => docs
                    .map(
                      (d) => SearchResult(
                        id: d['id'] ?? '',
                        title: d['title'] ?? '',
                        subtitle: d['subjectId'] ?? 'Note',
                        type: SearchResultType.academicYear,
                        destinationRoute: '/notes',
                      ),
                    )
                    .toList(),
              ),
        ),
      );
    }

    final resultsList = await Future.wait(futures);
    final entityResults = resultsList.expand((list) => list).toList();
    entityResults.sort((a, b) => a.title.compareTo(b.title));

    // Combine navigation destinations first, followed by entity results
    results.addAll(entityResults);
    return results.take(limit * 2).toList();
  }
}
