# Backend Migration Plan

A roadmap for migrating Acadex mock data layers into fully-integrated Firestore and Firebase services.

## Phase 1: Firebase Project Configuration
- **Status**: [COMPLETED]
- Firebase Core and Auth dependencies have been successfully integrated.
- Platform options configurations and dynamically mapped options generated.

## Phase 2: Authentication Migration
- **Status**: [IN_PROGRESS]
- `FirebaseAuthService` wrapper and Riverpod providers are fully functional.
- Error handling maps raw credentials exceptions into clean UI-level validation.

## Phase 3: Firestore Repository Migration
1. Implement new repositories (e.g. `FirestoreAcademicRepository`, `FirestoreAttendanceRepository`) extending their respective domain repository interfaces.
2. Map Firestore collections as proposed in `docs/FirestoreProposal.md`.
3. Replace the overridden providers in `main.dart` with Firestore implementations.

## Phase 4: Push Messaging (FCM)
1. Swap mock notification trigger streams with Firebase Messaging notifications.
2. Cloud Functions will handle sending system notifications (e.g., when a student falls below attendance requirement).
