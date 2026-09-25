import mongoose from 'mongoose';
import { User } from '../models/user.model';
import { Faculty } from '../models/faculty.model';
import { Student } from '../models/student.model';
import { Department } from '../models/department.model';
import { Course } from '../models/course.model';
import { Semester } from '../models/semester.model';
import { Section } from '../models/section.model';
import { Subject } from '../models/subject.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { Timetable } from '../models/timetable.model';
import { AuditLog } from '../models/auditLog.model';
import { AppRole } from '../constants/roles';
import { AccountStatus, TimetableStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

export interface IntegrityAuditResult {
  timestamp: string;
  collegeId: string;
  counts: {
    activeHods: number;
    activeFaculty: number;
    activeStudents: number;
    activeFacultyAssignments: number;
    activeStudentEnrollments: number;
    activeCourses: number;
    activeSemesters: number;
    activeSections: number;
    activeSubjects: number;
    activeTimetables: number;
    activeTimetableEntries: number;
  };
  orphans: {
    facultyAssignmentsWithoutFaculty: Array<{ assignmentId: string; missingFacultyId: string }>;
    studentEnrollmentsWithoutStudent: Array<{ enrollmentId: string; missingStudentId: string }>;
    timetableEntriesWithoutFacultyAssignment: Array<{ timetableId: string; entryId: string; missingAssignmentId: string }>;
    timetableEntriesWithoutFaculty: Array<{ timetableId: string; entryId: string; missingFacultyId: string }>;
    subjectsWithoutSemester: Array<{ subjectId: string; missingSemesterId: string }>;
    sectionsWithoutSemester: Array<{ sectionId: string; missingSemesterId: string }>;
    semestersWithoutCourse: Array<{ semesterId: string; missingCourseId: string }>;
    coursesWithoutDepartment: Array<{ courseId: string; missingDepartmentId: string }>;
    departmentsWithInvalidHod: Array<{ departmentId: string; invalidHodId: string; reason: string }>;
  };
  totalOrphansDetected: number;
  status: 'HEALTHY' | 'ORPHANS_DETECTED';
}

export class IntegrityService {
  /**
   * Run Forensic Data Integrity Audit across all academic relationships
   */
  static async runForensicAudit(
    requester: AuthenticatedUser,
    targetCollegeId?: string
  ): Promise<IntegrityAuditResult> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators have permission to run integrity audits');
    }

    let effectiveCollegeId: string | undefined;
    if (requester.role === AppRole.COLLEGE_ADMIN) {
      effectiveCollegeId = requester.collegeId;
      if (!effectiveCollegeId) {
        throw ApiError.forbidden('College admin must be associated with a valid college');
      }
    } else {
      effectiveCollegeId = targetCollegeId;
    }

    const collegeQuery = effectiveCollegeId && mongoose.Types.ObjectId.isValid(effectiveCollegeId)
      ? { collegeId: new mongoose.Types.ObjectId(effectiveCollegeId) }
      : {};

    // 1. Calculate Active Entity Counts
    const [
      activeHods,
      activeFaculty,
      activeStudents,
      activeFacultyAssignments,
      activeStudentEnrollments,
      activeCourses,
      activeSemesters,
      activeSections,
      activeSubjects,
      activeTimetables,
      publishedTimetables,
    ] = await Promise.all([
      User.countDocuments({ role: AppRole.HOD, accountStatus: AccountStatus.ACTIVE, ...collegeQuery }),
      Faculty.countDocuments({ isActive: true, status: 'active', ...collegeQuery }),
      Student.countDocuments({
        ...collegeQuery,
        $or: [{ accountStatus: AccountStatus.ACTIVE }, { lifecycleState: 'active' }],
      }),
      FacultyAssignment.countDocuments({ isActive: true, ...collegeQuery }),
      StudentEnrollment.countDocuments({ status: 'ACTIVE', ...collegeQuery }),
      Course.countDocuments({ isActive: true, ...collegeQuery }),
      Semester.countDocuments({ isActive: true, ...collegeQuery }),
      Section.countDocuments({ isActive: true, ...collegeQuery }),
      Subject.countDocuments({ isActive: true, ...collegeQuery }),
      Timetable.countDocuments({ status: TimetableStatus.PUBLISHED, ...collegeQuery }),
      Timetable.find({ status: TimetableStatus.PUBLISHED, ...collegeQuery }).select('entries'),
    ]);

    const activeTimetableEntries = publishedTimetables.reduce(
      (acc, t) => acc + (t.entries ? t.entries.length : 0),
      0
    );

    // 2. Scan for Orphaned Relationships

    // A. FacultyAssignment -> nonexistent Faculty
    const assignments = await FacultyAssignment.find(collegeQuery).select('_id facultyId');
    const assignmentFacultyIds = Array.from(new Set(assignments.map((a) => a.facultyId?.toString()).filter(Boolean)));
    const existingFaculty = await Faculty.find({ _id: { $in: assignmentFacultyIds } }).select('_id');
    const existingFacultySet = new Set(existingFaculty.map((f) => f._id.toString()));

    const facultyAssignmentsWithoutFaculty: Array<{ assignmentId: string; missingFacultyId: string }> = [];
    for (const a of assignments) {
      if (a.facultyId && !existingFacultySet.has(a.facultyId.toString())) {
        facultyAssignmentsWithoutFaculty.push({
          assignmentId: a._id.toString(),
          missingFacultyId: a.facultyId.toString(),
        });
      }
    }

    // B. StudentEnrollment -> nonexistent Student
    const enrollments = await StudentEnrollment.find(collegeQuery).select('_id studentId');
    const enrollmentStudentIds = Array.from(new Set(enrollments.map((e) => e.studentId?.toString()).filter(Boolean)));
    const existingStudents = await Student.find({ _id: { $in: enrollmentStudentIds } }).select('_id');
    const existingStudentSet = new Set(existingStudents.map((s) => s._id.toString()));

    const studentEnrollmentsWithoutStudent: Array<{ enrollmentId: string; missingStudentId: string }> = [];
    for (const e of enrollments) {
      if (e.studentId && !existingStudentSet.has(e.studentId.toString())) {
        studentEnrollmentsWithoutStudent.push({
          enrollmentId: e._id.toString(),
          missingStudentId: e.studentId.toString(),
        });
      }
    }

    // C. TimetableEntry -> nonexistent FacultyAssignment or Faculty
    const allTimetables = await Timetable.find(collegeQuery).select('_id entries');
    const timetableEntriesWithoutFacultyAssignment: Array<{ timetableId: string; entryId: string; missingAssignmentId: string }> = [];
    const timetableEntriesWithoutFaculty: Array<{ timetableId: string; entryId: string; missingFacultyId: string }> = [];

    const ttAssignmentIds: string[] = [];
    const ttFacultyIds: string[] = [];
    for (const t of allTimetables) {
      for (const entry of t.entries || []) {
        if (entry.facultyAssignmentId) ttAssignmentIds.push(entry.facultyAssignmentId.toString());
        if (entry.facultyId) ttFacultyIds.push(entry.facultyId.toString());
      }
    }

    const [validAssignments, validFacultyForTt] = await Promise.all([
      FacultyAssignment.find({ _id: { $in: ttAssignmentIds } }).select('_id'),
      Faculty.find({ _id: { $in: ttFacultyIds } }).select('_id'),
    ]);
    const validAssignmentSet = new Set(validAssignments.map((a) => a._id.toString()));
    const validFacultyForTtSet = new Set(validFacultyForTt.map((f) => f._id.toString()));

    for (const t of allTimetables) {
      for (const entry of t.entries || []) {
        const entryId = entry._id ? entry._id.toString() : 'unknown';
        if (entry.facultyAssignmentId && !validAssignmentSet.has(entry.facultyAssignmentId.toString())) {
          timetableEntriesWithoutFacultyAssignment.push({
            timetableId: t._id.toString(),
            entryId,
            missingAssignmentId: entry.facultyAssignmentId.toString(),
          });
        }
        if (entry.facultyId && !validFacultyForTtSet.has(entry.facultyId.toString())) {
          timetableEntriesWithoutFaculty.push({
            timetableId: t._id.toString(),
            entryId,
            missingFacultyId: entry.facultyId.toString(),
          });
        }
      }
    }

    // D. Subject -> nonexistent Semester
    const subjects = await Subject.find(collegeQuery).select('_id semesterId');
    const subjectSemIds = Array.from(new Set(subjects.map((s) => s.semesterId?.toString()).filter(Boolean)));
    const validSemesters = await Semester.find({ _id: { $in: subjectSemIds } }).select('_id');
    const validSemesterSet = new Set(validSemesters.map((s) => s._id.toString()));

    const subjectsWithoutSemester: Array<{ subjectId: string; missingSemesterId: string }> = [];
    for (const s of subjects) {
      if (s.semesterId && !validSemesterSet.has(s.semesterId.toString())) {
        subjectsWithoutSemester.push({
          subjectId: s._id.toString(),
          missingSemesterId: s.semesterId.toString(),
        });
      }
    }

    // E. Section -> nonexistent Semester
    const sections = await Section.find(collegeQuery).select('_id semesterId');
    const sectionSemIds = Array.from(new Set(sections.map((s) => s.semesterId?.toString()).filter(Boolean)));
    const validSemestersForSections = await Semester.find({ _id: { $in: sectionSemIds } }).select('_id');
    const validSemestersForSectionSet = new Set(validSemestersForSections.map((s) => s._id.toString()));

    const sectionsWithoutSemester: Array<{ sectionId: string; missingSemesterId: string }> = [];
    for (const sec of sections) {
      if (sec.semesterId && !validSemestersForSectionSet.has(sec.semesterId.toString())) {
        sectionsWithoutSemester.push({
          sectionId: sec._id.toString(),
          missingSemesterId: sec.semesterId.toString(),
        });
      }
    }

    // F. Semester -> nonexistent Course
    const semesters = await Semester.find(collegeQuery).select('_id courseId');
    const semCourseIds = Array.from(new Set(semesters.map((s) => s.courseId?.toString()).filter(Boolean)));
    const validCourses = await Course.find({ _id: { $in: semCourseIds } }).select('_id');
    const validCourseSet = new Set(validCourses.map((c) => c._id.toString()));

    const semestersWithoutCourse: Array<{ semesterId: string; missingCourseId: string }> = [];
    for (const sem of semesters) {
      if (sem.courseId && !validCourseSet.has(sem.courseId.toString())) {
        semestersWithoutCourse.push({
          semesterId: sem._id.toString(),
          missingCourseId: sem.courseId.toString(),
        });
      }
    }

    // G. Course -> nonexistent Department
    const courses = await Course.find(collegeQuery).select('_id departmentId');
    const courseDeptIds = Array.from(new Set(courses.map((c) => c.departmentId?.toString()).filter(Boolean)));
    const validDepartments = await Department.find({ _id: { $in: courseDeptIds } }).select('_id');
    const validDepartmentSet = new Set(validDepartments.map((d) => d._id.toString()));

    const coursesWithoutDepartment: Array<{ courseId: string; missingDepartmentId: string }> = [];
    for (const c of courses) {
      if (c.departmentId && !validDepartmentSet.has(c.departmentId.toString())) {
        coursesWithoutDepartment.push({
          courseId: c._id.toString(),
          missingDepartmentId: c.departmentId.toString(),
        });
      }
    }

    // H. Department -> nonexistent or invalid HOD
    const departments = await Department.find(collegeQuery).select('_id hodId');
    const deptHodIds = Array.from(new Set(departments.map((d) => d.hodId?.toString()).filter(Boolean)));
    const validHodUsers = await User.find({ _id: { $in: deptHodIds } }).select('_id role accountStatus');
    const hodUserMap = new Map(validHodUsers.map((u) => [u._id.toString(), u]));

    const departmentsWithInvalidHod: Array<{ departmentId: string; invalidHodId: string; reason: string }> = [];
    for (const d of departments) {
      if (d.hodId) {
        const hodUser = hodUserMap.get(d.hodId.toString());
        if (!hodUser) {
          departmentsWithInvalidHod.push({
            departmentId: d._id.toString(),
            invalidHodId: d.hodId.toString(),
            reason: 'Referenced HOD user does not exist in database',
          });
        } else if (hodUser.role !== AppRole.HOD) {
          departmentsWithInvalidHod.push({
            departmentId: d._id.toString(),
            invalidHodId: d.hodId.toString(),
            reason: `User has role "${hodUser.role}" instead of HOD`,
          });
        }
      }
    }

    const totalOrphansDetected =
      facultyAssignmentsWithoutFaculty.length +
      studentEnrollmentsWithoutStudent.length +
      timetableEntriesWithoutFacultyAssignment.length +
      timetableEntriesWithoutFaculty.length +
      subjectsWithoutSemester.length +
      sectionsWithoutSemester.length +
      semestersWithoutCourse.length +
      coursesWithoutDepartment.length +
      departmentsWithInvalidHod.length;

    return {
      timestamp: new Date().toISOString(),
      collegeId: effectiveCollegeId || 'GLOBAL',
      counts: {
        activeHods,
        activeFaculty,
        activeStudents,
        activeFacultyAssignments,
        activeStudentEnrollments,
        activeCourses,
        activeSemesters,
        activeSections,
        activeSubjects,
        activeTimetables,
        activeTimetableEntries,
      },
      orphans: {
        facultyAssignmentsWithoutFaculty,
        studentEnrollmentsWithoutStudent,
        timetableEntriesWithoutFacultyAssignment,
        timetableEntriesWithoutFaculty,
        subjectsWithoutSemester,
        sectionsWithoutSemester,
        semestersWithoutCourse,
        coursesWithoutDepartment,
        departmentsWithInvalidHod,
      },
      totalOrphansDetected,
      status: totalOrphansDetected === 0 ? 'HEALTHY' : 'ORPHANS_DETECTED',
    };
  }

  /**
   * Safely repair detected orphans without destroying historical data
   */
  static async repairOrphans(
    requester: AuthenticatedUser,
    targetCollegeId?: string
  ): Promise<{ repairedCount: number; details: string[] }> {
    if (requester.role !== AppRole.SUPER_ADMIN) {
      throw ApiError.forbidden('Only Super Admin can initiate orphan repairs');
    }

    const audit = await this.runForensicAudit(requester, targetCollegeId);
    let repairedCount = 0;
    const details: string[] = [];

    // 1. Deactivate FacultyAssignments without faculty
    if (audit.orphans.facultyAssignmentsWithoutFaculty.length > 0) {
      const ids = audit.orphans.facultyAssignmentsWithoutFaculty.map((a) => a.assignmentId);
      await FacultyAssignment.updateMany(
        { _id: { $in: ids } },
        { isActive: false }
      );
      repairedCount += ids.length;
      details.push(`Deactivated ${ids.length} orphaned FacultyAssignments`);
    }

    // 2. Remove timetable entries without faculty
    if (audit.orphans.timetableEntriesWithoutFaculty.length > 0) {
      const missingFacultyIds = audit.orphans.timetableEntriesWithoutFaculty.map((e) => new mongoose.Types.ObjectId(e.missingFacultyId));
      await Timetable.updateMany(
        {},
        { $pull: { entries: { facultyId: { $in: missingFacultyIds } } } }
      );
      repairedCount += audit.orphans.timetableEntriesWithoutFaculty.length;
      details.push(`Removed ${audit.orphans.timetableEntriesWithoutFaculty.length} invalid entries from timetables`);
    }

    // 3. Clear invalid HOD pointers from departments
    if (audit.orphans.departmentsWithInvalidHod.length > 0) {
      const deptIds = audit.orphans.departmentsWithInvalidHod.map((d) => d.departmentId);
      await Department.updateMany(
        { _id: { $in: deptIds } },
        { hodId: null }
      );
      repairedCount += deptIds.length;
      details.push(`Cleared ${deptIds.length} invalid HOD references on departments`);
    }

    // 4. Deactivate orphaned subjects without semester
    if (audit.orphans.subjectsWithoutSemester.length > 0) {
      const subjectIds = audit.orphans.subjectsWithoutSemester.map((s) => s.subjectId);
      await Subject.updateMany(
        { _id: { $in: subjectIds } },
        { isActive: false }
      );
      repairedCount += subjectIds.length;
      details.push(`Deactivated ${subjectIds.length} orphaned subjects without active semesters`);
    }

    // 5. Deactivate orphaned sections without semester
    if (audit.orphans.sectionsWithoutSemester.length > 0) {
      const sectionIds = audit.orphans.sectionsWithoutSemester.map((s) => s.sectionId);
      await Section.updateMany(
        { _id: { $in: sectionIds } },
        { isActive: false }
      );
      repairedCount += sectionIds.length;
      details.push(`Deactivated ${sectionIds.length} orphaned sections without active semesters`);
    }

    await AuditLog.create({
      collegeId: targetCollegeId || 'GLOBAL',
      actorUserId: requester.id,
      action: 'ORPHANS_REPAIRED',
      entityType: 'SystemIntegrity',
      entityId: 'ORPHAN_REPAIR_RUN',
      newValue: { repairedCount, details },
    });

    return { repairedCount, details };
  }
}
