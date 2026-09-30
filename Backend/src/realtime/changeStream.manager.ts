import mongoose from 'mongoose';
import { realtimeEventBus } from './realtimeEventBus';
import { AcadexEventType } from './contracts/eventRegistry';
import { RealtimeAction } from './contracts/eventEnvelope';
import { Logger } from '../utils/logger';

export class ChangeStreamManager {
  private static instance: ChangeStreamManager;
  private streams: any[] = [];
  private isWatching = false;
  private resumeTokens: Map<string, any> = new Map();

  // Deduplication cache: eventKey -> timestamp (kept for 15 seconds)
  private emittedKeys: Map<string, number> = new Map();

  private constructor() {
    // Periodically prune deduplication cache
    setInterval(() => {
      const now = Date.now();
      for (const [key, ts] of this.emittedKeys.entries()) {
        if (now - ts > 15000) {
          this.emittedKeys.delete(key);
        }
      }
    }, 10000);
  }

  public static getInstance(): ChangeStreamManager {
    if (!ChangeStreamManager.instance) {
      ChangeStreamManager.instance = new ChangeStreamManager();
    }
    return ChangeStreamManager.instance;
  }

  /**
   * Initializes Change Streams on supported MongoDB replica set deployments (e.g., MongoDB Atlas).
   * Safely degrades if MongoDB is standalone or in-memory test environment.
   */
  public async initialize(): Promise<boolean> {
    if (this.isWatching) {
      return true;
    }

    if (mongoose.connection.readyState !== 1) {
      Logger.warn('[ChangeStream] MongoDB not connected yet. Deferring Change Streams initialization.');
      return false;
    }

    try {
      // Test if current deployment supports change streams
      const isReplicaSet = await this.checkReplicaSetSupport();
      if (!isReplicaSet) {
        Logger.info(
          '[ChangeStream] MongoDB is running in standalone mode (no replica set). Realtime will operate via direct persistence-first service event emissions.'
        );
        return false;
      }

      this.setupTargetedWatchers();
      this.isWatching = true;
      Logger.info('[ChangeStream] MongoDB Change Streams successfully initialized on targeted collections.');
      return true;
    } catch (err: any) {
      Logger.warn(
        `[ChangeStream] MongoDB Change Streams not available (${err?.message}). Operating with direct persistence-first domain events.`
      );
      return false;
    }
  }

  private async checkReplicaSetSupport(): Promise<boolean> {
    try {
      const db = mongoose.connection.db;
      if (!db) return false;

      const hello = await db.command({ hello: 1 });
      return Boolean(hello.setName || hello.isreplicaset || hello.msg === 'isdbgrid');
    } catch {
      return false;
    }
  }

