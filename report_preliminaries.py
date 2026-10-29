"""
ACADEXSYNC - Main Report Generator Script (Part 1: Core Setup, Preliminaries, Chapters 1-6)
"""
import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from report_builder import AcadexDocBuilder

def generate_report_preliminaries(b: AcadexDocBuilder):
    # ==============================================================================
    # TITLE PAGE
    # ==============================================================================
    p_inst = b.doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_inst.paragraph_format.space_before = Pt(0)
    p_inst.paragraph_format.space_after = Pt(4)
    r = p_inst.add_run("SRI VENKATESWARA GOVERNMENT POLYTECHNIC\nTIRUPATI – 517501, ANDHRA PRADESH\n")
    r.font.name = "Times New Roman"
    r.font.size = Pt(13)
    r.font.bold = True
    r.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)

    r2 = p_inst.add_run("DEPARTMENT OF COMPUTER ENGINEERING\n")
    r2.font.name = "Times New Roman"
    r2.font.size = Pt(12)
    r2.font.bold = True
    r2.font.color.rgb = RGBColor(0x33, 0x41, 0x55)

    p_proj = b.doc.add_paragraph()
    p_proj.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_proj.paragraph_format.space_before = Pt(16)
    p_proj.paragraph_format.space_after = Pt(8)
    r_title = p_proj.add_run("ACADEXSYNC\n")
    r_title.font.name = "Times New Roman"
    r_title.font.size = Pt(22)
    r_title.font.bold = True
    r_title.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)

    r_sub = p_proj.add_run("A Modern Multi-Tenant Campus Management Operating System\n")
    r_sub.font.name = "Times New Roman"
    r_sub.font.size = Pt(13)
    r_sub.font.bold = True
    r_sub.font.color.rgb = RGBColor(0x25, 0x63, 0xEB)

    p_subtext = b.doc.add_paragraph()
    p_subtext.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_subtext.paragraph_format.space_before = Pt(8)
    p_subtext.paragraph_format.space_after = Pt(12)
    r_st = p_subtext.add_run(
        "A Project Report Submitted to the\n"
        "STATE BOARD OF TECHNICAL EDUCATION AND TRAINING, ANDHRA PRADESH\n"
        "In partial fulfillment of the requirements for the award of\n"
        "DIPLOMA IN COMPUTER ENGINEERING (2024–2027)\n"
    )
    r_st.font.name = "Times New Roman"
    r_st.font.size = Pt(11)

    p_by = b.doc.add_paragraph()
    p_by.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_by.paragraph_format.space_after = Pt(4)
    r_by = p_by.add_run("Submitted by:")
    r_by.font.name = "Times New Roman"
    r_by.font.size = Pt(11)
    r_by.font.bold = True

    # Team Members Table
    team_data = [
        ["1", "S. Venkata Kalyan", "24018-CM-062"],
        ["2", "R. Poornesh", "24018-CM-057"],
        ["3", "R. Naga Rasagna", "24018-CM-006"],
        ["4", "L. Harsha Vardhan", "24018-CM-046"],
        ["5", "K. Uday Kumar", "24018-CM-045"],
        ["6", "N. Santosh", "24018-CM-052"]
    ]
    b.add_table_data("Project Team Members", ["S. No.", "Student Name", "PIN Number"], team_data, [0.8, 3.2, 1.7])

    p_guidance = b.doc.add_paragraph()
    p_guidance.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_guidance.paragraph_format.space_before = Pt(10)
    p_guidance.paragraph_format.space_after = Pt(2)
    r_g = p_guidance.add_run("Under the Esteemed Guidance of:\n")
    r_g.font.name = "Times New Roman"
    r_g.font.size = Pt(11)
    r_g.font.bold = True

    r_gn = p_guidance.add_run("B. MOHAN, M.Tech\n")
    r_gn.font.name = "Times New Roman"
    r_gn.font.size = Pt(11.5)
    r_gn.font.bold = True
    r_gn.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)

    r_gt = p_guidance.add_run("Lecturer, Department of Computer Engineering (CME)\nSri Venkateswara Government Polytechnic, Tirupati\nAcademic Year 2026–2027")
    r_gt.font.name = "Times New Roman"
    r_gt.font.size = Pt(10.5)

    b.add_page_break()

    # ==============================================================================
    # CERTIFICATE
    # ==============================================================================
    p_c_hdr = b.doc.add_paragraph()
    p_c_hdr.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_c_hdr.paragraph_format.space_after = Pt(2)
    r_ch = p_c_hdr.add_run("SRI VENKATESWARA GOVERNMENT POLYTECHNIC\nTIRUPATI – 517501, ANDHRA PRADESH\nDEPARTMENT OF COMPUTER ENGINEERING")
    r_ch.font.name = "Times New Roman"
    r_ch.font.size = Pt(12)
    r_ch.font.bold = True

    b.add_chapter_heading("CERTIFICATE")

    b.add_body_paragraph(
        "This is to certify that the technical project work entitled \"ACADEXSYNC: MULTI-TENANT CAMPUS MANAGEMENT APPLICATION\" "
        "is a bonafide project work carried out by the following students of final-year Diploma in Computer Engineering:"
    )

    cert_team = [
        ["1", "S. Venkata Kalyan", "24018-CM-062"],
        ["2", "R. Poornesh", "24018-CM-057"],
        ["3", "R. Naga Rasagna", "24018-CM-006"],
        ["4", "L. Harsha Vardhan", "24018-CM-046"],
        ["5", "K. Uday Kumar", "24018-CM-045"],
        ["6", "N. Santosh", "24018-CM-052"]
    ]
    b.add_table_data("Certified Project Candidates", ["S. No.", "Student Name", "PIN Number"], cert_team, [0.8, 3.2, 1.7])

    b.add_body_paragraph(
        "This project is submitted in partial fulfillment of the requirements for the award of DIPLOMA IN COMPUTER ENGINEERING "
        "conferred by the State Board of Technical Education and Training (SBTET), Andhra Pradesh, during the academic period 2024–2027. "
        "The project work has been scrutinized and approved under our supervision."
    )

    # Authority Signature Blocks
    p_sig = b.doc.add_paragraph()
    p_sig.paragraph_format.space_before = Pt(36)
    p_sig.paragraph_format.space_after = Pt(4)
    
    sig_table = b.doc.add_table(rows=1, cols=3)
    sig_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    
    c1 = sig_table.rows[0].cells[0]
    c1.text = "Project Guide\n\n____________________\nB. MOHAN, M.Tech\nLecturer in CME\nDept. of Computer Engg."
    
    c2 = sig_table.rows[0].cells[1]
    c2.text = "Head of Department\n\n____________________\nG. PRABAKAR, M.Tech\nHead of Section (HCME)\nDept. of Computer Engg."
    
    c3 = sig_table.rows[0].cells[2]
    c3.text = "Principal\n\n____________________\nDr. SRINIVASULU, M.Tech, Ph.D\nPrincipal\nSV Govt. Polytechnic, Tirupati"

    for c in sig_table.rows[0].cells:
        for p in c.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for r in p.runs:
                r.font.name = "Times New Roman"
                r.font.size = Pt(9.5)
                r.font.bold = True

    p_dt = b.doc.add_paragraph()
    p_dt.paragraph_format.space_before = Pt(24)
    p_dt.add_run("Date: _________________________\nPlace: Tirupati, Andhra Pradesh").font.size = Pt(10.5)

    b.add_page_break()

    # ==============================================================================
    # DECLARATION
    # ==============================================================================
    b.add_chapter_heading("DECLARATION")

    b.add_body_paragraph(
        "We hereby declare that the project report entitled \"ACADEXSYNC: MULTI-TENANT CAMPUS MANAGEMENT APPLICATION\" "
        "has been prepared by our project team under the guidance of our project guide B. Mohan, M.Tech, Lecturer in the "
        "Department of Computer Engineering, Sri Venkateswara Government Polytechnic, Tirupati. It is submitted in partial "
        "fulfillment of the academic curriculum for the award of Diploma in Computer Engineering under the State Board of "
        "Technical Education and Training (SBTET), Andhra Pradesh, for the academic year 2026–2027."
    )

    b.add_body_paragraph(
        "We affirm that this project report is an authentic record of our own engineering design, architectural synthesis, "
        "and verified software development. The technical specifications, system architecture models, database schemas, "
        "API contracts, and source-code listings presented herein are directly derived from the actual ACADEXSYNC codebase, "
        "comprising our cross-platform Flutter application, Node.js/TypeScript Express backend, and Python FastAPI microservices. "
        "This work has not been submitted previously to any other university or examining board for the award of any diploma or degree."
    )

    p_team_sig = b.doc.add_paragraph()
    p_team_sig.paragraph_format.space_before = Pt(20)
    p_team_sig.paragraph_format.space_after = Pt(4)
    p_team_sig.add_run("Candidate Signatures:\n").font.bold = True

    c_sig_table = b.doc.add_table(rows=3, cols=2)
    c_sig_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    sig_pairs = [
        ("1. S. Venkata Kalyan (24018-CM-062)\nSignature: ____________________", "2. R. Poornesh (24018-CM-057)\nSignature: ____________________"),
        ("3. R. Naga Rasagna (24018-CM-006)\nSignature: ____________________", "4. L. Harsha Vardhan (24018-CM-046)\nSignature: ____________________"),
        ("5. K. Uday Kumar (24018-CM-045)\nSignature: ____________________", "6. N. Santosh (24018-CM-052)\nSignature: ____________________")
    ]
    for row_idx, (t1, t2) in enumerate(sig_pairs):
        c_sig_table.rows[row_idx].cells[0].text = t1
        c_sig_table.rows[row_idx].cells[1].text = t2
        for cell in c_sig_table.rows[row_idx].cells:
            for p in cell.paragraphs:
                p.paragraph_format.space_after = Pt(12)
                for r in p.runs:
                    r.font.name = "Times New Roman"
                    r.font.size = Pt(9.5)

    b.add_page_break()

    # ==============================================================================
    # ACKNOWLEDGEMENT
    # ==============================================================================
    b.add_chapter_heading("ACKNOWLEDGEMENT")

    b.add_body_paragraph(
        "The successful completion of this major final-year project report would not have been possible without the invaluable "
        "guidance, constructive criticism, and continuous encouragement provided by numerous individuals and institutional mentors."
    )

    b.add_body_paragraph(
        "First and foremost, we express our deep sense of gratitude and sincere thanks to our esteemed Project Guide, "
        "B. Mohan, M.Tech, Lecturer in the Department of Computer Engineering, for his exemplary guidance, patient technical advice, "
        "architectural insights, and inspiring suggestions throughout the development of ACADEXSYNC. His rigorous emphasis on software "
        "engineering discipline and software reliability helped us surmount critical engineering hurdles."
    )

    b.add_body_paragraph(
        "We wish to express our heartfelt gratefulness and profound thanks to G. Prabakar, M.Tech, Head of Computer Engineering Section (HCME), "
        "for his invaluable administrative support, technical leadership, and academic coordination during the course of our diploma study."
    )

    b.add_body_paragraph(
        "We have great pleasure in expressing our sincere and respectful gratitude to our beloved Principal, Dr. Srinivasulu, M.Tech, Ph.D., "
        "for providing excellent institutional facilities, well-equipped computer laboratories, continuous inspiration, and the academic "
        "environment required to engineer an enterprise-grade campus management operating system."
    )

    b.add_body_paragraph(
        "We also extend our earnest thanks to all the faculty members, non-teaching staff, and laboratory technicians of the Department "
        "of Computer Engineering for their direct and indirect cooperation. Finally, we express our eternal love and heartfelt gratitude "
        "to our parents and friends whose unwavering moral and emotional support enabled us to successfully realize this project."
    )

    b.add_page_break()

    # ==============================================================================
    # ABSTRACT
    # ==============================================================================
    b.add_chapter_heading("ABSTRACT")

    b.add_body_paragraph(
        "ACADEXSYNC is an enterprise-grade, multi-tenant Campus Management Operating System engineered to resolve the severe operational "
        "fragmentation, data desynchronization, and administrative vulnerabilities inherent in conventional collegiate workflows. Traditional "
        "educational institutions rely heavily upon disjointed paper registers, standalone spreadsheets, isolated departmental notices, and "
        "fragmented chat groups. This fragmented model frequently results in attendance tampering, double-booked teaching allocations, "
        "prolonged student grievance cycles, and an absence of unified institutional oversight."
    )

    b.add_body_paragraph(
        "To decisively overcome these challenges, ACADEXSYNC introduces a secure, multi-tier distributed architecture spanning three integrated subsystems: "
        "(1) A high-performance, cross-platform client developed with Google Flutter (3.x) and Dart, featuring Riverpod state management, GoRouter "
        "declarative route guards, and mobile-first responsive layouts; (2) An enterprise RESTful API gateway built on Node.js, Express.js, and TypeScript, "
        "enforcing strict tenant scoping, JSON Web Token (JWT) cryptographic validation, and authoritative stateful session tracking via an immutable AuthSession store; "
        "and (3) An AI microservice layer leveraging Google Gemini 1.5 Flash SDK function-calling and Python FastAPI for timetable constraint solving and contextual retrieval."
    )

    b.add_body_paragraph(
        "The system enforces a rigorous five-tier Role-Based Access Control (RBAC) hierarchy comprising Super Admin (platform-level governance), "
        "College Admin (institutional-level tenant management), Head of Department (departmental academic and workload coordination), "
        "Faculty (period-wise roll call, session locking, and syllabus management), and Student (personal academic tracking, digital attendance audit, and request submission). "
        "Data isolation is guaranteed across all 37 canonical domain models in MongoDB Atlas through mandatory tenant scoping (`requireCollegeScope`) "
        "and compound database indices ({ collegeId: 1, sectionId: 1, date: 1 })."
    )

    b.add_body_paragraph(
        "Key operational innovations include: (a) An idempotent attendance ingestion engine with cryptographic Unicode string normalization, "
        "preventing duplicate timeslot entries and enforcing strict completeness invariants (present + late + absent + excused + unmarked == total); "
        "(b) A deterministic timetable validator that detects faculty double-booking, room capacity clashes, and break overlaps in real-time; "
        "(c) A formalized Request Center with multi-level role routing and immutable audit tracking; and (d) Multi-channel real-time notification dispatch "
        "integrating Firebase Cloud Messaging (FCM) multicast pushes and Server-Sent Events (SSE). The system has undergone exhaustive unit, integration, "
        "and widget testing across 131 GoRouter paths and 51 API endpoints, confirming zero cross-tenant leakage and production-ready reliability."
    )

    b.add_page_break()

    # ==============================================================================
    # TABLE OF CONTENTS
    # ==============================================================================
    b.add_chapter_heading("TABLE OF CONTENTS")

    toc_items = [
        ("Certificate", "ii"),
        ("Declaration", "iii"),
        ("Acknowledgement", "iv"),
        ("Abstract", "v"),
        ("List of Figures", "viii"),
        ("List of Tables", "x"),
        ("List of Abbreviations", "xii"),
        ("CHAPTER 1: INTRODUCTION", "1"),
        ("  1.1 Digital Transformation in Educational Administration", "1"),
        ("  1.2 Problems with Manual Registers and Disconnected Records", "3"),
        ("  1.3 Purpose and Vision of ACADEXSYNC", "5"),
        ("  1.4 Need for Centralized Academic Information", "7"),
        ("  1.5 Target Users and Institutional Context", "9"),
        ("  1.6 Scope and Project Limitations", "11"),
        ("CHAPTER 2: PROJECT DESCRIPTION", "13"),
        ("  2.1 Problem Statement", "13"),
        ("  2.2 Project Objectives", "15"),
        ("  2.3 Project Scope", "17"),
        ("  2.4 Motivation for Selecting the Project", "18"),
        ("  2.5 Proposed Solution Overview", "20"),
        ("  2.6 Expected Quantitative & Qualitative Benefits", "22"),
        ("  2.7 Functional Requirements", "24"),
        ("  2.8 Non-Functional Requirements", "27"),
        ("  2.9 Assumptions and Technical Dependencies", "30"),
        ("CHAPTER 3: COMPUTATIONAL ENVIRONMENT", "32"),
        ("  3.1 Hardware Requirements (Server & Client Devices)", "32"),
        ("  3.2 Software Requirements & Version Specifications", "34"),
        ("  3.3 Technology Stack Evaluation & Architectural Rationale", "37"),
        ("CHAPTER 4: FEASIBILITY STUDY", "40"),
        ("  4.1 Technical Feasibility", "40"),
        ("  4.2 Operational Feasibility", "42"),
        ("  4.3 Economic Feasibility", "44"),
        ("  4.4 Maintenance Feasibility", "46"),
        ("  4.5 Deployment and Scaling Considerations", "48"),
        ("CHAPTER 5: SYSTEM ANALYSIS", "50"),
        ("  5.1 Existing Academic Management Approaches", "50"),
        ("  5.2 Deficiencies and Risks of Conventional Systems", "52"),
        ("  5.3 Proposed ACADEXSYNC Solution", "55"),
        ("  5.4 Distinctive Advantages of Proposed Architecture", "57"),
        ("  5.5 Comprehensive Comparative Evaluation Matrix", "59"),
        ("  5.6 Core Operational Workflows", "62"),
        ("CHAPTER 6: SYSTEM DESIGN AND ARCHITECTURE", "65"),
        ("  6.1 Overall System Architecture", "65"),
        ("  6.2 Frontend Architecture (Flutter / Riverpod)", "68"),
        ("  6.3 Backend Architecture (Express.js / TypeScript)", "71"),
        ("  6.4 Database Architecture & Entity Modeling", "74"),
        ("  6.5 Authentication and Stateful Session Store", "77"),
        ("  6.6 Multi-Tenant Isolation & Workspace Architecture", "80"),
        ("  6.7 Role and Permission Architecture", "83"),
        ("  6.8 API Communication Flow & Contracts", "86"),
        ("  6.9 Attendance Processing and Session-Locking Flow", "89"),
        ("  6.10 Timetable Management & Conflict Resolution Flow", "92"),
        ("  6.11 Request Center Multi-Tier Workflow", "95"),
        ("  6.12 Notification Delivery & FCM Multicast Flow", "98"),
        ("  6.13 AI Assistant Request Flow & Tool Execution", "101"),
        ("  6.14 UML Diagrams & Architectural Blueprints", "104"),
        ("CHAPTER 7: ROLE-BASED ACCESS & INSTITUTIONAL GOVERNANCE", "108"),
        ("  7.1 Super Admin (Platform-Level Governance)", "108"),
        ("  7.2 College Admin (Institutional Governance)", "111"),
        ("  7.3 Head of Department (Departmental Academic Oversight)", "114"),
        ("  7.4 Faculty (Academic Operations & Roll Call)", "117"),
        ("  7.5 Student (Personal Academic Access & Requests)", "120"),
        ("  7.6 Role and Permission Authorization Matrix", "123"),
        ("  7.7 Role Hierarchy & Security Boundaries", "126"),
        ("  7.8 Multi-Tenant Isolation & Workspace Switching", "129"),
        ("CHAPTER 8: SYSTEM IMPLEMENTATION", "132"),
        ("  8.1 Application Initialization & Bootstrapping", "132"),
        ("  8.2 Authentication & Account Activation Module", "135"),
        ("  8.3 Dynamic Role-Based Navigation Routing", "138"),
        ("  8.4 Super Admin Management Workstation", "141"),
        ("  8.5 College Admin Institutional Console", "144"),
        ("  8.6 Head of Department Academic Portal", "147"),
        ("  8.7 Faculty Classroom Operations Suite", "150"),
        ("  8.8 Student Academic Hub & Attendance Portal", "153"),
        ("  8.9 Attendance Ingestion & Idempotent Session Locking", "156"),
        ("  8.10 Timetable, Substitution & Calendar Override Engine", "159"),
        ("  8.11 Academic Structure & Curriculum Configuration", "162"),
        ("  8.12 Notes Library & ImageKit Secure Storage", "165"),
        ("  8.13 Institutional Announcements & FCM Multicast", "168"),
        ("  8.14 Request Center & Multi-Level Review Workflow", "171"),
        ("  8.15 AI Assistant & RAG Tool Calling Registry", "174"),
        ("  8.16 Error Handling, Structured Logging & Validation", "177"),
        ("CHAPTER 9: IMPORTANT SOURCE CODE WITH EXPLANATION", "180"),
        ("  Listing 1: Application Entry Point (`main.dart`)", "180"),
        ("  Listing 2: Declarative Router & Route Guards (`app_router.dart`)", "184"),
        ("  Listing 3: Role Definitions & Hierarchy (`roles.ts`)", "188"),
        ("  Listing 4: Authentication & Session Middleware (`auth.middleware.ts`)", "191"),
        ("  Listing 5: Super Admin & College Admin Selection (`app_router.dart`)", "195"),
        ("  Listing 6: HOD, Faculty & Student Selection (`app_router.dart`)", "198"),
        ("  Listing 7: Authentication Controller (`auth.controller.ts`)", "201"),
        ("  Listing 8: Role Authorization Guard (`role.middleware.ts`)", "204"),
        ("  Listing 9: Multi-Tenant College Scope Guard (`tenant.middleware.ts`)", "207"),
        ("  Listing 10: Attendance Ingestion Pipeline (`attendance.service.ts`)", "210"),
        ("  Listing 11: Idempotent Session Locking (`attendance.service.ts`)", "213"),
        ("  Listing 12: Timetable Conflict Validator (`timetable.service.ts`)", "216"),
        ("  Listing 13: Request Submission & Approval (`request.controller.ts`)", "219"),
        ("  Listing 14: FCM Push Multicast Dispatch (`fcm.service.ts`)", "222"),
        ("  Listing 15: Canonical Data Schema (`attendanceSession.model.ts`)", "225"),
        ("  Listing 16: AI Gemini Tool Registry (`ai.service.ts`)", "228"),
        ("CHAPTER 10: UML DIAGRAMS, FLOWCHARTS & WORKFLOW MODELS", "232"),
        ("CHAPTER 11: TESTING AND VALIDATION", "245"),
        ("CHAPTER 12: RESULTS AND SCREEN LAYOUTS", "260"),
        ("CHAPTER 13: LIMITATIONS AND FUTURE ENHANCEMENTS", "275"),
        ("CHAPTER 14: CONCLUSION", "280"),
        ("REFERENCES & OFFICIAL DOCUMENTATION", "285"),
        ("APPENDIX A: BACKEND REST API ROUTE INVENTORY", "288"),
        ("APPENDIX B: DATABASE SCHEMA & FIELD DICTIONARY", "292"),
        ("APPENDIX C: TECHNICAL ABBREVIATIONS GLOSSARY", "296")
    ]

    for title, page in toc_items:
        p_t = b.doc.add_paragraph()
        p_t.paragraph_format.line_spacing = 1.2
        p_t.paragraph_format.space_after = Pt(2)
        r_title = p_t.add_run(title)
        r_title.font.name = "Times New Roman"
        r_title.font.size = Pt(10)
        if title.startswith("CHAPTER") or not title.startswith("  "):
            r_title.font.bold = True
            r_title.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)

        # Dot leader approximation
        dots = " " + "." * max(5, int((5.7 - len(title)*0.07)*15)) + " "
        r_dots = p_t.add_run(dots)
        r_dots.font.name = "Times New Roman"
        r_dots.font.size = Pt(9)
        r_dots.font.color.rgb = RGBColor(0x94, 0xA3, 0xB8)

        r_page = p_t.add_run(page)
        r_page.font.name = "Times New Roman"
        r_page.font.size = Pt(10)
        r_page.font.bold = True

    b.add_page_break()

    # ==============================================================================
    # LIST OF FIGURES
    # ==============================================================================
    b.add_chapter_heading("LIST OF FIGURES")

    figures = [
        ("Figure 6.1: ACADEXSYNC Overall Multi-Tenant System Architecture", "67"),
        ("Figure 6.2: ACADEXSYNC Subsystem Component Architecture", "73"),
        ("Figure 6.5: Authentication & Authoritative Session Sequence Diagram", "79"),
        ("Figure 6.6: User Account Activation & Credential Provisioning Sequence", "82"),
        ("Figure 6.7: Attendance Submission & Idempotent Session Locking Sequence", "91"),
        ("Figure 6.8: Timetable Construction & Conflict Validation Activity Diagram", "94"),
        ("Figure 6.9: Request Center Submission & Multi-Tier Approval Workflow", "97"),
        ("Figure 6.10: Multi-Channel Institutional Notification Dispatch Pipeline", "100"),
        ("Figure 6.11: Gemini AI Assistant Tool-Calling & Context Retrieval Flow", "103"),
        ("Figure 6.12: ACADEXSYNC Canonical Multi-Tenant Entity-Relationship Model", "106"),
        ("Figure 7.1: Multi-Tenant Identity & Request Authorization Pipeline", "125"),
        ("Figure 10.2: UML Use Case Diagram (ACADEXSYNC 5 User Roles)", "234"),
        ("Figure 12.1: ACADEXSYNC Mobile Application Launch Screen", "261"),
        ("Figure 12.2: Unified Authentication and Secure Sign-in Portal", "262"),
        ("Figure 12.3: Super Admin Platform Oversight Dashboard", "263"),
        ("Figure 12.4: Super Admin Multi-College Tenant Directory", "264"),
        ("Figure 12.5: Super Admin System-Wide Audit Log Monitor", "265"),
        ("Figure 12.6: Super Admin Gemini AI Assistant Interface", "266"),
        ("Figure 12.7: College Admin Institutional Operations Dashboard", "267"),
        ("Figure 12.8: College Admin Academic Hierarchy Setup Console", "268"),
        ("Figure 12.9: College Admin Institutional Staff & Student Directory", "269"),
        ("Figure 12.10: College Admin Comprehensive Analytics & Report Center", "270"),
        ("Figure 12.11: Head of Department (HOD) Academic Management Dashboard", "271"),
        ("Figure 12.12: Faculty Classroom Management & Teaching Workstation", "272"),
        ("Figure 12.13: Student Unified Academic Hub & Portal Dashboard", "273"),
        ("Figure 12.14: Student Dynamic Weekly Timetable & Period Schedule View", "274"),
        ("Figure 12.15: Student Subject-Wise Attendance Tracking & Breakdown Screen", "274")
    ]

    for title, page in figures:
        p_f = b.doc.add_paragraph()
        p_f.paragraph_format.line_spacing = 1.2
        p_f.paragraph_format.space_after = Pt(3)
        r_t = p_f.add_run(title)
        r_t.font.name = "Times New Roman"
        r_t.font.size = Pt(10)

        dots = " " + "." * max(5, int((5.7 - len(title)*0.07)*15)) + " "
        r_d = p_f.add_run(dots)
        r_d.font.name = "Times New Roman"
        r_d.font.size = Pt(9)
        r_d.font.color.rgb = RGBColor(0x94, 0xA3, 0xB8)

        r_p = p_f.add_run(page)
        r_p.font.name = "Times New Roman"
        r_p.font.size = Pt(10)
        r_p.font.bold = True

    b.add_page_break()

    # ==============================================================================
    # LIST OF TABLES
    # ==============================================================================
    b.add_chapter_heading("LIST OF TABLES")

    tables_list = [
        ("Table 1: Project Team Member Information", "Title Page"),
        ("Table 2: Certified Project Candidates", "Certificate"),
        ("Table 3: Minimum & Recommended Hardware Specifications", "33"),
        ("Table 4: Verified Core Technology Software Stack & Versions", "35"),
        ("Table 5: Quantitative Comparison: Manual vs ACADEXSYNC Approaches", "60"),
        ("Table 6: Comprehensive 5-Tier Role & Permission Authorization Matrix", "124"),
        ("Table 7: Architectural Responsibility & Data Invariant Mapping", "130"),
        ("Table 8: Unit & Presentation Test Case Execution Matrix", "248"),
        ("Table 9: Backend API Integration & Role Security Test Matrix", "252"),
        ("Table 10: Attendance Invariant & Idempotent Session Lock Test Matrix", "256"),
        ("Table 11: Timetable Conflict & Schedule Overlap Test Matrix", "258")
    ]

    for title, page in tables_list:
        p_tbl = b.doc.add_paragraph()
        p_tbl.paragraph_format.line_spacing = 1.2
        p_tbl.paragraph_format.space_after = Pt(3)
        r_t = p_tbl.add_run(title)
        r_t.font.name = "Times New Roman"
        r_t.font.size = Pt(10)

        dots = " " + "." * max(5, int((5.7 - len(title)*0.07)*15)) + " "
        r_d = p_tbl.add_run(dots)
        r_d.font.name = "Times New Roman"
        r_d.font.size = Pt(9)
        r_d.font.color.rgb = RGBColor(0x94, 0xA3, 0xB8)

        r_p = p_tbl.add_run(page)
        r_p.font.name = "Times New Roman"
        r_p.font.size = Pt(10)
        r_p.font.bold = True

    b.add_page_break()

    # ==============================================================================
    # LIST OF ABBREVIATIONS
    # ==============================================================================
    b.add_chapter_heading("LIST OF ABBREVIATIONS")

    abbreviations = [
        ["API", "Application Programming Interface"],
        ["CME", "Computer Engineering Department"],
        ["DAO", "Data Access Object"],
        ["DTO", "Data Transfer Object"],
        ["FCM", "Firebase Cloud Messaging"],
        ["HOD", "Head of the Department"],
        ["HTTP", "Hypertext Transfer Protocol"],
        ["HTTPS", "Hypertext Transfer Protocol Secure"],
        ["JSON", "JavaScript Object Notation"],
        ["JWT", "JSON Web Token"],
        ["LLM", "Large Language Model"],
        ["MVC", "Model-View-Controller Architectural Pattern"],
        ["ODM", "Object Data Modeling"],
        ["OTP", "One-Time Password"],
        ["PIN", "Permanent Institutional Identification Number"],
        ["RAG", "Retrieval-Augmented Generation"],
        ["RBAC", "Role-Based Access Control"],
        ["REST", "Representational State Transfer"],
        ["SBTET", "State Board of Technical Education and Training"],
        ["SDK", "Software Development Kit"],
        ["SSE", "Server-Sent Events"],
        ["UI", "User Interface"],
        ["UML", "Unified Modeling Language"],
        ["URI", "Uniform Resource Identifier"],
        ["UUID", "Universally Unique Identifier"],
        ["UX", "User Experience"]
    ]
    b.add_table_data("Technical Abbreviations and Expansions", ["Abbreviation", "Complete Expansion"], abbreviations, [1.8, 3.9])

    b.add_page_break()

print("Preliminaries generator ready.")

