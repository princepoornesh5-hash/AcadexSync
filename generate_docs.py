import os
import sys
import docx
from docx.shared import Inches, Pt, Mm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer

def get_code_slice(file_path, start_line, end_line):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    return "".join(lines[start_line - 1 : end_line]).rstrip()

# 33 authoritative sections mapped directly to verified project files
SECTIONS = [
    # -------------------------------------------------------------------------
    # Application and authentication
    # -------------------------------------------------------------------------
    {
        "title": "Application Entry Point (main.dart)",
        "file": "Frontend/lib/main.dart (Excerpt)",
        "note": "Initializes network environment, Android system bars, global exception handlers, and boots the Flutter application within ProviderScope.",
        "code_path": "Frontend/lib/main.dart",
        "start": 29, "end": 60
    },
    {
        "title": "Application Routing",
        "file": "Frontend/lib/app/router/app_router.dart (Excerpt)",
        "note": "Configures top-level GoRouter with Riverpod listener, error boundary fallback, and core route definitions.",
        "code_path": "Frontend/lib/app/router/app_router.dart",
        "start": 440, "end": 468
    },
    {
        "title": "Login Form",
        "file": "Frontend/lib/features/auth/presentation/screens/login_screen.dart (Excerpt)",
        "note": "Manages multi-step login authentication state machine with dedicated FormState keys and input controllers.",
        "code_path": "Frontend/lib/features/auth/presentation/screens/login_screen.dart",
        "start": 38, "end": 70
    },
    {
        "title": "Login Validation",
        "file": "Frontend/lib/features/auth/presentation/screens/login_screen.dart (Excerpt)",
        "note": "Validates user inputs client-side, enforces email format regex, password length rules, and handles step progression.",
        "code_path": "Frontend/lib/features/auth/presentation/screens/login_screen.dart",
        "start": 133, "end": 162
    },
    {
        "title": "Authentication Service",
        "file": "Frontend/lib/features/auth/data/repositories/api_auth_repository.dart (Excerpt)",
        "note": "Dispatches credentials via Dio HTTP client, persists authentication and refresh tokens, and resolves current user profile.",
        "code_path": "Frontend/lib/features/auth/data/repositories/api_auth_repository.dart",
        "start": 16, "end": 45
    },
    {
        "title": "Role-Based Navigation",
        "file": "Frontend/lib/app/router/app_router.dart (Excerpt)",
        "note": "Enforces role guards and redirects authenticated users to their designated home dashboard while preventing unauthorized access.",
        "code_path": "Frontend/lib/app/router/app_router.dart",
        "start": 498, "end": 526
    },

    # -------------------------------------------------------------------------
    # Five user-role dashboards
    # -------------------------------------------------------------------------
    {
        "title": "Dashboard (Super Admin)",
        "file": "Frontend/lib/features/dashboard/presentation/screens/super_admin_dashboard.dart (Excerpt)",
        "note": "Platform-wide command dashboard monitoring global tenant health, total institutions, system alerts, and platform quick shortcuts.",
        "code_path": "Frontend/lib/features/dashboard/presentation/screens/super_admin_dashboard.dart",
        "start": 14, "end": 52
    },
    {
        "title": "Dashboard (College Admin)",
        "file": "Frontend/lib/features/dashboard/presentation/screens/college_admin_dashboard.dart (Excerpt)",
        "note": "Institutional dashboard presenting campus attendance overview, department allocations, academic operations, and alerts.",
        "code_path": "Frontend/lib/features/dashboard/presentation/screens/college_admin_dashboard.dart",
        "start": 27, "end": 66
    },
    {
        "title": "Dashboard (HOD)",
        "file": "Frontend/lib/features/dashboard/presentation/screens/hod_dashboard.dart (Excerpt)",
        "note": "Departmental view displaying branch health, faculty workload allocation, pending request reviews, and quick actions.",
        "code_path": "Frontend/lib/features/dashboard/presentation/screens/hod_dashboard.dart",
        "start": 27, "end": 69
    },
    {
        "title": "Dashboard (Faculty)",
        "file": "Frontend/lib/features/dashboard/presentation/screens/faculty_dashboard.dart (Excerpt)",
        "note": "Faculty operational view featuring assigned classes, quick attendance shortcuts, workload indicators, and upcoming teaching schedule.",
        "code_path": "Frontend/lib/features/dashboard/presentation/screens/faculty_dashboard.dart",
        "start": 22, "end": 60
    },
    {
        "title": "Dashboard (Student)",
        "file": "Frontend/lib/features/dashboard/presentation/screens/student_dashboard.dart (Excerpt)",
        "note": "Student portal summarizing academic progress, attendance shortage warnings, today's lecture schedule, and active notifications.",
        "code_path": "Frontend/lib/features/dashboard/presentation/screens/student_dashboard.dart",
        "start": 22, "end": 60
    },

    # -------------------------------------------------------------------------
    # Important academic modules
    # -------------------------------------------------------------------------
    {
        "title": "Attendance Management Module",
        "file": "Frontend/lib/features/attendance/presentation/screens/assigned_classes_screen.dart (Excerpt)",
        "note": "Presents instructor assigned lecture slots and handles modal selection for scheduled classes and approved substitutions.",
        "code_path": "Frontend/lib/features/attendance/presentation/screens/assigned_classes_screen.dart",
        "start": 20, "end": 49
    },
    {
        "title": "Student Attendance Analytics Module",
        "file": "Frontend/lib/features/attendance/presentation/screens/attendance_analytics_screen.dart (Excerpt)",
        "note": "Calculates attendance metrics, absence trends, and shortage risk notifications across configurable date ranges.",
        "code_path": "Frontend/lib/features/attendance/presentation/screens/attendance_analytics_screen.dart",
        "start": 27, "end": 57
    },
    {
        "title": "Faculty Attendance Submission",
        "file": "Frontend/lib/features/attendance/presentation/screens/mark_attendance_screen.dart (Excerpt)",
        "note": "Validates unmarked student entries, presents confirmation summaries, and commits session attendance records to the backend repository.",
        "code_path": "Frontend/lib/features/attendance/presentation/screens/mark_attendance_screen.dart",
        "start": 105, "end": 139
    },
    {
        "title": "Attendance Session Locking Logic",
        "file": "Backend/src/services/attendance.service.ts (Excerpt)",
        "note": "Enforces session finalization security by verifying faculty ownership, locking records against tampering, and emitting audit logs.",
        "code_path": "Backend/src/services/attendance.service.ts",
        "start": 1129, "end": 1157
    },
    {
        "title": "Request Center Module",
        "file": "Frontend/lib/features/requests/presentation/screens/request_center_screen.dart (Excerpt)",
        "note": "Coordinates user requests with tab navigation segregating submitted requests and incoming departmental reviews.",
        "code_path": "Frontend/lib/features/requests/presentation/screens/request_center_screen.dart",
        "start": 42, "end": 74
    },
    {
        "title": "Request Approval Logic",
        "file": "Backend/src/services/request.service.ts (Excerpt)",
        "note": "Validates approver authorization, blocks self-approvals, verifies state transition integrity, and records resolution notes.",
        "code_path": "Backend/src/services/request.service.ts",
        "start": 810, "end": 846
    },
    {
        "title": "Calendar Module",
        "file": "Frontend/lib/features/calendar/presentation/screens/calendar_screen.dart (Excerpt)",
        "note": "Manages academic calendar month transitions, date selection state, and loads institutional events and holiday overrides.",
        "code_path": "Frontend/lib/features/calendar/presentation/screens/calendar_screen.dart",
        "start": 50, "end": 82
    },
    {
        "title": "Timetable Module",
        "file": "Frontend/lib/features/timetable/presentation/screens/timetable_dashboard_screen.dart (Excerpt)",
        "note": "Renders role-specific academic timetables supporting day timeline, week spreadsheet grid, and list schedule views.",
        "code_path": "Frontend/lib/features/timetable/presentation/screens/timetable_dashboard_screen.dart",
        "start": 35, "end": 66
    },
    {
        "title": "Timetable Conflict Validation",
        "file": "Backend/src/services/timetable.service.ts (Excerpt)",
        "note": "Prevents schedule collisions by checking faculty overlaps, classroom double-bookings, and conflicting published section timetables.",
        "code_path": "Backend/src/services/timetable.service.ts",
        "start": 545, "end": 578
    },
    {
        "title": "Profile Module",
        "file": "Frontend/lib/features/profile/presentation/screens/profile_screen.dart (Excerpt)",
        "note": "Displays authenticated user identity details, institutional role badges, and handles client profile image selection and upload.",
        "code_path": "Frontend/lib/features/profile/presentation/screens/profile_screen.dart",
        "start": 26, "end": 60
    },
    {
        "title": "Student Academic Information",
        "file": "Frontend/lib/features/academic_records/presentation/screens/student_academic_history_screen.dart (Excerpt)",
        "note": "Renders chronological student semester records, GPA milestones, and enrolled academic period summaries.",
        "code_path": "Frontend/lib/features/academic_records/presentation/screens/student_academic_history_screen.dart",
        "start": 16, "end": 48
    },
    {
        "title": "Notes Management Module",
        "file": "Frontend/lib/features/notes/presentation/screens/notes_dashboard_screen.dart (Excerpt)",
        "note": "Provides searchable academic study materials and lecture notes with role-appropriate upload actions for faculty members.",
        "code_path": "Frontend/lib/features/notes/presentation/screens/notes_dashboard_screen.dart",
        "start": 24, "end": 54
    },
    {
        "title": "Notifications Module",
        "file": "Frontend/lib/features/notifications/presentation/screens/notification_center_screen.dart (Excerpt)",
        "note": "Delivers real-time notifications, unread counters, category filtering, and administrative announcement publishing actions.",
        "code_path": "Frontend/lib/features/notifications/presentation/screens/notification_center_screen.dart",
        "start": 27, "end": 57
    },

    # -------------------------------------------------------------------------
    # Backend core logic
    # -------------------------------------------------------------------------
    {
        "title": "Backend Authentication Controller",
        "file": "Backend/src/controllers/auth.controller.ts (Excerpt)",
        "note": "Handles HTTP authentication requests, validates credentials, extracts client request metadata, and dispatches to AuthService.",
        "code_path": "Backend/src/controllers/auth.controller.ts",
        "start": 8, "end": 35
    },
    {
        "title": "JWT or Session Verification Middleware",
        "file": "Backend/src/middleware/auth.middleware.ts (Excerpt)",
        "note": "Intercepts requests to verify JWT Bearer tokens, validates authoritative session state in AuthSession store, and enforces active status.",
        "code_path": "Backend/src/middleware/auth.middleware.ts",
        "start": 36, "end": 72
    },
    {
        "title": "Role Authorization Middleware",
        "file": "Backend/src/middleware/role.middleware.ts (Excerpt)",
        "note": "Restricts route execution to designated roles and evaluates hierarchical minimum privilege levels before invoking controllers.",
        "code_path": "Backend/src/middleware/role.middleware.ts",
        "start": 7, "end": 40
    },
    {
        "title": "College Tenant Isolation Middleware",
        "file": "Backend/src/middleware/tenant.middleware.ts (Excerpt)",
        "note": "Guarantees multi-tenant data boundaries by blocking cross-college resource queries and binding verified tenant IDs to requests.",
        "code_path": "Backend/src/middleware/tenant.middleware.ts",
        "start": 10, "end": 44
    },
    {
        "title": "Attendance Backend Service",
        "file": "Backend/src/services/attendance.service.ts (Excerpt)",
        "note": "Coordinates session creation, faculty teaching assignment verification, time-slot normalization, and attendance persistence.",
        "code_path": "Backend/src/services/attendance.service.ts",
        "start": 101, "end": 138
    },
    {
        "title": "Request Center Backend Service",
        "file": "Backend/src/services/request.service.ts (Excerpt)",
        "note": "Applies role permission filters, prevents rapid duplicate submissions, and resolves target routing for incoming institutional requests.",
        "code_path": "Backend/src/services/request.service.ts",
        "start": 355, "end": 394
    },
    {
        "title": "Timetable Backend Service",
        "file": "Backend/src/services/timetable.service.ts (Excerpt)",
        "note": "Enforces complete academic hierarchy validation, coordinates schedule conflict checks, and manages draft-to-published state transitions.",
        "code_path": "Backend/src/services/timetable.service.ts",
        "start": 641, "end": 680
    },
    {
        "title": "Attendance Database Model",
        "file": "Backend/src/models/attendanceSession.model.ts (Excerpt)",
        "note": "Defines Mongoose TypeScript interface and schema for attendance sessions with embedded student records and unique indexing.",
        "code_path": "Backend/src/models/attendanceSession.model.ts",
        "start": 18, "end": 52
    },
    {
        "title": "API Request and Response Handling",
        "file": "Backend/src/utils/apiResponse.ts & Backend/src/utils/apiError.ts (Excerpt)",
        "note": "Standardizes unified JSON response envelopes and custom operational error classes across all ACADEXSYNC HTTP endpoints.",
        "code_path": "Backend/src/utils/apiResponse.ts",
        "start": 10, "end": 38
    }
]