  private setupTargetedWatchers(): void {
    // 1. Notification Collection
    this.watchCollection('notifications', (change) => {
      const doc = change.fullDocument || (change as any).documentKey;
      if (!doc) return;

      const docId = (change.documentKey?._id || doc._id)?.toString();
      const action: RealtimeAction =
        change.operationType === 'insert'
          ? 'CREATED'
          : change.operationType === 'update'
          ? 'UPDATED'
          : 'DELETED';

      const eventKey = `notification:${docId}:${action}`;
      if (this.isDuplicate(eventKey)) return;

      if (action === 'CREATED' && doc.recipientUserId) {
        realtimeEventBus.publish({
          eventType: AcadexEventType.NOTIFICATION_CREATED,
          aggregateType: 'Notification',
          aggregateId: docId,
          action: 'CREATED',
          collegeId: doc.collegeId?.toString() || 'global',
          scope: {
            type: 'user',
            collegeId: doc.collegeId?.toString() || 'global',
            userId: doc.recipientUserId?.toString(),
          },
          payload: {
            notificationId: docId,
            category: doc.category,
            title: doc.title,
          },
        });
      }
    });

    // 2. Announcements Collection
    this.watchCollection('announcements', (change) => {
      const doc = change.fullDocument || (change as any).documentKey;
      if (!doc) return;

      const docId = (change.documentKey?._id || doc._id)?.toString();
      const action: RealtimeAction = change.operationType === 'insert' ? 'CREATED' : 'UPDATED';

      const eventKey = `announcement:${docId}:${action}`;
      if (this.isDuplicate(eventKey)) return;

      const collegeId = doc.collegeId?.toString() || 'global';
      realtimeEventBus.publish({
        eventType:
          action === 'CREATED'
            ? AcadexEventType.ANNOUNCEMENT_CREATED
            : AcadexEventType.ANNOUNCEMENT_UPDATED,
        aggregateType: 'Announcement',
        aggregateId: docId,
        action,
        collegeId,
        scope: {
          type: doc.departmentId ? 'department' : 'college',
          collegeId,
          departmentId: doc.departmentId?.toString(),
        },
        payload: {
          announcementId: docId,
          title: doc.title,
        },
      });
    });

    // 3. Requests Collection
    this.watchCollection('requests', (change) => {
      const doc = change.fullDocument || (change as any).documentKey;
      if (!doc) return;

      const docId = (change.documentKey?._id || doc._id)?.toString();
      const action: RealtimeAction =
        change.operationType === 'insert'
          ? 'CREATED'
          : change.operationType === 'update'
          ? 'STATUS_CHANGED'
          : 'UPDATED';

      const eventKey = `request:${docId}:${action}`;
      if (this.isDuplicate(eventKey)) return;

      const collegeId = doc.collegeId?.toString() || 'global';
      realtimeEventBus.publish({
        eventType:
          action === 'CREATED'
            ? AcadexEventType.REQUEST_CREATED
            : AcadexEventType.REQUEST_STATUS_CHANGED,
        aggregateType: 'Request',
        aggregateId: docId,
        action,
        collegeId,
        scope: {
          type: 'user',
          collegeId,
          userId: doc.userId?.toString(),
          departmentId: doc.departmentId?.toString(),
        },
        payload: {
          requestId: docId,
          status: doc.status,
          requestType: doc.requestType,
        },
      });
    });

    // 4. Timetables Collection
    this.watchCollection('timetables', (change) => {
      const doc = change.fullDocument || (change as any).documentKey;
      if (!doc) return;

      const docId = (change.documentKey?._id || doc._id)?.toString();
      const action: RealtimeAction =
        change.operationType === 'insert'
          ? 'CREATED'
          : change.operationType === 'delete'
          ? 'ARCHIVED'
          : 'UPDATED';

      const eventKey = `timetable:${docId}:${action}`;
      if (this.isDuplicate(eventKey)) return;

      const collegeId = doc.collegeId?.toString() || 'global';
      realtimeEventBus.publish({
        eventType:
          action === 'CREATED'
            ? AcadexEventType.TIMETABLE_CREATED
            : action === 'ARCHIVED'
            ? AcadexEventType.TIMETABLE_ARCHIVED
            : AcadexEventType.TIMETABLE_UPDATED,
        aggregateType: 'Timetable',
        aggregateId: docId,
        action,
        collegeId,
        scope: {
          type: 'college',
          collegeId,
          departmentId: doc.departmentId?.toString(),
        },
        payload: {
          timetableId: docId,
          departmentId: doc.departmentId?.toString(),
        },
      });
    });

    // 5. Attendance Sessions Collection
    this.watchCollection('attendancesessions', (change) => {
      const doc = change.fullDocument || (change as any).documentKey;
      if (!doc) return;

      const docId = (change.documentKey?._id || doc._id)?.toString();
      const action: RealtimeAction =
        change.operationType === 'insert'
          ? 'CREATED'
          : doc.isLocked
          ? 'LOCKED'
          : doc.status === 'COMPLETED'
          ? 'CLOSED'
          : 'UPDATED';

      const eventKey = `attendance:${docId}:${action}`;
      if (this.isDuplicate(eventKey)) return;

      const collegeId = doc.collegeId?.toString() || 'global';
      realtimeEventBus.publish({
        eventType:
          action === 'CREATED'
            ? AcadexEventType.ATTENDANCE_SESSION_CREATED
            : action === 'LOCKED'
            ? AcadexEventType.ATTENDANCE_LOCKED
            : AcadexEventType.ATTENDANCE_SESSION_UPDATED,
        aggregateType: 'AttendanceSession',
        aggregateId: docId,
        action,
        collegeId,
        scope: {
          type: 'department',
          collegeId,
          departmentId: doc.departmentId?.toString(),
        },
        payload: {
          sessionId: docId,
          facultyId: doc.facultyId?.toString(),
          sectionId: doc.sectionId?.toString(),
        },
      });
    });
  }

  private watchCollection(
    collectionName: string,
    handler: (change: any) => void
  ): void {
    try {
      const collection = mongoose.connection.collection(collectionName);
      const resumeToken = this.resumeTokens.get(collectionName);

      const stream = collection.watch([], {
        fullDocument: 'updateLookup',
        resumeAfter: resumeToken,
      });

      stream.on('change', (change: any) => {
        if (change._id) {
          this.resumeTokens.set(collectionName, change._id);
        }
        try {
          handler(change);
        } catch (handlerErr) {
          Logger.error(`[ChangeStream] Error handling change in ${collectionName}`, handlerErr);
        }
      });

      stream.on('error', (streamErr) => {
        Logger.warn(`[ChangeStream] Stream error in ${collectionName}: ${streamErr?.message}`);
      });

      this.streams.push(stream);
    } catch (err: any) {
      Logger.warn(`[ChangeStream] Could not watch collection ${collectionName}: ${err?.message}`);
    }
  }

  private isDuplicate(key: string): boolean {
    const now = Date.now();
    const existing = this.emittedKeys.get(key);
    if (existing && now - existing < 3000) {
      return true;
    }
    this.emittedKeys.set(key, now);
    return false;
  }

  public async close(): Promise<void> {
    for (const s of this.streams) {
      try {
        await s.close();
      } catch (_) {}
    }
    this.streams = [];
    this.isWatching = false;
  }
}

export const changeStreamManager = ChangeStreamManager.getInstance();
