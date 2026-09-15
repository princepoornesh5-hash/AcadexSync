import { Router } from 'express';
import { AcademicController } from '../../controllers/academic.controller';
import { HodController } from '../../controllers/hod.controller';
import { FacultyController } from '../../controllers/faculty.controller';
import { StudentController } from '../../controllers/student.controller';
import { TimetableController } from '../../controllers/timetable.controller';
import { NoteController } from '../../controllers/note.controller';
import { noteRouter } from './note.routes';
import { authenticateRequest } from '../../middleware/auth.middleware';
import {
  requireCollegeAdmin,
  requireHodOrAbove,
  requireFacultyOrAbove,
} from '../../middleware/role.middleware';

const router = Router();

router.use(authenticateRequest);

// HOD Management (Phase 9F.1)
router.post('/hods', requireCollegeAdmin, HodController.provision);
router.get('/hods', requireCollegeAdmin, HodController.list);
router.get('/hods/:id', HodController.getById);
router.put('/hods/:id', HodController.updateProfile);
router.patch('/hods/:id/department', requireCollegeAdmin, HodController.transferDepartment);
router.get('/hods/:id/summary', HodController.getSummary);

// Faculty Management (Phase 9G.1)
router.post('/faculty', requireHodOrAbove, FacultyController.provision);
router.get('/faculty', requireHodOrAbove, FacultyController.list);
router.get('/faculty/:id', FacultyController.getById);
router.put('/faculty/:id', FacultyController.updateProfile);
router.patch('/faculty/:id/department', requireCollegeAdmin, FacultyController.transferDepartment);
router.get('/faculty/:id/summary', FacultyController.getSummary);

// Student Management (Phase 9H.1)
router.post('/students/me/phone-request', StudentController.createPhoneRequest);
router.get('/student-contact-requests', StudentController.listContactRequests);
router.patch('/student-contact-requests/:id', requireFacultyOrAbove, StudentController.resolveContactRequest);

router.post('/students', requireFacultyOrAbove, StudentController.provision);
router.get('/students', requireFacultyOrAbove, StudentController.list);
router.get('/students/:id', StudentController.getById);
router.put('/students/:id', StudentController.updateProfile);
router.patch('/students/:id/institute-id', requireHodOrAbove, StudentController.correctInstituteId);
router.patch('/students/:id/department', requireCollegeAdmin, StudentController.transferDepartment);
router.get('/students/:id/summary', StudentController.getSummary);

// Academic Structure & Tree (Phase 9I.1)
router.get('/tree', AcademicController.getAcademicTree);

// Courses
router.get('/courses', AcademicController.listCourses);
router.post('/courses', requireHodOrAbove, AcademicController.createCourse);
router.get('/courses/:id', AcademicController.getCourseById);
router.put('/courses/:id', requireHodOrAbove, AcademicController.updateCourse);

// Academic Years
router.get('/academic-years', AcademicController.listAcademicYears);
router.post('/academic-years', requireCollegeAdmin, AcademicController.createAcademicYear);
router.get('/academic-years/:id', AcademicController.getAcademicYearById);
router.put('/academic-years/:id', requireCollegeAdmin, AcademicController.updateAcademicYear);

// Semesters
router.get('/semesters', AcademicController.listSemesters);
router.post('/semesters', requireHodOrAbove, AcademicController.createSemester);
router.get('/semesters/:id', AcademicController.getSemesterById);
router.put('/semesters/:id', requireHodOrAbove, AcademicController.updateSemester);

// Sections
router.get('/sections', AcademicController.listSections);
router.post('/sections', requireHodOrAbove, AcademicController.createSection);
router.get('/sections/:id', AcademicController.getSectionById);
router.put('/sections/:id', requireHodOrAbove, AcademicController.updateSection);

// Subjects
router.get('/subjects', AcademicController.listSubjects);
router.post('/subjects', requireHodOrAbove, AcademicController.createSubject);
router.get('/subjects/:id', AcademicController.getSubjectById);
router.put('/subjects/:id', requireHodOrAbove, AcademicController.updateSubject);

// Enrollments
router.get('/enrollments', AcademicController.listEnrollments);
router.post('/enrollments', requireFacultyOrAbove, AcademicController.enrollStudent);
router.get('/enrollments/:id', AcademicController.getEnrollmentById);
router.patch('/enrollments/:id', requireHodOrAbove, AcademicController.updateEnrollment);
router.delete('/enrollments/:id', requireHodOrAbove, AcademicController.deleteEnrollment);

// Room Management (Phase 9J.1)
router.post('/rooms', requireCollegeAdmin, TimetableController.createRoom);
router.get('/rooms', TimetableController.listRooms);
router.get('/rooms/:id', TimetableController.getRoomById);
router.put('/rooms/:id', requireCollegeAdmin, TimetableController.updateRoom);

// Timetable Management (Phase 9J.1)
router.get('/students/me/timetable', TimetableController.getStudentTimetable);
router.get('/sections/:sectionId/timetable', TimetableController.getSectionTimetable);
router.get('/faculty/:facultyId/timetable', TimetableController.getFacultyTimetable);

router.get('/timetables', TimetableController.list);
router.post('/timetables', requireHodOrAbove, TimetableController.create);
router.get('/timetables/:id', TimetableController.getById);
router.put('/timetables/:id', requireHodOrAbove, TimetableController.update);
router.post('/timetables/:id/publish', requireHodOrAbove, TimetableController.publish);
router.post('/timetables/:id/unpublish', requireHodOrAbove, TimetableController.unpublish);
router.post('/timetables/:id/archive', requireHodOrAbove, TimetableController.archive);
router.delete('/timetables/:id', requireHodOrAbove, TimetableController.delete);

// Notes Management (Phase 9L.1)
router.get('/subjects/:subjectId/notes', NoteController.getSubjectNotes);
router.get('/students/me/notes', NoteController.getStudentNotes);
router.use('/notes', noteRouter);

// Faculty Assignments & Workload (Module 5B)
router.post('/faculty-assignments', requireHodOrAbove, AcademicController.createFacultyAssignment);
router.get('/faculty-assignments', AcademicController.listFacultyAssignments);
router.get('/faculty-assignments/workload', AcademicController.getFacultyWorkload);
router.get('/faculty-assignments/my', requireFacultyOrAbove, AcademicController.getMyFacultyAssignments);
router.get('/faculty-assignments/:id', AcademicController.getFacultyAssignmentById);
router.put('/faculty-assignments/:id', requireHodOrAbove, AcademicController.updateFacultyAssignment);
router.delete('/faculty-assignments/:id', requireHodOrAbove, AcademicController.deleteFacultyAssignment);

// Backwards-Compatible Legacy Routes
router.post('/student-enrollments', requireCollegeAdmin, AcademicController.enrollStudent);

export const academicRouter = router;
