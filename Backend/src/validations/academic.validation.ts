import { z } from 'zod';

// Course Validation
export const createCourseSchema = z.object({
  departmentId: z.string().min(1, 'departmentId is required'),
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100),
  code: z.string().trim().min(2, 'Code must be at least 2 characters').max(30).toUpperCase(),
  duration: z.number().int().min(1).max(6).optional().default(3),
});

export const updateCourseSchema = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  code: z.string().trim().min(2).max(30).toUpperCase().optional(),
  duration: z.number().int().min(1).max(6).optional(),
  isActive: z.boolean().optional(),
});

export const courseQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  search: z.string().optional(),
  departmentId: z.string().optional(),
  collegeId: z.string().optional(),
});

// Academic Year Validation
export const createAcademicYearSchema = z.object({
  name: z.string().trim().min(4, 'Name must be at least 4 characters (e.g. 2026-2027)').max(50),
  startDate: z.string().datetime({ message: 'Invalid start date ISO string' }),
  endDate: z.string().datetime({ message: 'Invalid end date ISO string' }),
  isCurrent: z.boolean().optional().default(false),
}).refine((data) => new Date(data.startDate) < new Date(data.endDate), {
  message: 'startDate must be before endDate',
  path: ['endDate'],
});

export const updateAcademicYearSchema = z.object({
  name: z.string().trim().min(4).max(50).optional(),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  isCurrent: z.boolean().optional(),
  isActive: z.boolean().optional(),
});

export const academicYearQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  collegeId: z.string().optional(),
});

// Semester Validation
export const createSemesterSchema = z.object({
  courseId: z.string().min(1, 'courseId is required'),
  academicYearId: z.string().min(1, 'academicYearId is required'),
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(50),
  number: z.number().int().min(1).max(12),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  isCurrent: z.boolean().optional().default(false),
}).refine((data) => {
  if (data.startDate && data.endDate) {
    return new Date(data.startDate) < new Date(data.endDate);
  }
  return true;
}, {
  message: 'startDate must be before endDate',
  path: ['endDate'],
});

export const updateSemesterSchema = z.object({
  name: z.string().trim().min(2).max(50).optional(),
  number: z.number().int().min(1).max(12).optional(),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional(),
  isCurrent: z.boolean().optional(),
  isActive: z.boolean().optional(),
}).refine((data) => {
  if (data.startDate && data.endDate) {
    return new Date(data.startDate) < new Date(data.endDate);
  }
  return true;
}, {
  message: 'startDate must be before endDate',
  path: ['endDate'],
});

export const semesterQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  collegeId: z.string().optional(),
});

// Section Validation
export const createSectionSchema = z.object({
  courseId: z.string().min(1, 'courseId is required'),
  academicYearId: z.string().optional(),
  semesterId: z.string().min(1, 'semesterId is required'),
  name: z.string().trim().min(1, 'Section name is required').max(30),
  capacity: z.number().int().min(1).optional().default(60),
});

export const updateSectionSchema = z.object({
  name: z.string().trim().min(1).max(30).optional(),
  capacity: z.number().int().min(1).optional(),
  isActive: z.boolean().optional(),
});

export const sectionQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  semesterId: z.string().optional(),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  collegeId: z.string().optional(),
});

// Subject Validation
export const createSubjectSchema = z.object({
  courseId: z.string().min(1, 'courseId is required'),
  semesterId: z.string().min(1, 'semesterId is required'),
  academicYearId: z.string().optional(),
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100),
  code: z.string().trim().min(2, 'Code must be at least 2 characters').max(30).toUpperCase(),
  credits: z.number().min(0).max(10).optional().default(3),
  type: z.string().trim().optional().default('Theory'),
});

export const updateSubjectSchema = z.object({
  name: z.string().trim().min(2, 'Name must be at least 2 characters').max(100).optional(),
  code: z.string().trim().min(2, 'Code must be at least 2 characters').max(30).toUpperCase().optional(),
  credits: z.number().min(0).max(10).optional(),
  type: z.string().trim().optional(),
  isActive: z.boolean().optional(),
});

export const subjectQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  semesterId: z.string().optional(),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  collegeId: z.string().optional(),
});

// Student Enrollment Validation
export const enrollStudentSchema = z.object({
  studentId: z.string().min(1, 'studentId is required'),
  sectionId: z.string().min(1, 'sectionId is required'),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  semesterId: z.string().optional(),
  enrollmentDate: z.string().optional(),
});

export const updateEnrollmentSchema = z.object({
  status: z.enum(['active', 'completed', 'withdrawn', 'transferred', 'inactive']).optional(),
  sectionId: z.string().optional(),
});

export const enrollmentQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)).pipe(z.number().positive().max(100).default(20)),
  studentId: z.string().optional(),
  sectionId: z.string().optional(),
  semesterId: z.string().optional(),
  courseId: z.string().optional(),
  academicYearId: z.string().optional(),
  collegeId: z.string().optional(),
  departmentId: z.string().optional(),
  status: z.string().optional(),
});

// Faculty Assignment Validation
export const createFacultyAssignmentSchema = z.object({
  facultyId: z.string().min(1, 'facultyId is required'),
  subjectId: z.string().min(1, 'subjectId is required'),
  sectionId: z.string().min(1, 'sectionId is required'),
  courseId: z.string().optional(),
  semesterId: z.string().optional(),
  academicYearId: z.string().optional(),
  departmentId: z.string().optional(),
  roomId: z.string().optional(),
  maxStudents: z.number().int().positive().optional(),
  assignmentType: z.string().optional().default('lecture'),
});

export const updateFacultyAssignmentSchema = z.object({
  roomId: z.string().optional(),
  maxStudents: z.number().int().positive().optional(),
  assignmentType: z.string().optional(),
  isActive: z.boolean().optional(),
});

export const facultyAssignmentQuerySchema = z.object({
  page: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 1)).pipe(z.number().positive().default(1)),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 50)).pipe(z.number().positive().max(100).default(50)),
  collegeId: z.string().optional(),
  departmentId: z.string().optional(),
  facultyId: z.string().optional(),
  courseId: z.string().optional(),
  semesterId: z.string().optional(),
  sectionId: z.string().optional(),
  subjectId: z.string().optional(),
  academicYearId: z.string().optional(),
  isActive: z.string().optional().transform((v) => (v === 'true' ? true : v === 'false' ? false : undefined)),
});
