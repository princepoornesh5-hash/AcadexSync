"""
ACADEXSYNC - Chapters 6 to 8 Generator
Covers System Design & Architecture, Role-Based Access & Governance, and System Implementation.
"""
import os
from docx.shared import Pt, RGBColor
from report_builder import AcadexDocBuilder

DIAGRAMS_DIR = "ACADEXSYNC_Diagrams"

def generate_chapters_6_to_8(b: AcadexDocBuilder):
    # ==============================================================================
    # CHAPTER 6: SYSTEM DESIGN AND ARCHITECTURE
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 6: SYSTEM DESIGN AND ARCHITECTURE")

    b.add_section_heading("6.1 Overall System Architecture")
    b.add_body_paragraph(
        "ACADEXSYNC is architected as a modern, decoupled, multi-tier distributed system designed for high availability, fault tolerance, "
        "and strict multi-tenant isolation. The architecture is decomposed into four distinct layers: (1) The Client Presentation Tier, "
        "(2) The API Gateway & Security Tier, (3) The Core Domain Services Tier, and (4) The Persistence & Cloud Infrastructure Tier. "
        "Figure 6.1 illustrates the comprehensive system topology and communication protocols."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_01_system_architecture.png"),
        "ACADEXSYNC Overall Multi-Tenant System Architecture",
        width_inches=5.7
    )

    b.add_body_paragraph(
        "Client applications communicate with the backend gateway strictly via secure HTTPS REST endpoints and Server-Sent Events (SSE) "
        "for unidirectional real-time data streaming. All inbound requests pass through an authoritative security middleware pipeline before "
        "reaching domain controllers, ensuring that unauthenticated or out-of-scope requests are rejected at the platform perimeter."
    )

    b.add_section_heading("6.2 Frontend Architecture (Flutter / Riverpod)")
    b.add_body_paragraph(
        "The client application is built upon Google Flutter (3.24.x) utilizing the Dart programming language. The frontend strictly follows "
        "Feature-Driven Clean Architecture, isolating Presentation, Domain, and Data concerns into distinct modular boundaries. State management "
        "is powered by Flutter Riverpod (2.5.x), providing compile-time safe, unidirectional data binding and automatic provider disposal. "
        "Declarative routing is governed by GoRouter (14.2.x), which implements dynamic route guards that redirect users based on authentication "
        "status and active role assignments."
    )

    b.add_section_heading("6.3 Backend Architecture (Express.js / TypeScript)")
    b.add_body_paragraph(
        "The backend is developed as a modular Node.js application using TypeScript 5.4 and Express.js 4.19. The architecture adheres to a Layered "
        "MVC/Service pattern. Controllers handle HTTP request parsing and response formatting via standardized `ApiResponse` objects; business logic "
        "is encapsulated entirely within 31 dedicated Domain Services; and data access is managed through Mongoose Object Data Modeling (ODM). "
        "Figure 6.2 illustrates the internal component architecture of the frontend, backend, AI microservice, and database subsystems."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_04_component_diagram.png"),
        "ACADEXSYNC Subsystem Component Architecture",
        width_inches=5.7
    )

    b.add_section_heading("6.4 Database Architecture & Entity Modeling")
    b.add_body_paragraph(
        "The persistence layer utilizes MongoDB Atlas hosting 37 canonical domain collections. Each collection is strictly partitioned by `collegeId`. "
        "Relational integrity across documents is maintained via MongoDB ObjectIds and enforced through Mongoose schema validators and compound unique indexes. "
        "Figure 6.12 illustrates the canonical entity-relationship model linking core institutional, academic, and operational records."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_12_database_er_diagram.png"),
        "ACADEXSYNC Canonical Multi-Tenant Entity-Relationship Model",
        width_inches=5.7
    )

    b.add_section_heading("6.5 Authentication and Stateful Session Store")
    b.add_body_paragraph(
        "Security is rooted in an authoritative authentication pipeline. Upon successful credential verification (via bcrypt password hash comparison), "
        "the backend generates an authoritative `AuthSession` document in MongoDB with a unique UUIDv4 `sessionId`. A short-lived JSON Web Token (JWT) "
        "is issued containing the user ID, role, college ID, and session ID. On every incoming API request, `authenticateRequest` verifies both the "
        "cryptographic JWT signature and the live session status in the `AuthSession` collection, enabling instantaneous session revocation. "
        "Figures 6.5 and 6.6 depict the detailed authentication and account activation sequences."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_05_auth_login_sequence.png"),
        "Authentication & Authoritative Session Sequence Diagram",
        width_inches=5.6
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_06_activation_sequence.png"),
        "User Account Activation & Credential Provisioning Sequence",
        width_inches=5.6
    )

    b.add_section_heading("6.6 Multi-Tenant Isolation & Workspace Architecture")
    b.add_body_paragraph(
        "ACADEXSYNC implements logical multi-tenancy at the database level. Every institutional record contains a mandatory `collegeId` attribute. "
        "The `requireCollegeScope` middleware intercepts every request, validates that the user's authenticated `collegeId` matches the targeted "
        "resource, and automatically binds a tenant filter (`{ collegeId: req.user.collegeId }`) to all database queries. Super Admin users possess "
        "platform-wide privileges and can switch active workspace contexts using the `X-Workspace-Id` HTTP header."
    )

    b.add_section_heading("6.7 Role and Permission Architecture")
    b.add_body_paragraph(
        "Access control is governed by an explicit numeric hierarchy: Super Admin (100), College Admin (80), HOD (60), Faculty (40), and Student (20). "
        "Route access is enforced via `requireRoles` (whitelisting exact roles) or `requireMinRole` (verifying minimum hierarchical level). Permissions "
        "are evaluated server-side on every transaction, ensuring that client-side UI modifications cannot bypass security rules."
    )

    b.add_section_heading("6.8 API Communication Flow & Contracts")
    b.add_body_paragraph(
        "All API interactions adhere to standardized JSON contracts. Successful responses return `{ success: true, data: ..., message: ... }`, "
        "while errors return `{ success: false, error: { code: ..., message: ..., details: ... } }` with appropriate HTTP status codes (400, 401, 403, 404, 500)."
    )

    b.add_section_heading("6.9 Attendance Processing and Session-Locking Flow")
    b.add_body_paragraph(
        "Attendance capture is engineered to guarantee idempotency and mathematical completeness. Figure 6.7 illustrates the session submission "
        "and locking sequence. Timeslot strings are normalized to ASCII hyphens, duplicate sessions are rejected via compound unique indexes, "
        "and successful submission permanently transitions the session to `LOCKED` status, preventing further edits without HOD authorization."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_07_attendance_locking_sequence.png"),
        "Attendance Submission & Idempotent Session Locking Sequence",
        width_inches=5.6
    )

    b.add_section_heading("6.10 Timetable Management & Conflict Resolution Flow")
    b.add_body_paragraph(
        "The timetable engine validates new timeslot allocations against three critical constraints: (1) Room occupancy, (2) Faculty double-booking "
        "across other class sections, and (3) Configured institutional breaks. Figure 6.8 illustrates the activity diagram governing timetable validation."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_08_timetable_validation_activity.png"),
        "Timetable Construction & Conflict Validation Activity Diagram",
        width_inches=5.5
    )

    b.add_section_heading("6.11 Request Center Multi-Tier Workflow")
    b.add_body_paragraph(
        "The Request Center manages student leave, On-Duty (OD) applications, and academic grievances. Requests are automatically routed to the "
        "appropriate authority (HOD for departmental leave, College Admin for institutional permissions). Figure 6.9 details the complete flowchart."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_09_request_approval_flowchart.png"),
        "Request Center Submission & Multi-Tier Approval Workflow",
        width_inches=5.5
    )

    b.add_section_heading("6.12 Notification Delivery & FCM Multicast Flow")
    b.add_body_paragraph(
        "Notifications are dispatched across dual channels: high-priority mobile push notifications via Firebase Cloud Messaging (FCM) multicast, "
        "and real-time in-app badge updates via Server-Sent Events (SSE). Figure 6.10 details the notification dispatch pipeline."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_10_notification_flowchart.png"),
        "Multi-Channel Institutional Notification Dispatch Pipeline",
        width_inches=5.5
    )

    b.add_section_heading("6.13 AI Assistant Request Flow & Tool Execution")
    b.add_body_paragraph(
        "The AI Assistant integrates Google Gemini 1.5 Flash SDK via function-calling. When a user asks a question (e.g., 'What is my next class?'), "
        "the model invokes verified backend tools (`AiToolsRegistry`) with the user's authenticated context. Tool results are fed back into Gemini "
        "to synthesize an accurate, personalized response. Figure 6.11 illustrates this sequence."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_11_ai_assistant_sequence.png"),
        "Gemini AI Assistant Tool-Calling & Context Retrieval Flow",
        width_inches=5.6
    )

    b.add_section_heading("6.14 UML Diagrams & Architectural Blueprints")
    b.add_body_paragraph(
        "Figure 10.2 (presented in Chapter 10) details the UML Use Case diagram mapping operational capabilities across all five institutional roles."
    )

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 7: ROLE-BASED ACCESS & INSTITUTIONAL GOVERNANCE
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 7: ROLE-BASED ACCESS AND INSTITUTIONAL GOVERNANCE")

    b.add_body_paragraph(
        "Institutional governance requires strict demarcation of authority. In ACADEXSYNC, access control is governed by five clearly defined roles: "
        "Super Admin, College Admin, Head of Department (HOD), Faculty, and Student. Each role operates within strict architectural and tenant boundaries."
    )

    b.add_section_heading("7.1 Super Admin (Platform-Level Governance)")
    b.add_body_paragraph(
        "The Super Admin is the top-level platform owner. Crucially, Super Admin is NOT an ordinary college administrator; this role operates at the "
        "multi-tenant infrastructure tier. Super Admin capabilities include: (a) Provisioning new institutional tenants (Colleges) in the database; "
        "(b) Assigning initial College Admin credentials; (c) Inspecting system-wide immutable audit logs; (d) Monitoring database health and API throughput; "
        "and (e) Overriding tenant contexts using the `X-Workspace-Id` header for diagnostic purposes. Super Admin does not interfere with daily student "
        "attendance unless performing authorized technical audits."
    )

    b.add_section_heading("7.2 College Admin (Institutional Governance)")
    b.add_body_paragraph(
        "The College Admin operates at the single-institution tier (e.g. Principal or Academic Registrar). This role is strictly scoped to the "
        "assigned `collegeId` and CANNOT access or view records of other colleges on the platform. College Admin responsibilities include: "
        "(a) Configuring college-wide settings, terms, and academic calendars; (b) Establishing departments and assigning HODs; (c) Onboarding faculty "
        "and students via batch CSV import or invitation tokens; (d) Reviewing college-wide attendance reports and detention lists; and (e) Publishing "
        "official college announcements."
    )

    b.add_section_heading("7.3 Head of Department (HOD - Departmental Governance)")
    b.add_body_paragraph(
        "The Head of Department governs departmental curriculum execution and staff management. Scoped strictly to their assigned `departmentId`, "
        "HOD capabilities include: (a) Constructing and publishing weekly class timetables; (b) Assigning faculty members to specific subjects and sections; "
        "(c) Authorizing temporary teacher substitutions when staff are on leave; (d) Reviewing and approving student leave/OD applications; "
        "(e) Unlocking locked attendance sessions when legitimate corrections are required; and (f) Monitoring departmental attendance analytics."
    )

    b.add_section_heading("7.4 Faculty (Academic Operations)")
    b.add_body_paragraph(
        "Faculty members manage day-to-day classroom teaching and evaluation. Authorized strictly for their assigned subjects and class sections, "
        "faculty capabilities include: (a) Viewing their daily lecture schedule; (b) Conducting digital roll call and permanently locking attendance sessions; "
        "(c) Uploading syllabus notes and laboratory manuals to ImageKit CDN; (d) Publishing coursework assignments and evaluating submissions; and "
        "(e) Entering continuous internal assessment marks."
    )

    b.add_section_heading("7.5 Student (Personal Academic Access)")
    b.add_body_paragraph(
        "Students access personalized academic services. Scoped strictly to their personal records (`userId`), student capabilities include: "
        "(a) Viewing their live daily timetable and next upcoming class; (b) Tracking period-wise attendance and monitoring percentage thresholds; "
        "(c) Accessing verified departmental study notes; (d) Submitting digital leave, OD, and grievance applications with supporting documentation; "
        "and (e) Interacting with the AI assistant for schedule inquiries."
    )

    b.add_section_heading("7.6 Role and Permission Authorization Matrix")
    b.add_body_paragraph(
        "Table 6 establishes the authoritative role-permission matrix across all 15 core operations. Permissions are categorized as: "
        "FULL (unrestricted platform/tenant execution), SCOPED (authorized strictly within assigned department/college), ASSIGNED (restricted "
        "to individually assigned teaching subjects/classes), READ-ONLY (viewing privileges without mutation), and NO ACCESS (denied)."
    )

    perm_rows = [
        ["System Operation / Resource", "Super Admin", "College Admin", "Head of Dept", "Faculty", "Student"],
        ["Tenant / College Provisioning", "FULL", "NO ACCESS", "NO ACCESS", "NO ACCESS", "NO ACCESS"],
        ["Platform Audit Log Inspection", "FULL", "SCOPED (College)", "NO ACCESS", "NO ACCESS", "NO ACCESS"],
        ["Department & Course Setup", "FULL", "FULL (College)", "READ-ONLY", "NO ACCESS", "NO ACCESS"],
        ["User Provisioning & Invitations", "FULL", "FULL (College)", "SCOPED (Dept)", "NO ACCESS", "NO ACCESS"],
        ["Academic Calendar & Terms", "FULL", "FULL (College)", "READ-ONLY", "READ-ONLY", "READ-ONLY"],
        ["Timetable Grid Construction", "FULL", "FULL (College)", "FULL (Dept)", "NO ACCESS", "NO ACCESS"],
        ["Teacher Substitution Assignment", "FULL", "FULL (College)", "FULL (Dept)", "NO ACCESS", "NO ACCESS"],
        ["Period Attendance Marking", "FULL", "SCOPED (Audit)", "FULL (Dept)", "ASSIGNED", "NO ACCESS"],
        ["Attendance Session Locking", "FULL", "FULL (College)", "FULL (Dept)", "ASSIGNED", "NO ACCESS"],
        ["Attendance Session Unlocking", "FULL", "FULL (College)", "FULL (Dept)", "NO ACCESS", "NO ACCESS"],
        ["Personal Attendance Tracking", "FULL", "SCOPED (College)", "SCOPED (Dept)", "ASSIGNED", "PERSONAL (Self)"],
        ["Study Notes & Syllabus Upload", "FULL", "FULL (College)", "FULL (Dept)", "ASSIGNED", "NO ACCESS"],
        ["Assignment Publishing & Marks", "FULL", "FULL (College)", "SCOPED (Dept)", "ASSIGNED", "NO ACCESS"],
        ["Student Leave / OD Approval", "FULL", "FULL (College)", "FULL (Dept)", "NO ACCESS", "NO ACCESS"],
        ["Student Request Submission", "NO ACCESS", "NO ACCESS", "NO ACCESS", "NO ACCESS", "FULL (Self)"]
    ]
    b.add_table_data("Comprehensive 5-Tier Role & Permission Authorization Matrix", perm_rows[0], perm_rows[1:], [1.8, 0.8, 0.8, 0.8, 0.8, 0.8])

    b.add_section_heading("7.7 Role Hierarchy and Security Boundaries")
    b.add_body_paragraph(
        "Figure 7.1 illustrates the architectural identity pipeline. Global user identities are linked to college tenants via `WorkspaceMembership`. "
        "Roles are evaluated via `ROLE_HIERARCHY` constants, preventing privilege escalation. Even if a malicious client modifies its local UI state, "
        "backend route guards reject unauthorized transactions with HTTP 403 Forbidden."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_03_role_tenant_authorization.png"),
        "Multi-Tenant Identity & Request Authorization Pipeline",
        width_inches=5.7
    )

    b.add_section_heading("7.8 Multi-Tenant Data Isolation and Workspace Switching")
    b.add_body_paragraph(
        "Table 7 defines the architectural data invariants enforced by backend middleware. Invariant checks prevent data leaks across colleges, "
        "departments, and individual student boundaries."
    )

    inv_rows = [
        ["Architectural Boundary", "Governing Middleware", "Database Invariant Key", "Enforcement & Failure Behavior"],
        ["Multi-Tenant Isolation", "requireCollegeScope", "collegeId (Indexed)", "Rejects cross-tenant query with 403 Forbidden"],
        ["Active Institution Guard", "requireActiveCollege", "College.isActive == true", "Suspends operations if college status is INACTIVE"],
        ["Departmental Boundary", "requireDepartmentScope", "departmentId (Indexed)", "Restricts HOD to assigned department scope"],
        ["Role Privilege Gate", "requireRoles / MinRole", "AppRole & ROLE_HIERARCHY", "Enforces numeric rank (100, 80, 60, 40, 20)"],
        ["Stateful Session Guard", "authenticateRequest", "AuthSession.sessionId", "Fails closed if session is expired or revoked"]
    ]
    b.add_table_data("Architectural Responsibility & Data Invariant Mapping", inv_rows[0], inv_rows[1:], [1.4, 1.4, 1.4, 1.6])

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 8: SYSTEM IMPLEMENTATION
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 8: SYSTEM IMPLEMENTATION")

    b.add_section_heading("8.1 Application Initialization and Bootstrapping")
    b.add_body_paragraph(
        "The application bootstrapping sequence initializes critical subsystems prior to UI mounting. As verified in `Frontend/lib/main.dart`, "
        "the entry point ensures Flutter bindings, configures transparent Android edge-to-edge system bars, initializes network environment targets "
        "(automatically detecting Android emulator `10.0.2.2` versus physical Wi-Fi IP), configures global `PlatformDispatcher` error boundaries, "
        "initializes Firebase Admin SDK and FCM background listeners, and launches Riverpod's `ProviderScope`."
    )

    b.add_section_heading("8.2 Authentication and Account Activation Module")
    b.add_body_paragraph(
        "The authentication module supports multiple entry points: standard password sign-in, PIN Number lookup, 6-digit email OTP login, "
        "and new account activation. When administrators onboard new students or faculty, the system generates an 8-character invitation token. "
        "The user navigates to the Activation screen, enters the token, verifies their pre-assigned identity, sets a strong password, and transitions "
        "their account status from `PENDING` to `ACTIVE`."
    )

    b.add_section_heading("8.3 Role-Based Dynamic Navigation")
    b.add_body_paragraph(
        "Navigation is governed by GoRouter in `Frontend/lib/app/router/app_router.dart`. A reactive redirect hook listens to Riverpod's `authProvider`. "
        "When authentication succeeds, the router inspects the user's `role` and routes them directly to their dedicated dashboard "
        "(`/dashboard/super-admin`, `/dashboard/college-admin`, `/dashboard/hod`, `/dashboard/faculty`, or `/dashboard/student`). Unauthorized "
        "deep-link attempts trigger an immediate redirect to `/access-restricted`."
    )

    b.add_section_heading("8.4 Super Admin Management Workstation")
    b.add_body_paragraph(
        "The Super Admin interface provides platform oversight: multi-tenant college directory, global institutional onboarding wizards, "
        "system audit log monitors, and platform-level AI assistant integration."
    )

    b.add_section_heading("8.5 College Admin Institutional Console")
    b.add_body_paragraph(
        "The College Admin interface contains institutional management tools: academic calendar configuration, department setup, staff and student "
        "directories, faculty workload distribution overviews, and comprehensive institutional attendance reports."
    )

    b.add_section_heading("8.6 Head of Department (HOD) Academic Portal")
    b.add_body_paragraph(
        "The HOD workstation provides departmental coordination: weekly timetable grid builder, teacher substitution assignment modal, "
        "student leave/OD approval inbox, and locked attendance session audit tools."
    )

    b.add_section_heading("8.7 Faculty Classroom Operations Suite")
    b.add_body_paragraph(
        "The Faculty interface is optimized for rapid mobile classroom use: today's lecture cards, one-tap attendance roll call with swipeable "
        "student cards, idempotent session submission and locking, syllabus notes upload, and assignment publishing."
    )

    b.add_section_heading("8.8 Student Academic Hub & Attendance Portal")
    b.add_body_paragraph(
        "The Student portal displays: live today's timetable with countdown to next class, subject-wise attendance breakdown bars with color-coded "
        "75% threshold indicators, downloadable study notes, and the Request Center for leave submission."
    )

    b.add_section_heading("8.9 Attendance Ingestion & Idempotent Session Locking")
    b.add_body_paragraph(
        "Implemented in `Backend/src/services/attendance.service.ts`, the ingestion engine normalizes timeslots, verifies faculty teaching authorization "
        "via `TeachingAuthorizationService`, creates or updates the session, dual-writes individual `AttendanceRecord` documents, and commits "
        "a permanent `LOCKED` status flag."
    )

    b.add_section_heading("8.10 Timetable, Substitution & Calendar Override Engine")
    b.add_body_paragraph(
        "Implemented in `Backend/src/services/timetable.service.ts`, the engine validates faculty availability, room capacity, and break periods. "
        "When teachers take leave, HODs can inject temporary `TeacherSubstitution` records that override the daily schedule without altering the underlying weekly master template."
    )

    b.add_section_heading("8.11 Academic Structure & Curriculum Configuration")
    b.add_body_paragraph(
        "The academic structure module models the institutional hierarchy: College -> Department -> Course -> Academic Year -> Semester -> Section -> Subject. "
        "Changes propagate deterministically, ensuring historical enrollments remain immutable."
    )

    b.add_section_heading("8.12 Notes Library & ImageKit Secure Storage")
    b.add_body_paragraph(
        "Study notes are stored securely on ImageKit CDN. The backend issues short-lived cryptographic upload tokens; file metadata and access URLs "
        "are stored in the `Note` collection and made accessible strictly to enrolled students."
    )

    b.add_section_heading("8.13 Institutional Announcements & FCM Multicast")
    b.add_body_paragraph(
        "Implemented in `Backend/src/services/fcm.service.ts`, announcements are dispatched using Firebase Admin SDK multicast messaging, delivering "
        "instant push banners to registered Android device tokens while updating in-app Riverpod badge counters."
    )

    b.add_section_heading("8.14 Request Center & Multi-Level Review Workflow")
    b.add_body_paragraph(
        "The Request Center handles student leave, OD, and grievance applications. Approvers inspect attached documentation, enter mandatory review notes, "
        "and submit decisions. Approvals automatically trigger attendance adjustments in the database."
    )

    b.add_section_heading("8.15 AI Assistant & RAG Tool Calling Registry")
    b.add_body_paragraph(
        "Implemented in `Backend/src/services/ai.service.ts` and `aiTools.registry.ts`, the AI Assistant connects Google Gemini 1.5 Flash to real-time "
        "database queries via structured function calling, enforcing strict privacy boundaries against unauthorized data access."
    )

    b.add_section_heading("8.16 Error Handling, Structured Logging & Validation")
    b.add_body_paragraph(
        "All API endpoints utilize Zod request validation middleware. Server errors are logged with Winston structured JSON format including correlation IDs, "
        "and client exceptions are caught by Flutter's global `ErrorWidget.builder` and `PlatformDispatcher`."
    )

    b.add_page_break()

print("Chapters 6 to 8 generator ready.")

