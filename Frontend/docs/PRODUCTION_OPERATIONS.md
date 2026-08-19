# Acadex Production Operations Guide

This document defines the operational procedures for the Acadex platform, focusing on deployment, monitoring, backup strategies, and recovery.

## 1. Environment Configuration & Deployment
Acadex is a Flutter Web application backed by Firebase. 

### 1.1 Secrets & API Keys
No privileged backend secrets (e.g., Firebase Admin credentials, GenAI API keys) are embedded in the Flutter application. 
- **Client Configuration:** Non-sensitive Firebase App identification keys are stored in `firebase_options.dart`.
- **Server Configuration:** Cloud Functions require the `GOOGLE_API_KEY` for the AI Assistant. This is configured via Firebase Environment variables (`firebase functions:config:set ai.apikey="KEY"`).

### 1.2 Deployment Procedure
To deploy a new release to Firebase Hosting:
```bash
# 1. Clean the environment
flutter clean
flutter pub get

# 2. Run tests and static analysis
flutter analyze
flutter test

# 3. Build for Web (JS fallback due to file_picker WASM limitations)
flutter build web --release

# 4. Deploy to Firebase
firebase deploy --only hosting
```

## 2. Observability & Monitoring
Acadex implements a global `AcadexLogger` to trace critical application failures without leaking sensitive context.

- **Frontend Errors:** Unhandled exceptions and async crashes are caught via `runZonedGuarded` and `FlutterError.onError`. In production, these should be forwarded to Firebase Crashlytics.
- **Backend Logging:** Cloud Functions automatically log executions to Google Cloud Logging. 

## 3. Cost Control & Rate Limiting
To prevent accidental cost spikes:
- **Pagination:** Firestore queries (e.g., fetching students, faculty, notes, and notifications) are heavily paginated with `limit()` clauses.
- **AI Rate Limiting:** The AI chat interface debounces rapid requests (3 seconds) to prevent Cloud Function and GenAI API spamming.
- **Storage Limits:** File uploads are restricted to 5MB (Profile), 10MB (Certificates), and 25MB (Notes).

## 4. Backup & Recovery Strategy
Firebase provides robust infrastructure, but scheduled exports are required for disaster recovery.

- **Firestore Backups:** Configure Google Cloud Storage bucket exports for the `colleges` collection on a nightly basis using GCP Scheduled Functions.
- **Rollback Strategy:** If a deployment fails, use Firebase Hosting's one-click rollback feature via the Firebase Console:
  `Firebase Console -> Hosting -> View Release History -> Rollback`

## 5. Post-Deployment Smoke Test
After a successful deployment, operations personnel must verify:
1. **Authentication:** Log in as a Super Admin, College Admin, Faculty, and Student.
2. **Tenant Isolation:** Ensure a College Admin cannot query users from another `collegeId`.
3. **Storage Connectivity:** Upload a PDF Note as Faculty and verify it is downloadable by a Student.
4. **AI Connectivity:** Ask the AI Assistant a question and verify a contextual response is returned without error.
5. **Real-time Sync:** Verify that Attendance changes propagate instantly.
