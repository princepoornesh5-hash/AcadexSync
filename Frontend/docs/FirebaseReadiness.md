# Firebase Integration Readiness Check

This document tracks system readiness for swapping mock data with live Firebase/Firestore connections.

## Required Firebase Configuration

1. **Authentication**:
   - Swap `MockAuthRepository` with `firebase_auth` SDK commands.
   - Use standard email/password authentication.
2. **Database (Cloud Firestore)**:
   - Convert all JSON generation calls in repositories into Firestore document retrievals.
   - Example: Instead of reading in-memory lists, query collections.
3. **Push Notifications**:
   - Integrate `firebase_messaging` (FCM).
   - Register FCM token on user login and save to `/users/{uid}/fcmToken`.
   - Setup background and foreground handlers.
4. **Cloud Functions**:
   - Implement backend computations (e.g. calculating risk rates, sending low attendance alerts) rather than computing expensive batch profiles on the mobile client.
5. **Offline Support**:
   - Enable Firestore local persistence in `main.dart` to support offline access to dashboards, attendance lists, and offline local attendance logging.
