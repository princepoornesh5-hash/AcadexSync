export enum AccountStatus {
  ACTIVE = 'active',
  PENDING_ACTIVATION = 'pending_activation',
  DEACTIVATED = 'deactivated',
  INACTIVE = 'inactive',
  SUSPENDED = 'suspended',
}

export enum CollegeStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
}

export enum DepartmentStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
}

export enum InvitationStatus {
  PENDING = 'pending',
  USED = 'used',
  EXPIRED = 'expired',
  REVOKED = 'revoked',
}

export enum OtpPurpose {
  PASSWORD_RESET = 'password_reset',
  ACCOUNT_ACTIVATION = 'account_activation',
  PHONE_VERIFICATION = 'phone_verification',
  EMAIL_VERIFICATION = 'email_verification',
}

export enum OtpDeliveryMethod {
  EMAIL = 'email',
  SMS = 'sms',
}

export enum TokenType {
  ACCESS = 'access',
  REFRESH = 'refresh',
  PASSWORD_RESET = 'password_reset',
}

export enum AcademicYearStatus {
  UPCOMING = 'upcoming',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  ARCHIVED = 'archived',
}

export enum SemesterStatus {
  UPCOMING = 'upcoming',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  ARCHIVED = 'archived',
}

export enum SectionStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  ARCHIVED = 'archived',
}

export enum StudentLifecycleState {
  APPLICANT = 'applicant',
  ADMITTED = 'admitted',
  ACTIVE = 'active',
  ON_LEAVE = 'onLeave',
  SUSPENDED = 'suspended',
  TRANSFERRED = 'transferred',
  GRADUATED = 'graduated',
  ALUMNI = 'alumni',
}

export enum TimetableStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  ARCHIVED = 'archived',
}

export enum TimetableDay {
  MONDAY = 'monday',
  TUESDAY = 'tuesday',
  WEDNESDAY = 'wednesday',
  THURSDAY = 'thursday',
  FRIDAY = 'friday',
  SATURDAY = 'saturday',
  SUNDAY = 'sunday',
}

export enum TimetableTimingMode {
  SAME_EVERY_DAY = 'sameEveryDay',
  DIFFERENT_PER_DAY = 'differentPerDay',
}

export enum TimetableSessionType {
  LECTURE = 'lecture',
  LAB = 'lab',
  TUTORIAL = 'tutorial',
  PRACTICAL = 'practical',
  SEMINAR = 'seminar',
  OTHER = 'other',
}

export enum TimetableBreakType {
  LUNCH = 'lunch',
  TEA = 'tea',
  ASSEMBLY = 'assembly',
  CUSTOM = 'custom',
}

export enum AttendanceStatus {
  PRESENT = 'present',
  ABSENT = 'absent',
  LATE = 'late',
  EXCUSED = 'excused',
  MEDICAL_LEAVE = 'medicalLeave',
  ON_DUTY = 'onDuty',
  HOLIDAY = 'holiday',
}

export enum AttendanceSessionStatus {
  OPEN = 'open',
  LOCKED = 'locked',
  CLOSED = 'closed',
  CANCELLED = 'cancelled',
}

export enum NoteStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  UNPUBLISHED = 'unpublished',
  ARCHIVED = 'archived',
}

export enum NoteType {
  CHAPTER = 'CHAPTER',
  UNIT = 'UNIT',
  ASSIGNMENT_REFERENCE = 'ASSIGNMENT_REFERENCE',
  STUDY_MATERIAL = 'STUDY_MATERIAL',
  SYLLABUS = 'SYLLABUS',
  OTHER = 'OTHER',
}

export enum NoteLifecycleState {
  PENDING_UPLOAD = 'PENDING_UPLOAD',
  UPLOADED = 'UPLOADED',
  READY = 'READY',
  FAILED = 'FAILED',
  DELETING = 'DELETING',
  DELETED = 'DELETED',
}

export enum NoteVisibility {
  PUBLIC = 'PUBLIC',
  SECTION_ONLY = 'SECTION_ONLY',
  FACULTY_ONLY = 'FACULTY_ONLY',
}

export enum ResourceType {
  TEXT_NOTE = 'text_note',
  EXTERNAL_LINK = 'external_link',
  FILE_ATTACHMENT = 'file_attachment',
}

export enum NotificationCategory {
  ATTENDANCE = 'attendance',
  ACADEMIC = 'academic',
  SYSTEM = 'system',
  PROFILE = 'profile',
  SECURITY = 'security',
  NOTES = 'notes',
  CERTIFICATES = 'certificates',
  TIMETABLE = 'timetable',
  GENERAL = 'general',
}

export enum NotificationPriority {
  LOW = 'low',
  NORMAL = 'normal',
  HIGH = 'high',
  CRITICAL = 'critical',
}

export enum NotificationAudienceType {
  PERSONAL = 'personal',
  ROLE = 'role',
  DEPARTMENT = 'department',
  COLLEGE = 'college',
  PLATFORM = 'platform',
  SECTION = 'section',
}
