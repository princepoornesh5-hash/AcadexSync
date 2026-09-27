export enum CalendarSourceType {
  MANUAL = 'MANUAL',
  DERIVED = 'DERIVED',
  SYSTEM = 'SYSTEM',
}

export enum CalendarEventType {
  EVENT = 'EVENT',
  HOLIDAY = 'HOLIDAY',
  PUBLIC_HOLIDAY = 'PUBLIC_HOLIDAY',
  INSTITUTION_HOLIDAY = 'INSTITUTION_HOLIDAY',
  EXAM = 'EXAM',
  SEMINAR = 'SEMINAR',
  WORKSHOP = 'WORKSHOP',
  LAB_VIVA = 'LAB_VIVA',
  CLASS_TEST = 'CLASS_TEST',
  DEADLINE = 'DEADLINE',
  OTHER = 'OTHER',
}

export enum CalendarEventScope {
  COLLEGE = 'COLLEGE',
  DEPARTMENT = 'DEPARTMENT',
  SECTION = 'SECTION',
  CLASS = 'CLASS',
}

export enum CalendarEventStatus {
  DRAFT = 'DRAFT',
  PUBLISHED = 'PUBLISHED',
  CANCELLED = 'CANCELLED',
  ARCHIVED = 'ARCHIVED',
}

export enum CalendarRecurrence {
  NONE = 'NONE',
  ANNUAL = 'ANNUAL',
}
