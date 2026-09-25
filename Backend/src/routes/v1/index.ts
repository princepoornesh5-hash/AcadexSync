import { Router } from 'express';
import { healthRouter } from '../health.routes';
import { authRouter } from './auth.routes';
import { collegeRouter } from './college.routes';
import { departmentRouter } from './department.routes';
import { academicRouter } from './academic.routes';
import { userRouter } from './user.routes';
import { timetableRouter } from './timetable.routes';
import { attendanceRouter } from './attendance.routes';
import { noteRouter } from './note.routes';
import { notificationRouter } from './notification.routes';
import { auditRouter } from './audit.routes';
import { reportRouter } from './report.routes';
import { analyticsRouter } from './analytics.routes';
import { calendarOverrideRouter } from './calendarOverride.routes';
import { teacherSubstitutionRouter } from './teacherSubstitution.routes';
import { announcementRouter } from './announcement.routes';

const router = Router();

// Public Health endpoint at /api/v1/health
router.use('/health', healthRouter);

// Versioned feature routes
router.use('/auth', authRouter);
router.use('/colleges', collegeRouter);
router.use('/departments', departmentRouter);
router.use('/academics', academicRouter);
router.use('/users', userRouter);
router.use('/timetables', timetableRouter);
router.use('/calendar-overrides', calendarOverrideRouter);
router.use('/teacher-substitutions', teacherSubstitutionRouter);
router.use('/attendance', attendanceRouter);
router.use('/notes', noteRouter);
router.use('/notifications', notificationRouter);
router.use('/announcements', announcementRouter);
router.use('/audit', auditRouter);
router.use('/reports', reportRouter);
router.use('/analytics', analyticsRouter);

export const v1Router = router;
