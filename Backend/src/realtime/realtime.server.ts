import http from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import url from 'url';
import mongoose from 'mongoose';
import { verifyJwtToken } from '../utils/token';
import { TokenType, AccountStatus } from '../constants/status';
import { User } from '../models/user.model';
import { AuthSession } from '../models/authSession.model';
import { RoomManager, ConnectionIdentity } from './roomManager';
import { ScopeResolver } from './scopeResolver';
import { ClientInboundMessage, ServerOutboundMessage } from './contracts/eventEnvelope';
import { Logger } from '../utils/logger';

interface ExtWebSocket extends WebSocket {
  isAlive: boolean;
  authTimeoutTimer?: NodeJS.Timeout;
}

export class RealtimeServer {
  private static instance: RealtimeServer;
  private wss: WebSocketServer | null = null;
  private heartbeatInterval: NodeJS.Timeout | null = null;
  private roomManager = RoomManager.getInstance();

  private constructor() {}

  public static getInstance(): RealtimeServer {
    if (!RealtimeServer.instance) {
      RealtimeServer.instance = new RealtimeServer();
    }
    return RealtimeServer.instance;
  }

  /**
   * Initializes WebSocket server mounted on existing HTTP server.
   */
  public attachToServer(server: http.Server, wsPath = '/ws'): WebSocketServer {
    if (this.wss) {
      return this.wss;
    }

    this.wss = new WebSocketServer({
      server,
      path: wsPath,
      // Verify origin or basic limits if desired
      maxPayload: 64 * 1024, // 64KB max payload per message to prevent memory exhaustion
    });

    Logger.info(`[Realtime] WebSocket server attached at path: ${wsPath}`);

    this.wss.on('connection', (ws: WebSocket, req: http.IncomingMessage) => {
      this.handleConnection(ws as ExtWebSocket, req);
    });

    this.setupHeartbeat();

    return this.wss;
  }

  /**
   * Directly attaches a standalone WebSocketServer (useful for unit tests).
   */
  public attachStandalone(options: { port?: number; server?: http.Server }): WebSocketServer {
    this.wss = new WebSocketServer(options);
    this.wss.on('connection', (ws: WebSocket, req: http.IncomingMessage) => {
      this.handleConnection(ws as ExtWebSocket, req);
    });
    this.setupHeartbeat();
    return this.wss;
  }

  private handleConnection(ws: ExtWebSocket, req: http.IncomingMessage): void {
    ws.isAlive = true;

    ws.on('pong', () => {
      ws.isAlive = true;
    });

    // Parse potential token from query string: ?token=...
    const parsedUrl = url.parse(req.url || '', true);
    const tokenFromQuery = parsedUrl.query.token as string | undefined;

    if (tokenFromQuery) {
      this.authenticateSocket(ws, tokenFromQuery).catch((err) => {
        Logger.warn('[Realtime] Query token authentication failed', err);
      });
    } else {
      // Allow 10 seconds for initial client auth message
      ws.authTimeoutTimer = setTimeout(() => {
        if (!this.roomManager.isAuthenticated(ws)) {
          Logger.warn('[Realtime] Unauthenticated socket timed out after 10s. Closing.');
          this.sendErrorMessage(ws, 'UNAUTHENTICATED_TIMEOUT', 'Authentication required within 10s');
          ws.close(4401, 'Authentication timeout');
        }
      }, 10000);
    }

    ws.on('message', async (data: Buffer | string) => {
      try {
        const raw = data.toString();
        const msg = JSON.parse(raw) as ClientInboundMessage;
        await this.handleClientMessage(ws, msg);
      } catch (err: any) {
        Logger.warn('[Realtime] Malformed message received from client', err?.message);
        this.sendErrorMessage(ws, 'INVALID_PAYLOAD', 'Message must be valid JSON');
      }
    });

    ws.on('close', (_code, _reason) => {
      if (ws.authTimeoutTimer) {
        clearTimeout(ws.authTimeoutTimer);
      }
      this.roomManager.removeSocket(ws);
    });

    ws.on('error', (err) => {
      Logger.error('[Realtime] WebSocket error occurred', err);
      if (ws.authTimeoutTimer) {
        clearTimeout(ws.authTimeoutTimer);
      }
      this.roomManager.removeSocket(ws);
    });
  }

  private async handleClientMessage(ws: ExtWebSocket, msg: ClientInboundMessage): Promise<void> {
    switch (msg.action) {
      case 'ping': {
        this.sendSuccessResponse(ws, 'pong', { timestamp: Date.now() }, msg.requestId);
        break;
      }

      case 'authenticate': {
        if (!msg.token) {
          this.sendErrorMessage(ws, 'MISSING_TOKEN', 'Token is required', msg.requestId);
          return;
        }
        await this.authenticateSocket(ws, msg.token, msg.requestId);
        break;
      }

      case 'subscribe': {
        if (!this.roomManager.isAuthenticated(ws)) {
          this.sendErrorMessage(ws, 'UNAUTHORIZED', 'Authentication required to subscribe', msg.requestId);
          return;
        }
        if (!msg.channel) {
          this.sendErrorMessage(ws, 'MISSING_CHANNEL', 'Channel is required', msg.requestId);
          return;
        }

        const identity = this.roomManager.getIdentity(ws)!;
        const authResult = ScopeResolver.authorizeSubscription(identity, msg.channel);

        if (!authResult.allowed || !authResult.normalizedChannel) {
          Logger.warn(
            `[Realtime Security] User ${identity.userId} rejected from channel ${msg.channel}: ${authResult.reason}`
          );
          this.sendErrorMessage(
            ws,
            'FORBIDDEN_CHANNEL',
            authResult.reason || 'Subscription to channel forbidden',
            msg.requestId
          );
          return;
        }

        this.roomManager.joinRoom(ws, authResult.normalizedChannel);
        this.sendSuccessResponse(
          ws,
          'subscribed',
          { channel: authResult.normalizedChannel },
          msg.requestId
        );
        break;
      }

      case 'unsubscribe': {
        if (!this.roomManager.isAuthenticated(ws)) {
          return;
        }
        if (msg.channel) {
          this.roomManager.leaveRoom(ws, msg.channel);
          this.sendSuccessResponse(ws, 'unsubscribed', { channel: msg.channel }, msg.requestId);
        }
        break;
      }

      default:
        this.sendErrorMessage(ws, 'UNKNOWN_ACTION', `Action "${(msg as any).action}" not recognized`, msg.requestId);
    }
  }

