export enum NotificationType {
  NOTE_PUBLISHED = 'NOTE_PUBLISHED',
  NOTE_UPDATED = 'NOTE_UPDATED',
  ATTENDANCE_LOW = 'ATTENDANCE_LOW',
  ATTENDANCE_MARKED = 'ATTENDANCE_MARKED',
  TIMETABLE_PUBLISHED = 'TIMETABLE_PUBLISHED',
  TIMETABLE_UPDATED = 'TIMETABLE_UPDATED',
  TIMETABLE_CANCELLED = 'TIMETABLE_CANCELLED',
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
