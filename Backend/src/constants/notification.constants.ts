export enum NotificationType {
  NOTE_PUBLISHED = 'NOTE_PUBLISHED',
  NOTE_UPDATED = 'NOTE_UPDATED',
  ATTENDANCE_LOW = 'ATTENDANCE_LOW',
  ATTENDANCE_MARKED = 'ATTENDANCE_MARKED',
  ATTENDANCE_ABSENT = 'ATTENDANCE_ABSENT',
  ATTENDANCE_LATE = 'ATTENDANCE_LATE',
  TIMETABLE_PUBLISHED = 'TIMETABLE_PUBLISHED',
  TIMETABLE_UPDATED = 'TIMETABLE_UPDATED',
  TIMETABLE_CANCELLED = 'TIMETABLE_CANCELLED',
  CALENDAR_OVERRIDE = 'CALENDAR_OVERRIDE',
  TEACHER_SUBSTITUTION = 'TEACHER_SUBSTITUTION',
  ANNOUNCEMENT = 'ANNOUNCEMENT',
  SYSTEM = 'SYSTEM',
}

export enum NotificationCategory {
  NOTES = 'notes',
  ATTENDANCE = 'attendance',
  TIMETABLE = 'timetable',
  SYSTEM = 'system',
  ACADEMIC = 'academic',
  ANNOUNCEMENT = 'announcement',
  GENERAL = 'general',
}

export enum NotificationPriority {
  LOW = 'low',
  NORMAL = 'normal',
  HIGH = 'high',
  CRITICAL = 'critical',
}

export enum DevicePlatform {
  ANDROID = 'android',
  IOS = 'ios',
  WEB = 'web',
}

export enum AudienceScope {
  COLLEGE = 'COLLEGE',
  DEPARTMENT = 'DEPARTMENT',
  COURSE = 'COURSE',
  SEMESTER = 'SEMESTER',
  SECTION = 'SECTION',
  ROLE = 'ROLE',
  INDIVIDUAL = 'INDIVIDUAL',
}

export enum AnnouncementStatus {
  DRAFT = 'DRAFT',
  PUBLISHED = 'PUBLISHED',
  ARCHIVED = 'ARCHIVED',
}
