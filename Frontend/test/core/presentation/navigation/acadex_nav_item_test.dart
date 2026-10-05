import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/core/presentation/navigation/acadex_nav_item.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';

void main() {
  group('Role-Based Navigation Configuration', () {
    test('Super Admin should NOT have access to operational modules', () {
      final superAdminNav = AcadexNavigationService.getGroupedNavItems(AppRole.superAdmin);
      final allItems = superAdminNav.values.expand((items) => items).toList();
      
      final calendarItem = allItems.where((item) => item.label == 'Calendar' || item.route.startsWith('/calendar'));
      final timetableItem = allItems.where((item) => item.label == 'Timetable' || item.route.startsWith('/timetable'));
      final assignmentsItem = allItems.where((item) => item.label == 'Assignments' || item.route.startsWith('/assignments'));
      final requestsItem = allItems.where((item) => item.label == 'Request Center' || item.route.startsWith('/requests'));
      final attendanceItem = allItems.where((item) => item.label == 'Attendance' || item.route.startsWith('/attendance'));
      
      expect(calendarItem.isEmpty, true, reason: 'Super Admin should not have Calendar');
      expect(timetableItem.isEmpty, true, reason: 'Super Admin should not have Timetable');
      expect(assignmentsItem.isEmpty, true, reason: 'Super Admin should not have Assignments');
      expect(requestsItem.isEmpty, true, reason: 'Super Admin should not have Request Center');
      expect(attendanceItem.isEmpty, true, reason: 'Super Admin should not have Attendance');
    });

    test('Student should have access to relevant academic modules', () {
      final studentNav = AcadexNavigationService.getGroupedNavItems(AppRole.student);
      final allItems = studentNav.values.expand((items) => items).toList();
      
      final hasCalendar = allItems.any((item) => item.route.startsWith('/calendar'));
      final hasTimetable = allItems.any((item) => item.route.startsWith('/timetable'));
      final hasAssignments = allItems.any((item) => item.route.startsWith('/assignments') || item.route == '/my-assignments');
      
      expect(hasCalendar, true, reason: 'Student should have Calendar');
      expect(hasTimetable, true, reason: 'Student should have Timetable');
      expect(hasAssignments, true, reason: 'Student should have Assignments');
    });

    test('Faculty should have access to relevant academic modules', () {
      final facultyNav = AcadexNavigationService.getGroupedNavItems(AppRole.faculty);
      final allItems = facultyNav.values.expand((items) => items).toList();
      
      final hasTimetable = allItems.any((item) => item.route.startsWith('/timetable'));
      final hasAssignments = allItems.any((item) => item.route.startsWith('/assignments') || item.route == '/faculty-assignments');
      final hasCalendar = allItems.any((item) => item.route.startsWith('/calendar'));
      
      expect(hasTimetable, true, reason: 'Faculty should have Timetable');
      expect(hasAssignments, true, reason: 'Faculty should have Assignments');
      expect(hasCalendar, true, reason: 'Faculty should have Calendar');
    });

    test('HOD and College Admin retain their operational modules', () {
      final hodNav = AcadexNavigationService.getGroupedNavItems(AppRole.hod);
      final hodItems = hodNav.values.expand((items) => items).toList();
      expect(hodItems.any((item) => item.route.startsWith('/timetable')), true);
      
      final adminNav = AcadexNavigationService.getGroupedNavItems(AppRole.collegeAdmin);
      final adminItems = adminNav.values.expand((items) => items).toList();
      expect(adminItems.any((item) => item.route.startsWith('/academics')), true);
    });
  });
}
