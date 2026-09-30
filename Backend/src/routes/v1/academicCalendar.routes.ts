import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { requireRoles } from '../../middleware/role.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { AcademicCalendarController } from '../../controllers/academicCalendar.controller';
import { AppRole } from '../../constants/roles';
import {
  createCalendarEventSchema,
  updateCalendarEventSchema,
  createAcademicCalendarSchema,
  updateAcademicCalendarSchema,
  declareHolidaySchema,
} from '../../validations/calendarEvent.validation';

const router = Router();

// Multi-tenant and authentication boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// ── 1. WORKING DAY UTILITY (Must be before /:id) ─────────
router.get('/working-day', AcademicCalendarController.resolveWorkingDay);

// ── 2. ACADEMIC CALENDARS CRUD (Prompt 45) ───────────────
router.post(
  '/academic-calendars',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateBody(createAcademicCalendarSchema),
  AcademicCalendarController.createAcademicCalendar
);

router.get(
  '/academic-calendars',
  AcademicCalendarController.listAcademicCalendars
);

router.get(
  '/academic-calendars/:id',
  AcademicCalendarController.getAcademicCalendarById
);

router.put(
  '/academic-calendars/:id',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateBody(updateAcademicCalendarSchema),
  AcademicCalendarController.updateAcademicCalendar
);

router.post(
  '/academic-calendars/:id/activate',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  AcademicCalendarController.activateAcademicCalendar
);

router.post(
  '/academic-calendars/:id/close',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  AcademicCalendarController.closeAcademicCalendar
);

// ── 3. DECLARE HOLIDAY ───────────────────────────────────
router.post(
  '/holiday',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD),
  validateBody(declareHolidaySchema),
  AcademicCalendarController.declareHoliday
);

// ── 4. CENTRAL CALENDAR AGGREGATION ──────────────────────
router.get('/', AcademicCalendarController.getCalendar);

// ── 5. SINGLE EVENT DETAIL & MANAGEMENT ──────────────────
router.get('/:id', AcademicCalendarController.getEventById);

router.post(
  '/',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  validateBody(createCalendarEventSchema),
  AcademicCalendarController.createEvent
);

router.put(
  '/:id',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  validateBody(updateCalendarEventSchema),
  AcademicCalendarController.updateEvent
);

router.post(
  '/:id/cancel',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  AcademicCalendarController.cancelEvent
);

router.post(
  '/:id/publish',
  requireRoles(AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY),
  AcademicCalendarController.publishEvent
);

export const academicCalendarRouter = router;
