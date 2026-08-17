# Repository Architecture

Acadex uses abstract Repository interfaces to isolate domain logic from implementation details (mock or database sources).

## Directory Boundaries

Each repository consists of:
1. **Interface Contract**: Located in the domain layer (`lib/features/{feature}/domain/repositories/`).
2. **Mock Implementation**: Located in the data layer (`lib/features/{feature}/data/repositories/mock_{feature}_repository.dart`).
3. **Provider Registration**: Declared in presentation providers (`lib/features/{feature}/presentation/providers/`), referencing the mock implementation by default.

## Interface Contract Pattern

Example:
```dart
abstract class AcademicRepository {
  Future<List<Department>> getDepartments(String collegeId);
  Future<List<Course>> getCourses(String departmentId);
  Future<void> createDepartment(Department dept);
}
```

By coding widgets and providers against the interface, you can change implementation (e.g. swap `MockAcademicRepository` with `FirestoreAcademicRepository`) without altering a single widget build method.
