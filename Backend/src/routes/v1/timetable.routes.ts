import { Router } from 'express';
import { TimetableController } from '../../controllers/timetable.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireHodOrAbove } from '../../middleware/role.middleware';

const router = Router();

router.use(authenticateRequest);

// Room Management
router.post('/rooms', requireHodOrAbove, TimetableController.createRoom);
router.get('/rooms', TimetableController.listRooms);
router.get('/rooms/:id', TimetableController.getRoomById);
router.put('/rooms/:id', requireHodOrAbove, TimetableController.updateRoom);

// Specialized Timetable Lookups
router.get('/students/me', TimetableController.getStudentTimetable);
router.get('/sections/:sectionId', TimetableController.getSectionTimetable);
router.get('/faculty/me', TimetableController.getFacultyTimetable);
router.get('/faculty/:facultyId', TimetableController.getFacultyTimetable);
router.get('/departments/:departmentId', requireHodOrAbove, TimetableController.getDepartmentTimetable);

// Timetable CRUD & Lifecycle
router.get('/', TimetableController.list);
router.get('/:id', requireHodOrAbove, TimetableController.getById);
router.post('/', requireHodOrAbove, TimetableController.create);
router.put('/:id', requireHodOrAbove, TimetableController.update);
router.post('/:id/publish', requireHodOrAbove, TimetableController.publish);
router.post('/:id/unpublish', requireHodOrAbove, TimetableController.unpublish);
router.post('/:id/archive', requireHodOrAbove, TimetableController.archive);
router.delete('/:id', requireHodOrAbove, TimetableController.delete);

export const timetableRouter = router;
