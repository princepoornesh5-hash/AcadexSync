export type RealtimeAction =
  | 'CREATED'
  | 'UPDATED'
  | 'DELETED'
  | 'STATUS_CHANGED'
  | 'PUBLISHED'
  | 'UNPUBLISHED'
  | 'ARCHIVED'
  | 'LOCKED'
  | 'CLOSED'
  | 'BATCH_UPDATED'
  | 'READ'
  | 'SUBMITTED'
  | 'REVIEWED'
  | 'OPENED'
  | 'COMPLETED'
  | 'CANCELLED';

export type EventScopeType = 'college' | 'department' | 'user' | 'role' | 'channel';

export interface EventScope {
  type: EventScopeType;
  collegeId: string;
  departmentId?: string;
  userId?: string;
  role?: string;
  channel?: string;
}

export interface RealtimeEventEnvelope<T = Record<string, unknown>> {
  eventId: string;
  eventVersion: number;
  eventType: string;
  aggregateType: string;
  aggregateId: string;
  action: RealtimeAction;
  occurredAt: string; // ISO 8601
  collegeId: string;
  scope: EventScope;
  payload: T;
}

export type ClientInboundAction = 'authenticate' | 'subscribe' | 'unsubscribe' | 'ping';

export interface ClientInboundMessage {
  action: ClientInboundAction;
  token?: string;
  channel?: string;
  requestId?: string;
}

export type ServerOutboundType =
  | 'authenticated'
  | 'subscribed'
  | 'unsubscribed'
  | 'event'
  | 'pong'
  | 'error';

export interface ServerOutboundMessage<T = unknown> {
  type: ServerOutboundType;
  requestId?: string;
  success?: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}
