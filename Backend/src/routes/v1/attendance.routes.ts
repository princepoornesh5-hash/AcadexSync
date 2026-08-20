import { Router } from 'express';
import { AttendanceController } from '../../controllers/attendance.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import {
  requireFacultyOrAbove,
  requireHodOrAbove,
} from '../../middleware/role.middleware';

const router = Router();

router.use(authenticateRequest);

// Student Personal Attendance Views
router.get('/students/me', AttendanceController.getStudentHistory);
router.get('/students/me/subjects', AttendanceController.getStudentSubjects);
router.get('/students/me/summary', AttendanceController.getStudentSummary);

// Section & Faculty Attendance Views
router.get('/sections/:sectionId', AttendanceController.getSectionAttendance);
router.get('/faculty/me', AttendanceController.getFacultySessions);

// Attendance Analytics Engine
router.get('/analytics', AttendanceController.getAnalytics);

// Attendance Corrections
router.patch('/records/:id/correct', requireHodOrAbove, AttendanceController.correctRecord);

// Attendance Sessions CRUD & Lifecycle
router.post('/sessions', requireFacultyOrAbove, AttendanceController.createSession);
router.get('/sessions', AttendanceController.list);
router.get('/sessions/:id', AttendanceController.getById);
router.post('/sessions/:id/records', requireFacultyOrAbove, AttendanceController.submitRecords);
router.post('/sessions/:id/lock', requireFacultyOrAbove, AttendanceController.lockSession);
router.post('/sessions/:id/close', requireFacultyOrAbove, AttendanceController.closeSession);
router.post('/sessions/:id/cancel', requireHodOrAbove, AttendanceController.cancelSession);

// Backwards-Compatible Legacy Routes
router.post('/submit', requireFacultyOrAbove, AttendanceController.submit);
router.get('/student/:studentId/summary', AttendanceController.studentSummary);
router.get('/', AttendanceController.list);
router.get('/:id', AttendanceController.getById);

export const attendanceRouter = router;
