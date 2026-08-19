import os
import re

def main():
    # 1. attendance_workflow_test.dart
    f = 'test/attendance_workflow_test.dart'
    if os.path.exists(f):
        with open(f, 'r') as file:
            content = file.read()
        content = content.replace('FirebaseAttendanceRepository(fakeFirestore)', 'FirebaseAttendanceRepository(fakeFirestore, null)')
        content = content.replace("AttendanceSession(\n        id: 'sec1_sub1_20260812',", "AttendanceSession(\n        id: 'sec1_sub1_20260812',\n        collegeId: 'col-1',\n        departmentId: 'dept-1',")
        with open(f, 'w') as file:
            file.write(content)

    # 2. faculty_management_test.dart
    f = 'test/faculty_management_test.dart'
    if os.path.exists(f):
        with open(f, 'r') as file:
            content = file.read()
        content = content.replace("id: 'f1',\n        departmentId: 'dept-1',", "id: 'f1',\n        collegeId: 'col-1',\n        departmentId: 'dept-1',")
        content = content.replace("id: 'f2',\n        departmentId: 'dept-1',", "id: 'f2',\n        collegeId: 'col-2',\n        departmentId: 'dept-1',")
        content = content.replace("id: 'f3',\n        departmentId: 'dept-2',", "id: 'f3',\n        collegeId: 'col-1',\n        departmentId: 'dept-2',")
        with open(f, 'w') as file:
            file.write(content)

    # 3. firebase_academic_repository_test.dart
    f = 'test/firebase_academic_repository_test.dart'
    if os.path.exists(f):
        with open(f, 'r') as file:
            content = file.read()
        content = content.replace("Course(\n          id: 'course-1',", "Course(\n          id: 'course-1',\n          collegeId: 'col-1',")
        with open(f, 'w') as file:
            file.write(content)

    # 4. pilot_validation_test.dart
    f = 'test/pilot_validation_test.dart'
    if os.path.exists(f):
        with open(f, 'r') as file:
            content = file.read()
        content = content.replace("AcademicYear(\n        id: 'ay-2026',", "AcademicYear(\n        id: 'ay-2026',\n        collegeId: 'col-1',")
        content = content.replace("Semester(\n        id: 'sem-5',", "Semester(\n        id: 'sem-5',\n        collegeId: 'col-1',\n        departmentId: 'dept-cs',")
        content = content.replace("Section(\n        id: 'sec-5a',", "Section(\n        id: 'sec-5a',\n        collegeId: 'col-1',\n        departmentId: 'dept-cs',")
        content = content.replace("Subject(\n        id: 'sub-java',", "Subject(\n        id: 'sub-java',\n        collegeId: 'col-1',\n        departmentId: 'dept-cs',")
        content = content.replace("AttendanceSession(\n        id: 'session-1',", "AttendanceSession(\n        id: 'session-1',\n        collegeId: 'col-1',\n        departmentId: 'dept-cs',")
        
        content = content.replace("AcademicYear(id: 'ay-2026',", "AcademicYear(id: 'ay-2026', collegeId: 'col-1',")
        content = content.replace("Semester(id: 'sem-5',", "Semester(id: 'sem-5', collegeId: 'col-1', departmentId: 'dept-cs',")
        content = content.replace("Section(id: 'sec-5a',", "Section(id: 'sec-5a', collegeId: 'col-1', departmentId: 'dept-cs',")
        content = content.replace("Subject(id: 'sub-java',", "Subject(id: 'sub-java', collegeId: 'col-1', departmentId: 'dept-cs',")
        content = content.replace("AttendanceSession(id: 'session-1',", "AttendanceSession(id: 'session-1', collegeId: 'col-1', departmentId: 'dept-cs',")
        
        with open(f, 'w') as file:
            file.write(content)
            
    print("Test fixes applied.")

if __name__ == '__main__':
    main()
