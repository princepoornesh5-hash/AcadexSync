# Technical Debt Report

This report tracks identified technical debt, refactoring needs, and areas that require attention before production launch.

## 1. Asynchronous Timer Management in Widget Tests
- **Problem**: Widget testing sometimes fails with "Timer is still pending" when calling `pumpAndSettle` because of continuous animations (like blinking text field cursors) or delayed mock repo responses.
- **Location**: `/test/widget_test.dart` and async provider wrappers.
- **Impact**: Test suite execution is slowed down or fails.
- **Recommended Solution**: Force mock repositories to run immediately (without delays) when running in test mode. Override the settings and notifier providers using synchronous overrides in test cases.
- **Status**: Partially addressed in `widget_test.dart` by mocking `settingsRepoProvider`.

## 2. In-Memory Mock Mutability
- **Problem**: Mock repositories store state in-memory inside singleton instances (e.g. `mockSettingsRepo`).
- **Location**: `lib/features/*/data/repositories/`
- **Impact**: Changes are lost when the app restarts, and state can get dirty during test runs.
- **Recommended Solution**: Migrate mock data into a persistent local cache (e.g. `shared_preferences` or `hive`) before moving to Firebase.
- **Status**: Planned.

## 3. UI Layer Role Guarding
- **Problem**: Some routing path restrictions are enforced primarily at the UI level.
- **Location**: `lib/app/router/app_router.dart`
- **Impact**: A security gap if endpoints are accessed programmatically.
- **Recommended Solution**: Enforce strict Firestore security rules alongside frontend checks.
- **Status**: Documented.
