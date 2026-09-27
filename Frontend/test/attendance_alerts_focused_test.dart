import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/notifications/domain/models/notification_models.dart';
import 'package:campus_management/features/notifications/presentation/widgets/notification_card.dart';
import 'package:campus_management/features/institution_config/domain/models/institution_config_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  group('Prompt 22 — Attendance Alerts Domain & Model Tests', () {
    test('1. ATTENDANCE_ABSENT notification parses correctly with deep-link', () {
      final json = {
        'id': 'notif_abs_01',
        'title': 'Attendance Update',
        'body': 'You were marked absent for DBMS • Section A today.',
        'notificationType': 'ATTENDANCE_ABSENT',
        'category': 'attendance',
        'priority': 'normal',
        'isRead': false,
        'createdAt': '2026-09-27T10:00:00.000Z',
        'relatedEntityType': 'ATTENDANCE_SESSION',
        'relatedEntityId': 'sess_101',
        'metadata': {
          'sessionId': 'sess_101',
          'subjectId': 'sub_dbms_1',
          'subjectName': 'DBMS',
          'sectionName': 'Section A',
          'date': '2026-09-27',
          'attendanceStatus': 'ABSENT',
        },
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, 'notif_abs_01');
      expect(model.title, 'Attendance Update');
      expect(model.body, 'You were marked absent for DBMS • Section A today.');
      expect(model.notificationType, NotificationType.attendanceAbsent);
      expect(model.category, NotificationCategory.attendance);
      expect(model.priority, NotificationPriority.normal);
      expect(model.navigationTarget, '/attendance/student/subject/sub_dbms_1');
      expect(model.metadata?['subjectId'], 'sub_dbms_1');
    });

    test('2. ATTENDANCE_LOW warning notification parses correctly with percentage', () {
      final json = {
        'id': 'notif_warn_01',
        'title': 'Attendance Warning',
        'body': 'Your DBMS attendance is now 72.00%.',
        'notificationType': 'ATTENDANCE_LOW',
        'category': 'attendance',
        'priority': 'high',
        'isRead': false,
        'createdAt': '2026-09-27T10:00:00.000Z',
        'relatedEntityType': 'ATTENDANCE_SESSION',
        'relatedEntityId': 'sess_102',
        'metadata': {
          'sessionId': 'sess_102',
          'subjectId': 'sub_dbms_1',
          'subjectName': 'DBMS',
          'percentage': 72.0,
          'threshold': 75,
        },
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, 'notif_warn_01');
      expect(model.title, 'Attendance Warning');
      expect(model.body, 'Your DBMS attendance is now 72.00%.');
      expect(model.notificationType, NotificationType.attendanceLow);
      expect(model.priority, NotificationPriority.high);
      expect(model.navigationTarget, '/attendance/student/subject/sub_dbms_1');
      expect(model.metadata?['percentage'], 72.0);
    });

    test('3. ATTENDANCE_ALERT critical notification parses with critical priority', () {
      final json = {
        'id': 'notif_crit_01',
        'title': 'Attendance Alert',
        'body': 'Your DBMS attendance has fallen to 63.64%. Please review your attendance details.',
        'notificationType': 'ATTENDANCE_ALERT',
        'category': 'attendance',
        'priority': 'critical',
        'isRead': false,
        'createdAt': '2026-09-27T10:00:00.000Z',
        'relatedEntityType': 'ATTENDANCE_SESSION',
        'relatedEntityId': 'sess_103',
        'metadata': {
          'sessionId': 'sess_103',
          'subjectId': 'sub_dbms_1',
          'subjectName': 'DBMS',
          'percentage': 63.64,
          'criticalThreshold': 65,
        },
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, 'notif_crit_01');
      expect(model.title, 'Attendance Alert');
      expect(model.notificationType, NotificationType.attendanceAlert);
      expect(model.priority, NotificationPriority.critical);
      expect(model.navigationTarget, '/attendance/student/subject/sub_dbms_1');
    });

    test('4. AttendanceAlertsConfig model defaults and serialization', () {
      const config = AttendanceAlertsConfig();
      expect(config.enabled, isTrue);
      expect(config.warningPercentage, 75);
      expect(config.criticalPercentage, 65);
      expect(config.absenceAlertsEnabled, isTrue);

      final json = config.toJson();
      expect(json['enabled'], isTrue);
      expect(json['warningPercentage'], 75);
      expect(json['criticalPercentage'], 65);
      expect(json['absenceAlertsEnabled'], isTrue);

      final fromJson = AttendanceAlertsConfig.fromJson(json);
      expect(fromJson.enabled, isTrue);
      expect(fromJson.warningPercentage, 75);
      expect(fromJson.criticalPercentage, 65);
      expect(fromJson.absenceAlertsEnabled, isTrue);

      final modified = config.copyWith(warningPercentage: 80, criticalPercentage: 70);
      expect(modified.warningPercentage, 80);
      expect(modified.criticalPercentage, 70);
      expect(modified.enabled, isTrue);
    });

    test('5. InstitutionConfigModel includes AttendanceAlertsConfig correctly', () {
      final json = {
        'id': 'cfg_01',
        'collegeId': 'col_01',
        'institutionType': 'ENGINEERING',
        'attendanceAlerts': {
          'enabled': true,
          'warningPercentage': 78,
          'criticalPercentage': 68,
          'absenceAlertsEnabled': false,
        },
      };

      final model = InstitutionConfigModel.fromJson(json);
      expect(model.attendanceAlerts.enabled, isTrue);
      expect(model.attendanceAlerts.warningPercentage, 78);
      expect(model.attendanceAlerts.criticalPercentage, 68);
      expect(model.attendanceAlerts.absenceAlertsEnabled, isFalse);

      final serialized = model.toJson();
      expect(serialized['attendanceAlerts']['warningPercentage'], 78);
      expect(serialized['attendanceAlerts']['criticalPercentage'], 68);
      expect(serialized['attendanceAlerts']['absenceAlertsEnabled'], isFalse);
    });
  });

  group('Prompt 22 — Attendance Alerts UI Widget Tests', () {
    testWidgets('6. Absence notification card renders correctly with icon and copy', (tester) async {
      final notif = NotificationModel(
        id: 'abs_01',
        title: 'Attendance Update',
        message: 'You were marked absent for DBMS • Section A today.',
        notificationType: NotificationType.attendanceAbsent,
        category: NotificationCategory.attendance,
        priority: NotificationPriority.normal,
        audienceType: NotificationAudienceType.personal,
        timestamp: DateTime.now(),
        isRead: false,
        recipientUserId: 'student_1',
        recipientRole: AppRole.student,
        navigationTarget: '/attendance/student/subject/sub_dbms_1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: notif,
              onReadToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Attendance Update'), findsOneWidget);
      expect(find.text('You were marked absent for DBMS • Section A today.'), findsOneWidget);
      expect(find.byIcon(LucideIcons.userX), findsOneWidget);
    });

    testWidgets('7. Warning notification card renders correctly with percentage and warning icon', (tester) async {
      final notif = NotificationModel(
        id: 'warn_01',
        title: 'Attendance Warning',
        message: 'Your DBMS attendance is now 72.00%.',
        notificationType: NotificationType.attendanceLow,
        category: NotificationCategory.attendance,
        priority: NotificationPriority.high,
        audienceType: NotificationAudienceType.personal,
        timestamp: DateTime.now(),
        isRead: false,
        recipientUserId: 'student_1',
        recipientRole: AppRole.student,
        navigationTarget: '/attendance/student/subject/sub_dbms_1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: notif,
              onReadToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Attendance Warning'), findsOneWidget);
      expect(find.text('Your DBMS attendance is now 72.00%.'), findsOneWidget);
      expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);
    });

    testWidgets('8. Critical notification card renders correctly with shieldAlert icon', (tester) async {
      final notif = NotificationModel(
        id: 'crit_01',
        title: 'Attendance Alert',
        message: 'Your DBMS attendance has fallen to 63.64%. Please review your attendance details.',
        notificationType: NotificationType.attendanceAlert,
        category: NotificationCategory.attendance,
        priority: NotificationPriority.critical,
        audienceType: NotificationAudienceType.personal,
        timestamp: DateTime.now(),
        isRead: false,
        recipientUserId: 'student_1',
        recipientRole: AppRole.student,
        navigationTarget: '/attendance/student/subject/sub_dbms_1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: notif,
              onReadToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Attendance Alert'), findsOneWidget);
      expect(find.text('Your DBMS attendance has fallen to 63.64%. Please review your attendance details.'), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);
    });

    testWidgets('9. Disabled section concept does not leak into absence notification', (tester) async {
      final notif = NotificationModel(
        id: 'abs_no_sec',
        title: 'Attendance Update',
        message: 'You were marked absent for DBMS today.',
        notificationType: NotificationType.attendanceAbsent,
        category: NotificationCategory.attendance,
        priority: NotificationPriority.normal,
        audienceType: NotificationAudienceType.personal,
        timestamp: DateTime.now(),
        isRead: false,
        recipientUserId: 'student_1',
        recipientRole: AppRole.student,
        navigationTarget: '/attendance/student/subject/sub_dbms_1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: notif,
              onReadToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('You were marked absent for DBMS today.'), findsOneWidget);
      expect(find.textContaining('Section'), findsNothing);
    });

    testWidgets('10. Tapping attendance notification triggers read callback and has correct target', (tester) async {
      bool readToggled = false;

      final notif = NotificationModel(
        id: 'abs_tap_test',
        title: 'Attendance Update',
        message: 'You were marked absent for DBMS today.',
        notificationType: NotificationType.attendanceAbsent,
        category: NotificationCategory.attendance,
        priority: NotificationPriority.normal,
        audienceType: NotificationAudienceType.personal,
        timestamp: DateTime.now(),
        isRead: false,
        recipientUserId: 'student_1',
        recipientRole: AppRole.student,
        navigationTarget: '/attendance/student/subject/sub_dbms_1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationCard(
              notification: notif,
              onReadToggle: () {
                readToggled = true;
              },
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Attendance Update'));
      await tester.pumpAndSettle();

      expect(readToggled, isTrue);
      expect(notif.navigationTarget, '/attendance/student/subject/sub_dbms_1');
    });
  });
}
