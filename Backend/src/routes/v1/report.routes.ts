import { Router } from 'express';
import { ReportController } from '../../controllers/report.controller';
import { authenticateToken } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateQuery } from '../../middleware/validate.middleware';
import { dateRangeQuerySchema } from '../../validations/report.validation';
import { requireCollegeAdmin, requireHodOrAbove, requireFacultyOrAbove } from '../../middleware/role.middleware';
import { reportRateLimiter } from '../../middleware/rateLimiter.middleware';
import { asyncHandler } from '../../utils/asyncHandler';

const router = Router();

router.use(authenticateToken);
router.use(requireCollegeScope);
router.use(reportRateLimiter);

// 1. Role-Aware Dashboard
router.get(
  '/dashboard',
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getDashboard)
);

// 2. Attendance Reports
// Student Identity-derived endpoint
router.get(
  '/attendance/me',
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getMyAttendanceReport)
);

// Student Attendance by ID (Admin / Faculty / HOD or Student self)
router.get(
  '/attendance/student/:studentId',
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getStudentAttendanceReport)
);

// Section Attendance (Faculty, HOD, College Admin, Super Admin)
router.get(
  '/attendance/section/:sectionId',
  requireFacultyOrAbove,
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getSectionAttendanceReport)
);

// Department Attendance (HOD, College Admin, Super Admin)
router.get(
  '/attendance/department/:departmentId',
  requireHodOrAbove,
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getDepartmentAttendanceReport)
);

// College Attendance (College Admin, Super Admin)
router.get(
  '/attendance/college/:collegeId',
  requireCollegeAdmin,
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getCollegeAttendanceReport)
);

// Subject Attendance (Faculty, HOD, College Admin, Super Admin)
router.get(
  '/attendance/subject/:subjectId',
  requireFacultyOrAbove,
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getSubjectAttendanceReport)
);

// 3. Faculty Activity Report
router.get(
  '/faculty/:facultyId',
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getFacultyReport)
);

// 4. Academic Hierarchy & Capacity Utilization Report
router.get(
  '/academic',
  requireHodOrAbove,
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getAcademicReport)
);

// 5. Notes / Content Metrics Report
router.get(
  '/notes',
  validateQuery(dateRangeQuerySchema),
  asyncHandler(ReportController.getNotesReport)
);

export const reportRouter = router;
