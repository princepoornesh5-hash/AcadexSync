import { EventEmitter } from 'events';
import { IRequest } from '../models/request.model';
import { RequestStatus } from '../constants/request.constants';

export enum RequestEventType {
  REQUEST_CREATED = 'REQUEST_CREATED',
  REQUEST_SUBMITTED = 'REQUEST_SUBMITTED',
  REQUEST_RECEIVED = 'REQUEST_RECEIVED',
  REQUEST_STATUS_CHANGED = 'REQUEST_STATUS_CHANGED',
  REQUEST_RESPONDED = 'REQUEST_RESPONDED',
  REQUEST_CANCELLED = 'REQUEST_CANCELLED',
}

export interface RequestEventPayload {
  request: IRequest;
  previousStatus?: RequestStatus;
  newStatus?: RequestStatus;
  timestamp: Date;
}

class RequestEventBus extends EventEmitter {
  emitCreated(request: IRequest): void {
    this.emit(RequestEventType.REQUEST_CREATED, {
      request,
      newStatus: request.status,
      timestamp: new Date(),
    } as RequestEventPayload);
  }

  emitSubmitted(request: IRequest): void {
    this.emit(RequestEventType.REQUEST_SUBMITTED, {
      request,
      newStatus: request.status,
      timestamp: new Date(),
    } as RequestEventPayload);
  }

  emitReceived(request: IRequest): void {
    this.emit(RequestEventType.REQUEST_RECEIVED, {
      request,
      newStatus: RequestStatus.RECEIVED,
      timestamp: new Date(),
    } as RequestEventPayload);
  }

  emitStatusChanged(request: IRequest, previousStatus: RequestStatus, newStatus: RequestStatus): void {
    this.emit(RequestEventType.REQUEST_STATUS_CHANGED, {
      request,
      previousStatus,
      newStatus,
      timestamp: new Date(),
    } as RequestEventPayload);
  }

  emitResponded(request: IRequest): void {
    this.emit(RequestEventType.REQUEST_RESPONDED, {
      request,
      newStatus: request.status,
      timestamp: new Date(),
    } as RequestEventPayload);
  }

  emitCancelled(request: IRequest): void {
    this.emit(RequestEventType.REQUEST_CANCELLED, {
      request,
      newStatus: RequestStatus.CANCELLED,
      timestamp: new Date(),
    } as RequestEventPayload);
  }
}

export const requestEvents = new RequestEventBus();
