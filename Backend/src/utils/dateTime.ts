import { TimetableDay } from '../constants/status';

export const DEFAULT_INSTITUTION_TIMEZONE = 'Asia/Kolkata';

const DAY_MAP: Record<string, TimetableDay> = {
  sunday: TimetableDay.SUNDAY,
  monday: TimetableDay.MONDAY,
  tuesday: TimetableDay.TUESDAY,
  wednesday: TimetableDay.WEDNESDAY,
  thursday: TimetableDay.THURSDAY,
  friday: TimetableDay.FRIDAY,
  saturday: TimetableDay.SATURDAY,
};

/**
 * Normalizes any Date object or date/ISO string into a canonical YYYY-MM-DD
 * representation in the specified institution timezone (defaults to Asia/Kolkata).
 */
export function formatDateToCalendarString(
  date: Date | string,
  timeZone: string = DEFAULT_INSTITUTION_TIMEZONE
): string {
  if (typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return date;
  }

  const d = typeof date === 'string' ? new Date(date) : date;
  if (isNaN(d.getTime())) {
    throw new Error(`Invalid date provided for calendar formatting: ${date}`);
  }

  // en-CA format produces YYYY-MM-DD consistently
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  return formatter.format(d);
}

/**
 * Derives the TimetableDay (e.g. MONDAY, TUESDAY) from a calendar date or timestamp
 * respecting the institution's configured timezone.
 */
export function getTimetableDayFromDate(
  date: Date | string,
  timeZone: string = DEFAULT_INSTITUTION_TIMEZONE
): TimetableDay {
  if (typeof date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(date)) {
    // Pure YYYY-MM-DD string: parse at noon UTC so no boundary shift occurs
    const [y, m, d] = date.split('-').map(Number);
    const noonUtc = new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
    const dayNames = [
      TimetableDay.SUNDAY,
      TimetableDay.MONDAY,
      TimetableDay.TUESDAY,
      TimetableDay.WEDNESDAY,
      TimetableDay.THURSDAY,
      TimetableDay.FRIDAY,
      TimetableDay.SATURDAY,
    ];
    return dayNames[noonUtc.getUTCDay()];
  }

  const d = typeof date === 'string' ? new Date(date) : date;
  if (isNaN(d.getTime())) {
    throw new Error(`Invalid date provided for day of week calculation: ${date}`);
  }

  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone,
    weekday: 'long',
  });
  const weekday = formatter.format(d).toLowerCase();
  const timetableDay = DAY_MAP[weekday];
  if (!timetableDay) {
    throw new Error(`Failed to map weekday "${weekday}" to TimetableDay`);
  }
  return timetableDay;
}

/**
 * Parses a YYYY-MM-DD string into a Date object at noon UTC,
 * safely avoiding local machine or server midnight UTC boundary shifts.
 */
export function parseCalendarDate(dateStr: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
    throw new Error(`Expected date in YYYY-MM-DD format, got: ${dateStr}`);
  }
  const [y, m, d] = dateStr.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
}

/**
 * Returns UTC start of day for a date string or Date in the target timezone.
 */
export function startOfCalendarDay(
  date: Date | string,
  timeZone: string = DEFAULT_INSTITUTION_TIMEZONE
): Date {
  const dateStr = formatDateToCalendarString(date, timeZone);
  const [y, m, d] = dateStr.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0));
}

/**
 * Returns UTC end of day for a date string or Date in the target timezone.
 */
export function endOfCalendarDay(
  date: Date | string,
  timeZone: string = DEFAULT_INSTITUTION_TIMEZONE
): Date {
  const dateStr = formatDateToCalendarString(date, timeZone);
  const [y, m, d] = dateStr.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d, 23, 59, 59, 999));
}

/**
 * Determines whether two time intervals [s1, e1] and [s2, e2] overlap.
 * Assumes HH:mm format strings.
 */
export function isTimeOverlapping(s1: string, e1: string, s2: string, e2: string): boolean {
  return s1 < e2 && e1 > s2;
}