def build_docx(output_path):
    doc = docx.Document()

    # 1. Page Setup: A4, 0.75 in margins
    section = doc.sections[0]
    section.page_width = Mm(210)
    section.page_height = Mm(297)
    section.top_margin = Inches(0.75)
    section.bottom_margin = Inches(0.75)
    section.left_margin = Inches(0.75)
    section.right_margin = Inches(0.75)

    # 2. Header and Footer
    # Header: None (plain white)
    # Footer: Page X of Y (Times New Roman 10pt, Right aligned, Pure Black)
    footer = section.footer
    footer_p = footer.paragraphs[0]
    footer_p.alignment = WD_ALIGN_PARAGRAPH.RIGHT

    r_f1 = footer_p.add_run("Page ")
    r_f1.font.name = "Times New Roman"
    r_f1.font.size = Pt(10)
    r_f1.font.color.rgb = RGBColor(0, 0, 0)

    fld1 = OxmlElement('w:fldSimple')
    fld1.set(qn('w:instr'), 'PAGE')
    footer_p._p.append(fld1)

    r_f2 = footer_p.add_run(" of ")
    r_f2.font.name = "Times New Roman"
    r_f2.font.size = Pt(10)
    r_f2.font.color.rgb = RGBColor(0, 0, 0)

    fld2 = OxmlElement('w:fldSimple')
    fld2.set(qn('w:instr'), 'NUMPAGES')
    footer_p._p.append(fld2)

    # Document Header Title (Bold, Times New Roman 13pt, Pure Black)
    p_main = doc.add_paragraph()
    p_main.paragraph_format.space_before = Pt(0)
    p_main.paragraph_format.space_after = Pt(12)
    r_main = p_main.add_run("ACADEXSYNC - Core Source Code Documentation")
    r_main.font.name = "Times New Roman"
    r_main.font.size = Pt(13)
    r_main.font.bold = True
    r_main.font.color.rgb = RGBColor(0, 0, 0)

    total_lines = 0

    for idx, s in enumerate(SECTIONS):
        # Label: Bold, Times New Roman 11pt, Pure Black
        p_label = doc.add_paragraph()
        p_label.paragraph_format.space_before = Pt(10 if idx > 0 else 0)
        p_label.paragraph_format.space_after = Pt(2)
        p_label.paragraph_format.keep_with_next = True
        r_label = p_label.add_run(s['title'])
        r_label.font.name = "Times New Roman"
        r_label.font.size = Pt(11)
        r_label.font.bold = True
        r_label.font.color.rgb = RGBColor(0, 0, 0)

        # File Path: Times New Roman 10pt
        p_file = doc.add_paragraph()
        p_file.paragraph_format.space_before = Pt(0)
        p_file.paragraph_format.space_after = Pt(2)
        p_file.paragraph_format.keep_with_next = True
        
        rf_prefix = p_file.add_run("File: ")
        rf_prefix.font.name = "Times New Roman"
        rf_prefix.font.size = Pt(10)
        rf_prefix.font.bold = True
        rf_prefix.font.color.rgb = RGBColor(0, 0, 0)

        rf_path = p_file.add_run(s['file'])
        rf_path.font.name = "Consolas"
        rf_path.font.size = Pt(9.5)
        rf_path.font.color.rgb = RGBColor(0, 0, 0)

        # Short Note
        if s.get('note'):
            p_note = doc.add_paragraph()
            p_note.paragraph_format.space_before = Pt(0)
            p_note.paragraph_format.space_after = Pt(3)
            p_note.paragraph_format.keep_with_next = True
            r_note = p_note.add_run(s['note'])
            r_note.font.name = "Times New Roman"
            r_note.font.size = Pt(9.5)
            r_note.font.italic = True
            r_note.font.color.rgb = RGBColor(0, 0, 0)

        # Code block
        code_text = get_code_slice(s['code_path'], s['start'], s['end'])
        code_lines = code_text.split("\n")
        total_lines += len(code_lines)

        for line_idx, line in enumerate(code_lines):
            p_code = doc.add_paragraph()
            p_code.paragraph_format.space_before = Pt(0)
            p_code.paragraph_format.space_after = Pt(4 if line_idx == len(code_lines) - 1 else 0)
            p_code.paragraph_format.line_spacing = 1.0
            p_code.paragraph_format.left_indent = Inches(0.2)

            r_line = p_code.add_run(line if line else " ")
            r_line.font.name = "Consolas"
            r_line.font.size = Pt(8.5)
            r_line.font.color.rgb = RGBColor(0, 0, 0)

            # Preserve exact leading whitespaces
            for t_node in r_line._r.xpath('./w:t'):
                t_node.set(qn('xml:space'), 'preserve')

    doc.save(output_path)
    print(f"Generated {output_path} with {len(SECTIONS)} sections ({total_lines} total code lines).")
    return total_lines

if __name__ == "__main__":
    out_docx = "ACADEXSYNC_Core_Source_Code_Documentation.docx"
    build_docx(out_docx)
