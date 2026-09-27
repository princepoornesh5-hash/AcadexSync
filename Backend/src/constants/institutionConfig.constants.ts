export enum InstitutionType {
  ENGINEERING = 'ENGINEERING',
  POLYTECHNIC = 'POLYTECHNIC',
  ARTS_AND_SCIENCE = 'ARTS_AND_SCIENCE',
  UNIVERSITY = 'UNIVERSITY',
  CUSTOM = 'CUSTOM',
}

export enum AcademicConcept {
  DEPARTMENT = 'department',
  PROGRAM = 'program',
  ACADEMIC_YEAR = 'academicYear',
  SEMESTER = 'semester',
  SECTION = 'section',
  SUBJECT = 'subject',
  BUILDING = 'building',
  ROOM = 'room',
}

export interface IConceptTerm {
  singular: string;
  plural: string;
}

export interface ITerminologyConfig {
  department: IConceptTerm;
  program: IConceptTerm;
  academicYear: IConceptTerm;
  semester: IConceptTerm;
  section: IConceptTerm;
  subject: IConceptTerm;
  building: IConceptTerm;
  room: IConceptTerm;
}

export interface IAcademicStructureConfig {
  program: boolean;
  academicYear: boolean;
  semester: boolean;
  section: boolean;
  subject: boolean;
  building: boolean;
  room: boolean;
}

export interface IAttendanceAlertsConfig {
  enabled: boolean;
  warningPercentage: number;
  criticalPercentage: number;
  absenceAlertsEnabled: boolean;
}

export const DEFAULT_ATTENDANCE_ALERTS: IAttendanceAlertsConfig = {
  enabled: true,
  warningPercentage: 75,
  criticalPercentage: 65,
  absenceAlertsEnabled: true,
};

export const DEFAULT_TERMINOLOGY: ITerminologyConfig = {
  department: { singular: 'Department', plural: 'Departments' },
  program: { singular: 'Course', plural: 'Courses' },
  academicYear: { singular: 'Academic Year', plural: 'Academic Years' },
  semester: { singular: 'Semester', plural: 'Semesters' },
  section: { singular: 'Section', plural: 'Sections' },
  subject: { singular: 'Subject', plural: 'Subjects' },
  building: { singular: 'Building', plural: 'Buildings' },
  room: { singular: 'Room', plural: 'Rooms' },
};

export const DEFAULT_ACADEMIC_STRUCTURE: IAcademicStructureConfig = {
  program: true,
  academicYear: true,
  semester: true,
  section: true,
  subject: true,
  building: true,
  room: true,
};

export interface IInstitutionPreset {
  id: InstitutionType;
  name: string;
  description: string;
  suggestedStructure: IAcademicStructureConfig;
  suggestedTerminology: ITerminologyConfig;
}

export const INSTITUTION_PRESETS: Record<InstitutionType, IInstitutionPreset> = {
  [InstitutionType.ENGINEERING]: {
    id: InstitutionType.ENGINEERING,
    name: 'Engineering College',
    description: 'Traditional engineering college with departments, degree programs, semesters, and sections.',
    suggestedStructure: {
      program: true,
      academicYear: true,
      semester: true,
      section: true,
      subject: true,
      building: true,
      room: true,
    },
    suggestedTerminology: {
      department: { singular: 'Department', plural: 'Departments' },
      program: { singular: 'Course', plural: 'Courses' },
      academicYear: { singular: 'Academic Year', plural: 'Academic Years' },
      semester: { singular: 'Semester', plural: 'Semesters' },
      section: { singular: 'Section', plural: 'Sections' },
      subject: { singular: 'Subject', plural: 'Subjects' },
      building: { singular: 'Building', plural: 'Buildings' },
      room: { singular: 'Room', plural: 'Rooms' },
    },
  },
  [InstitutionType.POLYTECHNIC]: {
    id: InstitutionType.POLYTECHNIC,
    name: 'Polytechnic College',
    description: 'Diploma-granting technical institution with term-based structure and consolidated classes without extra sections.',
    suggestedStructure: {
      program: true,
      academicYear: true,
      semester: true,
      section: false, // Section disabled by default for polytechnic
      subject: true,
      building: false,
      room: false,
    },
    suggestedTerminology: {
      department: { singular: 'Department', plural: 'Departments' },
      program: { singular: 'Diploma Program', plural: 'Diploma Programs' },
      academicYear: { singular: 'Academic Year', plural: 'Academic Years' },
      semester: { singular: 'Term', plural: 'Terms' },
      section: { singular: 'Batch', plural: 'Batches' },
      subject: { singular: 'Course', plural: 'Courses' },
      building: { singular: 'Block', plural: 'Blocks' },
      room: { singular: 'Lab / Room', plural: 'Labs / Rooms' },
    },
  },
  [InstitutionType.ARTS_AND_SCIENCE]: {
    id: InstitutionType.ARTS_AND_SCIENCE,
    name: 'Arts & Science College',
    description: 'Liberal arts and science colleges with undergraduate/postgraduate degrees and classes.',
    suggestedStructure: {
      program: true,
      academicYear: true,
      semester: true,
      section: true,
      subject: true,
      building: true,
      room: true,
    },
    suggestedTerminology: {
      department: { singular: 'Department', plural: 'Departments' },
      program: { singular: 'Degree Program', plural: 'Degree Programs' },
      academicYear: { singular: 'Academic Year', plural: 'Academic Years' },
      semester: { singular: 'Semester', plural: 'Semesters' },
      section: { singular: 'Class', plural: 'Classes' },
      subject: { singular: 'Paper', plural: 'Papers' },
      building: { singular: 'Building', plural: 'Buildings' },
      room: { singular: 'Classroom', plural: 'Classrooms' },
    },
  },
  [InstitutionType.UNIVERSITY]: {
    id: InstitutionType.UNIVERSITY,
    name: 'University / Autonomous Institute',
    description: 'Multi-faculty institution with academic programs, schools/departments, and modules.',
    suggestedStructure: {
      program: true,
      academicYear: true,
      semester: true,
      section: true,
      subject: true,
      building: true,
      room: true,
    },
    suggestedTerminology: {
      department: { singular: 'School / Department', plural: 'Schools / Departments' },
      program: { singular: 'Academic Program', plural: 'Academic Programs' },
      academicYear: { singular: 'Academic Year', plural: 'Academic Years' },
      semester: { singular: 'Semester', plural: 'Semesters' },
      section: { singular: 'Division', plural: 'Divisions' },
      subject: { singular: 'Module', plural: 'Modules' },
      building: { singular: 'Wing / Block', plural: 'Wings / Blocks' },
      room: { singular: 'Lecture Hall', plural: 'Lecture Halls' },
    },
  },
  [InstitutionType.CUSTOM]: {
    id: InstitutionType.CUSTOM,
    name: 'Custom Configuration',
    description: 'Fully personalized structure and terminology tailored specifically to your college.',
    suggestedStructure: { ...DEFAULT_ACADEMIC_STRUCTURE },
    suggestedTerminology: { ...DEFAULT_TERMINOLOGY },
  },
};
