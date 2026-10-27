export enum AcademicScopeType {
  COLLEGE = 'COLLEGE',
  DEPARTMENT = 'DEPARTMENT',
  COURSE = 'COURSE',
  SEMESTER = 'SEMESTER',
  SECTION = 'SECTION',
  CLASS = 'CLASS',
  SUBJECT = 'SUBJECT',
}

export interface ValidatedAcademicScope {
  scope: AcademicScopeType;
  collegeId: string;
  departmentId?: string | null;
  courseId?: string | null;
  academicYearId?: string | null;
  semesterId?: string | null;
  sectionId?: string | null;
  subjectId?: string | null;
  facultyAssignmentId?: string | null;
  facultyId?: string | null;
}
