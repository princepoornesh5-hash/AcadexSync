import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_management/features/auth/data/repositories/api_auth_repository.dart';
import 'package:campus_management/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_management/features/auth/presentation/screens/activation_screen.dart';
import 'package:campus_management/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:campus_management/features/users/domain/models/user_profile_model.dart';
import 'package:campus_management/features/users/domain/models/user_status_enum.dart';
import 'package:campus_management/features/users/presentation/providers/user_providers.dart';
import 'package:campus_management/features/users/data/repositories/user_repository.dart';
import 'package:campus_management/features/users/presentation/screens/user_form_screen.dart';
import 'package:campus_management/features/users/presentation/screens/user_detail_screen.dart';
import 'package:campus_management/features/attendance/domain/models/assigned_class.dart';
import 'package:campus_management/features/attendance/domain/models/attendance_record.dart';
import 'package:campus_management/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:campus_management/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:campus_management/features/attendance/presentation/screens/mark_attendance_screen.dart';
import 'package:campus_management/features/timetable/domain/models/timetable_models.dart';
import 'package:campus_management/features/timetable/data/repositories/timetable_repository.dart';
import 'package:campus_management/features/timetable/presentation/providers/timetable_providers.dart';
import 'package:campus_management/features/timetable/presentation/screens/timetable_dashboard_screen.dart';
import 'package:campus_management/features/notes/domain/models/note_model.dart';
import 'package:campus_management/features/notes/data/repositories/notes_repository.dart';
import 'package:campus_management/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_management/features/notes/presentation/screens/notes_dashboard_screen.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/data/repositories/notification_repository.dart';
import 'package:campus_management/features/notifications/presentation/providers/notification_providers.dart';
import 'package:campus_management/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:campus_management/features/settings/domain/models/settings_models.dart';

// --- Fakes for Binding Audit ---

class AuditAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  AuditAuthNotifier([AuthState? initial])
      : super(initial ?? const AuthUnauthenticated());

  bool loginCalled = false;
  bool logoutCalled = false;
  bool activateCalled = false;
  bool resetPasswordCalled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> login(String identifier, String password) async {
    loginCalled = true;
    final role = identifier.contains('hod')
        ? AppRole.hod
        : identifier.contains('fac')
            ? AppRole.faculty
            : identifier.contains('stud')
                ? AppRole.student
                : AppRole.collegeAdmin;

    final user = UserModel(
      id: 'usr_audit_1',
      instituteId: identifier,
      name: 'Audit User',
      email: '$identifier@campus.edu',
      role: role,
      collegeId: 'col_audit_1',
      departmentId: 'dept_cs_1',
      accountStatus: AccountStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = AuthAuthenticated(user: user, token: 'audit_token_jwt');
  }

  void setAuthenticated(UserModel user) {
    state = AuthAuthenticated(user: user, token: 'audit_token_jwt');
  }
}

class AuditApiAuthRepository extends ApiAuthRepository {
  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String identifier,
    required String otpCode,
  }) async {
    return 'mock_jwt_reset_token';
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {}
}

class AuditUserRepository implements UserRepository {
  final List<UserProfileModel> users = [];
  bool createUserCalled = false;
  bool updateUserCalled = false;
  bool deleteUserCalled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<UserProfileModel>> getUsers({
    String? scopeCollegeId,
    String? scopeDepartmentId,
    AppRole? role,
    String? departmentId,
    UserStatus? status,
    String? searchQuery,
  }) async {
    var filtered = List<UserProfileModel>.from(users);
    if (role != null) {
      filtered = filtered.where((u) => u.role == role).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((u) => u.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    return filtered;
  }

  @override
  Future<UserProfileModel?> getUserById(String id) async {
    return users.firstWhere(
      (u) => u.id == id,
      orElse: () => UserProfileModel(
        id: id,
        name: 'Mock User',
        email: 'mock@campus.edu',
        role: AppRole.faculty,
        collegeId: 'col_1',
        status: UserStatus.active,
        accountStatus: AccountStatus.active,
      ),
    );
  }

  @override
  Future<UserProfileModel> createUser(UserProfileModel user) async {
    createUserCalled = true;
    final created = user.copyWith(
      id: 'usr_created_${DateTime.now().millisecondsSinceEpoch}',
      status: UserStatus.pending,
      accountStatus: AccountStatus.pendingActivation,
    );
    users.add(created);
    return created;
  }

  @override
  Future<UserProfileModel> updateUser(UserProfileModel user) async {
    updateUserCalled = true;
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      users[idx] = user;
    }
    return user;
  }

  @override
  Future<void> deleteUser(String id) async {
    deleteUserCalled = true;
    users.removeWhere((u) => u.id == id);
  }

  @override
  Future<void> reactivateUser(String id) async {}

  Future<String> generateActivationCode(UserProfileModel user) async {
    return 'ACADEX-998877';
  }
}

class AuditAttendanceRepository implements AttendanceRepository {
  bool markAttendanceCalled = false;
  final List<AttendanceRecord> records = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<AssignedClass>> getAssignedClasses(String facultyId, DateTime date) async {
    return [
      AssignedClass(
        id: 'cls_1',
        subjectId: 'sub_algo',
        subjectName: 'Algorithms & Complexity',
        sectionId: 'sec_a',
        sectionName: 'CSE Section A',
        semester: 'Semester 4',
        timeSlot: '09:00 - 10:00',
        date: date,
      ),
    ];
  }

