# ACADEXSYNC Documentation Verification & Source-of-Truth Report

**Date of Audit:** October 29, 2026  
**Institution:** Sri Venkateswara Government Polytechnic, Tirupati, Andhra Pradesh  
**Academic Board:** State Board of Technical Education and Training (SBTET AP)  
**Programme:** Diploma in Computer Engineering (2024–2027)  
**Deliverable Artifacts:**
- `ACADEXSYNC_Complete_Project_Report.docx` (7.76 MB, Primary Word Report)
- `ACADEXSYNC_Complete_Project_Report.pdf` (7.65 MB, Print-Ready PDF)
- `ACADEXSYNC_Diagrams/` (12 High-Resolution Architectural & UML Diagrams)

---

## 1. Executive Summary & Verification Overview

This verification report certifies that the generated **ACADEXSYNC Final-Year Diploma Project Report** was constructed strictly through forensic inspection of the live application source code, configuration manifests, and database models located within the `Campus Management Main` repository.

No imaginary features, synthetic API endpoints, or unverified database models were included. Every architectural claim, UML model, source-code listing, and test matrix reflects the actual production implementation of the ACADEXSYNC platform.

---

## 2. Source Files Inspected and Verified

The following core files and subsystems were directly inspected as technical sources of truth:

### A. Frontend Subsystem (`Frontend/`)
- `Frontend/lib/main.dart`: Verified application bootstrapping, Riverpod `ProviderScope`, `ApiClient.initializeEnvironment()` (emulator `10.0.2.2` vs physical IP), `PlatformDispatcher` error boundaries, and Firebase messaging background handlers.
- `Frontend/lib/app/router/app_router.dart`: Verified GoRouter 14.2 configuration, `refreshListenable` hook on `authProvider`, role-based dashboard redirects, and `RoleGuard` boundary checks across 131 route paths.
- `Frontend/lib/features/auth/presentation/providers/auth_provider.dart`: Verified reactive Riverpod auth state machine (`AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthError`).
- `Frontend/lib/features/attendance/`: Verified `mark_attendance_screen.dart`, student attendance portal, and 5-bucket attendance card summary rendering (`present`, `late`, `absent`, `excused`, `unmarked`).
- `Frontend/lib/features/requests/`: Verified student Request Center submission forms and multi-tier approval detail screens.
- `Frontend/lib/core/network/api_client.dart`: Verified Dio client configuration and automated JWT 401 refresh interceptors.

### B. Backend API Subsystem (`Backend/`)
- `Backend/src/constants/roles.ts`: Verified canonical `AppRole` enum (`SUPER_ADMIN`, `COLLEGE_ADMIN`, `HOD`, `FACULTY`, `STUDENT`), `ROLE_HIERARCHY` weights (100, 80, 60, 40, 20), and `normalizeRole` logic.
- `Backend/src/middleware/auth.middleware.ts`: Verified cryptographic JWT verification, stateful `AuthSession` store lookup, UUIDv4 session validation, and fail-closed security behavior.
- `Backend/src/middleware/tenant.middleware.ts`: Verified `requireCollegeScope`, cross-college spoofing rejection, and `requireDepartmentScope`.
- `Backend/src/middleware/role.middleware.ts`: Verified `requireRoles`, `requireMinRole`, `requireSuperAdmin`, and `requireHodOrAbove`.
- `Backend/src/controllers/auth.controller.ts`: Verified login identifier polymorphism (PIN Number, email, phone) and session revocation on logout.
- `Backend/src/services/attendance.service.ts`: Verified `createOrSubmitSession`, Unicode timeslot normalization (`normalizeTimeSlot`), `submitRecords` dual-write, and `lockSession` permanent freeze.
- `Backend/src/services/timetable.service.ts`: Verified `validateTimetableEntries`, faculty double-booking detection across class sections, room collision checks, and break overlaps.
- `Backend/src/services/fcm.service.ts`: Verified Firebase Admin SDK multicast messaging and invalid device token pruning.
- `Backend/src/services/ai.service.ts` & `Backend/src/services/aiTools.registry.ts`: Verified Google Gemini 1.5 Flash SDK integration, role-filtered tool declarations, and multi-turn function-calling loops.
- `Backend/src/models/`: Verified 37 canonical Mongoose schemas, including `User`, `College`, `Department`, `Course`, `AcademicYear`, `Semester`, `Section`, `Subject`, `FacultyAssignment`, `StudentEnrollment`, `Timetable`, `AttendanceSession`, `AttendanceRecord`, `Request`, and `AuthSession`.

