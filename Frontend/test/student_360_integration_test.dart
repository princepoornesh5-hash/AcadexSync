import 'package:flutter_test/flutter_test.dart';
import 'package:campus_management/features/academic_structure/domain/models/academic_models.dart';

void main() {
  group('Student 360 Integration Tests — Domain & Model Serialization', () {
    test('1. StudentAcademicProfile parses full authoritative Student 360 payload', () {
      final json = {
        'student': {
          'id': 'stud_123',
          'collegeId': 'col_1',
          'name': 'Aarav Sharma',
          'rollNumber': 'CS2026-001',
          'email': 'aarav@acadex.edu',
          'phone': '9876543210',
          'status': 'active',
        },
        'enrollment': {
          'id': 'enr_1',
          'status': 'active',
          'program': 'B.Tech CSE',
          'semester': '6',
          'section': 'A',
          'batch': '2023-2027',
          'academicYear': '2025-2026',
        },
        'attendanceMetrics': {
          'totalSessions': 100,
          'attendedSessions': 85,
          'attendancePercentage': 85.0,
          'hasDetailedAttendance': true,
          'hasPercentageOnlyAttendance': true,
        },
        'historicalPercentageMetrics': [
          {
            'term': 'Semester 1',
            'academicYear': '2023-2024',
            'percentage': 88.5,
            'sourceType': 'HISTORICAL_SUMMARY',
            'isCountBased': false,
          }
        ],
        'assessments': [
          {
            'id': 'mark_1',
            'assessmentId': 'asmt_1',
            'title': 'Mid-Term Exam',
            'category': 'MIDTERM',
            'subjectName': 'Computer Networks',
            'marksObtained': 42.5,
            'maximumMarks': 50.0,
            'status': 'ENTERED',
            'isPassed': true,
            'sourceType': 'LIVE',
          },
          {
            'id': 'mark_2',
            'assessmentId': 'asmt_2',
            'title': 'Unit Test 1',
            'category': 'TEST',
            'subjectName': 'Operating Systems',
            'marksObtained': null,
            'maximumMarks': 25.0,
            'status': 'ABSENT',
            'isPassed': false,
            'sourceType': 'IMPORTED',
            'importBatchId': 'batch_99',
          },
          {
            'id': 'mark_3',
            'assessmentId': 'asmt_3',
            'title': 'Lab Practical',
            'category': 'LAB',
            'subjectName': 'Algorithms Lab',
            'marksObtained': null,
            'maximumMarks': 30.0,
            'status': 'EXEMPTED',
            'isPassed': null,
            'sourceType': 'LIVE',
          }
        ],
        'assignments': [
          {
            'id': 'asg_1',
            'title': 'Network Topologies Design',
            'status': 'PUBLISHED',
            'dueDate': '2026-04-10',
            'maximumMarks': 20,
            'isSubmitted': true,
            'marks': 19,
          }
        ],
        'subjectsWithFaculty': [
          {
            'id': 'sub_1',
            'code': 'CS301',
            'name': 'Computer Networks',
            'credits': 4,
            'type': 'Theory',
            'faculty': {
              'id': 'fac_1',
              'name': 'Dr. Rao',
              'email': 'rao@acadex.edu',
              'designation': 'Associate Professor',
            }
          }
        ],
        'notesCount': 12,
        'contactRequests': [
          {
            'id': 'req_1',
            'requestedPhone': '9876543211',
            'reason': 'Change of contact number',
            'status': 'PENDING',
          }
        ],
        'academicRecords': [
          {
            'recordType': 'GradeSheet',
            'details': 'Semester 5 Official Grade Sheet Registry Entry',
          }
        ],
        'officialResults': [
          {
            'semester': 'Semester 5',
            'sgpa': '8.75',
            'resultStatus': 'PUBLISHED',
          }
        ],
        'timelineEvents': [
          {
            'action': 'PROMOTED',
            'description': 'Promoted to Semester 6',
            'timestamp': '2026-01-10T10:00:00Z',
          }
        ],
        'enrollmentHistory': [
          {
            'status': 'active',
            'semesterId': {'number': 6},
            'sectionId': {'name': 'A'},
            'academicYearId': {'name': '2025-2026'},
          }
        ]
      };

      final profile = StudentAcademicProfile.fromJson(json);

      expect(profile.student.id, 'stud_123');
      expect(profile.student.name, 'Aarav Sharma');

      // Attendance precision
      expect(profile.overallAttendancePercentage, 85.0);
      expect(profile.hasDetailedAttendance, isTrue);
      expect(profile.hasPercentageOnlyAttendance, isTrue);
      expect(profile.historicalPercentageMetrics.length, 1);
      expect(profile.historicalPercentageMetrics.first['percentage'], 88.5);

      // Assessments
      expect(profile.assessments.length, 3);
      expect(profile.assessments[0]['status'], 'ENTERED');
      expect(profile.assessments[0]['marksObtained'], 42.5);
      expect(profile.assessments[0]['isPassed'], isTrue);

      expect(profile.assessments[1]['status'], 'ABSENT');
      expect(profile.assessments[1]['marksObtained'], isNull);
      expect(profile.assessments[1]['sourceType'], 'IMPORTED');
      expect(profile.assessments[1]['importBatchId'], 'batch_99');

      expect(profile.assessments[2]['status'], 'EXEMPTED');
      expect(profile.assessments[2]['marksObtained'], isNull);

      // Assignments & Subjects
      expect(profile.assignments.length, 1);
      expect(profile.assignments.first['marks'], 19);
      expect(profile.subjectsWithFaculty.length, 1);
      expect(profile.subjectsWithFaculty.first['faculty']['name'], 'Dr. Rao');

      // Notes, Requests, Records, Timeline
      expect(profile.notesCount, 12);
      expect(profile.contactRequests.length, 1);
      expect(profile.academicRecords.length, 1);
      expect(profile.officialResults.length, 1);
      expect(profile.officialResults.first['sgpa'], '8.75');
      expect(profile.timelineEvents.length, 1);
      expect(profile.enrollmentHistory.length, 1);
    });

    test('2. StudentAcademicProfile handles minimal empty payload gracefully', () {
      final json = {
        'student': {
          'id': 'stud_minimal',
          'collegeId': 'col_1',
          'name': 'New Student',
          'rollNumber': 'CS-000',
          'email': 'new@acadex.edu',
        },
      };

      final profile = StudentAcademicProfile.fromJson(json);

      expect(profile.student.id, 'stud_minimal');
      expect(profile.overallAttendancePercentage, 0.0);
      expect(profile.hasDetailedAttendance, isFalse);
      expect(profile.hasPercentageOnlyAttendance, isFalse);
      expect(profile.historicalPercentageMetrics, isEmpty);
      expect(profile.assessments, isEmpty);
      expect(profile.assignments, isEmpty);
      expect(profile.subjectsWithFaculty, isEmpty);
      expect(profile.notesCount, 0);
      expect(profile.contactRequests, isEmpty);
      expect(profile.academicRecords, isEmpty);
      expect(profile.officialResults, isEmpty);
      expect(profile.timelineEvents, isEmpty);
      expect(profile.enrollmentHistory, isEmpty);
    });
  });
}
