import { RoomManager, ConnectionIdentity } from '../../src/realtime/roomManager';
import { ScopeResolver } from '../../src/realtime/scopeResolver';
import { RealtimeEventBus } from '../../src/realtime/realtimeEventBus';
import { EVENT_REGISTRY, AcadexEventType } from '../../src/realtime/contracts/eventRegistry';
import { RealtimeEventEnvelope } from '../../src/realtime/contracts/eventEnvelope';
import { signJwtToken } from '../../src/utils/token';
import { RealtimeServer } from '../../src/realtime/realtime.server';
import { WebSocket } from 'ws';

describe('ACADEX Realtime Infrastructure & Security Test Suite', () => {
  let roomManager: RoomManager;
  let eventBus: RealtimeEventBus;

  beforeEach(() => {
    roomManager = RoomManager.getInstance();
    roomManager.clear();
    eventBus = RealtimeEventBus.getInstance();
  });

  // =========================================================================
  // 1. EVENT REGISTRY & ENVELOPE INTEGRITY
  // =========================================================================
  describe('Event Registry & Envelope Contracts', () => {
    it('E1: Validates that all defined event types have valid registry entries', () => {
      for (const eventType of Object.values(AcadexEventType)) {
        const def = EVENT_REGISTRY[eventType];
        expect(def).toBeDefined();
        expect(def.version).toBeGreaterThanOrEqual(1);
        expect(def.aggregateType).toBeTruthy();
        expect(def.allowedScopeTypes.length).toBeGreaterThan(0);
        expect(def.requiredPayloadKeys.length).toBeGreaterThan(0);
      }
    });

    it('E2: Normalizes event envelope with required standard properties and version', () => {
      const envelope = eventBus.publish({
        eventType: AcadexEventType.NOTIFICATION_CREATED,
        aggregateType: 'Notification',
        aggregateId: 'notif_123',
        action: 'CREATED',
        collegeId: 'college_alpha',
        scope: {
          type: 'user',
          collegeId: 'college_alpha',
          userId: 'user_456',
        },
        payload: {
          notificationId: 'notif_123',
          title: 'Class Cancelled',
        },
      });

      expect(envelope.eventId).toMatch(/^evt_/);
      expect(envelope.eventVersion).toBe(1);
      expect(envelope.eventType).toBe(AcadexEventType.NOTIFICATION_CREATED);
      expect(envelope.aggregateType).toBe('Notification');
      expect(envelope.aggregateId).toBe('notif_123');
      expect(envelope.action).toBe('CREATED');
      expect(envelope.occurredAt).toBeDefined();
      expect(envelope.collegeId).toBe('college_alpha');
      expect(envelope.scope.userId).toBe('user_456');
    });
  });

  // =========================================================================
  // 2. SUBSCRIPTION AUTHORIZATION & SCOPE RESOLUTION (SECURITY R4, R5, R6)
  // =========================================================================
  describe('ScopeResolver Authorization Boundaries', () => {
    const facultyIdentity: ConnectionIdentity = {
      userId: 'fac_100',
      role: 'FACULTY',
      collegeId: 'college_alpha',
      departmentId: 'dept_cs',
      connectedAt: new Date(),
    };

    const studentIdentity: ConnectionIdentity = {
      userId: 'stud_200',
      role: 'STUDENT',
      collegeId: 'college_alpha',
      departmentId: 'dept_cs',
      sectionId: 'sec_a',
      connectedAt: new Date(),
    };

    const hodIdentity: ConnectionIdentity = {
      userId: 'hod_300',
      role: 'HOD',
      collegeId: 'college_alpha',
      departmentId: 'dept_cs',
      connectedAt: new Date(),
    };

    it('R3: Cross-tenant college subscription is rejected', () => {
      const res = ScopeResolver.authorizeSubscription(facultyIdentity, 'college:college_beta');
      expect(res.allowed).toBe(false);
      expect(res.reason).toContain('Cross-tenant subscription forbidden');
    });

    it('R3: Own college subscription is permitted', () => {
      const res = ScopeResolver.authorizeSubscription(facultyIdentity, 'college:college_alpha');
      expect(res.allowed).toBe(true);
      expect(res.normalizedChannel).toBe('college:college_alpha');
    });

    it('R4: HOD Department A cannot subscribe to Department B scope', () => {
      const res = ScopeResolver.authorizeSubscription(
        hodIdentity,
        'department:college_alpha:dept_ee'
      );
      expect(res.allowed).toBe(false);
      expect(res.reason).toContain('Not authorized for this department scope');
    });

    it('R4: HOD Department A can subscribe to own Department A', () => {
      const res = ScopeResolver.authorizeSubscription(
        hodIdentity,
        'department:college_alpha:dept_cs'
      );
      expect(res.allowed).toBe(true);
    });

    it('R5: Faculty cannot subscribe to another Faculty private channel', () => {
      const res = ScopeResolver.authorizeSubscription(facultyIdentity, 'faculty:fac_999');
      expect(res.allowed).toBe(false);
      expect(res.reason).toContain('Cannot subscribe to faculty channel');
    });

    it('R5: Faculty can subscribe to own channel', () => {
      const res = ScopeResolver.authorizeSubscription(facultyIdentity, 'faculty:fac_100');
      expect(res.allowed).toBe(true);
    });

    it('R6: Student cannot subscribe to another Student private channel', () => {
      const res = ScopeResolver.authorizeSubscription(studentIdentity, 'student:stud_999');
      expect(res.allowed).toBe(false);
      expect(res.reason).toContain('Cannot subscribe to student channel');
    });

    it('R6: Student can subscribe to own channel', () => {
      const res = ScopeResolver.authorizeSubscription(studentIdentity, 'student:stud_200');
      expect(res.allowed).toBe(true);
    });

    it('R6: Cannot subscribe to another user private user channel', () => {
      const res = ScopeResolver.authorizeSubscription(studentIdentity, 'user:other_user');
      expect(res.allowed).toBe(false);
    });
  });

  // =========================================================================
  // 3. SERVER-SIDE TENANT ISOLATION (SECURITY R3, R7, R8, R9)
  // =========================================================================
  describe('RoomManager Multi-Tenant Event Filtering', () => {
    it('R3: College A event is NEVER delivered to College B client', () => {
      const mockWsA = {
        readyState: WebSocket.OPEN,
        send: jest.fn(),
      } as unknown as WebSocket;

      const mockWsB = {
        readyState: WebSocket.OPEN,
        send: jest.fn(),
      } as unknown as WebSocket;

      const identityA: ConnectionIdentity = {
        userId: 'user_a',
        role: 'COLLEGE_ADMIN',
        collegeId: 'college_alpha',
        connectedAt: new Date(),
      };

      const identityB: ConnectionIdentity = {
        userId: 'user_b',
        role: 'COLLEGE_ADMIN',
        collegeId: 'college_beta',
        connectedAt: new Date(),
      };

      roomManager.registerAuthenticatedSocket(mockWsA, identityA);
      roomManager.registerAuthenticatedSocket(mockWsB, identityB);

      // Force join a common shared room name to test server-side tenant filter guard
      roomManager.joinRoom(mockWsA, 'common_room');
      roomManager.joinRoom(mockWsB, 'common_room');

      const collegeAEvent: RealtimeEventEnvelope = {
        eventId: 'evt_001',
        eventVersion: 1,
        eventType: AcadexEventType.TIMETABLE_UPDATED,
        aggregateType: 'Timetable',
        aggregateId: 'tt_100',
        action: 'UPDATED',
        occurredAt: new Date().toISOString(),
        collegeId: 'college_alpha',
        scope: {
          type: 'college',
          collegeId: 'college_alpha',
        },
        payload: { timetableId: 'tt_100' },
      };

      const delivered = roomManager.broadcastToRoom('common_room', collegeAEvent);

      expect(delivered).toBe(1);
      expect((mockWsA.send as jest.Mock).mock.calls.length).toBe(1);
      expect((mockWsB.send as jest.Mock).mock.calls.length).toBe(0); // College B client received ZERO packets!
    });

    it('R10: Disconnect cleanup safely clears rooms and identity', () => {
      const mockWs = {
        readyState: WebSocket.OPEN,
        send: jest.fn(),
      } as unknown as WebSocket;

      const identity: ConnectionIdentity = {
        userId: 'temp_user',
        role: 'FACULTY',
        collegeId: 'college_alpha',
        connectedAt: new Date(),
      };

      const rooms = roomManager.registerAuthenticatedSocket(mockWs, identity);
      expect(rooms.length).toBeGreaterThan(0);
      expect(roomManager.isAuthenticated(mockWs)).toBe(true);

      roomManager.removeSocket(mockWs);

      expect(roomManager.isAuthenticated(mockWs)).toBe(false);
      expect(roomManager.getIdentity(mockWs)).toBeUndefined();
      expect(roomManager.getRoomsForSocket(mockWs).length).toBe(0);
    });
  });

  // =========================================================================
  // 5. WEBSOCKET AUTHENTICATION BOUNDARY (SECURITY R1, R2)
  // =========================================================================
  describe('RealtimeServer Authentication Boundary', () => {
    const realtimeServer = RealtimeServer.getInstance();

    it('R1: Rejects connection when authentication token is invalid or malformed', async () => {
      const mockWs: any = {
        readyState: WebSocket.OPEN,
        send: jest.fn(),
        close: jest.fn(),
      };

      const result = await realtimeServer.authenticateSocket(mockWs, 'invalid.malformed.token');
      expect(result).toBe(false);
      expect(mockWs.close).toHaveBeenCalledWith(4401, 'Unauthorized');
      expect(mockWs.send).toHaveBeenCalled();
      const sentPayload = JSON.parse(mockWs.send.mock.calls[0][0]);
      expect(sentPayload.type).toBe('error');
      expect(sentPayload.error.code).toBe('UNAUTHORIZED');
    });

    it('R2: Rejects connection when JWT token has expired', async () => {
      const expiredToken = signJwtToken(
        {
          userId: 'user_expired_123',
          role: 'STUDENT',
          tokenType: 'ACCESS',
        } as any,
        -60 // expired 60 seconds ago
      );

      const mockWs: any = {
        readyState: WebSocket.OPEN,
        send: jest.fn(),
        close: jest.fn(),
      };

      const result = await realtimeServer.authenticateSocket(mockWs, expiredToken);
      expect(result).toBe(false);
      expect(mockWs.close).toHaveBeenCalledWith(4401, 'Unauthorized');
      const sentPayload = JSON.parse(mockWs.send.mock.calls[0][0]);
      expect(sentPayload.error.code).toBe('UNAUTHORIZED');
      expect(sentPayload.error.message.toLowerCase()).toContain('expired');
    });
  });
});
