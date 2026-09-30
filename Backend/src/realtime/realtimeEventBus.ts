import { EventEmitter } from 'events';
import crypto from 'crypto';
import { RealtimeEventEnvelope } from './contracts/eventEnvelope';
import { EVENT_REGISTRY, AcadexEventType } from './contracts/eventRegistry';
import { RoomManager } from './roomManager';
import { ScopeResolver } from './scopeResolver';
import { Logger } from '../utils/logger';

export class RealtimeEventBus extends EventEmitter {
  private static instance: RealtimeEventBus;
  private roomManager = RoomManager.getInstance();

  private constructor() {
    super();
    this.setMaxListeners(100);
  }

  public static getInstance(): RealtimeEventBus {
    if (!RealtimeEventBus.instance) {
      RealtimeEventBus.instance = new RealtimeEventBus();
    }
    return RealtimeEventBus.instance;
  }

  /**
   * Publishes a versioned domain event to authorized realtime rooms.
   * MUST only be called after database persistence has succeeded!
   */
  public publish<T extends Record<string, unknown> = Record<string, unknown>>(
    event: Omit<RealtimeEventEnvelope<T>, 'eventId' | 'occurredAt' | 'eventVersion'> & {
      eventId?: string;
      occurredAt?: string;
      eventVersion?: number;
    }
  ): RealtimeEventEnvelope<T> {
    const eventType = event.eventType as AcadexEventType;
    const def = EVENT_REGISTRY[eventType];

    const version = event.eventVersion || def?.version || 1;
    const eventId = event.eventId || `evt_${Date.now()}_${crypto.randomBytes(6).toString('hex')}`;
    const occurredAt = event.occurredAt || new Date().toISOString();

    const normalizedEnvelope: RealtimeEventEnvelope<T> = {
      eventId,
      eventVersion: version,
      eventType: event.eventType,
      aggregateType: event.aggregateType,
      aggregateId: event.aggregateId,
      action: event.action,
      occurredAt,
      collegeId: event.collegeId,
      scope: event.scope,
      payload: event.payload as T,
    };

    // 1. Emit internal event on Node EventEmitter for in-process hooks
    this.emit(event.eventType, normalizedEnvelope);
    this.emit('*', normalizedEnvelope);

    // 2. Resolve target rooms
    const targetRooms = ScopeResolver.resolveTargetRooms(normalizedEnvelope as any);

    // 3. Broadcast to each target room via RoomManager
    let totalDelivered = 0;
    for (const room of targetRooms) {
      totalDelivered += this.roomManager.broadcastToRoom(room, normalizedEnvelope as any);
    }

    Logger.info(
      `[Realtime] Dispatched ${normalizedEnvelope.eventType} (${normalizedEnvelope.eventId}) -> rooms: [${targetRooms.join(', ')}], recipients: ${totalDelivered}`
    );

    return normalizedEnvelope;
  }
}

export const realtimeEventBus = RealtimeEventBus.getInstance();
