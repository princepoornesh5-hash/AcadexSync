"""
ACADEXSYNC - Chapters 1 to 5 Generator
Covers Introduction, Project Description, Computational Environment, Feasibility Study, and System Analysis.
"""
from docx.shared import Pt, RGBColor
from report_builder import AcadexDocBuilder

def generate_chapters_1_to_5(b: AcadexDocBuilder):
    # ==============================================================================
    # CHAPTER 1: INTRODUCTION
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 1: INTRODUCTION")

    b.add_section_heading("1.1 Digital Transformation in Educational Administration")
    b.add_body_paragraph(
        "Over the past decade, the rapid evolution of information and communication technologies has revolutionized organizational "
        "operations across government, enterprise, and educational sectors. In higher education and polytechnic engineering institutions, "
        "digital transformation is no longer a peripheral luxury; it has become an indispensable imperative for academic integrity, "
        "institutional governance, and operational efficiency. Academic administration encompasses a vast web of highly interdependent "
        "responsibilities: scheduling lecture timetables across multiple physical classrooms and laboratories, recording daily and period-wise "
        "attendance, tracking continuous assessment marks, managing faculty workloads, coordinating curricular notes, and processing student "
        "applications for leave or duty exemptions. In traditional polytechnic institutions operating under state technical education boards, "
        "these processes have historically been administered through manual paper registers, static ledger books, and fragmented desktop spreadsheets."
    )
    b.add_body_paragraph(
        "While manual methods sufficed during earlier eras characterized by smaller student cohorts and fixed curricular regimes, the expansion "
        "of contemporary technical education has strained manual administration to its breaking point. Modern polytechnic colleges manage "
        "hundreds to thousands of students enrolled across diverse disciplines such as Computer Engineering, Mechanical Engineering, "
        "Civil Engineering, and Electronics. Under this operational scale, the continued reliance upon physical registers introduces intolerable "
        "friction, administrative overhead, human error, and vulnerability to record falsification. The digital transformation of campus management "
        "substitutes error-prone physical handling with automated, deterministic, and auditable digital workflows that operate synchronously "
        "across all institutional tiers."
    )

    b.add_section_heading("1.2 Problems with Manual Attendance Registers and Disconnected Records")
    b.add_body_paragraph(
        "The core administrative vulnerability in collegiate operations lies in the capture and consolidation of student attendance. "
        "Under the manual paradigm, faculty members physically carry paper attendance ledgers from classroom to classroom during each period. "
        "This practice suffers from severe structural deficiencies:"
    )
    b.add_bullet_point(
        "Vulnerability to Proxies and Data Tampering",
        "Physical attendance callouts in crowded classrooms are notoriously susceptible to fraudulent proxy responses. Furthermore, physical "
        "ledgers can be easily modified after the fact through unauthorized mark alterations, erasure, or unverified manual additions."
    )
    b.add_bullet_point(
        "Severe Latency in Data Consolidation",
        "Because attendance marks remain locked inside physical registers or individual faculty notebooks, aggregate attendance percentages "
        "are typically calculated only once a month or at the end of the semester. Consequently, chronically absent students and their parents "
        "receive no timely intervention or warning alerts until they are already ineligible to appear for board examinations."
    )
    b.add_bullet_point(
        "Absence of Cross-System Synchronization",
        "Attendance records remain completely disconnected from the academic timetable, leave management workflows, and internal examination ledgers. "
        "If a student is granted official On-Duty (OD) status for a technical symposium, the sanctioning letter frequently fails to reach "
        "the concerned subject faculty in time, resulting in unjustified attendance penalties."
    )
    b.add_bullet_point(
        "Physical Loss and Catastrophic Record Destruction",
        "Physical ledgers are vulnerable to physical damage, misplacement, fire, or ink deterioration. Once lost, reconstructing past attendance "
        "records for statutory auditing or SBTET verification becomes virtually impossible."
    )

    b.add_section_heading("1.3 Purpose and Vision of ACADEXSYNC")
    b.add_body_paragraph(
        "ACADEXSYNC is conceived and engineered to serve as an authoritative, multi-tenant Campus Management Operating System designed specifically "
        "to eradicate the fragmentation of technical educational administration. The vision of ACADEXSYNC is to establish a singular, unified "
        "digital backbone that synchronously links institutional governance, departmental oversight, classroom teaching operations, and student "
        "academic life into a coherent, real-time ecosystem."
    )
    b.add_body_paragraph(
        "Rather than functioning merely as a cosmetic portal or a set of disparate utility screens, ACADEXSYNC establishes an immutable, "
        "authoritative source of truth for every campus entity. Every lecture timeslot, student enrollment, faculty assignment, attendance roll call, "
        "and administrative approval is verified by deterministic server-side business rules before being permanently committed. The system eliminates "
        "informal communication silos by delivering instantaneous push notifications, automated threshold breach alerts, and intelligent "
        "AI-assisted student query resolution."
    )

    b.add_section_heading("1.4 Need for Centralized Academic Information")
    b.add_body_paragraph(
        "Educational institutions require unified visibility across their entire operational hierarchy. When administrative information is scattered "
        "across isolated silos—such as standalone Excel files in the Principal's office, paper diaries in departmental HOD cabins, and private "
        "WhatsApp groups between teachers and students—institutional leadership is effectively blind to daily operational realities. "
        "Centralized academic information ensures that:"
    )
    b.add_bullet_point("Real-Time Institutional Oversight", "The Principal and College Administrators can monitor real-time class conductance, period attendance percentages, and faculty workloads with zero latency across all departments simultaneously.")
    b.add_bullet_point("Deterministic Rule Enforcement", "Institutional policies, such as the mandatory 75% minimum attendance requirement for SBTET board examination eligibility, are computed automatically and transparently, eliminating arbitrary manual discretion.")
    b.add_bullet_point("Statutory Compliance and Auditing", "Complete immutable audit trails are recorded for every critical operation, including grade updates, attendance modifications, and administrative role assignments, satisfying rigorous academic accreditation standards.")

    b.add_section_heading("1.5 Target Users and Institutional Context")
    b.add_body_paragraph(
        "ACADEXSYNC is specifically architected for deployment within government polytechnics, affiliated technical engineering colleges, "
        "and multi-campus technical institutions governed by boards of technical education such as the State Board of Technical Education "
        "and Training, Andhra Pradesh (SBTET AP). The institutional environment comprises five distinct user categories:"
    )
    b.add_bullet_point("1. Super Admin", "Platform administrators who oversee multi-college provisioning, global institutional onboarding, system health monitoring, and platform-wide security auditing.")
    b.add_bullet_point("2. College Admin", "Institutional authorities (Principals, Academic Directors, and Administrative Registrars) who configure college-specific academic years, maintain departmental structures, provision staff credentials, and oversee college-wide performance.")
    b.add_bullet_point("3. Head of Department (HOD)", "Academic leaders who coordinate departmental curriculum execution, construct and publish weekly timetables, balance faculty workloads, approve student leave/OD applications, and manage teacher substitutions.")
    b.add_bullet_point("4. Faculty Members", "Instructional staff who conduct classroom lectures, execute period-wise student roll calls, lock attendance sessions, upload syllabus notes, and publish coursework assignments.")
    b.add_bullet_point("5. Students", "Enrolled diploma engineering candidates who track their daily class schedules, monitor personal attendance percentages, access verified study materials, submit formal academic requests, and interact with the AI assistant.")

    b.add_section_heading("1.6 Scope and Project Limitations")
    b.add_body_paragraph(
        "The project scope encompasses complete vertical slices across core campus domains: multi-tenant institutional partitioning, "
        "secure authentication with session revocation, five-tier RBAC enforcement, dynamic timetable construction with conflict validation, "
        "idempotent attendance marking with session locking, formal student request processing, push notification delivery, and an AI assistant "
        "with function-calling tool execution. "
    )
    b.add_body_paragraph(
        "Certain operational boundaries are explicitly identified as scope limitations in the current implementation: physical biometric "
        "hardware integration (e.g. fingerprint scanners or RFID turnstiles) is not directly interfaced, as attendance is captured via authenticated "
        "faculty mobile clients; payment gateway integration for student tuition fee collection is designated for future phases; and parent-specific "
        "mobile access portals remain planned for subsequent architectural releases."
    )

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 2: PROJECT DESCRIPTION
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 2: PROJECT DESCRIPTION")

    b.add_section_heading("2.1 Problem Statement")
    b.add_body_paragraph(
        "Technical education institutions currently lack an integrated, dependable, and tamper-resistant operating platform to manage daily "
        "academic operations. The coexistence of paper registers, decentralized spreadsheets, and informal messaging applications produces "
        "severe information asymmetry, frequent attendance discrepancies, untracked timetable clashes, delayed grievance resolution, and an "
        "absence of auditability. There is an urgent necessity for an enterprise-grade multi-tenant software system that unifies these critical "
        "academic workflows, enforces rigorous cryptographic security and tenant isolation, and provides real-time transparency to administrators, "
        "faculty, and students alike."
    )

    b.add_section_heading("2.2 Project Objectives")
    b.add_body_paragraph("To decisively resolve the aforementioned problem, ACADEXSYNC establishes the following primary engineering objectives:")
    b.add_bullet_point("Objective 1: Multi-Tenant Architecture", "Engineer a robust multi-tenant data architecture where multiple colleges can securely operate within an isolated, partitioned MongoDB database while ensuring zero cross-tenant data leakage.")
    b.add_bullet_point("Objective 2: Authoritative Identity and Session Security", "Implement an authoritative authentication system using JSON Web Tokens (JWT) coupled with a stateful, database-backed AuthSession store enabling instant cross-device session validation and revocation.")
    b.add_bullet_point("Objective 3: Idempotent Attendance & Invariant Integrity", "Design an attendance ingestion engine that enforces Unicode normalization, compound index uniqueness, and strict mathematical completeness invariants (`present + late + absent + excused + unmarked == total`), backed by permanent session locking.")
    b.add_bullet_point("Objective 4: Timetable Conflict & Substitution Management", "Construct a conflict-free timetable management engine capable of validating room availability, faculty double-booking, and period overlaps, augmented with temporary teacher substitution capabilities.")
    b.add_bullet_point("Objective 5: Formalized Multi-Tier Request Center", "Create an asynchronous request and approval workflow allowing students to submit leave and OD applications with document verification, multi-level review routing, and automated attendance adjustments.")
    b.add_bullet_point("Objective 6: Contextual AI Assistant Integration", "Incorporate Google Gemini 1.5 Flash SDK tool-calling capabilities to allow authorized users to query personalized schedules, attendance standings, and institutional guidelines via natural language.")

    b.add_section_heading("2.3 Project Scope")
    b.add_body_paragraph(
        "ACADEXSYNC spans the full software development lifecycle, encompassing requirements analysis, UML architectural modeling, "
        "REST API design, database schema formulation, mobile-first responsive UI implementation, automated integration testing, and production "
        "containerization. The scope incorporates 37 canonical domain entities, 21 REST controllers, 31 core backend services, and 131 declarative "
        "frontend routes serving five discrete institutional roles."
    )

    b.add_section_heading("2.4 Motivation for Selecting the Project")
    b.add_body_paragraph(
        "As final-year Diploma in Computer Engineering students at Sri Venkateswara Government Polytechnic, Tirupati, our team has directly "
        "experienced the acute frustrations of manual institutional administration. We witnessed faculty members spending up to 15 minutes of each "
        "lecture period manually taking roll call in physical registers, students running between departments to obtain physical signatures on OD letters, "
        "and classmates being blindsided by attendance shortages at the semester's end. Selecting ACADEXSYNC as our final-year project allows us to "
        "apply our comprehensive polytechnic curriculum—encompassing software engineering, database management systems, computer networks, and modern "
        "mobile application development—to engineer a production-ready solution that solves real-world operational challenges in our own academic community."
    )

    b.add_section_heading("2.5 Proposed Solution Overview")
    b.add_body_paragraph(
        "The proposed solution is ACADEXSYNC: an enterprise-grade, multi-tier campus operating system comprising a high-performance cross-platform "
        "Flutter frontend, a Node.js/TypeScript REST API gateway, a MongoDB Atlas persistence engine, and a Python FastAPI AI microservice. "
        "The solution replaces all physical registers with secure digital workflows accessible from mobile smartphones, tablets, and desktop workstations. "
        "Deterministic server-side middleware enforces strict tenant boundaries, role hierarchies, and session states, ensuring unmatched data security."
    )

    b.add_section_heading("2.6 Expected Quantitative & Qualitative Benefits")
    b.add_body_paragraph("The deployment of ACADEXSYNC yields profound measurable benefits across the institution:")
    b.add_bullet_point("90% Reduction in Roll Call Latency", "Digital attendance marking with pre-populated student rosters reduces roll call duration from 15 minutes to under 60 seconds per lecture period, conserving thousands of instructional hours annually.")
    b.add_bullet_point("100% Elimination of Attendance Calculation Errors", "Automated real-time aggregation completely eliminates manual mathematical errors in attendance percentages, eliminating disputed detention lists.")
    b.add_bullet_point("Zero Timetable Scheduling Collisions", "Deterministic backend validation prevents faculty double-booking and room collisions at the time of schedule creation.")
    b.add_bullet_point("Instantaneous Institutional Communication", "Broadcast notices and critical student alerts are delivered in real time via Firebase Cloud Messaging push notifications, eliminating reliance upon informal WhatsApp notices.")

    b.add_section_heading("2.7 Functional Requirements")
    b.add_body_paragraph("The functional requirements of ACADEXSYNC are organized across seven core functional modules:")
    b.add_bullet_point("FR-1: Authentication & Activation", "The system shall authenticate users via PIN Number, email, or phone; enforce bcrypt password hashing; support 6-digit OTP verification; and facilitate account onboarding via unique single-use invitation codes.")
    b.add_bullet_point("FR-2: Role-Based Dashboarding", "The system shall dynamically resolve the authenticated user's active role and present tailored dashboards for Super Admin, College Admin, HOD, Faculty, and Student users.")
    b.add_bullet_point("FR-3: Attendance & Session Locking", "The system shall permit authorized faculty to create attendance sessions, record student statuses (present, late, absent, excused), lock sessions permanently against tampering, and generate audit logs.")
    b.add_bullet_point("FR-4: Timetable & Substitution Engine", "The system shall support weekly timetable grid construction, room allocations, faculty double-booking checks, and temporary teacher substitution overrides.")
    b.add_bullet_point("FR-5: Academic Structure Hierarchy", "The system shall model multi-level academic hierarchies: College -> Department -> Course -> Academic Year -> Semester -> Section -> Subject -> Faculty Assignment.")
    b.add_bullet_point("FR-6: Request Center & Approvals", "The system shall allow students to submit leave and OD requests, route them to designated approvers based on scope, track status transitions, and update attendance automatically upon approval.")
    b.add_bullet_point("FR-7: Contextual AI Assistant", "The system shall process natural language queries using Google Gemini 1.5 Flash SDK, execute verified server-side tool functions, and stream real-time answers.")

    b.add_section_heading("2.8 Non-Functional Requirements")
    b.add_bullet_point("NFR-1: Security & Confidentiality", "All network traffic shall be encrypted via HTTPS/TLS 1.3. Passwords shall be hashed using bcrypt (salt rounds = 10). Session tokens shall be cryptographically signed using HS256/RS256 algorithms.")
    b.add_bullet_point("NFR-2: Multi-Tenant Data Isolation", "The backend middleware shall enforce strict tenant isolation, guaranteeing that users from College A cannot query, mutate, or discover data belonging to College B under any condition.")
    b.add_bullet_point("NFR-3: Performance & Response Time", "REST API endpoints shall respond within 250 milliseconds under standard load. The Flutter client shall maintain 60 frames per second (fps) during UI animations and scrolling.")
    b.add_bullet_point("NFR-4: Availability & Fault Tolerance", "The database cluster shall maintain 99.9% uptime with automated replication and failover in MongoDB Atlas. Unhandled frontend exceptions shall be caught by error boundaries without crashing the application.")

    b.add_section_heading("2.9 Assumptions and Technical Dependencies")
    b.add_body_paragraph(
        "System operation assumes continuous internet connectivity for live database synchronization, though client-side caching enables "
        "graceful offline viewing. Operating assumptions require that institutional administrators maintain accurate faculty assignments and "
        "that students possess Android/iOS smartphones or web browsers compatible with modern HTML5 and Flutter Web standards."
    )

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 3: COMPUTATIONAL ENVIRONMENT
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 3: COMPUTATIONAL ENVIRONMENT")

    b.add_section_heading("3.1 Hardware Requirements")
    b.add_body_paragraph(
        "ACADEXSYNC is engineered to maintain high computational efficiency across both server infrastructure and client edge devices. "
        "The application architecture distributes computational loads: heavy relational aggregations and AI tool executions are processed by "
        "the backend server cluster, while view rendering and state reconciliation occur smoothly on the client device."
    )

    hw_specs = [
        ["Subsystem", "Minimum Specification", "Recommended Production Specification"],
        ["Backend API Server", "2 vCPU Cores, 4 GB RAM, 20 GB SSD", "4+ vCPU Cores, 8+ GB RAM, High-speed NVMe Storage"],
        ["MongoDB Atlas Host", "Shared Tier (M0 / M2 Cluster)", "Dedicated M10+ Multi-AZ Replica Set Cluster"],
        ["AI Microservice Host", "2 vCPU Cores, 4 GB RAM (Python 3.11)", "4 vCPU Cores, 8 GB RAM with Container Orchestration"],
        ["Client Mobile Devices", "Android 8.0 (Oreo) or iOS 12.0+, 2 GB RAM", "Android 12+ or iOS 15+, 4+ GB RAM, Full HD Display"],
        ["Client Desktop / Web", "Dual Core 2.0 GHz CPU, 4 GB RAM", "Quad Core 2.5+ GHz CPU, 8+ GB RAM, Chrome/Edge/Safari"]
    ]
    b.add_table_data("Minimum and Recommended Hardware Specifications", hw_specs[0], hw_specs[1:], [1.6, 2.0, 2.1])

    b.add_section_heading("3.2 Software Requirements & Version Specifications")
    b.add_body_paragraph(
        "The complete software environment has been verified against the actual repository source code and dependency manifests. "
        "Every dependency has been locked to ensure deterministic, reproducible builds across staging and production environments."
    )

    sw_specs = [
        ["Component / Technology", "Software / Framework Name", "Verified Production Version", "Architectural Role"],
        ["Mobile & Web Frontend", "Google Flutter SDK", "3.24.x (Dart 3.5.x)", "Cross-platform responsive client application"],
        ["State Management", "Flutter Riverpod", "2.5.x", "Reactive, compile-safe dependency & state injection"],
        ["Client Routing", "GoRouter", "14.2.x", "Declarative URL routing and role-based route guards"],
        ["Network Client", "Dio", "5.4.x", "HTTP client with automated JWT 401 refresh interceptors"],
        ["Backend Gateway Runtime", "Node.js (LTS)", "v20.x / v22.x LTS", "High-throughput asynchronous JavaScript runtime"],
        ["Programming Language", "TypeScript", "5.4.x", "Type-safe compile-time verified backend development"],
        ["API Web Framework", "Express.js", "4.19.x", "Lightweight, robust HTTP REST micro-framework"],
        ["Object Data Modeling", "Mongoose", "8.3.x", "MongoDB schema validation, indexing, and middleware"],
        ["Primary Database", "MongoDB Atlas", "7.0+ Enterprise Server", "Document-oriented NoSQL multi-tenant database"],
        ["In-Memory Cache & Store", "Redis (Upstash / Cloud)", "7.x", "High-speed token revocation & rate limiting cache"],
        ["AI Microservice Runtime", "Python / FastAPI", "Python 3.11+ / FastAPI 0.111+", "Asynchronous microservice for constraint solving"],
        ["Generative AI SDK", "Google Gen AI SDK", "0.1.1 (@google/genai)", "Gemini 1.5 Flash function-calling tool execution"],
        ["Cloud Storage CDN", "ImageKit SDK", "5.0.x", "Secure CDN file storage for study notes and documents"],
        ["Push Messaging", "Firebase Admin SDK", "12.0.x", "FCM push token management and multicast distribution"]
    ]
    b.add_table_data("Verified Core Technology Software Stack & Versions", sw_specs[0], sw_specs[1:], [1.3, 1.5, 1.4, 1.5])

    b.add_section_heading("3.3 Technology Stack Evaluation & Architectural Rationale")
    b.add_body_paragraph(
        "The selection of this technology stack was dictated by rigorous engineering considerations. Flutter was chosen over native Android "
        "(Kotlin) or React Native due to its single-codebase compiling efficiency, high-performance Impeller graphics engine, and pixel-perfect "
        "consistency across Android, iOS, and Web. Node.js with TypeScript was selected for the API gateway to exploit its asynchronous, "
        "non-blocking I/O event loop, which effortlessly handles thousands of concurrent roll call submissions and real-time SSE connections. "
        "MongoDB Atlas was selected for its schema flexibility, native JSON mapping, and potent indexing capabilities, enabling compound "
        "tenant keys ({ collegeId: 1, sectionId: 1, date: 1 }) to deliver sub-millisecond query responses."
    )

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 4: FEASIBILITY STUDY
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 4: FEASIBILITY STUDY")

    b.add_section_heading("4.1 Technical Feasibility")
    b.add_body_paragraph(
        "A technical feasibility study assesses whether the proposed software engineering goals can be achieved utilizing available "
        "programming technologies, infrastructure, and technical competencies. ACADEXSYNC demonstrates complete technical feasibility: "
        "Flutter 3.x provides mature, stable cross-platform mobile frameworks with extensive native hardware abstractions; Node.js and Express.js "
        "represent the industry benchmark for high-concurrency RESTful APIs; and MongoDB Atlas provides enterprise-grade scalability, automated "
        "clustering, and high-availability replication. Our project team possessed the requisite software competencies in TypeScript, Dart, "
        "database modeling, and REST protocol design to develop and verify all system components."
    )

    b.add_section_heading("4.2 Operational Feasibility")
    b.add_body_paragraph(
        "Operational feasibility evaluates how seamlessly the solution integrates into the daily routines of institutional personnel. "
        "ACADEXSYNC is engineered with a mobile-first philosophy, recognizing that faculty members and students predominantly interact via "
        "smartphones. The intuitive user interface requires minimal operational training: faculty can complete attendance marking in four screen "
        "taps, and students can view daily timetables on a single consolidated dashboard. By maintaining familiar polytechnic terminology "
        "(such as PIN Numbers, Semesters, Sections, and HOD approvals), the system achieves enthusiastic institutional acceptance and "
        "eliminates user resistance."
    )

    b.add_section_heading("4.3 Economic Feasibility")
    b.add_body_paragraph(
        "Economic feasibility examines the cost-benefit ratio of system implementation and maintenance. Traditional paper administration incurs "
        "continuous recurring expenditures on paper ledgers, printing, physical stationery, and manual auditing labor. ACADEXSYNC relies upon "
        "open-source foundational technologies (Flutter, Node.js, Express, FastAPI) requiring zero proprietary licensing fees. Cloud hosting utilizes "
        "highly cost-effective managed tiers (MongoDB Atlas, Render/AWS, Firebase free-tier FCM, and ImageKit free bandwidth quotas), ensuring "
        "that operational expenditure remains negligible compared to the thousands of administrative hours saved."
    )

    b.add_section_heading("4.4 Maintenance Feasibility")
    b.add_body_paragraph(
        "The software architecture strictly adheres to Clean Architecture principles on the frontend and Layered MVC/Service patterns on the backend. "
        "Clear separation of concerns ensures that modifications to database schemas do not break client presentation widgets. Automated test suites "
        "spanning 51 integration tests and 138 widget tests provide robust regression barriers, ensuring straightforward long-term maintainability."
    )

    b.add_section_heading("4.5 Deployment and Scaling Considerations")
    b.add_body_paragraph(
        "The backend API gateway is completely stateless, externalizing session state to MongoDB and in-memory caches. This enables horizontal "
        "scaling across multi-instance Docker containers behind a reverse proxy (NGINX or cloud load balancers). Multi-tenant scoping guarantees "
        "that adding fifty additional colleges requires zero schema modifications or code alterations, proving boundless architectural scalability."
    )

    b.add_page_break()

    # ==============================================================================
    # CHAPTER 5: SYSTEM ANALYSIS
    # ==============================================================================
    b.add_chapter_heading("CHAPTER 5: SYSTEM ANALYSIS")

    b.add_section_heading("5.1 Existing Academic Management Approaches")
    b.add_body_paragraph(
        "Collegiate academic management systems currently in operation fall into three broad categories: (1) Completely manual paper-based "
        "ledger systems; (2) Disjointed desktop spreadsheet tools (e.g., individual teachers maintaining private Microsoft Excel files); and "
        "(3) Legacy monolithic web portals built on outdated PHP/Java architectures that lack mobile responsiveness and real-time synchronization. "
        "In typical government polytechnics, daily operations remain almost entirely paper-driven."
    )

    b.add_section_heading("5.2 Deficiencies and Risks of Conventional Systems")
    b.add_body_paragraph("Critical analysis of existing methodologies exposes several crippling operational vulnerabilities:")
    b.add_bullet_point("Absence of Idempotency & Duplicate Entries", "Manual record entries and rudimentary spreadsheets lack compound uniqueness constraints. When faculty mark makeup classes or record attendance offline, duplicate records and conflicting timeslots frequently corrupt database integrity.")
    b.add_bullet_point("Data Fragmentation and Synchronization Lag", "Academic data is segregated across unconnected islands. Examination branches, departmental offices, and hostel wardens maintain competing, out-of-sync student attendance totals.")
    b.add_bullet_point("Zero Proactive Warning Mechanisms", "Students unaware of marginal attendance declines are routinely shocked by sudden detention notices issued days before final examinations, generating intense stress and administrative friction.")

    b.add_section_heading("5.3 Proposed ACADEXSYNC Solution")
    b.add_body_paragraph(
        "ACADEXSYNC replaces this broken paradigm with a reactive, unified operating system. Every transaction is authenticated, authorized, "
        "scoped to its institutional tenant, and committed to a centralized cloud database. Real-time push notifications alert students instantly "
        "to attendance changes or timetable updates, while deterministic session locking prevents retrospective tampering."
    )

    b.add_section_heading("5.4 Distinctive Advantages of Proposed Architecture")
    b.add_bullet_point("Unified Multi-Tenant Isolation", "A single backend deployment securely serves multiple colleges with mathematical data partitioning.")
    b.add_bullet_point("Idempotent Roll Call Processing", "Unicode normalization and compound indexing guarantee that accidental double-taps or network retries never generate duplicate attendance sessions.")
    b.add_bullet_point("Stateful Session Security", "Instantaneous cross-device session termination via authoritative database-backed session tracking.")

    b.add_section_heading("5.5 Comprehensive Comparative Evaluation Matrix")
    b.add_body_paragraph("Table 5 provides a rigorous point-by-point comparison between conventional manual methods and ACADEXSYNC.")

    comp_rows = [
        ["Feature / Capability", "Conventional Manual Approach", "ACADEXSYNC Platform"],
        ["Attendance Ingestion Time", "10–15 minutes per period", "< 60 seconds via digital roster"],
        ["Tamper Resistance", "Vulnerable to eraser & pen edits", "Immutable DB records with session locking"],
        ["Attendance Invariant", "Frequent summation discrepancies", "Strict invariant enforcement (`total == sum`)"],
        ["Timetable Clash Detection", "Manual human review (frequent clashes)", "Deterministic automated collision rejection"],
        ["Request Approval Cycle", "3–7 days (physical letters & signatures)", "< 2 hours via multi-tier digital workflow"],
        ["Student Visibility", "Monthly / semester-end ledger audits", "Instant real-time smartphone dashboard"],
        ["Parent & Staff Alerts", "Delayed postal notices or none", "Instant FCM push notifications & SSE"],
        ["Data Loss Risk", "Catastrophic (physical ledger damage)", "Zero (automated cloud backups & failover)"],
        ["Multi-Tenant Isolation", "Not applicable (physical filing)", "Strict tenant isolation via `collegeId`"]
    ]
    b.add_table_data("Quantitative Comparison: Manual vs ACADEXSYNC Approaches", comp_rows[0], comp_rows[1:], [1.6, 2.0, 2.1])

    b.add_section_heading("5.6 Core Operational Workflows")
    b.add_body_paragraph(
        "The system coordinates four primary operational pathways: (1) The Institutional Provisioning Workflow, wherein Super Admin provisions "
        "a College, College Admin configures academic years and departments, and staff are onboarded via single-use invitation tokens; (2) The Teaching "
        "and Roll Call Workflow, wherein faculty view today's classes, take period roll call, submit records, and trigger permanent session locking; "
        "(3) The Student Request and Absence Workflow, wherein students apply for leave or OD, approvers review attached proof, and approvals automatically "
        "mark attendance as 'excused'; and (4) The Real-Time Alert Workflow, wherein announcements and attendance warnings are dispatched instantaneously."
    )

    b.add_page_break()

print("Chapters 1 to 5 generator ready.")

