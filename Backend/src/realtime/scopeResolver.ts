import { ConnectionIdentity } from './roomManager';
import { RealtimeEventEnvelope } from './contracts/eventEnvelope';
import { Logger } from '../utils/logger';

export interface SubscriptionValidationResult {
  allowed: boolean;
  reason?: string;
  normalizedChannel?: string;
}

export class ScopeResolver {
  /**
   * Authorizes client subscription requests.
   * Clients can NEVER subscribe to foreign colleges, foreign user channels, or unauthorized scopes.
   */
  public static authorizeSubscription(
    identity: ConnectionIdentity,
    requestedChannel: string
  ): SubscriptionValidationResult {
    if (!requestedChannel || typeof requestedChannel !== 'string') {
      return { allowed: false, reason: 'Invalid channel format' };
    }

    const trimmed = requestedChannel.trim();
    const parts = trimmed.split(':');
    const prefix = parts[0];

    // 1. College room: college:{collegeId}
    if (prefix === 'college') {
      const targetCollegeId = parts[1];
      if (!targetCollegeId) {
        return { allowed: false, reason: 'Missing collegeId in channel' };
      }
      if (identity.role === 'SUPER_ADMIN' || identity.collegeId === targetCollegeId) {
        return { allowed: true, normalizedChannel: `college:${targetCollegeId}` };
      }
      return { allowed: false, reason: 'Cross-tenant subscription forbidden' };
    }

    // 2. Department room: department:{collegeId}:{departmentId} or department:{departmentId}
    if (prefix === 'department') {
      let targetCollegeId = identity.collegeId;
      let targetDeptId = parts[1];
      if (parts.length >= 3) {
        targetCollegeId = parts[1];
        targetDeptId = parts[2];
      }

      if (!targetDeptId) {
        return { allowed: false, reason: 'Missing departmentId in channel' };
      }

      if (identity.role !== 'SUPER_ADMIN' && identity.collegeId !== targetCollegeId) {
        return { allowed: false, reason: 'Cross-tenant department subscription forbidden' };
      }

      if (
        identity.role === 'SUPER_ADMIN' ||
        identity.role === 'COLLEGE_ADMIN' ||
        identity.departmentId === targetDeptId
      ) {
        return {
          allowed: true,
          normalizedChannel: `department:${targetCollegeId}:${targetDeptId}`,
        };
      }
      return { allowed: false, reason: 'Not authorized for this department scope' };
    }

    // 3. User room: user:{userId}
    if (prefix === 'user') {
      const targetUserId = parts[1];
      if (identity.role === 'SUPER_ADMIN' || identity.userId === targetUserId) {
        return { allowed: true, normalizedChannel: `user:${targetUserId}` };
      }
      return { allowed: false, reason: 'Cannot subscribe to another user private channel' };
    }

    // 4. Faculty room: faculty:{facultyId}
    if (prefix === 'faculty') {
      const targetFacultyId = parts[1];
      if (
        identity.userId === targetFacultyId ||
        ['SUPER_ADMIN', 'COLLEGE_ADMIN', 'HOD'].includes(identity.role)
      ) {
        return { allowed: true, normalizedChannel: `faculty:${targetFacultyId}` };
      }
      return { allowed: false, reason: 'Cannot subscribe to faculty channel' };
    }

    // 5. Student room: student:{studentId}
    if (prefix === 'student') {
      const targetStudentId = parts[1];
      if (
        identity.userId === targetStudentId ||
        ['SUPER_ADMIN', 'COLLEGE_ADMIN', 'HOD', 'FACULTY'].includes(identity.role)
      ) {
        return { allowed: true, normalizedChannel: `student:${targetStudentId}` };
      }
      return { allowed: false, reason: 'Cannot subscribe to student channel' };
    }

    // 6. Section room: section:{collegeId}:{sectionId} or section:{sectionId}
    if (prefix === 'section') {
      let targetCollegeId = identity.collegeId;
      let targetSectionId = parts[1];
      if (parts.length >= 3) {
        targetCollegeId = parts[1];
        targetSectionId = parts[2];
      }
      if (identity.role !== 'SUPER_ADMIN' && identity.collegeId !== targetCollegeId) {
        return { allowed: false, reason: 'Cross-tenant section subscription forbidden' };
      }
      return {
        allowed: true,
        normalizedChannel: `section:${targetCollegeId}:${targetSectionId}`,
      };
    }

    // 7. Contextual Timetable channel: timetable:{timetableId}
    if (prefix === 'timetable') {
      const timetableId = parts[1];
      if (!timetableId) return { allowed: false, reason: 'Missing timetableId' };
      return { allowed: true, normalizedChannel: `timetable:${timetableId}` };
    }

    // 8. Contextual Attendance channel: attendance:{sessionId}
    if (prefix === 'attendance') {
      const sessionId = parts[1];
      if (!sessionId) return { allowed: false, reason: 'Missing sessionId' };
      return { allowed: true, normalizedChannel: `attendance:${sessionId}` };
    }

    Logger.warn(
      `[Realtime Security] Rejected subscription to unknown or unauthorized channel: "${requestedChannel}" by user ${identity.userId}`
    );
    return { allowed: false, reason: 'Unsupported channel name' };
  }

  /**
   * Resolves target rooms to which an event must be broadcast based on event scope.
   */
  public static resolveTargetRooms(event: RealtimeEventEnvelope): string[] {
    const rooms = new Set<string>();

    switch (event.scope.type) {
      case 'user':
        if (event.scope.userId) {
          rooms.add(`user:${event.scope.userId}`);
        }
        break;

      case 'college':
        if (event.collegeId && event.collegeId !== 'global') {
          rooms.add(`college:${event.collegeId}`);
        } else {
          rooms.add('global:superadmin');
        }
        break;

      case 'department':
        if (event.collegeId && event.scope.departmentId) {
          rooms.add(`department:${event.collegeId}:${event.scope.departmentId}`);
        }
        break;

      case 'role':
        if (event.collegeId && event.scope.role) {
          rooms.add(`role:${event.collegeId}:${event.scope.role.toUpperCase()}`);
        }
        break;

      case 'channel':
        if (event.scope.channel) {
          rooms.add(event.scope.channel);
        }
        break;
    }

    // Also target contextual resource room if present
    if (event.aggregateType === 'Timetable') {
      rooms.add(`timetable:${event.aggregateId}`);
    } else if (event.aggregateType === 'AttendanceSession') {
      rooms.add(`attendance:${event.aggregateId}`);
    }

    return Array.from(rooms);
  }
}
