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
  sessionId?: string;
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
    if (identity.collegeId && identity.collegeId !== 'global' && identity.collegeId !== 'unassigned') {
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
   * Rebinds an authenticated socket to a new active workspace context without disconnecting.
   * Cleans up old institutional rooms and joins new workspace rooms while preserving personal room.
   */
  public rebindWorkspace(ws: WebSocket, updatedIdentity: ConnectionIdentity): string[] {
    const currentRooms = this.getRoomsForSocket(ws);
    for (const room of currentRooms) {
      if (
        room.startsWith('college:') ||
        room.startsWith('role:') ||
        room.startsWith('department:') ||
        room.startsWith('section:')
      ) {
        this.leaveRoom(ws, room);
      }
    }

    this.socketIdentities.set(ws, updatedIdentity);

    const newBaseRooms = this.deriveBaseRooms(updatedIdentity);
    for (const room of newBaseRooms) {
      this.joinRoom(ws, room);
    }

    Logger.info(
      `[Realtime] Rebound live socket for user ${updatedIdentity.userId} to workspace ${updatedIdentity.collegeId} (Role: ${updatedIdentity.role}). Active rooms: ${newBaseRooms.length}`
    );

    return newBaseRooms;
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
   * Immediately revokes all institutional room access for a user in a specified workspace.
   * Cleans up all college, role, department, and section rooms while preserving the personal user room.
   */
  public revokeWorkspaceForUser(
    userId: string,
    collegeId: string,
    reason = 'Membership revoked or suspended'
  ): { removedRooms: string[]; affectedSockets: number } {
    const removedRooms: string[] = [];
    let affectedSockets = 0;

    for (const [ws, identity] of this.socketIdentities.entries()) {
      if (identity.userId === userId && identity.collegeId === collegeId) {
        affectedSockets++;
        const currentRooms = this.getRoomsForSocket(ws);
        for (const room of currentRooms) {
          if (
            room.startsWith(`college:${collegeId}`) ||
            room.startsWith(`role:${collegeId}:`) ||
            room.startsWith(`department:${collegeId}:`) ||
            room.startsWith(`section:${collegeId}:`)
          ) {
            this.leaveRoom(ws, room);
            if (!removedRooms.includes(room)) {
              removedRooms.push(room);
            }
          }
        }

        identity.collegeId = 'unassigned';
        identity.departmentId = undefined;
        identity.sectionId = undefined;

        if (ws.readyState === WebSocket.OPEN) {
          const message: ServerOutboundMessage = {
            type: 'workspace_revoked',
            success: false,
            error: {
              code: 'WORKSPACE_REVOKED',
              message: `Institutional access to workspace ${collegeId} has been revoked: ${reason}`,
            },
            data: { collegeId, reason },
          };
          try {
            ws.send(JSON.stringify(message));
          } catch (err) {
            Logger.error(`[Realtime] Failed to send workspace_revoked to user ${userId}`, err);
          }
        }
      }
    }

    Logger.info(
      `[Realtime Security] Revoked workspace ${collegeId} for user ${userId}. Affected sockets: ${affectedSockets}, rooms removed: ${removedRooms.length}`
    );

    return { removedRooms, affectedSockets };
  }

  /**
   * Revalidates effective roles and department scopes for a user in a college,
   * removing unauthorized rooms and updating connection identity.
   */
  public async revalidateUserAuthorization(userId: string, collegeId: string): Promise<void> {
    const { WorkspaceMembership } = await import('../models/workspaceMembership.model');
    const { WorkspaceRoleAssignment } = await import('../models/workspaceRoleAssignment.model');
    const { MembershipStatus, RoleAssignmentStatus } = await import('../constants/status');
    const { ROLE_HIERARCHY, AppRole } = await import('../constants/roles');

    for (const [ws, identity] of this.socketIdentities.entries()) {
      if (identity.userId === userId) {
        if (identity.role === AppRole.SUPER_ADMIN) {
          continue;
        }

        if (identity.collegeId !== collegeId && identity.collegeId !== 'unassigned') {
          continue;
        }

        const mem = await WorkspaceMembership.findOne({
          userId,
          collegeId,
          status: MembershipStatus.ACTIVE,
        });

        if (!mem) {
          if (identity.collegeId === collegeId) {
            this.revokeWorkspaceForUser(userId, collegeId, 'Membership is no longer active');
          }
          continue;
        }

        const roleAssignments = await WorkspaceRoleAssignment.find({
          membershipId: mem._id,
          status: RoleAssignmentStatus.ACTIVE,
        });

        if (roleAssignments.length === 0) {
          this.revokeWorkspaceForUser(userId, collegeId, 'No active roles remaining');
          continue;
        }

        const activeRoles = roleAssignments.map((ra) => ra.role);
        const authorizedDeptIds = roleAssignments
          .map((ra) => ra.departmentId?.toString())
          .filter(Boolean) as string[];

        let primaryRole = activeRoles[0];
        let maxWeight = ROLE_HIERARCHY[primaryRole] ?? 0;
        for (const r of activeRoles) {
          const w = ROLE_HIERARCHY[r] ?? 0;
          if (w > maxWeight) {
            maxWeight = w;
            primaryRole = r;
          }
        }

        identity.collegeId = collegeId;
        identity.role = primaryRole;
        identity.departmentId = authorizedDeptIds[0] || undefined;

        // Prune rooms that are no longer authorized
        const currentRooms = this.getRoomsForSocket(ws);
        for (const room of currentRooms) {
          if (room.startsWith(`role:${collegeId}:`)) {
            const roomRole = room.split(':')[2];
            if (!activeRoles.includes(roomRole as any)) {
              this.leaveRoom(ws, room);
            }
          } else if (room.startsWith(`department:${collegeId}:`)) {
            const roomDeptId = room.split(':')[2];
            if (!authorizedDeptIds.includes(roomDeptId)) {
              this.leaveRoom(ws, room);
            }
          }
        }

        // Join authorized rooms
        const desiredRooms = this.deriveBaseRooms(identity);
        for (const room of desiredRooms) {
          this.joinRoom(ws, room);
        }

        if (ws.readyState === WebSocket.OPEN) {
          const message: ServerOutboundMessage = {
            type: 'roles_updated',
            success: true,
            data: {
              collegeId,
              role: primaryRole,
              activeRoles,
              departmentId: identity.departmentId,
              rooms: this.getRoomsForSocket(ws),
            },
          };
          try {
            ws.send(JSON.stringify(message));
          } catch (_) {}
        }
      }
    }
  }

  /**
   * Revokes a specific authenticated session and closes its associated socket.
   */
  public revokeSession(sessionId: string): number {
    let closedCount = 0;
    for (const [ws, identity] of this.socketIdentities.entries()) {
      if (identity.sessionId === sessionId) {
        closedCount++;
        Logger.info(`[Realtime Security] Closing socket for revoked sessionId: ${sessionId}`);
        if (ws.readyState === WebSocket.OPEN) {
          const message: ServerOutboundMessage = {
            type: 'error',
            success: false,
            error: {
              code: 'SESSION_REVOKED',
              message: 'Authentication session has been revoked',
            },
          };
          try {
            ws.send(JSON.stringify(message));
          } catch (_) {}
          ws.close(4401, 'Session revoked');
        }
        this.removeSocket(ws);
      }
    }
    return closedCount;
  }

  /**
   * Revokes all active sockets for a specific user.
   */
  public revokeAllUserSockets(userId: string, reason = 'All sessions revoked'): number {
    let closedCount = 0;
    for (const [ws, identity] of this.socketIdentities.entries()) {
      if (identity.userId === userId) {
        closedCount++;
        Logger.info(`[Realtime Security] Closing socket for user ${userId} (${reason})`);
        if (ws.readyState === WebSocket.OPEN) {
          const message: ServerOutboundMessage = {
            type: 'error',
            success: false,
            error: {
              code: 'SESSION_REVOKED',
              message: reason,
            },
          };
          try {
            ws.send(JSON.stringify(message));
          } catch (_) {}
          ws.close(4401, reason);
        }
        this.removeSocket(ws);
      }
    }
    return closedCount;
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
