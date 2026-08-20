import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/presentation/screens/activation_screen.dart';
import 'package:campus_management/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:campus_management/features/auth/repositories/auth_repository.dart';
import 'package:campus_management/features/users/domain/models/user_profile_model.dart';
import 'package:campus_management/features/users/presentation/widgets/user_status_badge.dart';

void main() {
  group('ACADEX Account Lifecycle — Models & Enums Tests', () {
    test('AccountStatus correctly maps to/from backend snake_case and string values', () {
      expect(AccountStatusExtension.fromString('pending_activation'), AccountStatus.pendingActivation);
      expect(AccountStatusExtension.fromString('pending'), AccountStatus.pendingActivation);
      expect(AccountStatusExtension.fromString('active'), AccountStatus.active);
      expect(AccountStatusExtension.fromString('deactivated'), AccountStatus.deactivated);
      expect(AccountStatusExtension.fromString('inactive'), AccountStatus.inactive);
      expect(AccountStatusExtension.fromString('suspended'), AccountStatus.suspended);

      expect(AccountStatus.pendingActivation.value, 'pending_activation');
      expect(AccountStatus.active.value, 'active');
      expect(AccountStatus.deactivated.value, 'deactivated');
      expect(AccountStatus.inactive.value, 'inactive');
      expect(AccountStatus.suspended.value, 'suspended');

      expect(AccountStatus.pendingActivation.displayName, 'Pending Activation');
      expect(AccountStatus.active.displayName, 'Active');
    });

    test('UserModel and UserProfileModel deserialize and serialize all lifecycle fields', () {
      final json = {
        'id': 'user-101',
        'firebaseUid': 'fb-uid-101',
        'instituteId': 'CS2026-001',
        'name': 'Priya Sharma',
        'email': 'priya@campus.edu',
        'phone': '+91 9876543210',
        'role': 'STUDENT',
        'accountStatus': 'pending_activation',
        'activationStatus': 'pending',
        'collegeId': 'col-1',
        'departmentId': 'dept-cse',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user-101');
      expect(user.instituteId, 'CS2026-001');
      expect(user.name, 'Priya Sharma');
      expect(user.role, AppRole.student);
      expect(user.accountStatus, AccountStatus.pendingActivation);
      expect(user.activationStatus, 'pending');

      final profile = UserProfileModel.fromJson(json);
      expect(profile.employeeId, 'CS2026-001');
      expect(profile.phone, '+91 9876543210');
      expect(profile.accountStatus, AccountStatus.pendingActivation);

      final userJson = user.toJson();
      expect(userJson['accountStatus'], 'pending_activation');
      expect(userJson['instituteId'], 'CS2026-001');
    });

    testWidgets('UserStatusBadge renders correctly for AccountStatus.pendingActivation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserStatusBadge(status: AccountStatus.pendingActivation),
          ),
        ),
      );

      expect(find.text('Pending Activation'), findsOneWidget);
    });
  });

  group('ACADEX Account Lifecycle — Activation Screen UI/UX Tests', () {
    testWidgets('Step 1: Renders College Code, Student/Employee ID, and Activation Code fields', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ActivationScreen(),
          ),
        ),
      );

      expect(find.text('Activate Account'), findsWidgets);
      expect(find.text('College Code'), findsOneWidget);
      expect(find.text('Student or Employee ID'), findsOneWidget);
      expect(find.text('Activation Code'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Step 1 validation requires all fields before proceeding', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ActivationScreen(),
          ),
        ),
      );

      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your college code'), findsOneWidget);
      expect(find.text('Please enter your ID'), findsOneWidget);
      expect(find.text('Please enter your activation code'), findsOneWidget);
    });

    testWidgets('Step 1 valid submission transitions to Step 2: Create Password', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ActivationScreen(),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'ACADEX-COL');
      await tester.enterText(textFields.at(1), 'CS2026001');
      await tester.enterText(textFields.at(2), 'ACT-8899');

      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Create Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });
  });

  group('ACADEX Account Lifecycle — Forgot Password Screen 3-Step Flow Tests', () {
    testWidgets('Step 1: Renders email/phone input and Send Verification Code button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Email or Phone'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
    });

    testWidgets('Step 1 validation requires email or phone', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      final sendBtn = find.text('Send Verification Code');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email or phone'), findsOneWidget);
    });
  });

  group('ACADEX Account Lifecycle — MockAuthRepository Contract Tests', () {
    test('MockAuthRepository implements all lifecycle methods cleanly', () async {
      final repo = MockAuthRepository();

      // 1. Login
      final user = await repo.login('admin@acadex.com', 'acadex123');
      expect(user.role, AppRole.superAdmin);

      // 2. Development Role Login
      final faculty = await repo.loginAsDevelopmentRole(AppRole.faculty);
      expect(faculty.role, AppRole.faculty);

      // 3. Password Reset Request
      await repo.sendPasswordResetEmail('student@acadex.com');

      // 4. OTP Verification
      final token = await repo.verifyPasswordResetOtp(identifier: 'student@acadex.com', otpCode: '123456');
      expect(token, isNotEmpty);

      // 5. Password Reset
      await repo.resetPassword(resetToken: token, newPassword: 'NewPassword123');

      // 6. Account Activation
      final activationRes = await repo.activateAccount(
        collegeCode: 'COL1',
        instituteId: 'STUD101',
        activationCode: 'ACT1234',
        password: 'Password123',
      );
      expect(activationRes['user'], isNotNull);

      // 7. Change Password
      await repo.changePassword(currentPassword: 'acadex123', newPassword: 'NewPassword123');

      // 8. Logout
      await repo.logout();
    });
  });
}
