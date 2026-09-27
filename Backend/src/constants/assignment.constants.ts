export enum AssignmentType {
  HOMEWORK = 'Homework',
  LAB_WORK = 'Lab Work',
  QUIZ = 'Quiz',
  PROJECT = 'Project',
  OTHER = 'Other',
}

export enum AssignmentStatus {
  DRAFT = 'DRAFT',
  PUBLISHED = 'PUBLISHED',
  CLOSED = 'CLOSED',
}

export enum StudentTaskStatus {
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  OVERDUE = 'OVERDUE',
}

export enum FacultyReviewStatus {
  NOT_REVIEWED = 'NOT_REVIEWED',
  REVIEWED = 'REVIEWED',
}

export enum AssignmentEvent {
  ASSIGNMENT_PUBLISHED = 'ASSIGNMENT_PUBLISHED',
  ASSIGNMENT_DUE_SOON = 'ASSIGNMENT_DUE_SOON',
  ASSIGNMENT_OVERDUE = 'ASSIGNMENT_OVERDUE',
  ASSIGNMENT_COMPLETED = 'ASSIGNMENT_COMPLETED',
  ASSIGNMENT_GRADED = 'ASSIGNMENT_GRADED',
}
