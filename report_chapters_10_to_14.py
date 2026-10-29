"""
ACADEXSYNC - Chapters 10 to 14 & Appendices Generator
Covers UML Diagrams, Testing, Results/Screenshots, Limitations/Enhancements, Conclusion, References, and Appendices.
"""
import os
from docx.shared import Pt, RGBColor
from report_builder import AcadexDocBuilder

DIAGRAMS_DIR = "ACADEXSYNC_Diagrams"
BASELINE_DIR = "docs/runtime_qa/baseline"
P02_DIR = "docs/runtime_qa/prompt02_1/screenshots"

def generate_chapters_10_to_14(b: AcadexDocBuilder):
    # ==============================================================================
    # CHAPTER 10: UML DIAGRAMS, FLOWCHARTS & WORKFLOW MODELS
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 10: UML DIAGRAMS, FLOWCHARTS & WORKFLOW MODELS")

    b.add_body_paragraph(
        "Software modeling provides the formal blueprint for verifying system structure, actor interactions, operational workflows, and "
        "data lifecycles. This chapter consolidates the complete suite of Unified Modeling Language (UML) diagrams and workflow charts for ACADEXSYNC. "
        "Each diagram is constructed in strict conformance with standard UML conventions and verified against the actual repository implementation."
    )

    b.add_section_heading("10.1 Overall System Architecture")
    b.add_body_paragraph(
        "The complete system topology is documented in Figure 6.1 (Chapter 6). It models the multi-tier separation between the Flutter client tier, "
        "the Express.js gateway tier, core service subsystems, and MongoDB Atlas / cloud infrastructure."
    )

    b.add_section_heading("10.2 UML Use Case Diagram (5 Actors)")
    b.add_body_paragraph(
        "Figure 10.2 illustrates the comprehensive UML Use Case diagram mapping operational capabilities across all five institutional roles. "
        "The system boundary encloses the ACADEXSYNC platform, delineating the exact functional responsibilities of Super Admin, College Admin, "
        "Head of Department, Faculty, and Student actors."
    )

    b.add_figure(
        os.path.join(DIAGRAMS_DIR, "figure_02_use_case_diagram.png"),
        "UML Use Case Diagram (ACADEXSYNC 5 User Roles)",
        width_inches=5.7
    )

    b.add_section_heading("10.3 Role and Tenant Authorization Pipeline")
    b.add_body_paragraph(
        "Detailed in Figure 7.1 (Chapter 7), the authorization model demonstrates how global user identities are bound to college workspaces and "
        "filtered through the four-stage middleware pipeline (`authenticateRequest`, `requireCollegeScope`, `requireDepartmentScope`, `requireRoles`)."
    )

    b.add_section_heading("10.4 Subsystem Component Architecture")
    b.add_body_paragraph(
        "Detailed in Figure 6.2 (Chapter 6), the component model maps the internal modular decomposition of the Flutter client, Express API, "
        "FastAPI AI microservice, and MongoDB database clusters."
    )

    b.add_section_heading("10.5 Authentication & Session Sequence Diagram")
    b.add_body_paragraph(
        "Figure 6.5 (Chapter 6) details the execution sequence during user login, from initial credential capture to AuthSession persistence and JWT issuance."
    )

    b.add_section_heading("10.6 User Account Activation Sequence Diagram")
    b.add_body_paragraph(
        "Figure 6.6 (Chapter 6) details the onboarding sequence wherein unactivated users redeem single-use invitation tokens to initialize their accounts."
    )

    b.add_section_heading("10.7 Attendance Submission & Idempotent Session Locking Sequence")
    b.add_body_paragraph(
        "Figure 6.7 (Chapter 6) details the roll call ingestion sequence, verifying teaching context, normalizing timeslots, and permanently locking sessions."
    )

    b.add_section_heading("10.8 Timetable Construction & Conflict Validation Activity Diagram")
    b.add_body_paragraph(
        "Figure 6.8 (Chapter 6) details the activity logic governing conflict detection for room occupancy, faculty double-booking, and break overlaps."
    )

    b.add_section_heading("10.9 Request Center Submission & Approval Flowchart")
    b.add_body_paragraph(
        "Figure 6.9 (Chapter 6) details the decision flowchart for student leave/OD applications, routing to appropriate approvers and adjusting attendance."
    )

    b.add_section_heading("10.10 Notification Delivery Pipeline Flowchart")
    b.add_body_paragraph(
        "Figure 6.10 (Chapter 6) details the multi-channel notification dispatch pipeline integrating FCM push notifications and in-app SSE streams."
    )

    b.add_section_heading("10.11 AI Assistant Tool-Calling Sequence Diagram")
    b.add_body_paragraph(
        "Figure 6.11 (Chapter 6) details the multi-turn function-calling loop between Google Gemini 1.5 Flash and server-side tool functions."
    )

    b.add_section_heading("10.12 Entity-Relationship (ER) Architecture Diagram")
    b.add_body_paragraph(
        "Figure 6.12 (Chapter 6) provides the relational model connecting the 14 core database entities across institutional and academic tiers."
    )

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 11: TESTING AND VALIDATION
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 11: TESTING AND VALIDATION")

    b.add_section_heading("11.1 Testing Methodology & Quality Assurance Framework")
    b.add_body_paragraph(
        "To ensure mission-critical stability and strict data integrity, ACADEXSYNC was subjected to a comprehensive multi-tier testing regime. "
        "The testing strategy encompasses four levels: (1) Unit Testing, validating standalone utility functions, validators, and normalization algorithms; "
        "(2) Widget Testing, verifying Flutter UI components, layout responsiveness, and Riverpod state changes; (3) Integration Testing, evaluating "
        "end-to-end API controllers, middleware pipelines, and MongoDB persistence; and (4) Security Boundary Testing, rigorously validating "
        "multi-tenant isolation, role hierarchy gates, and session revocation."
    )

    b.add_section_heading("11.2 Unit Testing and Validation")
    b.add_body_paragraph(
        "Unit test suites verify critical domain functions in isolation. In the backend, unit tests validate `normalizeTimeSlot`, ensuring that "
        "Unicode en-dashes (`\\u2013`), em-dashes (`\\u2014`), and variable whitespace are deterministically converted to standard ASCII hyphens (`-`). "
        "In the frontend, unit tests validate Riverpod state notifiers, confirming that auth state transitions from `AuthInitial` to `AuthAuthenticated` "
        "deterministically emit the expected state objects."
    )

    b.add_section_heading("11.3 Widget and Presentation Testing")
    b.add_body_paragraph(
        "Widget tests execute within the Flutter test harness across varying screen geometries (360x640 mobile, 768x1024 tablet, 1920x1080 desktop). "
        "Tests confirm that UI components never render pixel overflow exceptions (RenderFlex overflow), that tap targets meet the 48x48 dp accessibility "
        "standard, and that attendance cards accurately display all five status buckets (present, late, absent, excused, unmarked)."
    )

    b.add_section_heading("11.4 Backend Integration Testing")
    b.add_body_paragraph(
        "Backend integration suites utilize Supertest against a live MongoDB test instance. Over 51 integration tests verify that API endpoints "
        "correctly parse payloads, enforce Zod schemas, persist documents, and return standardized `ApiResponse` structures."
    )

    b.add_section_heading("11.5 API Endpoint Contract Validation")
    b.add_body_paragraph(
        "Every endpoint is tested against its OpenAPI/Swagger contract. Responses are checked for mandatory fields, correct HTTP status codes "
        "(200 OK, 201 Created, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found), and standardized error structures."
    )

    b.add_section_heading("11.6 Authentication and Session Security Tests")
    b.add_body_paragraph(
        "Security suites test credential validation: bcrypt password verification, rejection of expired JWTs, detection of forged token signatures, "
        "and immediate request rejection when an `AuthSession` is revoked via the database."
    )

    b.add_section_heading("11.7 Role Hierarchy and Security Boundary Verification")
    b.add_body_paragraph(
        "Role testing verifies that horizontal and vertical privilege escalation is impossible. Tests confirm that students attempting to call "
        "faculty attendance endpoints receive HTTP 403, and faculty attempting to create colleges receive HTTP 403."
    )

    b.add_section_heading("11.8 Multi-Tenant Isolation Verification")
    b.add_body_paragraph(
        "Tenant isolation tests simulate cross-tenant attacks. An authenticated user belonging to College A attempts to query student records from "
        "College B by passing `collegeId=College_B` in query parameters or URL paths. In every test case, `requireCollegeScope` intercepts the request "
        "and returns HTTP 403 Forbidden, confirming zero cross-tenant leakage."
    )

    b.add_section_heading("11.9 Attendance Invariant and Session Integrity Tests")
    b.add_body_paragraph(
        "Regression tests verify that attendance summaries obey the completeness invariant: `present + late + absent + excused + unmarked == total`. "
        "Tests also verify session locking: once `status = LOCKED`, subsequent PUT or POST mutation requests are rejected."
    )

    b.add_section_heading("11.10 Timetable Conflict & Substitution Validation Tests")
    b.add_body_paragraph(
        "Timetable tests verify that scheduling collisions are rejected. Tests attempt to book the same room or faculty member for two overlapping "
        "classes simultaneously, confirming that `validateTimetableEntries` raises HTTP 409 Conflict."
    )

    b.add_section_heading("11.11 Comprehensive Test Execution Matrices")
    b.add_body_paragraph("Tables 8 through 11 present verified test execution cases across all system tiers.")

    # Table 8: Unit & Presentation Test Cases
    t8_rows = [
        ["Test ID", "Subsystem", "Test Scenario", "Precondition & Input", "Expected Result", "Status"],
        ["TC-U01", "Backend Util", "Unicode Timeslot Normalization", "Input: '10:00 – 12:00' (en-dash)", "Returns normalized '10:00 - 12:00'", "PASS"],
        ["TC-U02", "Backend Util", "ASCII Timeslot Pass-Through", "Input: '09:00 - 10:00' (hyphen)", "Returns identical '09:00 - 10:00'", "PASS"],
        ["TC-U03", "Backend Role", "Role Normalization", "Input: 'college_admin' / 'collegeadmin'", "Normalizes to AppRole.COLLEGE_ADMIN", "PASS"],
        ["TC-W01", "Frontend UI", "Login Screen Render", "App launched in unauthenticated state", "Login form renders with email/pass fields", "PASS"],
        ["TC-W02", "Frontend UI", "Attendance Card Summary", "Session with 2 P, 1 L, 2 Excused (Total 5)", "All 4 buckets render; sum matches Total (5)", "PASS"],
        ["TC-W03", "Frontend UI", "GoRouter Unauth Guard", "Navigate to /dashboard/student while logged out", "Intercepted and redirected to /login", "PASS"]
    ]
    b.add_table_data("Unit & Presentation Test Case Execution Matrix", t8_rows[0], t8_rows[1:], [0.9, 1.1, 1.6, 1.8, 1.8, 0.7])

    # Table 9: Backend API Integration & Role Security
    t9_rows = [
        ["Test ID", "Endpoint Tested", "Test Scenario", "Security Precondition", "Expected HTTP Result", "Status"],
        ["TC-I01", "POST /auth/login", "Valid credentials", "User active in MongoDB", "200 OK + JWT Access & Refresh Token", "PASS"],
        ["TC-I02", "POST /auth/login", "Invalid password", "User exists, incorrect pass", "401 Unauthorized ('Invalid credentials')", "PASS"],
        ["TC-I03", "GET /academic/departments", "HOD queries departments", "HOD token from College A", "200 OK with College A departments only", "PASS"],
        ["TC-I04", "POST /colleges", "College Admin attempts college creation", "College Admin token", "403 Forbidden (Requires SUPER_ADMIN)", "PASS"],
        ["TC-I05", "GET /users", "Cross-tenant spoofing", "Token College A, query ?collegeId=College_B", "403 Forbidden ('Cross-college access blocked')", "PASS"],
        ["TC-I06", "POST /auth/refresh", "Revoked session refresh", "AuthSession marked isRevoked=true", "401 Unauthorized ('Session revoked')", "PASS"]
    ]
    b.add_table_data("Backend API Integration & Role Security Test Matrix", t9_rows[0], t9_rows[1:], [0.9, 1.6, 1.6, 1.6, 1.8, 0.7])

    # Table 10: Attendance Invariant & Idempotent Session Lock
    t10_rows = [
        ["Test ID", "Operation", "Test Scenario", "Data Precondition", "Expected Result", "Status"],
        ["TC-A01", "POST /attendance/sessions", "Idempotent session creation", "Submit identical timeslot twice", "Reuses existing session document (No duplicate)", "PASS"],
        ["TC-A02", "POST /sessions/:id/submit", "Complete roll call submission", "5 students marked (P, L, E)", "Records saved; session status updated", "PASS"],
        ["TC-A03", "POST /sessions/:id/lock", "Faculty locks session", "Faculty owns session", "200 OK; status=LOCKED; isLocked=true", "PASS"],
        ["TC-A04", "PUT /sessions/:id/records", "Mutation of locked session", "Session status is LOCKED", "403 Forbidden ('Session is locked')", "PASS"],
        ["TC-A05", "POST /sessions/:id/lock", "Other faculty attempts lock", "Different faculty token", "403 Forbidden ('Can only lock own sessions')", "PASS"]
    ]
    b.add_table_data("Attendance Invariant & Idempotent Session Lock Test Matrix", t10_rows[0], t10_rows[1:], [0.9, 1.6, 1.6, 1.6, 1.8, 0.7])

    # Table 11: Timetable Conflict & Schedule Overlap
    t11_rows = [
        ["Test ID", "Operation", "Test Scenario", "Conflict Precondition", "Expected Result", "Status"],
        ["TC-T01", "POST /timetables", "Valid conflict-free schedule", "All rooms and faculty free", "201 Created; timetable saved", "PASS"],
        ["TC-T02", "POST /timetables", "Faculty double-booking", "Faculty already teaching Sec B", "409 Conflict ('Faculty double-booking')", "PASS"],
        ["TC-T03", "POST /timetables", "Room occupancy clash", "Room 204 booked by another class", "409 Conflict ('Room code clash')", "PASS"],
        ["TC-T04", "POST /timetables", "Break overlap conflict", "Class scheduled during lunch break", "409 Conflict ('Break overlap')", "PASS"]
    ]
    b.add_table_data("Timetable Conflict & Schedule Overlap Test Matrix", t11_rows[0], t11_rows[1:], [0.9, 1.6, 1.6, 1.6, 1.8, 0.7])

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 12: RESULTS AND SCREEN LAYOUTS
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 12: RESULTS AND SCREEN LAYOUTS")

    b.add_body_paragraph(
        "The practical implementation of ACADEXSYNC was validated through rigorous end-to-end user experience testing across all five user roles. "
        "This chapter presents verified screenshots captured directly from the executing Flutter application running in production and baseline "
        "test environments. Each screen layout illustrates a key functional module, showcasing the responsive design, clean visual hierarchy, "
        "and rich operational capabilities engineered into the platform."
    )

    # 1. Launch & Auth Screens
    b.add_section_heading("12.1 Authentication and Onboarding Screens")
    b.add_body_paragraph(
        "Figure 12.1 illustrates the application launch screen, which initializes the environment and checks for stored credentials. "
        "Figure 12.2 shows the unified authentication screen, supporting PIN Number, email, and password entry with real-time field validation."
    )

    b.add_figure(os.path.join(BASELINE_DIR, "01_launch_screen.png"), "ACADEXSYNC Mobile Application Launch Screen", width_inches=3.2)
    b.add_figure(os.path.join(BASELINE_DIR, "login_ready.png"), "Unified Authentication and Secure Sign-in Portal", width_inches=3.2)

    # 2. Super Admin Screens
    b.add_section_heading("12.2 Super Admin Platform Governance Screens")
    b.add_body_paragraph(
        "Figure 12.3 showcases the Super Admin dashboard displaying platform-wide health metrics and college tenant counts. "
        "Figure 12.4 shows the multi-college directory, and Figure 12.5 presents the system audit log monitor."
    )

    b.add_figure(os.path.join(BASELINE_DIR, "02_super_admin_dashboard.png"), "Super Admin Platform Oversight Dashboard", width_inches=3.2)
    b.add_figure(os.path.join(P02_DIR, "super_admin__colleges.png"), "Super Admin Multi-College Tenant Directory", width_inches=3.2)
    b.add_figure(os.path.join(P02_DIR, "super_admin__audit_logs.png"), "Super Admin System-Wide Audit Log Monitor", width_inches=3.2)
    b.add_figure(os.path.join(P02_DIR, "super_admin__ai_assistant.png"), "Super Admin Gemini AI Assistant Interface", width_inches=3.2)

    # 3. College Admin Screens
    b.add_section_heading("12.3 College Admin Institutional Console Screens")
    b.add_body_paragraph(
        "Figure 12.7 depicts the College Admin operational dashboard. Figures 12.8, 12.9, and 12.10 illustrate the academic structure hierarchy, "
        "the staff/student user directory, and the comprehensive attendance report center."
    )

    b.add_figure(os.path.join(BASELINE_DIR, "03_college_admin_dashboard.png"), "College Admin Institutional Operations Dashboard", width_inches=3.2)
    b.add_figure(os.path.join(BASELINE_DIR, "03_college_admin_academics.png"), "College Admin Academic Hierarchy Setup Console", width_inches=3.2)
    b.add_figure(os.path.join(BASELINE_DIR, "03_college_admin_people.png"), "College Admin Institutional Staff & Student Directory", width_inches=3.2)
    b.add_figure(os.path.join(BASELINE_DIR, "03_college_admin_reports.png"), "College Admin Comprehensive Analytics & Report Center", width_inches=3.2)

    # 4. HOD & Faculty Screens
    b.add_section_heading("12.4 HOD & Faculty Workstation Screens")
    b.add_body_paragraph(
        "Figure 12.11 displays the HOD departmental management dashboard. Figure 12.12 shows the Faculty classroom workstation, allowing teachers "
        "to view their daily schedule and initiate period attendance."
    )

    b.add_figure(os.path.join(BASELINE_DIR, "04_hod_dashboard.png"), "Head of Department (HOD) Academic Management Dashboard", width_inches=3.2)
    b.add_figure(os.path.join(BASELINE_DIR, "05_faculty_dashboard.png"), "Faculty Classroom Management & Teaching Workstation", width_inches=3.2)

    # 5. Student Screens
    b.add_section_heading("12.5 Student Academic Portal Screens")
    b.add_body_paragraph(
        "Figure 12.13 displays the Student unified academic hub. Figure 12.14 showcases the student's dynamic weekly timetable, and Figure 12.15 "
        "presents the subject-wise attendance breakdown with real-time percentage indicators."
    )

    b.add_figure(os.path.join(BASELINE_DIR, "06_student_dashboard.png"), "Student Unified Academic Hub & Portal Dashboard", width_inches=3.2)
    b.add_figure(os.path.join(BASELINE_DIR, "06_student_timetable.png"), "Student Dynamic Weekly Timetable & Period Schedule View", width_inches=3.2)
    b.add_figure(os.path.join(BASELINE_DIR, "06_student_attendance.png"), "Student Subject-Wise Attendance Tracking & Breakdown Screen", width_inches=3.2)

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 13: LIMITATIONS AND FUTURE ENHANCEMENTS
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 13: LIMITATIONS AND FUTURE ENHANCEMENTS")

    b.add_section_heading("13.1 Current System Scope Limitations")
    b.add_body_paragraph(
        "While ACADEXSYNC comprehensively fulfills its architectural and functional objectives for polytechnic administration, the following "
        "operational boundaries are recognized in the current release:"
    )
    b.add_bullet_point("Biometric & Hardware Turnstile Integration", "Attendance roll call is currently captured digitally via authenticated faculty mobile devices. The platform does not currently interface directly with physical fingerprint scanners or RFID turnstiles.")
    b.add_bullet_point("Online Fee Payment Gateway", "The current system manages student academic records and admissions workflows but does not yet integrate payment gateways (such as Razorpay or Stripe) for tuition fee processing.")
    b.add_bullet_point("Dedicated Parent Portal", "While students and administrators receive real-time notifications, a dedicated parent mobile portal with customized guardian-specific views remains designated for future releases.")

    b.add_section_heading("13.2 Future Functional Enhancements")
    b.add_body_paragraph(
        "Future engineering releases of ACADEXSYNC are planned to incorporate several advanced enterprise capabilities:"
    )
    b.add_bullet_point("Predictive Academic Analytics", "Machine learning algorithms running on the FastAPI microservice to forecast student examination performance based on attendance patterns and continuous internal assessment marks.")
    b.add_bullet_point("Automated Biometric Edge Sync", "MQTT-based edge synchronization allowing IoT biometric devices in laboratories to automatically sync attendance logs directly into `AttendanceSession` records.")
    b.add_bullet_point("Parent Guardian Portal", "A dedicated mobile interface providing parents with direct visibility into daily attendance, academic progress, and official college announcements.")
    b.add_bullet_point("SBTET State-Level Portal Integration", "Direct API integration with the State Board of Technical Education and Training (SBTET AP) portal for automated submission of semester attendance registers and internal assessment marks.")

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 14: CONCLUSION
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 14: CONCLUSION")

    b.add_section_heading("14.1 Summary of Contributions")
    b.add_body_paragraph(
        "The ACADEXSYNC project represents a transformative leap in collegiate academic administration. Over the course of this final-year "
        "diploma engineering project, our team successfully conceptualized, architected, developed, and validated an enterprise-grade, "
        "multi-tenant Campus Management Operating System. The platform decisively resolves the chronic challenges of manual attendance registers, "
        "scheduling collisions, data fragmentation, and administrative latency."
    )
    b.add_body_paragraph(
        "Key engineering achievements include: (1) An authoritative, five-tier Role-Based Access Control architecture serving Super Admin, "
        "College Admin, HOD, Faculty, and Student users; (2) An idempotent attendance engine enforcing Unicode normalization and permanent session "
        "locking; (3) A deterministic timetable validator preventing faculty double-booking and room clashes; (4) A responsive, mobile-first Flutter client "
        "with compile-safe Riverpod state management; (5) High-priority FCM push messaging; and (6) Contextual AI assistant integration powered by Google "
        "Gemini 1.5 Flash SDK function-calling."
    )

    b.add_section_heading("14.2 Pedagogical and Engineering Takeaways")
    b.add_body_paragraph(
        "Developing ACADEXSYNC provided our project team with invaluable practical mastery across the full software engineering discipline. "
        "We gained deep expertise in modern TypeScript development, asynchronous event loops, NoSQL compound indexing in MongoDB Atlas, "
        "Clean Architecture and reactive state management in Flutter, declarative routing with GoRouter, cryptographic JWT session security, "
        "and automated regression testing. Beyond technical skills, we acquired essential collaborative competencies in Git version control, "
        "architectural documentation, and user-centric software design."
    )

    b.add_section_heading("14.3 Concluding Remarks")
    b.add_body_paragraph(
        "In conclusion, ACADEXSYNC successfully demonstrates how modern cloud-native architectures and mobile-first engineering can modernize "
        "government polytechnic and technical education institutions. By replacing fragile paper ledgers with an authoritative, auditable, and "
        "intelligent digital platform, ACADEXSYNC elevates institutional governance, conserves thousands of instructional hours, and empowers "
        "educators and students to achieve academic excellence. The platform stands fully verified, documented, and prepared for institutional deployment."
    )

    b.add_page_break()

    # ==============================================================================
    # REFERENCES & APPENDICES
    # ==============================================================================
    b.add_chapter_heading("REFERENCES & OFFICIAL DOCUMENTATION")

    refs = [
        "1. Google Flutter Documentation. 'Flutter Architectural Overview and State Management with Riverpod.' Google Developer Library, 2024. https://docs.flutter.dev",
        "2. Node.js Foundation. 'Node.js v20 LTS Runtime Architecture and Asynchronous I/O.' OpenJS Foundation, 2024. https://nodejs.org",
        "3. Express.js Project. 'Express Routing, Middleware, and Security Best Practices.' OpenJS Foundation, 2024. https://expressjs.com",
        "4. MongoDB Inc. 'MongoDB Atlas Architecture Guide: Compound Indexing and Multi-Tenant Partitioning.' MongoDB Documentation, 2024. https://www.mongodb.com/docs",
        "5. Google Cloud. 'Firebase Cloud Messaging (FCM) Architecture and Multicast Distribution.' Google Cloud Documentation, 2024. https://firebase.google.com/docs/cloud-messaging",
        "6. Google DeepMind. 'Gemini 1.5 Flash: Structured Tool Calling and Function Declarations.' Google Developer Documentation, 2024. https://ai.google.dev",
        "7. State Board of Technical Education and Training, Andhra Pradesh (SBTET AP). 'Curriculum-20 (C-20) Scheme and Guidelines for Diploma in Computer Engineering.' SBTET AP, 2024.",
        "8. Martin, Robert C. 'Clean Architecture: A Craftsman's Guide to Software Structure and Design.' Prentice Hall, 2017.",
        "9. Fielding, Roy Thomas. 'Architectural Styles and the Design of Network-based Software Architectures.' Doctoral dissertation, University of California, Irvine, 2000.",
        "10. Rescorla, E. 'The Transport Layer Security (TLS) Protocol Version 1.3.' RFC 8446, Internet Engineering Task Force (IETF), 2018."
    ]

    for r in refs:
        p_ref = b.doc.add_paragraph()
        p_ref.paragraph_format.line_spacing = 1.3
        p_ref.paragraph_format.space_after = Pt(4)
        run_r = p_ref.add_run(r)
        run_r.font.name = "Times New Roman"
        run_r.font.size = Pt(10)

    b.add_page_break()

    # APPENDIX A: API INVENTORY
    b.add_chapter_heading("APPENDIX A: BACKEND REST API ROUTE INVENTORY")
    b.add_body_paragraph("Summary inventory of verified version 1 REST routes exposed by the ACADEXSYNC backend gateway.")

    api_routes = [
        ["HTTP Method", "Endpoint URI", "Authorized Roles", "Primary Functional Purpose"],
        ["POST", "/api/v1/auth/login", "Public / All", "Authenticates credentials, generates AuthSession, issues JWT"],
        ["POST", "/api/v1/auth/refresh", "Public / All", "Refreshes expired access token via active refresh session"],
        ["POST", "/api/v1/auth/logout", "Authenticated", "Revokes authoritative AuthSession document in MongoDB"],
        ["POST", "/api/v1/auth/activate/verify", "Public", "Validates 8-character single-use invitation token"],
        ["POST", "/api/v1/auth/activate/complete", "Public", "Sets user password and transitions account to ACTIVE"],
        ["POST", "/api/v1/attendance/sessions", "FACULTY, HOD, ADMIN", "Creates or updates attendance session idempotently"],
        ["POST", "/api/v1/attendance/sessions/:id/submit", "FACULTY, HOD", "Submits student roll call records (P, L, A, E)"],
        ["POST", "/api/v1/attendance/sessions/:id/lock", "FACULTY, HOD, ADMIN", "Permanently locks session; creates audit log"],
        ["GET", "/api/v1/attendance/student/history", "STUDENT, FACULTY, HOD", "Retrieves student attendance breakdown and percentage"],
        ["GET", "/api/v1/timetables/section/:id", "All Roles", "Fetches weekly timetable grid with teacher substitutions"],
        ["POST", "/api/v1/timetables", "HOD, COLLEGE_ADMIN", "Constructs new timetable with conflict validation"],
        ["POST", "/api/v1/requests", "STUDENT, FACULTY", "Submits formal leave, OD, or grievance application"],
        ["PUT", "/api/v1/requests/:id/status", "HOD, COLLEGE_ADMIN", "Approve/Reject request; auto-adjusts attendance"],
        ["POST", "/api/v1/notifications/announcements", "COLLEGE_ADMIN, HOD", "Publishes institutional broadcast notice"],
        ["POST", "/api/v1/ai/chat", "Authenticated", "Executes multi-turn Gemini 1.5 Flash tool calling query"]
    ]
    b.add_table_data("Verified Backend REST API Route Inventory", api_routes[0], api_routes[1:], [1.1, 2.3, 1.4, 2.5])

    b.add_page_break()

    # APPENDIX B: DATABASE SCHEMA DICTIONARY
    b.add_chapter_heading("APPENDIX B: DATABASE SCHEMA & FIELD DICTIONARY")
    b.add_body_paragraph("Summary dictionary of core canonical collections, primary keys, and indexing rules.")

    schema_dict = [
        ["Collection Name", "Canonical Primary Key", "Tenant Partition Key", "Key Compound Indexes", "Owning Entity"],
        ["colleges", "_id (ObjectId)", "Self (Root)", "{ code: 1, name: 1 }", "College"],
        ["departments", "_id (ObjectId)", "collegeId", "{ collegeId: 1, code: 1 }", "Department"],
        ["courses", "_id (ObjectId)", "collegeId", "{ collegeId: 1, departmentId: 1, code: 1 }", "Course"],
        ["academicyears", "_id (ObjectId)", "collegeId", "{ collegeId: 1, name: 1 }", "AcademicYear"],
        ["semesters", "_id (ObjectId)", "collegeId", "{ collegeId: 1, courseId: 1, number: 1 }", "Semester"],
        ["sections", "_id (ObjectId)", "collegeId", "{ collegeId: 1, semesterId: 1, name: 1 }", "Section"],
        ["subjects", "_id (ObjectId)", "collegeId", "{ collegeId: 1, semesterId: 1, code: 1 }", "Subject"],
        ["facultyassignments", "_id (ObjectId)", "collegeId", "{ collegeId: 1, facultyId: 1, subjectId: 1, sectionId: 1 }", "FacultyAssignment"],
        ["studentenrollments", "_id (ObjectId)", "collegeId", "{ collegeId: 1, studentId: 1, semesterId: 1, sectionId: 1 }", "StudentEnrollment"],
        ["timetables", "_id (ObjectId)", "collegeId", "{ collegeId: 1, sectionId: 1, semesterId: 1 }", "Timetable"],
        ["attendancesessions", "_id (ObjectId)", "collegeId", "{ collegeId: 1, sectionId: 1, subjectId: 1, date: 1, timeSlot: 1 }", "AttendanceSession"],
        ["attendancerecords", "_id (ObjectId)", "collegeId", "{ collegeId: 1, sessionId: 1, studentId: 1 }", "AttendanceRecord"],
        ["requests", "_id (ObjectId)", "collegeId", "{ collegeId: 1, requesterId: 1, status: 1 }", "Request"],
        ["authsessions", "_id (ObjectId)", "User-scoped", "{ sessionId: 1, userId: 1 }", "AuthSession"]
    ]
    b.add_table_data("Canonical Database Schema & Field Index Dictionary", schema_dict[0], schema_dict[1:], [1.4, 1.2, 1.2, 2.0, 1.4])

    b.add_page_break()

    # APPENDIX C: ABBREVIATIONS
    b.add_chapter_heading("APPENDIX C: TECHNICAL ABBREVIATIONS GLOSSARY")
    b.add_body_paragraph("Authoritative glossary of technical abbreviations utilized throughout the project report.")

    glossary = [
        ["API", "Application Programming Interface: A defined software intermediary enabling applications to communicate."],
        ["bcrypt", "Adaptive cryptographic hash function designed specifically for secure password storage."],
        ["Clean Architecture", "Software architectural paradigm segregating business entities, use cases, and interfaces."],
        ["FCM", "Firebase Cloud Messaging: Cross-platform messaging service for delivering push notifications."],
        ["GoRouter", "Declarative URL-based routing framework for Flutter supporting stateful shell routes."],
        ["JWT", "JSON Web Token: Open standard (RFC 7519) defining a compact format for securely transmitting JSON claims."],
        ["NoSQL", "Non-relational database architecture optimized for distributed document storage and horizontal scaling."],
        ["Riverpod", "Reactive state management framework for Flutter providing compile-time safe dependency injection."],
        ["UUIDv4", "Universally Unique Identifier version 4: 128-bit label generated using pseudo-random numbers."]
    ]
    b.add_table_data("Comprehensive Technical Glossary", ["Abbreviation", "Technical Definition"], glossary, [1.5, 4.2])

print("Chapters 10 to 14 generator ready.")