  /**
   * Authenticates a WebSocket using the ACADEX JWT token.
   */
  public async authenticateSocket(
    ws: ExtWebSocket,
    token: string,
    requestId?: string
  ): Promise<boolean> {
    try {
      const payload = verifyJwtToken(token, TokenType.ACCESS);

      // Verify session revocation if sessionId is present
      if (payload.sessionId && mongoose.Types.ObjectId.isValid(payload.sessionId)) {
        const session = await AuthSession.findById(payload.sessionId);
        if (session && (session.revokedAt != null || session.isExpired())) {
          this.sendErrorMessage(
            ws,
            'SESSION_REVOKED',
            'Authentication session revoked. Please log in again.',
            requestId
          );
          ws.close(4401, 'Session revoked');
          return false;
        }
      }

      // Verify user in database and enforce ACTIVE status
      let userDoc: any = null;
      if (mongoose.Types.ObjectId.isValid(payload.userId)) {
        userDoc = await User.findById(payload.userId);
      }

      if (!userDoc) {
        this.sendErrorMessage(ws, 'USER_NOT_FOUND', 'User account does not exist', requestId);
        ws.close(4401, 'User not found');
        return false;
      }

      if (userDoc.accountStatus !== AccountStatus.ACTIVE) {
        this.sendErrorMessage(ws, 'ACCOUNT_INACTIVE', 'Account is not active', requestId);
        ws.close(4403, 'Account inactive');
        return false;
      }

      if (ws.authTimeoutTimer) {
        clearTimeout(ws.authTimeoutTimer);
        ws.authTimeoutTimer = undefined;
      }

      const identity: ConnectionIdentity = {
        userId: userDoc.id,
        role: userDoc.role,
        collegeId: userDoc.collegeId ? userDoc.collegeId.toString() : 'global',
        departmentId: userDoc.departmentId ? userDoc.departmentId.toString() : undefined,
        sectionId: userDoc.sectionId ? userDoc.sectionId.toString() : undefined,
        courseId: userDoc.courseId ? userDoc.courseId.toString() : undefined,
        semesterId: userDoc.semesterId ? userDoc.semesterId.toString() : undefined,
        email: userDoc.email || undefined,
        name: userDoc.name,
        connectedAt: new Date(),
      };

      const baseRooms = this.roomManager.registerAuthenticatedSocket(ws, identity);

      this.sendSuccessResponse(
        ws,
        'authenticated',
        {
          userId: identity.userId,
          role: identity.role,
          collegeId: identity.collegeId,
          departmentId: identity.departmentId,
          rooms: baseRooms,
        },
        requestId
      );

      return true;
    } catch (err: any) {
      Logger.warn('[Realtime] Socket token verification failed', err?.message);
      this.sendErrorMessage(
        ws,
        'UNAUTHORIZED',
        err?.message || 'Invalid or expired authentication token',
        requestId
      );
      ws.close(4401, 'Unauthorized');
      return false;
    }
  }

  private setupHeartbeat(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
    }

    // Ping every 30 seconds
    this.heartbeatInterval = setInterval(() => {
      if (!this.wss) return;

      this.wss.clients.forEach((client) => {
        const extWs = client as ExtWebSocket;
        if (!extWs.isAlive) {
          Logger.info('[Realtime] Terminating unresponsive socket.');
          this.roomManager.removeSocket(extWs);
          return extWs.terminate();
        }
        extWs.isAlive = false;
        extWs.ping();
      });
    }, 30000);
  }

  public sendSuccessResponse<T>(
    ws: WebSocket,
    type: ServerOutboundMessage['type'],
    data: T,
    requestId?: string
  ): void {
    if (ws.readyState === WebSocket.OPEN) {
      const msg: ServerOutboundMessage<T> = {
        type,
        requestId,
        success: true,
        data,
      };
      ws.send(JSON.stringify(msg));
    }
  }

  public sendErrorMessage(
    ws: WebSocket,
    code: string,
    message: string,
    requestId?: string
  ): void {
    if (ws.readyState === WebSocket.OPEN) {
      const msg: ServerOutboundMessage = {
        type: 'error',
        requestId,
        success: false,
        error: { code, message },
      };
      ws.send(JSON.stringify(msg));
    }
  }

  public async close(): Promise<void> {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
    }

    if (this.wss) {
      for (const client of this.wss.clients) {
        client.close(1001, 'Server shutting down');
      }
      await new Promise<void>((resolve) => {
        this.wss!.close(() => resolve());
      });
      this.wss = null;
    }
    this.roomManager.clear();
  }
}

export const realtimeServer = RealtimeServer.getInstance();
