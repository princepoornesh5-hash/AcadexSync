import { requestEvents, RequestEventType, RequestEventPayload } from './request.events';
import { NotificationService } from '../services/notification.service';
import { NotificationType, NotificationPriority } from '../constants/notification.constants';
import { RequestStatus, RequestType } from '../constants/request.constants';
import { User } from '../models';
import { logger } from '../utils/logger';

function formatRequestType(type: RequestType | string): string {
  switch (type) {
    case 'LEAVE':
      return 'Leave Request';
    case 'ATTENDANCE_CORRECTION':
      return 'Attendance Correction';
    case 'ACADEMIC_ISSUE':
      return 'Academic Issue';
    case 'GENERAL_REQUEST':
      return 'General Request';
    case 'COMPLAINT_ISSUE':
      return 'Complaint / Issue';
    case 'DOCUMENT_REQUEST':
      return 'Document Request';
    case 'ON_DUTY':
      return 'On-Duty Request';
    case 'PERMISSION':
      return 'Permission Request';
    case 'TIMETABLE_CHANGE':
      return 'Timetable Change Request';
    case 'RESOURCE_REQUEST':
      return 'Resource Request';
    case 'CLASSROOM_LAB_ISSUE':
      return 'Classroom / Lab Issue';
    case 'WORKLOAD_CONCERN':
      return 'Workload Concern';
    case 'FACULTY_REQUIREMENT':
      return 'Faculty Requirement';
    case 'INFRASTRUCTURE_ISSUE':
      return 'Infrastructure Issue';
    case 'ACADEMIC_APPROVAL':
      return 'Academic Approval';
    case 'EVENT_WORKSHOP_APPROVAL':
      return 'Event Approval';
    case 'GENERAL_ADMIN_REQUEST':
      return 'Administration Request';
    default:
      return 'Request';
  }
}

function formatStatus(status: RequestStatus): string {
  switch (status) {
    case RequestStatus.APPROVED:
      return 'Approved';
    case RequestStatus.REJECTED:
      return 'Rejected';
    case RequestStatus.RESOLVED:
      return 'Resolved';
    case RequestStatus.IN_REVIEW:
      return 'Under Review';
    case RequestStatus.CLOSED:
      return 'Closed';
    default:
      return status;
  }
}

let isInitialized = false;

export function initRequestNotificationListener(): void {
  if (isInitialized) return;
  isInitialized = true;

  // 1. REQUEST CREATED -> Notify Responsible Authority
  requestEvents.on(RequestEventType.REQUEST_CREATED, async (payload: RequestEventPayload) => {
    try {
      const { request } = payload;
      const typeLabel = formatRequestType(request.requestType);

      // Determine recipient(s)
      const recipientIds: string[] = [];

      if (request.targetUserId) {
        recipientIds.push(request.targetUserId.toString());
      } else {
        // Find users with targetRole in scope
        const query: Record<string, unknown> = {
          collegeId: request.collegeId,
          role: request.targetRole,
        };
        if (request.departmentId && request.targetRole !== 'COLLEGE_ADMIN') {
          query.departmentId = request.departmentId;
        }

        const authorities = await User.find(query).select('_id').lean();
        for (const auth of authorities) {
          recipientIds.push(auth._id.toString());
        }
      }

      for (const recipientId of recipientIds) {
        const idempotencyKey = `req_created_${request._id?.toString() || request.id}_${recipientId}`;

        await NotificationService.createNotification({
          collegeId: request.collegeId.toString(),
          departmentId: request.departmentId ? request.departmentId.toString() : undefined,
          recipientUserId: recipientId,
          recipientRole: request.targetRole,
          title: `New ${typeLabel}`,
          body: `${request.requesterName} submitted a ${typeLabel}: "${request.title}"`,
          notificationType: NotificationType.REQUEST_RECEIVED,
          priority: NotificationPriority.NORMAL,
          entityType: 'REQUEST',
          entityId: request.requestId || (request._id ? request._id.toString() : request.id),
          relatedEntityType: 'REQUEST',
          relatedEntityId: request.requestId || (request._id ? request._id.toString() : request.id),
          deepLink: `/requests/${request._id ? request._id.toString() : request.id}`,
          metadata: {
            requestId: request.requestId,
            internalId: request._id ? request._id.toString() : request.id,
            requestType: request.requestType,
            status: request.status,
          },
          idempotencyKey,
        });
      }
    } catch (err) {
      // Non-blocking error handling: Request remains authoritative
      logger.error('Failed to create notification on REQUEST_CREATED event', err as Error);
    }
  });

  // 2. REQUEST STATUS CHANGED or RESPONDED -> Notify Requester
  const handleStatusChangeOrResponse = async (payload: RequestEventPayload) => {
    try {
      const { request, newStatus } = payload;
      const status = newStatus || request.status;
      const typeLabel = formatRequestType(request.requestType);
      const recipientId = request.requesterUserId.toString();

      let notifType = NotificationType.REQUEST_UPDATED;
      let title = `${typeLabel} ${formatStatus(status)}`;

      if (status === RequestStatus.APPROVED) {
        notifType = NotificationType.REQUEST_APPROVED;
        title = `${typeLabel} Approved`;
      } else if (status === RequestStatus.REJECTED) {
        notifType = NotificationType.REQUEST_REJECTED;
        title = `${typeLabel} Rejected`;
      } else if (status === RequestStatus.RESOLVED) {
        notifType = NotificationType.REQUEST_RESPONDED;
        title = `${typeLabel} Resolved`;
      } else if (status === RequestStatus.IN_REVIEW) {
        notifType = NotificationType.REQUEST_UPDATED;
        title = `${typeLabel} Under Review`;
      }

      let body = `Your ${typeLabel.toLowerCase()} has been marked as ${formatStatus(status).toLowerCase()}.`;
      if (request.responseMessage) {
        body = `${request.responseMessage}`;
      }

      const historyCount = request.history ? request.history.length : 1;
      const idempotencyKey = `req_status_${request._id?.toString() || request.id}_${status}_${historyCount}_${recipientId}`;

      await NotificationService.createNotification({
        collegeId: request.collegeId.toString(),
        departmentId: request.departmentId ? request.departmentId.toString() : undefined,
        recipientUserId: recipientId,
        recipientRole: request.requesterRole,
        title,
        body,
        notificationType: notifType,
        priority: NotificationPriority.NORMAL,
        entityType: 'REQUEST',
        entityId: request.requestId || (request._id ? request._id.toString() : request.id),
        relatedEntityType: 'REQUEST',
        relatedEntityId: request.requestId || (request._id ? request._id.toString() : request.id),
        deepLink: `/requests/${request._id ? request._id.toString() : request.id}`,
        metadata: {
          requestId: request.requestId,
          internalId: request._id ? request._id.toString() : request.id,
          requestType: request.requestType,
          status,
          responseMessage: request.responseMessage,
        },
        idempotencyKey,
      });
    } catch (err) {
      // Non-blocking: Request remains authoritative
      logger.error('Failed to create notification on request status/response event', err as Error);
    }
  };

  requestEvents.on(RequestEventType.REQUEST_STATUS_CHANGED, handleStatusChangeOrResponse);
  requestEvents.on(RequestEventType.REQUEST_RESPONDED, handleStatusChangeOrResponse);
}
