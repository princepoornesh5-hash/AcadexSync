"""
ACADEXSYNC - Academic Project Report Diagram Generator
Generates 12 high-resolution, professionally formatted UML, architecture, and workflow diagrams.
"""
import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches

OUTPUT_DIR = "ACADEXSYNC_Diagrams"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Common style constants
FONT_FAMILY = "sans-serif"
COLOR_PRIMARY = "#1E3A8A"      # Deep Navy
COLOR_SECONDARY = "#2563EB"    # Royal Blue
COLOR_ACCENT = "#0D9488"       # Teal
COLOR_AMBER = "#D97706"        # Amber
COLOR_BG_LIGHT = "#F8FAFC"     # Light Slate
COLOR_BORDER = "#64748B"       # Slate Gray
COLOR_DARK = "#0F172A"         # Charcoal Dark
COLOR_GREEN = "#16A34A"        # Emerald
COLOR_RED = "#DC2626"          # Crimson
COLOR_BOX_BG = "#EFF6FF"       # Soft Blue tint

def draw_box(ax, x, y, w, h, title, subtitle=None, bg_color=COLOR_BOX_BG, border_color=COLOR_SECONDARY, text_color=COLOR_DARK, title_size=10, sub_size=8, corner_radius=0.02):
    fancy = patches.FancyBboxPatch(
        (x, y), w, h,
        boxstyle=f"round,pad=0.01,rounding_size={corner_radius}",
        edgecolor=border_color,
        facecolor=bg_color,
        linewidth=1.5,
        zorder=2
    )
    ax.add_patch(fancy)
    if subtitle:
        ax.text(x + w/2, y + h*0.65, title, ha="center", va="center", fontsize=title_size, fontweight="bold", color=text_color, zorder=3)
        ax.text(x + w/2, y + h*0.32, subtitle, ha="center", va="center", fontsize=sub_size, color="#475569", zorder=3)
    else:
        ax.text(x + w/2, y + h/2, title, ha="center", va="center", fontsize=title_size, fontweight="bold", color=text_color, zorder=3)

def draw_arrow(ax, x1, y1, x2, y2, label=None, color=COLOR_SECONDARY, label_pos=0.5, label_offset=0.03, style="->", rad=0.0):
    ax.annotate(
        "", xy=(x2, y2), xytext=(x1, y1),
        arrowprops=dict(
            arrowstyle=style,
            color=color,
            linewidth=1.6,
            connectionstyle=f"arc3,rad={rad}",
            shrinkA=4,
            shrinkB=4
        ),
        zorder=4
    )
    if label:
        xm = x1 + (x2 - x1) * label_pos
        ym = y1 + (y2 - y1) * label_pos + label_offset
        ax.text(xm, ym, label, ha="center", va="center", fontsize=8, color="#1E293B",
                bbox=dict(boxstyle="square,pad=0.15", fc="white", ec="none", alpha=0.9), zorder=5)