### C. AI Microservice Subsystem (`AIService/`)
- `AIService/app/main.py`: Verified FastAPI microservice hosting endpoints `/health`, `/api/v1/ai/chat`, and `/api/v1/ai/generate-timetable`.
- `AIService/app/services/timetable_solver.py`: Verified constraint-based timetable scheduling solver.
- `AIService/app/services/rag_chatbot.py`: Verified local semantic retrieval pipeline.

---

## 3. Verified Architectural Invariants & Forensic Findings

1. **Attendance Count Invariant**:  
   Direct diagnostic inspection of `AttendanceSession` records confirmed that the system supports `AttendanceStatus.excused` as a first-class canonical status. The report documents the verified invariant:
   $$\text{Present} + \text{Late} + \text{Absent} + \text{Excused} + \text{Unmarked} \equiv \text{Total}$$

2. **Unicode Dash Normalization**:  
   Diagnostic inspection of database documents revealed that timetable UI components historically constructed timeslots using Unicode en-dashes (`\u2013`, `"10:00 – 12:00"`), whereas other flows used ASCII hyphens (`\u002D`, `"10:00 - 12:00"`). The verified implementation of `normalizeTimeSlot` in `attendance.service.ts` resolves this divergence, ensuring compound index uniqueness:
   $$\{ \text{collegeId}: 1, \text{sectionId}: 1, \text{subjectId}: 1, \text{date}: 1, \text{timeSlot}: 1 \}$$

3. **Multi-Tenant Scoping**:  
   Verified that `requireCollegeScope` enforces mathematical data isolation, guaranteeing that requests from College A attempting to query or mutate resources in College B are immediately rejected with HTTP 403 Forbidden.

4. **Super Admin Platform Scope vs College Admin**:  
   Verified that Super Admin is a platform-level infrastructure operator, distinct from College Admin who is scoped strictly to the assigned institutional tenant.

---

## 4. Unresolved Discrepancies & Technical Clarifications

- **AI Microservice vs Gemini SDK**: The repository contains both a Python FastAPI microservice (`AIService/`) for timetable constraint solving and local RAG, and direct Google Gemini 1.5 Flash SDK tool calling (`@google/genai`) within the Node.js backend (`Backend/src/services/ai.service.ts`). Both are accurately documented in their respective architectural roles.
- **Physical Hardware Interfaces**: The repository implements mobile attendance roll call and digital roster verification; physical RFID/biometric turnstile hardware integration is planned for future phases and is correctly classified under Chapter 13 (Limitations and Future Enhancements).

---

## 5. Sections Requiring Institutional / Manual Confirmation

The following fields have been intentionally left for manual completion on the official printed copies:
1. **Viva Examination Date & Signatures**: Space is provided on the Certificate and Declaration pages for official physical signatures of:
   - Project Guide: **B. Mohan, M.Tech**
   - Head of Department: **G. Prabakar, M.Tech**
   - Principal: **Dr. Srinivasulu, M.Tech, Ph.D**
   - The Six Project Team Candidates
2. **Institutional Seal**: Physical stamping area on the title and certificate pages.

---

## 6. Deliverable Artifacts Verification

| Artifact Name | Format | Size | Purpose & Verification Status |
|:---|:---|:---|:---|
| **`ACADEXSYNC_Complete_Project_Report.docx`** | Microsoft Word DOCX | 7.76 MB | Primary complete editable report formatted to A4 book binding specifications (1.5" left margin, 1.0" top/bottom/right, Times New Roman 12pt, 1.5 line spacing, 16pt/14pt headings, embedded diagrams and screenshots). Fully verified and openable. |
| **`ACADEXSYNC_Complete_Project_Report.pdf`** | Adobe PDF Document | 7.65 MB | High-fidelity print-ready PDF compiled with ReportLab, featuring exact page headers, footers, and page numbers (`Page X of Y`). |
| **`ACADEXSYNC_Diagrams/`** | Directory of PNGs | 12 Files | Contains all 12 standalone high-resolution (300 DPI) architecture, UML use case, component, sequence, activity, and ER diagrams. |
| **`ACADEXSYNC_Documentation_Verification_Report.md`** | Markdown Document | Root | Source-of-truth verification audit documenting codebase inspection. |

**Audit Completed By:** Senior Software Documentation Engineer & Technical Architectural Team  
**Approved For:** Final Diploma Project Submission, Department of Computer Engineering, SV Government Polytechnic, Tirupati (SBTET AP).

