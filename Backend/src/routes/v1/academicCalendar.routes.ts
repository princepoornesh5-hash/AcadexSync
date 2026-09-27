import { Router } from 'express';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeScope } from '../../middleware/tenant.middleware';
import { validateBody } from '../../middleware/validate.middleware';
import { AcademicCalendarController } from '../../controllers/academicCalendar.controller';
import {
  createCalendarEventSchema,
  updateCalendarEventSchema,
} from '../../validations/calendarEvent.validation';

const router = Router();

// Multi-tenant and authentication boundaries
router.use(authenticateRequest);
router.use(requireCollegeScope);

// 1. Central Calendar Aggregation endpoint (One calendar for everyone)
router.get('/', AcademicCalendarController.getCalendar);

// 2. Single Event Detail
router.get('/:id', AcademicCalendarController.getEventById);

// 3. Create Event (Role-authorized: College Admin, HOD, Faculty)
router.post(
  '/',
  validateBody(createCalendarEventSchema),
  AcademicCalendarController.createEvent
);

// 4. Update Event (Authorized creator/HOD/Admin)
router.put(
  '/:id',
  validateBody(updateCalendarEventSchema),
  AcademicCalendarController.updateEvent
);

// 5. Cancel Event (Sets status to CANCELLED)
router.post('/:id/cancel', AcademicCalendarController.cancelEvent);

// 6. Publish Event
router.post('/:id/publish', AcademicCalendarController.publishEvent);

export const academicCalendarRouter = router;
