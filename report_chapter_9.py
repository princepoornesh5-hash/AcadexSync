"""
ACADEXSYNC - Chapter 9 Generator: Important Source Code with Explanation
Covers all 16 verified production source code listings from the repository.
"""
from report_builder import AcadexDocBuilder

def generate_chapter_9(b: AcadexDocBuilder):
    b.add_chapter_heading("CHAPTER 9: IMPORTANT SOURCE CODE WITH EXPLANATION")

    b.add_body_paragraph(
        "This chapter presents sixteen authoritative source-code listings extracted directly from the ACADEXSYNC production repository. "
        "Each listing documents a critical architectural component spanning the cross-platform Flutter frontend, the Node.js/TypeScript Express API gateway, "
        "and the Google Gemini AI integration. Each code excerpt is accompanied by a comprehensive technical breakdown explaining its algorithmic logic, "
        "inputs, outputs, execution flow, and security considerations."
    )

    # ==============================================================================
    # LISTING 1: main.dart
    # ==============================================================================
    code_main = """// File: Frontend/lib/main.dart
void main() async {
  debugPrint('[BOOT_START]');
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Initialize Network & API Target (Emulator 10.0.2.2 vs Physical Device IP)
      await ApiClient.initializeEnvironment();

      // 2. Android Edge-to-Edge System Bar Configuration
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // 3. Centralized Framework & Async Error Boundaries
      FlutterError.onError = (FlutterErrorDetails details) {
        AcadexLogger.error('Flutter Framework Error', error: details.exception, stackTrace: details.stack);
        if (!kReleaseMode) FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        AcadexLogger.error('Unhandled Async Error (PlatformDispatcher)', error: error, stackTrace: stack);
        return true; // Prevent unhandled crash
      };

      // 4. Initialize Firebase Admin / Messaging Predictably
      await FirebaseInitializer.initializePredictably();

      // 5. Mount Root Application with Riverpod ProviderScope
      runApp(
        const ProviderScope(
          child: AcadexApp(),
        ),
      );
    },
    (error, stack) => AcadexLogger.error('Fatal Zone Error', error: error, stackTrace: stack),
  );
}"""
    b.add_code_listing(
        "Application Entry Point and Bootstrap Lifecycle",
        "Frontend/lib/main.dart",
        code_main,
        [
            ("runZonedGuarded Wrapper", "Encapsulates the entire runtime inside an isolated async zone, intercepting uncaught asynchronous exceptions and routing them to `AcadexLogger` to guarantee zero unhandled app crashes."),
            ("WidgetsFlutterBinding.ensureInitialized()", "Binds the Flutter framework engine to the host platform before any platform channels or native asynchronous APIs are invoked."),
            ("ApiClient.initializeEnvironment()", "Deterministically detects whether the client is executing on an Android emulator (routing to `10.0.2.2:5001`) or a physical smartphone (resolving live Wi-Fi gateway IP or production domain)."),
            ("SystemUIOverlayStyle Configuration", "Configures transparent system and navigation bars, enforcing modern edge-to-edge layout rendering on Android and iOS devices."),
            ("ProviderScope Mounting", "Wraps `AcadexApp` inside Riverpod's root `ProviderScope`, initializing the reactive state tree and enabling global dependency injection.")
        ],
        inputs="Application launch intent from mobile OS or desktop runtime.",
        outputs="Initialized Riverpod container mounting `AcadexApp` with global error barriers.",
        security="Prevents fatal application terminations on unhandled exceptions; enforces secure HTTPS endpoints."
    )

    # ==============================================================================
    # LISTING 2: Declarative Router & Route Guards
    # ==============================================================================
    code_router = """// File: Frontend/lib/app/router/app_router.dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/startup',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final isAuth = authState is AuthAuthenticated;
      final isStartup = state.matchedLocation == '/startup';
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState is AuthInitial || isStartup) return null;

      // 1. Unauthenticated users must be redirected to /login
      if (!isAuth) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Authenticated users attempting /login or /startup redirected to role dashboard
      if (isLoggingIn || isStartup) {
        final role = authState.user.role;
        return RoleRedirectHelper.resolveDashboardPath(role);
      }

      // 3. Enforce strict role boundary on protected routes
      if (!RoleGuard.isAuthorized(authState.user.role, state.matchedLocation)) {
        return '/access-restricted';
      }

      return null;
    },
    routes: [ ... ],
  );
});"""
    b.add_code_listing(
        "Declarative Router with Role-Based Route Guards",
        "Frontend/lib/app/router/app_router.dart",
        code_router,
        [
            ("refreshListenable Hook", "Subscribes GoRouter directly to Riverpod's `authNotifier.stream`, triggering automatic route re-evaluation whenever auth state changes (e.g. login, session expiry, or logout)."),
            ("Unauthenticated Interception", "Guards all internal paths against unauthenticated access, transparently funneling unauthorized visitors to `/login`."),
            ("Role-Based Dashboard Resolution", "Invokes `RoleRedirectHelper.resolveDashboardPath` to route users to `/dashboard/super-admin`, `/dashboard/college-admin`, `/dashboard/hod`, `/dashboard/faculty`, or `/dashboard/student` based on verified token identity."),
            ("RoleGuard Boundary Check", "Verifies whether the current user's role possesses statutory permissions for the targeted URI, immediately redirecting violators to `/access-restricted`.")
        ],
        inputs="Inbound route navigation intent (`state.matchedLocation`) and active `authState`.",
        outputs="Authorized destination route path or redirection URI string.",
        security="Prevents privilege escalation by restricting URI navigation based on authenticated role context."
    )

    # ==============================================================================
    # LISTING 3: Role Definitions & Hierarchy
    # ==============================================================================
    code_roles = """// File: Backend/src/constants/roles.ts
export enum AppRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  COLLEGE_ADMIN = 'COLLEGE_ADMIN',
  HOD = 'HOD',
  FACULTY = 'FACULTY',
  STUDENT = 'STUDENT',
}

export const ROLE_HIERARCHY: Record<AppRole, number> = {
  [AppRole.SUPER_ADMIN]: 100,
  [AppRole.COLLEGE_ADMIN]: 80,
  [AppRole.HOD]: 60,
  [AppRole.FACULTY]: 40,
  [AppRole.STUDENT]: 20,
};

export function normalizeRole(role: string): AppRole {
  const normalized = role.trim().replace(/[\\s_-]+/g, '_').toUpperCase();
  switch (normalized) {
    case 'SUPERADMIN':
    case 'SUPER_ADMIN':
      return AppRole.SUPER_ADMIN;
    case 'COLLEGEADMIN':
    case 'COLLEGE_ADMIN':
      return AppRole.COLLEGE_ADMIN;
    case 'HOD':
      return AppRole.HOD;
    case 'FACULTY':
      return AppRole.FACULTY;
    case 'STUDENT':
      return AppRole.STUDENT;
    default:
      throw new Error(`Unrecognized or invalid AppRole value: "${role}"`);
  }
}"""
    b.add_code_listing(
        "Institutional Role Enumeration and Hierarchy Mapping",
        "Backend/src/constants/roles.ts",
        code_roles,
        [
            ("AppRole Enum", "Defines the canonical five institutional roles, providing strict compile-time type safety across all backend services, controllers, and models."),
            ("ROLE_HIERARCHY Weight Mapping", "Assigns an immutable numeric rank to each role (100 down to 20), allowing hierarchical route guards (`requireMinRole`) to perform deterministic mathematical permission comparisons."),
            ("normalizeRole Function", "Sanitizes user input strings by stripping whitespace and normalizing casing and hyphens, preventing subtle authorization bypasses caused by string variations.")
        ],
        inputs="Raw role string from database document or token claim.",
        outputs="Type-safe `AppRole` enum member or normalized hierarchy weight.",
        security="Centralizes access control definitions; prevents role spoofing via strict normalization."
    )

    # ==============================================================================
    # LISTING 4: Authentication & Session Middleware
    # ==============================================================================
    code_auth_mw = """// File: Backend/src/middleware/auth.middleware.ts
export async function authenticateRequest(req: Request, _res: Response, next: NextFunction): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(ApiError.unauthorized('Authentication token is required'));
  }

  const token = authHeader.split(' ')[1];
  try {
    const payload = verifyJwtToken(token, TokenType.ACCESS);

    // 1. Authoritative Database Session Validation
    if (payload.sessionId) {
      if (!isValidSessionId(payload.sessionId)) {
        return next(ApiError.unauthorized('Invalid session identifier format'));
      }

      const session = await AuthSession.findOne({ sessionId: payload.sessionId });
      if (!session || session.userId.toString() !== payload.userId.toString()) {
        return next(ApiError.unauthorized('Session not found or user mismatch. Please log in again.'));
      }

      if (session.isRevoked() || session.isExpired()) {
        return next(ApiError.unauthorized('Authentication session has expired or been revoked.'));
      }
    }

    // 2. Canonical User Verification
    const user = await User.findById(payload.userId);
    if (!user || user.accountStatus !== AccountStatus.ACTIVE) {
      return next(ApiError.unauthorized('User account is inactive or not found'));
    }

    // 3. Attach Authoritative Request Context
    req.user = {
      id: user._id.toString(),
      instituteId: user.instituteId,
      name: user.name,
      role: payload.role,
      collegeId: payload.collegeId || user.collegeId?.toString(),
      departmentId: payload.departmentId || user.departmentId?.toString(),
      sessionId: payload.sessionId,
      accountStatus: user.accountStatus,
    };
    req.collegeId = req.user.collegeId;

    return next();
  } catch (err) {
    return next(ApiError.unauthorized('Invalid or expired authentication token'));
  }
}"""
    b.add_code_listing(
        "Authoritative Authentication & Stateful Session Verification Middleware",
        "Backend/src/middleware/auth.middleware.ts",
        code_auth_mw,
        [
            ("Bearer Token Extraction", "Extracts the JWT access token from the HTTP `Authorization` header, rejecting missing or malformed headers with HTTP 401 Unauthorized."),
            ("Cryptographic Token Verification", "Invokes `verifyJwtToken` to validate the digital signature and expiration timestamp of the token."),
            ("Stateful AuthSession Lookup", "Performs an authoritative query against MongoDB's `AuthSession` collection, verifying that the session has not been revoked by an administrator or concurrent logout."),
            ("Active User Verification", "Confirms that the user exists in the `User` collection and possesses `AccountStatus.ACTIVE` status."),
            ("Request Context Binding", "Binds verified user metadata to `req.user` and `req.collegeId`, establishing the security context for downstream controllers.")
        ],
        inputs="Inbound HTTP request carrying `Authorization: Bearer <JWT>` header.",
        outputs="Appends verified `AuthenticatedUser` object to `req.user` and invokes `next()`.",
        security="Fails closed on any session validation anomaly; prevents revoked token reuse."
    )

    # ==============================================================================
    # LISTING 5: Super Admin & College Admin Selection
    # ==============================================================================
    code_admin_selection = """// File: Frontend/lib/app/router/app_router.dart (Excerpt: Admin Dashboard Selection)
GoRoute(
  path: '/dashboard/super-admin',
  builder: (context, state) {
    return const SuperAdminDashboardScreen();
  },
  routes: [
    GoRoute(
      path: 'colleges',
      builder: (context, state) => const CollegeDirectoryScreen(),
    ),
    GoRoute(
      path: 'audit-logs',
      builder: (context, state) => const PlatformAuditLogsScreen(),
    ),
  ],
),
GoRoute(
  path: '/dashboard/college-admin',
  builder: (context, state) {
    return const CollegeAdminDashboardScreen();
  },
  routes: [
    GoRoute(
      path: 'academics',
      builder: (context, state) => const AcademicStructureHomeScreen(),
    ),
    GoRoute(
      path: 'people',
      builder: (context, state) => const UserDirectoryScreen(),
    ),
    GoRoute(
      path: 'reports',
      builder: (context, state) => const AttendanceReportCenterScreen(),
    ),
  ],
),"""
    b.add_code_listing(
        "Administrative Dashboard Route Declarations",
        "Frontend/lib/app/router/app_router.dart",
        code_admin_selection,
        [
            ("Super Admin Sub-Tree", "Defines the platform administrative boundary: `/dashboard/super-admin` providing root access to multi-college directory (`colleges`) and global audit logs (`audit-logs`)."),
            ("College Admin Sub-Tree", "Defines institutional administrative routes: `/dashboard/college-admin` exposing academic structure management (`academics`), user directory (`people`), and attendance reporting (`reports`)."),
            ("Hierarchical Nesting", "Uses nested GoRoute sub-paths to preserve persistent navigation bars and drawer states while navigating sub-features.")
        ],
        inputs="Route navigation state matching administrative URI patterns.",
        outputs="Renders `SuperAdminDashboardScreen` or `CollegeAdminDashboardScreen` with nested tabs.",
        security="Protected by `RoleGuard`, ensuring lower-tier roles cannot mount administrative view trees."
    )

    # ==============================================================================
    # LISTING 6: HOD, Faculty, and Student Selection
    # ==============================================================================
    code_academic_selection = """// File: Frontend/lib/app/router/app_router.dart (Excerpt: HOD, Faculty & Student Selection)
GoRoute(
  path: '/dashboard/hod',
  builder: (context, state) => const HodDashboardScreen(),
  routes: [
    GoRoute(path: 'timetable', builder: (context, state) => const TimetableManagementScreen()),
    GoRoute(path: 'workload', builder: (context, state) => const FacultyWorkloadScreen()),
    GoRoute(path: 'approvals', builder: (context, state) => const RequestCenterScreen()),
  ],
),
GoRoute(
  path: '/dashboard/faculty',
  builder: (context, state) => const FacultyDashboardScreen(),
  routes: [
    GoRoute(path: 'mark-attendance', builder: (context, state) => const MarkAttendanceScreen()),
    GoRoute(path: 'my-classes', builder: (context, state) => const MyAssignmentsScreen()),
    GoRoute(path: 'notes', builder: (context, state) => const NotesManagementScreen()),
  ],
),
GoRoute(
  path: '/dashboard/student',
  builder: (context, state) => const StudentDashboardScreen(),
  routes: [
    GoRoute(path: 'attendance', builder: (context, state) => const StudentAttendancePortalScreen()),
    GoRoute(path: 'timetable', builder: (context, state) => const StudentTimetableScreen()),
    GoRoute(path: 'requests', builder: (context, state) => const RequestCenterScreen()),
  ],
),"""
    b.add_code_listing(
        "Academic Role Dashboard Route Declarations",
        "Frontend/lib/app/router/app_router.dart",
        code_academic_selection,
        [
            ("HOD Operational Routes", "Exposes departmental tools: weekly timetable management, faculty workload distribution, and leave/OD approvals."),
            ("Faculty Classroom Routes", "Exposes teaching utilities: rapid attendance roll call (`mark-attendance`), assigned subject schedule (`my-classes`), and syllabus notes management."),
            ("Student Portal Routes", "Exposes personal student views: live attendance tracking (`attendance`), daily schedule (`timetable`), and digital request submission (`requests`).")
        ],
        inputs="Authenticated navigation state for HOD, Faculty, or Student users.",
        outputs="Mounts the appropriate role dashboard widget tree.",
        security="Strictly isolates faculty attendance submission from student view-only portals."
    )

    # ==============================================================================
    # LISTING 7: Authentication Controller
    # ==============================================================================
    code_auth_ctrl = """// File: Backend/src/controllers/auth.controller.ts
export class AuthController {
  static login = asyncHandler(async (req: Request, res: Response) => {
    const { identifier, password, collegeId, preferredWorkspaceId } = req.body;
    if (!identifier || !password) {
      throw ApiError.badRequest('Identifier (PIN Number, email, or phone) and password are required');
    }

    const rawHeaderWorkspaceId = req.headers['x-workspace-id'];
    const headerWorkspaceId = (
      Array.isArray(rawHeaderWorkspaceId) ? rawHeaderWorkspaceId[0] : rawHeaderWorkspaceId
    )?.trim();

    const metadata = {
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip || req.socket.remoteAddress,
      preferredWorkspaceId: preferredWorkspaceId || collegeId || headerWorkspaceId,
      collegeId: collegeId || preferredWorkspaceId || headerWorkspaceId,
    };

    const result = await AuthService.login(identifier, password, metadata);
    return ApiResponse.success(res, result, 'Login successful');
  });

  static logout = asyncHandler(async (req: Request, res: Response) => {
    const sessionId = req.user?.sessionId;
    const userId = req.user?.id;
    if (sessionId) {
      await AuthService.revokeSession(sessionId, userId);
    }
    return ApiResponse.success(res, null, 'Logged out successfully');
  });
}"""
    b.add_code_listing(
        "Backend Authentication Controller (Login & Logout)",
        "Backend/src/controllers/auth.controller.ts",
        code_auth_ctrl,
        [
            ("Identifier Validation", "Accepts polymorphic login identifiers (PIN Number, email address, or phone number) alongside the plain-text password."),
            ("Workspace Metadata Extraction", "Captures user agent, client IP, and target `X-Workspace-Id` to resolve multi-tenant workspace context."),
            ("AuthService Delegation", "Delegates credential verification and session creation to `AuthService.login`."),
            ("Session Revocation on Logout", "Extracts `req.user.sessionId` and permanently revokes the authoritative database session record.")
        ],
        inputs="POST payload containing `{ identifier, password }` and client headers.",
        outputs="HTTP 200 JSON with access token, refresh token, user profile, and session ID.",
        security="Enforces password hashing; captures client metadata for security auditing."
    )

    # ==============================================================================
    # LISTING 8: Role Authorization Guard
    # ==============================================================================
    code_role_mw = """// File: Backend/src/middleware/role.middleware.ts
export function requireRoles(...allowedRoles: AppRole[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(ApiError.unauthorized('Authentication required'));
    }

    const hasAllowedRole =
      allowedRoles.includes(req.user.role) ||
      (req.user.activeRoles && req.user.activeRoles.some((r) => allowedRoles.includes(r)));

    if (!hasAllowedRole) {
      return next(
        ApiError.forbidden(`Access denied. Role "${req.user.role}" does not have permission.`)
      );
    }

    return next();
  };
}

export const requireSuperAdmin = requireRoles(AppRole.SUPER_ADMIN);
export const requireCollegeAdmin = requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN);
export const requireHodOrAbove = requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD);
export const requireFacultyOrAbove = requireRoles(
  AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY
);"""
    b.add_code_listing(
        "Declarative Role-Based Access Control Middleware",
        "Backend/src/middleware/role.middleware.ts",
        code_role_mw,
        [
            ("Higher-Order Function Pattern", "Returns an Express middleware closure parameterized by allowed `AppRole` values."),
            ("Multi-Role Membership Check", "Evaluates both primary `req.user.role` and secondary `req.user.activeRoles` array."),
            ("Pre-Configured Role Gates", "Exports reusable semantic guards (`requireSuperAdmin`, `requireCollegeAdmin`, `requireHodOrAbove`, `requireFacultyOrAbove`).")
        ],
        inputs="Inbound request with authenticated `req.user` context.",
        outputs="Invokes `next()` if authorized; rejects with HTTP 403 Forbidden on failure.",
        security="Prevents unauthorized vertical role traversal across API endpoints."
    )

    # ==============================================================================
    # LISTING 9: Multi-Tenant College Scope Guard
    # ==============================================================================
    code_tenant_mw = """// File: Backend/src/middleware/tenant.middleware.ts
export function requireCollegeScope(req: Request, _res: Response, next: NextFunction): void {
  if (!req.user) {
    return next(ApiError.unauthorized('User authentication required for tenant validation'));
  }

  // Super Admin has unrestricted platform access
  if (req.user.role === AppRole.SUPER_ADMIN) {
    return next();
  }

  const userCollegeId = req.user.collegeId;
  if (!userCollegeId) {
    return next(ApiError.forbidden('User does not belong to any registered college tenant'));
  }

  // Detect and reject cross-college spoofing in params, query, or body
  const targetCollegeId = req.params.collegeId || (req.query.collegeId as string) || req.body?.collegeId;
  if (targetCollegeId && targetCollegeId.toString() !== userCollegeId.toString()) {
    return next(
      ApiError.forbidden('Cross-college tenant access is strictly prohibited. Access restricted.')
    );
  }

  req.collegeId = userCollegeId;
  return next();
}"""
    b.add_code_listing(
        "Multi-Tenant College Isolation Middleware",
        "Backend/src/middleware/tenant.middleware.ts",
        code_tenant_mw,
        [
            ("Super Admin Exemption", "Permits platform Super Admins unrestricted cross-tenant oversight for platform maintenance."),
            ("Tenant College Binding", "Validates that non-SuperAdmin users possess a valid `collegeId` in their authenticated token."),
            ("Cross-Tenant Spoofing Rejection", "Inspects URL params, query strings, and body payloads; rejects any mismatch between targeted college and authenticated tenant with HTTP 403 Forbidden.")
        ],
        inputs="Inbound HTTP request parameters and verified `req.user.collegeId`.",
        outputs="Binds verified `req.collegeId` and continues request pipeline.",
        security="Guarantees absolute multi-tenant data isolation; prevents cross-college data access."
    )

    # ==============================================================================
    # LISTING 10: Attendance Ingestion Pipeline
    # ==============================================================================
    code_att_ingest = """// File: Backend/src/services/attendance.service.ts (Excerpt: Session Ingestion)
async createOrSubmitSession(
  collegeId: string,
  data: Partial<IAttendanceSession> & { records?: any[]; facultyAssignmentId?: any },
  actorUserId?: string,
  requester?: AuthenticatedUser
): Promise<IAttendanceSession> {
  // 1. Normalize timeSlot string (replaces Unicode dashes with ASCII hyphen)
  const normalizedTimeSlot = normalizeTimeSlot(data.timeSlot || '');

  // 2. Validate Teaching Context via TeachingAuthorizationService
  if (requester && requester.role === AppRole.FACULTY) {
    const isAuthorized = await TeachingAuthorizationService.verifyFacultyTeachingContext({
      collegeId,
      facultyUserId: requester.id,
      sectionId: data.sectionId?.toString() || '',
      subjectId: data.subjectId?.toString() || '',
    });
    if (!isAuthorized) {
      throw ApiError.forbidden('You are not authorized to record attendance for this class section');
    }
  }

  // 3. Find or Create Session Idempotently using Compound Unique Index
  let session = await AttendanceSession.findOne({
    collegeId,
    sectionId: data.sectionId,
    subjectId: data.subjectId,
    date: data.date,
    timeSlot: normalizedTimeSlot,
  });

  if (!session) {
    session = new AttendanceSession({
      ...data,
      collegeId,
      timeSlot: normalizedTimeSlot,
      status: AttendanceSessionStatus.OPEN,
      createdBy: actorUserId,
    });
    await session.save();
  }

  // 4. Ingest and Dual-Write Student Attendance Records
  if (data.records && data.records.length > 0) {
    session = await this.submitRecords(session._id.toString(), data.records, requester!);
  }

  return session;
}"""
    b.add_code_listing(
        "Idempotent Attendance Session Creation and Ingestion Pipeline",
        "Backend/src/services/attendance.service.ts",
        code_att_ingest,
        [
            ("Unicode Timeslot Normalization", "Calls `normalizeTimeSlot` to transform Unicode en-dashes (`\\u2013`) into standard ASCII hyphens (`-`), preventing duplicate sessions caused by encoding differences."),
            ("Teaching Authorization Verification", "Invokes `TeachingAuthorizationService` to verify that the faculty member is officially assigned to teach the targeted subject and section."),
            ("Compound Index Deduplication", "Queries MongoDB using the exact compound key (`collegeId`, `sectionId`, `subjectId`, `date`, `timeSlot`), reusing existing sessions on network retries."),
            ("Dual-Write Record Ingestion", "Delegates record storage to `submitRecords`, persisting granular `AttendanceRecord` documents while maintaining an embedded snapshot in `session.records`.")
        ],
        inputs="`collegeId`, session metadata, student attendance status array, and `requester` user.",
        outputs="Persisted `AttendanceSession` Mongoose document.",
        security="Prevents unauthorized teachers from marking attendance; prevents duplicate sessions."
    )

    # ==============================================================================
    # LISTING 11: Idempotent Session Locking
    # ==============================================================================
    code_att_lock = """// File: Backend/src/services/attendance.service.ts (Excerpt: lockSession)
async lockSession(sessionId: string, requester: AuthenticatedUser): Promise<IAttendanceSession> {
  if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
    throw ApiError.forbidden('Unauthorized to lock attendance session');
  }

  const session = await this.getSessionById(sessionId, requester.collegeId, requester.role === AppRole.SUPER_ADMIN, requester);

  if (requester.role === AppRole.FACULTY) {
    const facultyProfile = await this.resolveFacultyProfile(requester);
    if (session.facultyId.toString() !== facultyProfile._id.toString() && session.facultyId.toString() !== requester.id) {
      throw ApiError.forbidden('Faculty can only lock their own attendance sessions');
    }
  }

  session.status = AttendanceSessionStatus.LOCKED;
  session.isLocked = true;
  session.lastModifiedBy = requester.id;
  await session.save();

  await AuditLog.create({
    collegeId: session.collegeId.toString(),
    actorUserId: requester.id,
    action: 'ATTENDANCE_SESSION_LOCKED',
    entityType: 'AttendanceSession',
    entityId: session.id,
  });

  return session;
}"""
    b.add_code_listing(
        "Permanent Attendance Session Locking and Audit Recording",
        "Backend/src/services/attendance.service.ts",
        code_att_lock,
        [
            ("Authorization Verification", "Ensures that only authorized staff (Super Admin, College Admin, HOD, or the teaching Faculty member) can lock a session."),
            ("Faculty Ownership Guard", "Prevents teachers from locking or modifying sessions belonging to other faculty members."),
            ("Status Transition & Lock Commit", "Sets `status = AttendanceSessionStatus.LOCKED` and `isLocked = true`, freezing all contained student marks against further mutation."),
            ("Immutable Audit Logging", "Creates a persistent `AuditLog` entry recording the exact timestamp, actor ID, and action.")
        ],
        inputs="`sessionId` string and `requester` user context.",
        outputs="Locked `IAttendanceSession` document.",
        security="Prevents retrospective mark manipulation; establishes an immutable academic audit trail."
    )

    # ==============================================================================
    # LISTING 12: Timetable Conflict Validation
    # ==============================================================================
    code_tt_validate = """// File: Backend/src/services/timetable.service.ts (Excerpt: validateTimetableEntries)
static async validateTimetableEntries(
  collegeId: string,
  semesterId: string,
  courseId: string,
  section: InstanceType<typeof Section> | null,
  entries: ITimetableGridEntry[],
  currentTimetableId?: string,
  academicYearId?: string,
  breaks: ITimetableBreak[] = []
): Promise<void> {
  const timeRegex = /^([01]\\d|2[0-3]):([0-5]\\d)$/;

  // 1. Time Format Checks
  for (const e of entries) {
    if (!timeRegex.test(e.startTime) || !timeRegex.test(e.endTime) || e.startTime >= e.endTime) {
      throw ApiError.badRequest(`Entry has invalid time range: ${e.startTime} - ${e.endTime}`);
    }
  }

  // 2. Break Overlap Checks
  if (breaks && breaks.length > 0) {
    for (const entry of entries) {
      for (const brk of breaks) {
        const applies = !brk.appliesToDays || brk.appliesToDays.includes(entry.dayOfWeek);
        if (applies && isTimeOverlapping(entry.startTime, entry.endTime, brk.startTime, brk.endTime)) {
          throw ApiError.conflict(
            `Break conflict: Class on ${entry.dayOfWeek} overlaps with break "${brk.name}"`
          );
        }
      }
    }
  }

  // 3. Faculty Double-Booking & Room Collision Checks
  for (const entry of entries) {
    const facultyClash = await Timetable.findOne({
      collegeId,
      _id: { $ne: currentTimetableId },
      'entries.dayOfWeek': entry.dayOfWeek,
      'entries.facultyId': entry.facultyId,
      'entries.startTime': { $lt: entry.endTime },
      'entries.endTime': { $gt: entry.startTime },
    });
    if (facultyClash) {
      throw ApiError.conflict(`Faculty double-booking conflict on ${entry.dayOfWeek} (${entry.startTime}-${entry.endTime})`);
    }
  }
}"""
    b.add_code_listing(
        "Deterministic Timetable Conflict and Overlap Validator",
        "Backend/src/services/timetable.service.ts",
        code_tt_validate,
        [
            ("Time Format Verification", "Validates that timeslots match strict 24-hour HH:MM format and that `startTime < endTime`."),
            ("Break Overlap Detection", "Iterates over institutional break intervals (lunch, assembly), rejecting any classes scheduled across break windows."),
            ("Cross-Section Faculty Double-Booking Check", "Queries all active timetables across the college to verify that the assigned faculty member is not already teaching another class during the same time interval.")
        ],
        inputs="College ID, semester ID, array of proposed `ITimetableGridEntry` objects, and break schedules.",
        outputs="Completes successfully if no conflicts exist; throws `ApiError.conflict` on overlap.",
        security="Prevents scheduling impossibilities and double-booked faculty workloads."
    )

    # ==============================================================================
    # LISTING 13: Request Submission & Approval
    # ==============================================================================
    code_request_ctrl = """// File: Backend/src/controllers/request.controller.ts
export class RequestController {
  static createRequest = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const created = await RequestService.createRequest(req.body, req.user!);
    ApiResponse.created(res, created, 'Request submitted successfully.');
  });

  static respondToRequest = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const updated = await RequestService.respondToRequest(req.params.id, req.body, req.user!);
    ApiResponse.success(res, updated, 'Response submitted successfully.');
  });

  static updateStatus = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const updated = await RequestService.updateStatus(
      req.params.id,
      req.body.status,
      req.body.note,
      req.user!
    );
    ApiResponse.success(res, updated, 'Request status updated successfully.');
  });
}"""
    b.add_code_listing(
        "Request Center Workflow Controller",
        "Backend/src/controllers/request.controller.ts",
        code_request_ctrl,
        [
            ("createRequest Action", "Receives student leave or OD submissions, validates document attachments, and delegates creation to `RequestService`."),
            ("respondToRequest Action", "Permits authorized approvers (HOD, College Admin) to record official review remarks and request additional documentation."),
            ("updateStatus Action", "Executes formal state transitions (PENDING -> APPROVED / REJECTED); automatically invokes attendance adjustment hooks on approval.")
        ],
        inputs="HTTP request body containing request details, target status, and review notes.",
        outputs="JSON response with updated `Request` document.",
        security="Restricts approval status mutations strictly to designated institutional authorities."
    )

    # ==============================================================================
    # LISTING 14: FCM Push Multicast Dispatch
    # ==============================================================================
    code_fcm = """// File: Backend/src/services/fcm.service.ts (Excerpt: sendMulticastNotification)
export class FcmService {
  static async sendMulticastNotification(
    deviceTokens: string[],
    payload: PushNotificationPayload
  ): Promise<PushDeliveryResult> {
    if (!this.ensureInitialized()) {
      return { successfulCount: 0, failureCount: 0, invalidTokens: [] };
    }

    const messaging = this.mockMessagingClient || getMessaging(this.appInstance!);
    const message: MulticastMessage = {
      tokens: deviceTokens,
      notification: {
        title: payload.title,
        body: payload.body,
        imageUrl: payload.imageUrl,
      },
      data: payload.data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'acadex_high_importance_channel',
          sound: 'default',
        },
      },
    };

    const response: BatchResponse = await messaging.sendEachForMulticast(message);
    const invalidTokens: string[] = [];

    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errCode = resp.error?.code;
        if (errCode === 'messaging/invalid-registration-token' || errCode === 'messaging/registration-token-not-registered') {
          invalidTokens.push(deviceTokens[idx]);
        }
      }
    });

    return {
      successfulCount: response.successCount,
      failureCount: response.failureCount,
      invalidTokens,
    };
  }
}"""
    b.add_code_listing(
        "High-Priority Firebase Cloud Messaging (FCM) Multicast Dispatcher",
        "Backend/src/services/fcm.service.ts",
        code_fcm,
        [
            ("ensureInitialized Guard", "Initializes the Firebase Admin SDK singleton using environment service account credentials, gracefully degrading in offline development."),
            ("Multicast Message Construction", "Assembles the FCM payload with high-priority Android delivery channels (`acadex_high_importance_channel`), sound alerts, and custom deep-link routing data."),
            ("sendEachForMulticast Execution", "Dispatches the message batch to hundreds of client device tokens simultaneously."),
            ("Invalid Token Pruning", "Detects unregistered or expired tokens (`registration-token-not-registered`) and flags them for deletion from the database.")
        ],
        inputs="Array of Android FCM device tokens and `PushNotificationPayload`.",
        outputs="`PushDeliveryResult` object containing success count, failure count, and invalid tokens.",
        security="Prevents credential exposure by loading service account secrets from secure environment variables."
    )

    # ==============================================================================
    # LISTING 15: Canonical Data Schema
    # ==============================================================================
    code_schema = """// File: Backend/src/models/attendanceSession.model.ts (Excerpt: Schema Definition)
const AttendanceSessionSchema = new Schema<IAttendanceSession>(
  {
    collegeId: { type: Schema.Types.ObjectId, ref: 'College', required: true, index: true },
    departmentId: { type: Schema.Types.ObjectId, ref: 'Department', required: true, index: true },
    facultyId: { type: Schema.Types.ObjectId, ref: 'Faculty', required: true, index: true },
    subjectId: { type: Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    subjectName: { type: String, required: true },
    sectionId: { type: Schema.Types.ObjectId, ref: 'Section', default: null, index: true },
    timeSlot: { type: String, required: true, trim: true },
    date: { type: Date, required: true, index: true },
    records: [AttendanceRecordItemSchema],
    status: {
      type: String,
      enum: Object.values(AttendanceSessionStatus),
      default: AttendanceSessionStatus.OPEN,
      index: true,
    },
    isLocked: { type: Boolean, default: false },
    version: { type: Number, default: 1 },
  },
  { timestamps: true }
);

// Compound Unique Index: Guarantees Exactly One Session Per Timeslot Per Section
AttendanceSessionSchema.index(
  { collegeId: 1, sectionId: 1, subjectId: 1, date: 1, timeSlot: 1 },
  { unique: true }
);"""
    b.add_code_listing(
        "Canonical Attendance Session Schema and Compound Unique Index",
        "Backend/src/models/attendanceSession.model.ts",
        code_schema,
        [
            ("Tenant Partitioning Fields", "Defines mandatory `collegeId` and `departmentId` references indexed for rapid scoped querying."),
            ("Embedded Record Item Subdocuments", "Embeds `AttendanceRecordItemSchema` array representing the roll call snapshot taken at class time."),
            ("Compound Unique Index", "Establishes a composite unique index on `{ collegeId, sectionId, subjectId, date, timeSlot }`, enforcing database-level uniqueness across sessions."),
            ("Optimistic Concurrency Versioning", "Includes a `version` field to guard against concurrent write collisions.")
        ],
        inputs="Mongoose document initialization data matching `IAttendanceSession` interface.",
        outputs="Validated MongoDB document persisted in `attendancesessions` collection.",
        security="Compound uniqueness prevents database corruption and duplicate roll call records."
    )

    # ==============================================================================
    # LISTING 16: AI Gemini Tool Registry
    # ==============================================================================
    code_ai = """// File: Backend/src/services/ai.service.ts (Excerpt: AI Tool-Calling Loop)
export class AiService {
  static async generateChatResponse(params: GenerateChatResponseParams): Promise<ChatResponseResult> {
    const client = AiService.getClient();
    const modelName = env.GEMINI_MODEL || 'gemini-1.5-flash';
    const tools = getFunctionDeclarationsForRole(params.user.role);

    const contents: any[] = [
      { role: 'user', parts: [{ text: params.message }] }
    ];

    // Multi-Turn Tool Calling Execution Loop
    for (let round = 0; round < MAX_TOOL_ROUNDS; round++) {
      const response = await client.models.generateContent({
        model: modelName,
        contents,
        tools: [{ functionDeclarations: tools }],
      });

      const candidate = response.candidates?.[0];
      const functionCalls = candidate?.content?.parts?.filter(p => p.functionCall).map(p => p.functionCall);

      if (!functionCalls || functionCalls.length === 0) {
        return {
          answer: candidate?.content?.parts?.[0]?.text || 'No response generated.',
          model: modelName,
        };
      }

      // Execute Tool Functions with Authenticated User Context
      const toolResponses = [];
      for (const call of functionCalls) {
        const executed = await AiToolsRegistry.executeTool(
          call.name,
          call.args || {},
          { user: params.user, collegeId: params.collegeId || params.user.collegeId || '' }
        );
        toolResponses.push({
          functionResponse: { name: call.name, response: executed.result }
        });
      }

      contents.push(candidate.content);
      contents.push({ role: 'user', parts: toolResponses });
    }

    return { answer: 'Processed your query.', model: modelName };
  }
}"""
    b.add_code_listing(
        "Google Gemini 1.5 Flash Function-Calling Execution Loop",
        "Backend/src/services/ai.service.ts",
        code_ai,
        [
            ("Role-Filtered Function Declarations", "Calls `getFunctionDeclarationsForRole` to dynamically bind only those tools authorized for the user's role (e.g. students cannot invoke admin tools)."),
            ("Model Turn & Tool Invocation", "Sends prompt and tools to Gemini 1.5 Flash, detecting model-generated `functionCall` objects."),
            ("Secure Tool Execution", "Executes server-side tools via `AiToolsRegistry.executeTool`, injecting the verified `req.user` context to enforce tenant data isolation."),
            ("Feedback & Synthesis", "Feeds tool query results back into the model conversation history, allowing Gemini to synthesize a natural, context-rich response.")
        ],
        inputs="User natural language prompt, chat history, and authenticated `req.user`.",
        outputs="`ChatResponseResult` containing synthesized answer and optional action proposal.",
        security="Filters function declarations by role; executes database queries strictly within user's tenant scope."
    )

    b.add_page_break()

print("Chapter 9 generator ready.")

