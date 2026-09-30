import { WebSocket } from 'ws';
import { RealtimeEventEnvelope, ServerOutboundMessage } from './contracts/eventEnvelope';
import { Logger } from '../utils/logger';

export interface ConnectionIdentity {
  userId: string;
  role: string;
  collegeId: string;
  departmentId?: string;
  sectionId?: string;
  courseId?: string;
  semesterId?: string;
  email?: string;
  name?: string;
  connectedAt: Date;
}

export class RoomManager {
  private static instance: RoomManager;

  // roomName -> Set of WebSockets
  private rooms: Map<string, Set<WebSocket>> = new Map();

  // WebSocket -> Set of roomNames
  private socketRooms: Map<WebSocket, Set<string>> = new Map();

  // WebSocket -> authenticated ConnectionIdentity
  private socketIdentities: Map<WebSocket, ConnectionIdentity> = new Map();

  private constructor() {}

  public static getInstance(): RoomManager {
    if (!RoomManager.instance) {
      RoomManager.instance = new RoomManager();
    }
    return RoomManager.instance;
  }

  /**
   * Registers an authenticated socket and joins its server-derived base rooms.
   */
  public registerAuthenticatedSocket(ws: WebSocket, identity: ConnectionIdentity): string[] {
    this.socketIdentities.set(ws, identity);

    const baseRooms = this.deriveBaseRooms(identity);
    for (const room of baseRooms) {
      this.joinRoom(ws, room);
    }

    Logger.info(
      `[Realtime] Socket authenticated for user ${identity.userId} (Role: ${identity.role}, College: ${identity.collegeId}). Joined ${baseRooms.length} base rooms.`
    );

    return baseRooms;
  }

  /**
   * Derives default server-authorized rooms for a connection identity.
   */
  public deriveBaseRooms(identity: ConnectionIdentity): string[] {
    const rooms: string[] = [];

    // 1. Private User Room (for personal notifications, direct requests)
    rooms.push(`user:${identity.userId}`);

    // 2. College Tenant Room
    if (identity.collegeId && identity.collegeId !== 'global') {
      rooms.push(`college:${identity.collegeId}`);

      // 3. College Role Room
      rooms.push(`role:${identity.collegeId}:${identity.role.toUpperCase()}`);

      // 4. Department Room if user is assigned to a department
      if (identity.departmentId) {
        rooms.push(`department:${identity.collegeId}:${identity.departmentId}`);
      }

      // 5. Section Room if student is enrolled in a section
      if (identity.sectionId) {
        rooms.push(`section:${identity.collegeId}:${identity.sectionId}`);
      }
    }

    // 6. Role-specific private channels
    if (identity.role.toUpperCase() === 'FACULTY') {
      rooms.push(`faculty:${identity.userId}`);
    } else if (identity.role.toUpperCase() === 'STUDENT') {
      rooms.push(`student:${identity.userId}`);
    } else if (identity.role.toUpperCase() === 'SUPER_ADMIN') {
      rooms.push('global:superadmin');
    }

    return rooms;
  }

  /**
   * Joins a room.
   */
  public joinRoom(ws: WebSocket, room: string): void {
    if (!this.rooms.has(room)) {
      this.rooms.set(room, new Set());
    }
    this.rooms.get(room)!.add(ws);

    if (!this.socketRooms.has(ws)) {
      this.socketRooms.set(ws, new Set());
    }
    this.socketRooms.get(ws)!.add(room);
  }

  /**
   * Leaves a room.
   */
  public leaveRoom(ws: WebSocket, room: string): void {
    const clients = this.rooms.get(room);
    if (clients) {
      clients.delete(ws);
      if (clients.size === 0) {
        this.rooms.delete(room);
      }
    }

    const rooms = this.socketRooms.get(ws);
    if (rooms) {
      rooms.delete(room);
    }
  }

  /**
   * Cleans up all state for a disconnected socket.
   */
  public removeSocket(ws: WebSocket): void {
    const rooms = this.socketRooms.get(ws);
    if (rooms) {
      for (const room of rooms) {
        const clients = this.rooms.get(room);
        if (clients) {
          clients.delete(ws);
          if (clients.size === 0) {
            this.rooms.delete(room);
          }
        }
      }
      this.socketRooms.delete(ws);
    }

    const identity = this.socketIdentities.get(ws);
    if (identity) {
      Logger.info(`[Realtime] Cleaned up socket for user ${identity.userId}`);
    }
    this.socketIdentities.delete(ws);
  }

  /**
   * Gets identity of a socket.
   */
  public getIdentity(ws: WebSocket): ConnectionIdentity | undefined {
    return this.socketIdentities.get(ws);
  }

  /**
   * Checks if socket is authenticated.
   */
  public isAuthenticated(ws: WebSocket): boolean {
    return this.socketIdentities.has(ws);
  }

  /**
   * Returns current active rooms for a socket.
   */
  public getRoomsForSocket(ws: WebSocket): string[] {
    const rooms = this.socketRooms.get(ws);
    return rooms ? Array.from(rooms) : [];
  }

  /**
   * Broadcasts a versioned event to one or more target rooms with tenant isolation.
   */
  public broadcastToRoom(room: string, event: RealtimeEventEnvelope): number {
    const clients = this.rooms.get(room);
    if (!clients || clients.size === 0) {
      return 0;
    }

    const message: ServerOutboundMessage<RealtimeEventEnvelope> = {
      type: 'event',
      data: event,
    };
    const serialized = JSON.stringify(message);
    let deliveredCount = 0;

    for (const ws of clients) {
      if (ws.readyState !== WebSocket.OPEN) {
        continue;
      }

      const identity = this.socketIdentities.get(ws);
      if (!identity) {
        // Drop unauthenticated socket
        continue;
      }

      // Mandatory Server-Side Tenant Isolation:
      // College A clients NEVER receive College B events!
      if (
        identity.role !== 'SUPER_ADMIN' &&
        event.collegeId &&
        event.collegeId !== 'global' &&
        identity.collegeId !== event.collegeId
      ) {
        Logger.warn(
          `[Realtime Security] Prevented cross-tenant event leak: Event College (${event.collegeId}) != User College (${identity.collegeId}) for user ${identity.userId}`
        );
        continue;
      }

      // Department scope isolation
      if (
        event.scope.type === 'department' &&
        event.scope.departmentId &&
        identity.role !== 'SUPER_ADMIN' &&
        identity.role !== 'COLLEGE_ADMIN'
      ) {
        if (identity.departmentId !== event.scope.departmentId) {
          continue;
        }
      }

      // Send serialized event
      try {
        ws.send(serialized);
        deliveredCount++;
      } catch (err) {
        Logger.error(`[Realtime] Failed to send event to user ${identity.userId}`, err);
      }
    }

    return deliveredCount;
  }

  /**
   * Broadcasts to a specific user by userId.
   */
  public broadcastToUser(userId: string, event: RealtimeEventEnvelope): number {
    return this.broadcastToRoom(`user:${userId}`, event);
  }

  /**
   * Gets stats for monitoring.
   */
  public getStats(): { totalSockets: number; totalRooms: number } {
    return {
      totalSockets: this.socketIdentities.size,
      totalRooms: this.rooms.size,
    };
  }

  /**
   * Clears all connections (for tests).
   */
  public clear(): void {
    this.rooms.clear();
    this.socketRooms.clear();
    this.socketIdentities.clear();
  }
}
