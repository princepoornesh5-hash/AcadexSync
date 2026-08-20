import { Router } from 'express';
import { DepartmentController } from '../../controllers/department.controller';
import { HodController } from '../../controllers/hod.controller';
import { FacultyController } from '../../controllers/faculty.controller';
import { StudentController } from '../../controllers/student.controller';
import { AcademicController } from '../../controllers/academic.controller';
import { authenticateRequest } from '../../middleware/auth.middleware';
import { requireCollegeAdmin } from '../../middleware/role.middleware';

const router = Router();

router.use(authenticateRequest);

// Read Endpoints (Super Admin or Scoped College Admin / HOD / Faculty)
router.get('/', DepartmentController.list);
router.get('/:id', DepartmentController.getById);
router.get('/:id/summary', DepartmentController.getSummary);
router.get('/:departmentId/hod', HodController.getByDepartmentId);
router.get('/:departmentId/faculty', FacultyController.getByDepartmentId);
router.get('/:departmentId/students', StudentController.getByDepartmentId);
router.get('/:departmentId/courses', AcademicController.listCourses);

// Mutation Endpoints (Super Admin or College Admin)
router.post('/', requireCollegeAdmin, DepartmentController.create);
router.put('/:id', requireCollegeAdmin, DepartmentController.update);
router.patch('/:id/status', requireCollegeAdmin, DepartmentController.updateStatus);

export const departmentRouter = router;