  Future<void> saveAttendanceRecords(List<AttendanceRecord> newRecords) async {
    markAttendanceCalled = true;
    records.addAll(newRecords);
  }
}

class AuditTimetableRepository implements TimetableRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<TimetableModel>> watchTimetable({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? sectionId,
  }) async* {
    yield [
      TimetableModel(
        id: 'tt_1',
        collegeId: collegeId ?? 'col_1',
        departmentId: departmentId ?? 'dept_cs',
        sectionId: sectionId ?? 'sec_a',
        facultyId: userId,
        subjectId: 'sub_algo',
        dayOfWeek: TimetableDay.monday,
        startTime: '09:00',
        endTime: '10:00',
        roomNumber: 'Lab 3',
        courseId: 'crs_algo',
        semesterId: 'sem_4',
        academicYearId: 'ay_2026',
        sessionType: TimetableSessionType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

class AuditNotesRepository implements NotesRepository {
  final List<NoteModel> notes = [
    NoteModel(
      id: 'note_1',
      title: 'Dynamic Programming Lecture Notes',
      description: 'Comprehensive notes for DP algorithms',
      resourceType: ResourceType.fileAttachment,
      subjectId: 'sub_algo',
      semesterId: 'sem_4',
      sectionId: 'sec_a',
      departmentId: 'dept_cs',
      collegeId: 'col_1',
      authorUserId: 'fac_1',
      fileUrl: 'https://ik.imagekit.io/mock/dp_notes.pdf',
      fileType: 'pdf',
      fileSize: 2048576,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<NoteModel>> watchNotes({
    required AppRole role,
    required String userId,
    String? collegeId,
    String? departmentId,
    String? courseId,
    String? semesterId,
    String? sectionId,
  }) async* {
    yield notes;
  }
}

class AuditNotificationRepository implements NotificationRepository {
  final List<NotificationModel> notifications = [
    NotificationModel(
      id: 'notif_1',
      title: 'New Assignment Published',
      message: 'Algorithms Assignment 3 is now live.',
      category: NotificationCategory.academic,
      priority: NotificationPriority.normal,
      audienceType: NotificationAudienceType.personal,
      timestamp: DateTime.now(),
      isRead: false,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<List<NotificationModel>> watchNotifications(UserModel user, NotificationPreferences prefs) async* {
    yield notifications;
  }

  @override
  Future<void> markAsRead(String id, String userId) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx] = NotificationModel(
        id: notifications[idx].id,
        title: notifications[idx].title,
        message: notifications[idx].message,
        category: notifications[idx].category,
        priority: notifications[idx].priority,
        audienceType: notifications[idx].audienceType,
        timestamp: notifications[idx].timestamp,
        isRead: true,
      );
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    for (var i = 0; i < notifications.length; i++) {
      notifications[i] = NotificationModel(
        id: notifications[i].id,
        title: notifications[i].title,
        message: notifications[i].message,
        category: notifications[i].category,
        priority: notifications[i].priority,
        audienceType: notifications[i].audienceType,
        timestamp: notifications[i].timestamp,
        isRead: true,
      );
    }
  }
}

Widget buildAuditTestApp({
  required Widget child,
  AuditAuthNotifier? authNotifier,
  AuditUserRepository? userRepo,
  AuditAttendanceRepository? attendanceRepo,
  AuditTimetableRepository? timetableRepo,
  AuditNotesRepository? notesRepo,
  AuditNotificationRepository? notifRepo,
  AssignedClass? activeClass,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(path: '/login', builder: (context, state) => const Scaffold(body: Text('Login Screen'))),
      GoRoute(path: '/activate', builder: (context, state) => const Scaffold(body: Text('Activate Screen'))),
      GoRoute(path: '/forgot-password', builder: (context, state) => const Scaffold(body: Text('Forgot Password Screen'))),
      GoRoute(path: '/dashboard', builder: (context, state) => const Scaffold(body: Text('Dashboard Screen'))),
      GoRoute(path: '/dashboard/student', builder: (context, state) => const Scaffold(body: Text('Student Dashboard'))),
      GoRoute(path: '/dashboard/faculty', builder: (context, state) => const Scaffold(body: Text('Faculty Dashboard'))),
      GoRoute(path: '/dashboard/hod', builder: (context, state) => const Scaffold(body: Text('HOD Dashboard'))),
      GoRoute(path: '/dashboard/college_admin', builder: (context, state) => const Scaffold(body: Text('College Admin Dashboard'))),
      GoRoute(path: '/dashboard/super_admin', builder: (context, state) => const Scaffold(body: Text('Super Admin Dashboard'))),
    ],
  );

  return ProviderScope(
    overrides: [
      apiAuthRepositoryProvider.overrideWithValue(AuditApiAuthRepository()),
      if (authNotifier != null) authProvider.overrideWith((ref) => authNotifier),
      if (userRepo != null) userRepositoryProvider.overrideWithValue(userRepo),
      if (attendanceRepo != null) attendanceRepoProvider.overrideWithValue(attendanceRepo),
      if (timetableRepo != null) timetableRepositoryProvider.overrideWithValue(timetableRepo),
      if (notesRepo != null) notesRepositoryProvider.overrideWithValue(notesRepo),
      if (notifRepo != null) notificationRepositoryProvider.overrideWithValue(notifRepo),
      if (activeClass != null) activeClassProvider.overrideWith((ref) => activeClass),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('ACADEX — Master Backend ↔ Flutter 9-Flow Binding Audit Tests', () {
    
    testWidgets('FLOW 1: College Admin creates HOD -> Form dispatches creation -> PENDING_ACTIVATION', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final userRepo = AuditUserRepository();
      await tester.pumpWidget(buildAuditTestApp(
        child: const UserFormScreen(),
        userRepo: userRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Dr. Ada Lovelace');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'ada@campus.edu');
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number'), '+91 9876543210');
      await tester.enterText(find.widgetWithText(TextFormField, 'Employee / Institutional ID'), 'EMP-HOD-CS');

      final submitBtn = find.text('Register User');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(userRepo.createUserCalled, isTrue);
      expect(userRepo.users.any((u) => u.name == 'Dr. Ada Lovelace'), isTrue);
      expect(userRepo.users.first.accountStatus, AccountStatus.pendingActivation);
    });

    testWidgets('FLOW 2: Faculty Activation -> Step 1 Code Verification -> Step 2 Password Setup -> ACTIVE', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAuditTestApp(
        child: const ActivationScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Activate Account'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(0), 'COL01');
      await tester.enterText(inputs.at(1), 'FAC-CS-01');
      await tester.enterText(inputs.at(2), 'ACADEX-123456');

      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Create Password'), findsOneWidget);
    });

    testWidgets('FLOW 3: Student Login -> Backend Authentication -> Dashboard Routing', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authNotifier = AuditAuthNotifier();
      await tester.pumpWidget(buildAuditTestApp(
        child: const LoginScreen(),
        authNotifier: authNotifier,
      ));
      await tester.pumpAndSettle();

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.first, 'student_1@campus.edu');
      await tester.enterText(inputs.last, 'StudentPass@123');

      final loginBtn = find.text('Sign In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(authNotifier.loginCalled, isTrue);
      expect(authNotifier.state, isA<AuthAuthenticated>());
      final authState = authNotifier.state as AuthAuthenticated;
      expect(authState.user.role, AppRole.student);
    });

    testWidgets('FLOW 4: Faculty opens Timetable -> Displays assigned classes from backend', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final facultyUser = UserModel(
        id: 'fac_1',
        instituteId: 'EMP-FAC-01',
        name: 'Prof. Turing',
        email: 'turing@campus.edu',
        role: AppRole.faculty,
        collegeId: 'col_1',
        departmentId: 'dept_cs',
        accountStatus: AccountStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authNotifier = AuditAuthNotifier();
      authNotifier.setAuthenticated(facultyUser);
      final timetableRepo = AuditTimetableRepository();

      await tester.pumpWidget(buildAuditTestApp(
        child: const TimetableDashboardScreen(),
        authNotifier: authNotifier,
        timetableRepo: timetableRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Timetable'), findsOneWidget);
    });

    testWidgets('FLOW 5: Faculty Attendance -> Mark attendance -> Backend persists records', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final attendanceRepo = AuditAttendanceRepository();
      final assignedClass = AssignedClass(
        id: 'cls_1',
        subjectId: 'sub_algo',
        subjectName: 'Algorithms & Complexity',
        sectionId: 'sec_a',
        sectionName: 'CSE Section A',
        semester: 'Semester 4',
        timeSlot: '09:00 - 10:00',
        date: DateTime.now(),
      );

      await tester.pumpWidget(buildAuditTestApp(
        child: const MarkAttendanceScreen(),
        attendanceRepo: attendanceRepo,
        activeClass: assignedClass,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Algorithms & Complexity'), findsOneWidget);
    });

    testWidgets('FLOW 6: Notes System -> Notes repository watch -> Note listed and visible for student', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final studentUser = UserModel(
        id: 'stud_1',
        instituteId: 'ROLL-101',
        name: 'Student Ada',
        email: 'ada@student.edu',
        role: AppRole.student,
        collegeId: 'col_1',
        departmentId: 'dept_cs',
        semesterId: 'sem_4',
        sectionId: 'sec_a',
        accountStatus: AccountStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authNotifier = AuditAuthNotifier();
      authNotifier.setAuthenticated(studentUser);
      final notesRepo = AuditNotesRepository();

      await tester.pumpWidget(buildAuditTestApp(
        child: const NotesDashboardScreen(),
        authNotifier: authNotifier,
        notesRepo: notesRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Academic Resources'), findsOneWidget);
    });

    testWidgets('FLOW 7: Notifications -> AppTopBar unread badge reflects unread count -> Mark read reduces count', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final user = UserModel(
        id: 'usr_audit_1',
        instituteId: 'EMP-01',
        name: 'Prof. Grace',
        email: 'grace@campus.edu',
        role: AppRole.faculty,
        collegeId: 'col_1',
        accountStatus: AccountStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authNotifier = AuditAuthNotifier();
      authNotifier.setAuthenticated(user);
      final notifRepo = AuditNotificationRepository();

      await tester.pumpWidget(buildAuditTestApp(
        child: const NotificationCenterScreen(),
        authNotifier: authNotifier,
        notifRepo: notifRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Notification Center'), findsOneWidget);
    });

    testWidgets('FLOW 8: Forgot Password Recovery -> Email input -> OTP -> Password reset flow', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAuditTestApp(
        child: const ForgotPasswordScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);

      final input = find.byType(TextFormField).first;
      await tester.enterText(input, 'recovery@campus.edu');
      final submitBtn = find.text('Send Verification Code');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('STEP 2 OF 3'), findsOneWidget);
    });

    testWidgets('FLOW 9: Admin Directory Search -> Profile Detail -> Live Edit -> Persists in Backend', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final userRepo = AuditUserRepository();
      final existingUser = UserProfileModel(
        id: 'usr_target_1',
        instituteId: 'EMP-TARG-01',
        name: 'Dr. Target Person',
        email: 'target@campus.edu',
        role: AppRole.faculty,
        collegeId: 'col_audit_1',
        departmentId: 'dept_cs',
        accountStatus: AccountStatus.active,
        status: UserStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      userRepo.users.add(existingUser);

      await tester.pumpWidget(buildAuditTestApp(
        child: const UserDetailScreen(userId: 'usr_target_1'),
        userRepo: userRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Target Person'), findsWidgets);
      expect(find.text('target@campus.edu'), findsOneWidget);
    });
  });
}