# ==============================================================================
# Diagram 1: Overall ACADEXSYNC System Architecture
# ==============================================================================
def generate_diagram_1():
    fig, ax = plt.subplots(figsize=(12, 7.5), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.1: ACADEXSYNC Overall Multi-Tenant System Architecture", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    # Layer 1: Client Layer
    ax.add_patch(patches.Rectangle((0.03, 0.72), 0.94, 0.20, fc="#F1F5F9", ec="#94A3B8", ls="--", lw=1.2))
    ax.text(0.05, 0.89, "CLIENT TIER (Cross-Platform Flutter & Riverpod)", fontsize=10, fontweight="bold", color="#334155")
    draw_box(ax, 0.05, 0.74, 0.16, 0.13, "Super Admin\nPortal", "Platform Mgmt", "#E0F2FE", "#0284C7")
    draw_box(ax, 0.24, 0.74, 0.16, 0.13, "College Admin\nPortal", "Tenant Academics", "#E0F2FE", "#0284C7")
    draw_box(ax, 0.43, 0.74, 0.16, 0.13, "HOD\nWorkstation", "Dept Coordination", "#E0F2FE", "#0284C7")
    draw_box(ax, 0.62, 0.74, 0.16, 0.13, "Faculty\nInterface", "Classes & Attendance", "#E0F2FE", "#0284C7")
    draw_box(ax, 0.81, 0.74, 0.16, 0.13, "Student\nPortal", "Timetable & Records", "#E0F2FE", "#0284C7")

    # Layer 2: API Gateway & Security
    ax.add_patch(patches.Rectangle((0.03, 0.44), 0.94, 0.22, fc="#F8FAFC", ec="#94A3B8", ls="--", lw=1.2))
    ax.text(0.05, 0.63, "API GATEWAY & SECURITY LAYER (Express.js / TypeScript)", fontsize=10, fontweight="bold", color="#334155")
    draw_box(ax, 0.05, 0.46, 0.21, 0.14, "JWT Auth & Session Guard", "UUIDv4 AuthSession Store", "#FEF3C7", "#D97706")
    draw_box(ax, 0.28, 0.46, 0.21, 0.14, "Tenant Scope Guard", "requireCollegeScope (Multi-Tenant)", "#FEF3C7", "#D97706")
    draw_box(ax, 0.51, 0.46, 0.21, 0.14, "Role Hierarchy RBAC", "5-Tier Permission Check", "#FEF3C7", "#D97706")
    draw_box(ax, 0.74, 0.46, 0.23, 0.14, "Rate Limiter & Validation", "Zod Validation / Express", "#FEF3C7", "#D97706")

    # Layer 3: Core Domain Services
    ax.add_patch(patches.Rectangle((0.03, 0.21), 0.94, 0.18, fc="#F1F5F9", ec="#94A3B8", ls="--", lw=1.2))
    ax.text(0.05, 0.36, "CORE SERVICE SUBSYSTEMS", fontsize=10, fontweight="bold", color="#334155")
    draw_box(ax, 0.05, 0.23, 0.16, 0.11, "Attendance & Lock", "Idempotent Service", "#DCFCE7", "#16A34A")
    draw_box(ax, 0.23, 0.23, 0.16, 0.11, "Timetable & Sub", "Conflict Validator", "#DCFCE7", "#16A34A")
    draw_box(ax, 0.41, 0.23, 0.16, 0.11, "Request Center", "Multi-Level Workflow", "#DCFCE7", "#16A34A")
    draw_box(ax, 0.59, 0.23, 0.16, 0.11, "FCM Notification", "Multicast & In-App", "#DCFCE7", "#16A34A")
    draw_box(ax, 0.77, 0.23, 0.20, 0.11, "Gemini Tool Registry", "RAG & Structured Actions", "#DCFCE7", "#16A34A")

    # Layer 4: Persistence & Cloud Infrastructure
    ax.add_patch(patches.Rectangle((0.03, 0.02), 0.94, 0.15, fc="#F8FAFC", ec="#94A3B8", ls="--", lw=1.2))
    ax.text(0.05, 0.14, "PERSISTENCE & INFRASTRUCTURE TIER", fontsize=10, fontweight="bold", color="#334155")
    draw_box(ax, 0.05, 0.04, 0.28, 0.08, "MongoDB Atlas (37 Collections)", "Tenant-partitioned collections", "#F3E8FF", "#9333EA")
    draw_box(ax, 0.37, 0.04, 0.26, 0.08, "FastAPI Microservice", "Constraint Solver & Local RAG", "#F3E8FF", "#9333EA")
    draw_box(ax, 0.67, 0.04, 0.15, 0.08, "ImageKit CDN", "Secure Doc Store", "#F3E8FF", "#9333EA")
    draw_box(ax, 0.84, 0.04, 0.13, 0.08, "Firebase FCM", "Push Delivery", "#F3E8FF", "#9333EA")

    # Connectors
    draw_arrow(ax, 0.5, 0.72, 0.5, 0.66, "HTTPS REST / SSE Streams")
    draw_arrow(ax, 0.5, 0.44, 0.5, 0.39, "Authorized Execution")
    draw_arrow(ax, 0.5, 0.21, 0.5, 0.17, "Mongoose ODM / HTTP Proxy")

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_01_system_architecture.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 2: UML Use Case Diagram (5 Actors)
# ==============================================================================
def generate_diagram_2():
    fig, ax = plt.subplots(figsize=(12, 8), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 10.2: UML Use Case Diagram (ACADEXSYNC 5 User Roles)", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    # Draw System Boundary
    boundary = patches.Rectangle((0.26, 0.05), 0.48, 0.88, fill=False, ec=COLOR_PRIMARY, lw=2, ls="--")
    ax.add_patch(boundary)
    ax.text(0.50, 0.90, "ACADEXSYNC Platform Boundary", ha="center", fontsize=11, fontweight="bold", color=COLOR_PRIMARY)

    # Actors on Left: Super Admin, College Admin, HOD
    actors_left = [
        ("Super Admin\n(Platform)", 0.80),
        ("College Admin\n(Institution)", 0.50),
        ("Head of Dept\n(Department)", 0.20)
    ]
    for name, y in actors_left:
        ax.plot(0.10, y + 0.03, 'o', ms=12, mfc="#DBEAFE", mec=COLOR_SECONDARY, mew=2)
        ax.plot([0.10, 0.10], [y - 0.02, y + 0.015], color=COLOR_DARK, lw=2)
        ax.plot([0.07, 0.13], [y, y], color=COLOR_DARK, lw=2)
        ax.plot([0.10, 0.07], [y - 0.02, y - 0.05], color=COLOR_DARK, lw=2)
        ax.plot([0.10, 0.13], [y - 0.02, y - 0.05], color=COLOR_DARK, lw=2)
        ax.text(0.10, y - 0.09, name, ha="center", fontsize=8.5, fontweight="bold", color=COLOR_DARK)

    # Actors on Right: Faculty, Student
    actors_right = [
        ("Faculty Member\n(Teaching)", 0.65),
        ("Student\n(Learner)", 0.30)
    ]
    for name, y in actors_right:
        ax.plot(0.90, y + 0.03, 'o', ms=12, mfc="#DCFCE7", mec=COLOR_GREEN, mew=2)
        ax.plot([0.90, 0.90], [y - 0.02, y + 0.015], color=COLOR_DARK, lw=2)
        ax.plot([0.87, 0.93], [y, y], color=COLOR_DARK, lw=2)
        ax.plot([0.90, 0.87], [y - 0.02, y - 0.05], color=COLOR_DARK, lw=2)
        ax.plot([0.90, 0.93], [y - 0.02, y - 0.05], color=COLOR_DARK, lw=2)
        ax.text(0.90, y - 0.09, name, ha="center", fontsize=8.5, fontweight="bold", color=COLOR_DARK)

    # Use Cases (Ovals) inside boundary
    use_cases = [
        ("UC1: Onboard Institutions & Audit Logs", 0.82),
        ("UC2: Configure Academics & Manage Staff", 0.70),
        ("UC3: Build Timetable & Faculty Workload", 0.58),
        ("UC4: Review Requests & Substitutions", 0.46),
        ("UC5: Mark & Lock Period Attendance", 0.34),
        ("UC6: Upload Notes & Manage Assignments", 0.22),
        ("UC7: View Timetable & Track Attendance", 0.10)
    ]
    for title, y in use_cases:
        oval = patches.Ellipse((0.50, y), 0.42, 0.075, fc="#F8FAFC", ec=COLOR_SECONDARY, lw=1.4)
        ax.add_patch(oval)
        ax.text(0.50, y, title, ha="center", va="center", fontsize=8.5, fontweight="bold", color="#1E293B")

    # Connectors Left
    draw_arrow(ax, 0.16, 0.80, 0.29, 0.82, color=COLOR_SECONDARY)
    draw_arrow(ax, 0.16, 0.50, 0.29, 0.70, color=COLOR_SECONDARY)
    draw_arrow(ax, 0.16, 0.50, 0.29, 0.58, color=COLOR_SECONDARY)
    draw_arrow(ax, 0.16, 0.20, 0.29, 0.58, color=COLOR_SECONDARY)
    draw_arrow(ax, 0.16, 0.20, 0.29, 0.46, color=COLOR_SECONDARY)

    # Connectors Right
    draw_arrow(ax, 0.84, 0.65, 0.71, 0.34, color=COLOR_GREEN)
    draw_arrow(ax, 0.84, 0.65, 0.71, 0.22, color=COLOR_GREEN)
    draw_arrow(ax, 0.84, 0.30, 0.71, 0.46, color=COLOR_GREEN)
    draw_arrow(ax, 0.84, 0.30, 0.71, 0.10, color=COLOR_GREEN)

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_02_use_case_diagram.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 3: Role and Tenant Authorization Pipeline
# ==============================================================================
def generate_diagram_3():
    fig, ax = plt.subplots(figsize=(11, 7), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 7.1: Multi-Tenant Identity & Request Authorization Pipeline", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    draw_box(ax, 0.05, 0.78, 0.25, 0.14, "Global User Identity", "Canonical User Model\n(User._id, instituteId, email)", "#E0F2FE", "#0284C7")
    draw_box(ax, 0.38, 0.78, 0.25, 0.14, "Workspace Membership", "WorkspaceMembership Model\n(collegeId, status: ACTIVE)", "#E0F2FE", "#0284C7")
    draw_box(ax, 0.70, 0.78, 0.25, 0.14, "Role Assignment", "WorkspaceRoleAssignment\n(role: AppRole, departmentId)", "#E0F2FE", "#0284C7")

    draw_arrow(ax, 0.30, 0.85, 0.38, 0.85, "1:N Link")
    draw_arrow(ax, 0.63, 0.85, 0.70, 0.85, "1:N Scoped")

    # Inbound Request
    draw_box(ax, 0.05, 0.45, 0.90, 0.18, "Inbound HTTP Request", "Headers: { Authorization: 'Bearer <JWT>', X-Workspace-Id: '<collegeId>' }", "#FEF3C7", "#D97706")

    # Pipeline stages
    draw_box(ax, 0.05, 0.10, 0.20, 0.22, "1. authenticateRequest", "• Verify JWT signature & exp\n• Validate AuthSession in DB\n• Fail closed on mismatch\n• Attach req.user", "#DCFCE7", "#16A34A", title_size=9, sub_size=7.5)
    draw_box(ax, 0.29, 0.10, 0.20, 0.22, "2. requireCollegeScope", "• Allow Super Admin platform\n• Enforce req.collegeId match\n• Reject cross-college spoofing\n• Fail 403 Forbidden", "#DCFCE7", "#16A34A", title_size=9, sub_size=7.5)
    draw_box(ax, 0.53, 0.10, 0.20, 0.22, "3. requireDepartmentScope", "• Check HOD departmentId\n• Authorized depts check\n• Block cross-dept leaks\n• Attach req.departmentId", "#DCFCE7", "#16A34A", title_size=9, sub_size=7.5)
    draw_box(ax, 0.77, 0.10, 0.18, 0.22, "4. requireRoles / MinRole", "• Evaluate ROLE_HIERARCHY\n• SUPER_ADMIN (100)\n• COLLEGE_ADMIN (80)\n• HOD (60) / FACULTY (40)", "#DCFCE7", "#16A34A", title_size=9, sub_size=7.5)

    draw_arrow(ax, 0.50, 0.78, 0.50, 0.63, "Resolves Authoritative Context")
    draw_arrow(ax, 0.50, 0.45, 0.50, 0.35, "Passes Through Middleware Chain")
    draw_arrow(ax, 0.25, 0.21, 0.29, 0.21)
    draw_arrow(ax, 0.49, 0.21, 0.53, 0.21)
    draw_arrow(ax, 0.73, 0.21, 0.77, 0.21)

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_03_role_tenant_authorization.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 4: Frontend / Backend / Database / AI Component Diagram
# ==============================================================================
def generate_diagram_4():
    fig, ax = plt.subplots(figsize=(11, 7.5), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.2: ACADEXSYNC Subsystem Component Architecture", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    # Component 1: Flutter Client Subsystems
    ax.add_patch(patches.Rectangle((0.05, 0.52), 0.42, 0.38, fc="#F8FAFC", ec=COLOR_PRIMARY, lw=1.5))
    ax.text(0.07, 0.86, "Flutter Client Subsystem", fontsize=10, fontweight="bold", color=COLOR_PRIMARY)
    draw_box(ax, 0.07, 0.70, 0.18, 0.13, "Auth & Session", "Riverpod AuthProvider", "#DBEAFE", "#2563EB")
    draw_box(ax, 0.27, 0.70, 0.18, 0.13, "GoRouter Guard", "Role Redirection", "#DBEAFE", "#2563EB")
    draw_box(ax, 0.07, 0.55, 0.18, 0.12, "Attendance UI", "Mark & History", "#DBEAFE", "#2563EB")
    draw_box(ax, 0.27, 0.55, 0.18, 0.12, "Dio Client", "JWT Refresh Hook", "#DBEAFE", "#2563EB")

    # Component 2: Backend API Subsystems
    ax.add_patch(patches.Rectangle((0.53, 0.52), 0.42, 0.38, fc="#F8FAFC", ec=COLOR_SECONDARY, lw=1.5))
    ax.text(0.55, 0.86, "Express Backend Subsystem", fontsize=10, fontweight="bold", color=COLOR_SECONDARY)
    draw_box(ax, 0.55, 0.70, 0.18, 0.13, "21 REST Controllers", "Versioned v1 API", "#FEF3C7", "#D97706")
    draw_box(ax, 0.75, 0.70, 0.18, 0.13, "Auth & Tenant MW", "Strict Isolation", "#FEF3C7", "#D97706")
    draw_box(ax, 0.55, 0.55, 0.18, 0.12, "31 Domain Services", "Business Logic", "#FEF3C7", "#D97706")
    draw_box(ax, 0.75, 0.55, 0.18, 0.12, "ImageKit & FCM", "External Adapters", "#FEF3C7", "#D97706")

    # Component 3: AI Microservice Subsystem
    ax.add_patch(patches.Rectangle((0.05, 0.08), 0.42, 0.35, fc="#F8FAFC", ec=COLOR_ACCENT, lw=1.5))
    ax.text(0.07, 0.39, "AI Engine & RAG Subsystem", fontsize=10, fontweight="bold", color=COLOR_ACCENT)
    draw_box(ax, 0.07, 0.23, 0.18, 0.12, "FastAPI Service", "Port 8000 Microservice", "#CCFBF1", "#0D9488")
    draw_box(ax, 0.27, 0.23, 0.18, 0.12, "Timetable Solver", "Constraint Engine", "#CCFBF1", "#0D9488")
    draw_box(ax, 0.07, 0.10, 0.38, 0.10, "Google Gemini 1.5 Flash SDK", "AiToolsRegistry Function Calling", "#CCFBF1", "#0D9488")

    # Component 4: Database Subsystem
    ax.add_patch(patches.Rectangle((0.53, 0.08), 0.42, 0.35, fc="#F8FAFC", ec="#7C3AED", lw=1.5))
    ax.text(0.55, 0.39, "Database & Storage Subsystem", fontsize=10, fontweight="bold", color="#7C3AED")
    draw_box(ax, 0.55, 0.23, 0.18, 0.12, "MongoDB Atlas", "37 Collections", "#EDE9FE", "#7C3AED")
    draw_box(ax, 0.75, 0.23, 0.18, 0.12, "Mongoose ODM", "Schemas & Indexes", "#EDE9FE", "#7C3AED")
    draw_box(ax, 0.55, 0.10, 0.38, 0.10, "Multi-Tenant Compound Indexes", "{ collegeId: 1, sectionId: 1, date: 1 }", "#EDE9FE", "#7C3AED")

    # Connections
    draw_arrow(ax, 0.47, 0.70, 0.53, 0.70, "HTTP / JSON")
    draw_arrow(ax, 0.74, 0.52, 0.74, 0.43, "Data Queries")
    draw_arrow(ax, 0.53, 0.60, 0.47, 0.28, "AI Proxy & RPC")

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_04_component_diagram.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 5: Authentication & Session Sequence Diagram
# ==============================================================================
def generate_diagram_5():
    fig, ax = plt.subplots(figsize=(11, 7.5), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.5: Authentication & Authoritative Session Sequence Diagram", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    lifelines = [
        ("User / Client\n(Flutter UI)", 0.12),
        ("AuthController\n(Express)", 0.36),
        ("User Model\n(MongoDB)", 0.60),
        ("AuthSession Store\n(MongoDB)", 0.84)
    ]

    for name, x in lifelines:
        draw_box(ax, x - 0.10, 0.84, 0.20, 0.09, name, bg_color="#EFF6FF", border_color=COLOR_SECONDARY, title_size=8.5)
        ax.plot([x, x], [0.10, 0.84], color="#94A3B8", ls="--", lw=1.2, zorder=1)

    steps = [
        (0.76, 0.12, 0.36, "1. POST /auth/login { identifier, password }", COLOR_SECONDARY),
        (0.68, 0.36, 0.60, "2. findOne({ instituteId / email })", COLOR_DARK),
        (0.60, 0.60, 0.36, "3. Return canonical User document", COLOR_DARK),
        (0.52, 0.36, 0.36, "4. bcrypt.compare(password, hash)", COLOR_AMBER),
        (0.44, 0.36, 0.84, "5. create({ sessionId: UUIDv4, userId })", COLOR_SECONDARY),
        (0.36, 0.84, 0.36, "6. Return persisted AuthSession", COLOR_DARK),
        (0.28, 0.36, 0.36, "7. signJwt({ userId, role, sessionId })", COLOR_GREEN),
        (0.20, 0.36, 0.12, "8. 200 OK { token, user, sessionId }", COLOR_GREEN),
        (0.13, 0.12, 0.12, "9. SecureStorage.write() & Navigate", COLOR_PRIMARY)
    ]

    for y, x1, x2, label, color in steps:
        if x1 == x2:
            # Self call
            ax.plot([x1, x1 + 0.05, x1 + 0.05, x1], [y, y, y - 0.03, y - 0.03], color=color, lw=1.5)
            ax.text(x1 + 0.06, y - 0.015, label, va="center", fontsize=7.5, color=color, fontweight="bold")
        else:
            draw_arrow(ax, x1, y, x2, y, label=label, color=color, label_offset=0.02)

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_05_auth_login_sequence.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 6: Institutional Activation Sequence Diagram
# ==============================================================================
def generate_diagram_6():
    fig, ax = plt.subplots(figsize=(11, 7), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.6: User Account Activation & Credential Provisioning Sequence", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    lifelines = [
        ("New Staff / Student\n(Client)", 0.12),
        ("ActivationController\n(Express)", 0.36),
        ("Invitation Model\n(Database)", 0.60),
        ("User & Session\n(Database)", 0.84)
    ]

    for name, x in lifelines:
        draw_box(ax, x - 0.10, 0.84, 0.20, 0.09, name, bg_color="#EFF6FF", border_color=COLOR_SECONDARY, title_size=8.5)
        ax.plot([x, x], [0.10, 0.84], color="#94A3B8", ls="--", lw=1.2, zorder=1)

    steps = [
        (0.74, 0.12, 0.36, "1. POST /auth/activate/verify { token, code }", COLOR_SECONDARY),
        (0.66, 0.36, 0.60, "2. findOne({ code, status: 'PENDING' })", COLOR_DARK),
        (0.58, 0.60, 0.36, "3. Return invitation (pre-assigned role & college)", COLOR_DARK),
        (0.50, 0.12, 0.36, "4. POST /auth/activate/complete { password }", COLOR_SECONDARY),
        (0.42, 0.36, 0.84, "5. hash password & update User status = ACTIVE", COLOR_AMBER),
        (0.34, 0.36, 0.60, "6. mark Invitation status = CONSUMED", COLOR_DARK),
        (0.26, 0.36, 0.84, "7. create AuthSession & issue initial JWT", COLOR_GREEN),
        (0.18, 0.36, 0.12, "8. 200 OK { token, profile, role }", COLOR_GREEN)
    ]

    for y, x1, x2, label, color in steps:
        draw_arrow(ax, x1, y, x2, y, label=label, color=color, label_offset=0.02)

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_06_activation_sequence.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 7: Attendance Marking and Session Locking Sequence Diagram
# ==============================================================================
def generate_diagram_7():
    fig, ax = plt.subplots(figsize=(11, 7.5), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.7: Attendance Submission & Idempotent Session Locking Sequence", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    lifelines = [
        ("Faculty Member\n(Mobile App)", 0.12),
        ("AttendanceController\n(Backend API)", 0.36),
        ("TeachingAuthService\n(Authorization)", 0.60),
        ("Attendance Models\n(Session & Records)", 0.84)
    ]

    for name, x in lifelines:
        draw_box(ax, x - 0.10, 0.84, 0.20, 0.09, name, bg_color="#EFF6FF", border_color=COLOR_SECONDARY, title_size=8.5)
        ax.plot([x, x], [0.10, 0.84], color="#94A3B8", ls="--", lw=1.2, zorder=1)

    steps = [
        (0.75, 0.12, 0.36, "1. POST /attendance/sessions { sectionId, subjectId, timeSlot }", COLOR_SECONDARY),
        (0.67, 0.36, 0.60, "2. verifyTeachingContext(facultyId, subject, section)", COLOR_DARK),
        (0.59, 0.60, 0.36, "3. OK: Authorized via FacultyAssignment / Sub", COLOR_GREEN),
        (0.51, 0.36, 0.84, "4. normalize(timeSlot) & findOneAndUpdate(session)", COLOR_AMBER),
        (0.43, 0.12, 0.36, "5. POST /attendance/sessions/:id/submit { records: [...] }", COLOR_SECONDARY),
        (0.35, 0.36, 0.84, "6. Dual-write granular AttendanceRecord documents", COLOR_DARK),
        (0.27, 0.36, 0.84, "7. lockSession(id) -> status = 'LOCKED', auditLog", COLOR_RED),
        (0.19, 0.36, 0.12, "8. 200 OK { sessionId, summary: { present, late, absent } }", COLOR_GREEN)
    ]

    for y, x1, x2, label, color in steps:
        draw_arrow(ax, x1, y, x2, y, label=label, color=color, label_offset=0.02)

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_07_attendance_locking_sequence.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 8: Timetable Creation & Validation Activity Diagram
# ==============================================================================
def generate_diagram_8():
    fig, ax = plt.subplots(figsize=(10, 8), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.8: Timetable Construction & Conflict Validation Activity Diagram", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    # Start Node
    ax.plot(0.50, 0.94, 'o', ms=16, mfc=COLOR_DARK, mec=COLOR_DARK)
    ax.text(0.50, 0.965, "Start: Create/Edit Timetable", ha="center", fontsize=8.5, fontweight="bold")

    draw_arrow(ax, 0.50, 0.93, 0.50, 0.86)
    draw_box(ax, 0.30, 0.80, 0.40, 0.06, "HOD Selects Class Section & Day/Period", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)

    draw_arrow(ax, 0.50, 0.80, 0.50, 0.73)
    draw_box(ax, 0.30, 0.67, 0.40, 0.06, "Assign Faculty, Subject & Room", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)

    draw_arrow(ax, 0.50, 0.67, 0.50, 0.60)
    # Decision Diamond 1: Faculty Double Booked?
    ax.plot([0.50, 0.65, 0.50, 0.35, 0.50], [0.60, 0.54, 0.48, 0.54, 0.60], color=COLOR_AMBER, lw=1.8)
    ax.text(0.50, 0.54, "Faculty Double-Booked\nin Another Section?", ha="center", va="center", fontsize=7.5, fontweight="bold")

    draw_arrow(ax, 0.65, 0.54, 0.80, 0.54, "Yes", label_offset=0.015)
    draw_box(ax, 0.80, 0.50, 0.18, 0.08, "Flag Conflict!\nSuggest Sub/Swap", bg_color="#FEE2E2", border_color=COLOR_RED, title_size=7.5)
    draw_arrow(ax, 0.89, 0.58, 0.70, 0.70, rad=-0.3)

    draw_arrow(ax, 0.50, 0.48, 0.50, 0.41, "No", label_offset=0.02)
    # Decision Diamond 2: Room Occupied?
    ax.plot([0.50, 0.65, 0.50, 0.35, 0.50], [0.41, 0.35, 0.29, 0.35, 0.41], color=COLOR_AMBER, lw=1.8)
    ax.text(0.50, 0.35, "Room Occupied by\nAnother Class?", ha="center", va="center", fontsize=7.5, fontweight="bold")

    draw_arrow(ax, 0.65, 0.35, 0.80, 0.35, "Yes", label_offset=0.015)
    draw_box(ax, 0.80, 0.31, 0.18, 0.08, "Flag Room Clash!\nSelect Other Room", bg_color="#FEE2E2", border_color=COLOR_RED, title_size=7.5)
    draw_arrow(ax, 0.89, 0.39, 0.70, 0.68, rad=-0.3)

    draw_arrow(ax, 0.50, 0.29, 0.50, 0.22, "No", label_offset=0.02)
    draw_box(ax, 0.30, 0.16, 0.40, 0.06, "Commit Timeslot to TimetableGrid", bg_color="#DCFCE7", border_color=COLOR_GREEN)

    draw_arrow(ax, 0.50, 0.16, 0.50, 0.09)
    draw_box(ax, 0.30, 0.03, 0.40, 0.06, "Publish Timetable & Broadcast via FCM", bg_color="#DCFCE7", border_color=COLOR_GREEN)

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_08_timetable_validation_activity.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 9: Student Request Submission & Approval Flowchart
# ==============================================================================
def generate_diagram_9():
    fig, ax = plt.subplots(figsize=(10, 8), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.9: Request Center Submission & Multi-Tier Approval Workflow", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    draw_box(ax, 0.35, 0.88, 0.30, 0.07, "Student Submits Request\n(Leave, On-Duty, Grievance)", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)
    draw_arrow(ax, 0.50, 0.88, 0.50, 0.81)

    draw_box(ax, 0.30, 0.74, 0.40, 0.07, "Backend Assigns Request ID & PENDING Status\nTarget Role Evaluated (HOD / Admin)", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)
    draw_arrow(ax, 0.50, 0.74, 0.50, 0.67)

    # Decision 1: Target Approver
    ax.plot([0.50, 0.65, 0.50, 0.35, 0.50], [0.67, 0.61, 0.55, 0.61, 0.67], color=COLOR_AMBER, lw=1.8)
    ax.text(0.50, 0.61, "Request Scope?", ha="center", va="center", fontsize=8, fontweight="bold")

    draw_arrow(ax, 0.35, 0.61, 0.20, 0.61, "Departmental")
    draw_box(ax, 0.05, 0.57, 0.22, 0.08, "Routed to HOD Inbox\n(Departmental)", bg_color="#FEF3C7", border_color=COLOR_AMBER)

    draw_arrow(ax, 0.65, 0.61, 0.80, 0.61, "College-Wide")
    draw_box(ax, 0.73, 0.57, 0.22, 0.08, "Routed to College Admin\n(Institutional)", bg_color="#FEF3C7", border_color=COLOR_AMBER)

    draw_arrow(ax, 0.16, 0.57, 0.16, 0.44)
    draw_arrow(ax, 0.84, 0.57, 0.84, 0.44)

    draw_box(ax, 0.25, 0.37, 0.50, 0.07, "Approver Reviews Academic Context & Documentation", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)
    draw_arrow(ax, 0.16, 0.44, 0.25, 0.40)
    draw_arrow(ax, 0.84, 0.44, 0.75, 0.40)

    draw_arrow(ax, 0.50, 0.37, 0.50, 0.30)
    # Decision 2: Approval
    ax.plot([0.50, 0.65, 0.50, 0.35, 0.50], [0.30, 0.24, 0.18, 0.24, 0.30], color=COLOR_AMBER, lw=1.8)
    ax.text(0.50, 0.24, "Decision Approved?", ha="center", va="center", fontsize=8, fontweight="bold")

    draw_arrow(ax, 0.35, 0.24, 0.20, 0.24, "Approved")
    draw_box(ax, 0.05, 0.19, 0.22, 0.08, "Status: APPROVED\nExcused Attendance Triggered", bg_color="#DCFCE7", border_color=COLOR_GREEN)

    draw_arrow(ax, 0.65, 0.24, 0.80, 0.24, "Rejected")
    draw_box(ax, 0.73, 0.19, 0.22, 0.08, "Status: REJECTED\nMandatory Reason Provided", bg_color="#FEE2E2", border_color=COLOR_RED)

    draw_arrow(ax, 0.16, 0.19, 0.40, 0.09)
    draw_arrow(ax, 0.84, 0.19, 0.60, 0.09)

    draw_box(ax, 0.30, 0.02, 0.40, 0.07, "Push Notification & In-App Alert Delivered to Student", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_09_request_approval_flowchart.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 10: Notification Delivery Flowchart
# ==============================================================================
def generate_diagram_10():
    fig, ax = plt.subplots(figsize=(10, 7.5), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.10: Multi-Channel Institutional Notification Dispatch Pipeline", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    draw_box(ax, 0.32, 0.88, 0.36, 0.07, "Trigger Event: Announcement / Attendance Alert", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)
    draw_arrow(ax, 0.50, 0.88, 0.50, 0.80)

    draw_box(ax, 0.28, 0.73, 0.44, 0.07, "NotificationService.dispatchNotification(payload)", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)
    draw_arrow(ax, 0.50, 0.73, 0.50, 0.65)

    draw_box(ax, 0.25, 0.58, 0.50, 0.07, "Query Audience Recipients (Role / Dept / Section Filter)", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)
    draw_arrow(ax, 0.50, 0.58, 0.50, 0.50)

    draw_box(ax, 0.25, 0.43, 0.50, 0.07, "Batch Persist Notification in MongoDB\n(isRead: false, recipientId, collegeId)", bg_color="#DCFCE7", border_color=COLOR_GREEN)
    draw_arrow(ax, 0.50, 0.43, 0.50, 0.35)

    # Branch into 2 Channels: FCM vs Realtime
    draw_arrow(ax, 0.50, 0.35, 0.25, 0.26, "Push Channel")
    draw_arrow(ax, 0.50, 0.35, 0.75, 0.26, "Real-Time In-App")

    draw_box(ax, 0.08, 0.17, 0.34, 0.09, "Firebase FCM Multicast\nDeliver to Android DeviceTokens", bg_color="#FEF3C7", border_color=COLOR_AMBER)
    draw_box(ax, 0.58, 0.17, 0.34, 0.09, "Server-Sent Events (SSE) Stream\nDeliver to Active Riverpod Listeners", bg_color="#FEF3C7", border_color=COLOR_AMBER)

    draw_arrow(ax, 0.25, 0.17, 0.40, 0.08)
    draw_arrow(ax, 0.75, 0.17, 0.60, 0.08)

    draw_box(ax, 0.30, 0.01, 0.40, 0.07, "Client Receives Alert: SnackBar Banner & Badge Update", bg_color="#EFF6FF", border_color=COLOR_SECONDARY)

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_10_notification_flowchart.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 11: AI Assistant Request Sequence Diagram
# ==============================================================================
def generate_diagram_11():
    fig, ax = plt.subplots(figsize=(11, 7.5), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.11: Gemini AI Assistant Tool-Calling & Context Retrieval Flow", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    lifelines = [
        ("User\n(Flutter Chat)", 0.12),
        ("AiController\n(Express API)", 0.36),
        ("Google Gemini\n1.5 Flash Model", 0.60),
        ("AiToolsRegistry\n& MongoDB", 0.84)
    ]

    for name, x in lifelines:
        draw_box(ax, x - 0.10, 0.84, 0.20, 0.09, name, bg_color="#EFF6FF", border_color=COLOR_SECONDARY, title_size=8.5)
        ax.plot([x, x], [0.10, 0.84], color="#94A3B8", ls="--", lw=1.2, zorder=1)

    steps = [
        (0.75, 0.12, 0.36, "1. POST /ai/chat { message: 'When is my next class?' }", COLOR_SECONDARY),
        (0.67, 0.36, 0.60, "2. generateContentStream(prompt + tools, roleContext)", COLOR_DARK),
        (0.59, 0.60, 0.36, "3. FunctionCall: getNextClassForStudent(studentId)", COLOR_AMBER),
        (0.51, 0.36, 0.84, "4. executeTool('getNextClassForStudent', args, req.user)", COLOR_AMBER),
        (0.43, 0.84, 0.36, "5. Return structured DB record: { Subject: 'IOT', Room: '204' }", COLOR_DARK),
        (0.35, 0.36, 0.60, "6. Feed toolResponse back to Gemini Model turn", COLOR_SECONDARY),
        (0.27, 0.60, 0.36, "7. Model synthesizes natural response & proposal", COLOR_GREEN),
        (0.19, 0.36, 0.12, "8. SSE Stream delta chunks & ActionProposal to client", COLOR_GREEN)
    ]

    for y, x1, x2, label, color in steps:
        draw_arrow(ax, x1, y, x2, y, label=label, color=color, label_offset=0.02)

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_11_ai_assistant_sequence.png"), dpi=300)
    plt.close()

# ==============================================================================
# Diagram 12: Database Relationship (ER) Diagram
# ==============================================================================
def generate_diagram_12():
    fig, ax = plt.subplots(figsize=(12, 8.5), dpi=300)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    fig.patch.set_facecolor("white")

    plt.title("Figure 6.12: ACADEXSYNC Canonical Multi-Tenant Entity-Relationship Model", fontsize=13, fontweight="bold", pad=15, color=COLOR_PRIMARY)

    # Entities
    # Root: College
    draw_box(ax, 0.40, 0.88, 0.20, 0.08, "College (Root Tenant)", "_id, name, code, status", "#DBEAFE", "#1E3A8A")

    # Tier 2: Department, AcademicYear
    draw_box(ax, 0.15, 0.74, 0.20, 0.08, "Department", "_id, collegeId, code, hodId", "#EFF6FF", "#2563EB")
    draw_box(ax, 0.65, 0.74, 0.20, 0.08, "AcademicYear", "_id, collegeId, name, dates", "#EFF6FF", "#2563EB")

    # Tier 3: Course, Faculty
    draw_box(ax, 0.05, 0.58, 0.18, 0.08, "Course (Program)", "_id, departmentId, code", "#EFF6FF", "#2563EB")
    draw_box(ax, 0.30, 0.58, 0.18, 0.08, "Faculty", "_id, userId, departmentId", "#DCFCE7", "#16A34A")
    draw_box(ax, 0.55, 0.58, 0.18, 0.08, "Semester (Term)", "_id, courseId, academicYearId", "#EFF6FF", "#2563EB")
    draw_box(ax, 0.78, 0.58, 0.18, 0.08, "Subject", "_id, departmentId, semesterId", "#EFF6FF", "#2563EB")

    # Tier 4: Section, Student
    draw_box(ax, 0.05, 0.42, 0.18, 0.08, "Section (Class)", "_id, semesterId, name", "#EFF6FF", "#2563EB")
    draw_box(ax, 0.30, 0.42, 0.18, 0.08, "Student", "_id, userId, departmentId", "#DCFCE7", "#16A34A")
    draw_box(ax, 0.55, 0.42, 0.22, 0.08, "FacultyAssignment", "_id, facultyId, subjectId, secId", "#FEF3C7", "#D97706")
    draw_box(ax, 0.80, 0.42, 0.16, 0.08, "Room", "_id, collegeId, number", "#EFF6FF", "#2563EB")

    # Tier 5: Operational Records
    draw_box(ax, 0.05, 0.24, 0.22, 0.08, "StudentEnrollment", "_id, studentId, sectionId, semId", "#FEF3C7", "#D97706")
    draw_box(ax, 0.32, 0.24, 0.20, 0.08, "Timetable", "_id, sectionId, entries[]", "#EFF6FF", "#2563EB")
    draw_box(ax, 0.57, 0.24, 0.22, 0.08, "AttendanceSession", "_id, facultyAssignmentId, lock", "#FEE2E2", "#DC2626")
    draw_box(ax, 0.82, 0.24, 0.15, 0.08, "Note", "_id, subjectId, url", "#EFF6FF", "#2563EB")

    # Tier 6: Granular Records
    draw_box(ax, 0.57, 0.08, 0.22, 0.08, "AttendanceRecord", "_id, sessionId, studentId, status", "#FEE2E2", "#DC2626")
    draw_box(ax, 0.20, 0.08, 0.20, 0.08, "Request", "_id, requesterId, approverRole", "#EFF6FF", "#2563EB")

    # Connectors
    draw_arrow(ax, 0.40, 0.88, 0.25, 0.82, "1:N")
    draw_arrow(ax, 0.60, 0.88, 0.75, 0.82, "1:N")
    draw_arrow(ax, 0.25, 0.74, 0.14, 0.66, "1:N")
    draw_arrow(ax, 0.25, 0.74, 0.39, 0.66, "1:N")
    draw_arrow(ax, 0.14, 0.58, 0.14, 0.50, "1:N")
    draw_arrow(ax, 0.64, 0.58, 0.66, 0.50, "1:N")
    draw_arrow(ax, 0.39, 0.58, 0.66, 0.50, "binds")
    draw_arrow(ax, 0.87, 0.58, 0.66, 0.50, "binds")
    draw_arrow(ax, 0.14, 0.42, 0.16, 0.32, "1:N")
    draw_arrow(ax, 0.39, 0.42, 0.16, 0.32, "1:N")
    draw_arrow(ax, 0.66, 0.42, 0.68, 0.32, "authorizes")
    draw_arrow(ax, 0.68, 0.24, 0.68, 0.16, "1:N (Roll Call)")

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, "figure_12_database_er_diagram.png"), dpi=300)
    plt.close()

if __name__ == "__main__":
    print("Generating Figure 1...")
    generate_diagram_1()
    print("Generating Figure 2...")
    generate_diagram_2()
    print("Generating Figure 3...")
    generate_diagram_3()
    print("Generating Figure 4...")
    generate_diagram_4()
    print("Generating Figure 5...")
    generate_diagram_5()
    print("Generating Figure 6...")
    generate_diagram_6()
    print("Generating Figure 7...")
    generate_diagram_7()
    print("Generating Figure 8...")
    generate_diagram_8()
    print("Generating Figure 9...")
    generate_diagram_9()
    print("Generating Figure 10...")
    generate_diagram_10()
    print("Generating Figure 11...")
    generate_diagram_11()
    print("Generating Figure 12...")
    generate_diagram_12()
    print("All 12 diagrams successfully generated in ACADEXSYNC_Diagrams/!")

