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
router.use('/attendance', attendanceRouter);
router.use('/notes', noteRouter);
router.use('/notifications', notificationRouter);
router.use('/audit', auditRouter);
router.use('/reports', reportRouter);

export const v1Router = router;
