import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getMessaging, MulticastMessage, BatchResponse } from 'firebase-admin/messaging';
import { env } from '../config/env';
import { Logger } from '../utils/logger';

export interface PushNotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
  imageUrl?: string;
}

export interface PushDeliveryResult {
  successfulCount: number;
  failureCount: number;
  invalidTokens: string[];
}

export class FcmService {
  private static appInstance: App | null = null;
  private static mockMessagingClient: any = null;

  /**
   * For unit & integration testing to inject mock Firebase Messaging
   */
  static setMockMessagingForTesting(mock: any): void {
    this.mockMessagingClient = mock;
  }

  /**
   * Initializes Firebase Admin SDK singleton with service account credentials from env
   */
  private static ensureInitialized(): boolean {
    if (this.mockMessagingClient) return true;
    if (this.appInstance) return true;

    try {
      const existingApps = getApps();
      if (existingApps.length > 0) {
        this.appInstance = existingApps[0];
        return true;
      }

      if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_CLIENT_EMAIL || !env.FIREBASE_PRIVATE_KEY) {
        Logger.warn('Firebase Admin credentials not fully configured in env; push delivery disabled in this environment.');
        return false;
      }

      const formattedPrivateKey = env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');

      this.appInstance = initializeApp({
        credential: cert({
          projectId: env.FIREBASE_PROJECT_ID,
          clientEmail: env.FIREBASE_CLIENT_EMAIL,
          privateKey: formattedPrivateKey,
        }),
      });

      Logger.info('Firebase Admin SDK initialized successfully');
      return true;
    } catch (error) {
      Logger.error('Failed to initialize Firebase Admin SDK', error as Error);
      return false;
    }
  }

  /**
   * Sends FCM push notification to a list of device tokens
   */
  static async sendMulticast(
    tokens: string[],
    payload: PushNotificationPayload
  ): Promise<PushDeliveryResult> {
    if (!tokens || tokens.length === 0) {
      return { successfulCount: 0, failureCount: 0, invalidTokens: [] };
    }

    // Use mock client if injected during testing
    if (this.mockMessagingClient) {
      return await this.mockMessagingClient.sendMulticast(tokens, payload);
    }

    const ready = this.ensureInitialized();
    if (!ready || !this.appInstance) {
      return {
        successfulCount: 0,
        failureCount: tokens.length,
        invalidTokens: [],
      };
    }

    const invalidTokens: string[] = [];
    let successfulCount = 0;
    let failureCount = 0;

    try {
      const message: MulticastMessage = {
        tokens,
        notification: {
          title: payload.title,
          body: payload.body,
          imageUrl: payload.imageUrl,
        },
        data: payload.data ?? {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const messaging = getMessaging(this.appInstance);
      const response: BatchResponse = await messaging.sendEachForMulticast(message);

      response.responses.forEach((resp, index) => {
        if (resp.success) {
          successfulCount++;
        } else {
          failureCount++;
          const errorCode = resp.error?.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered'
          ) {
            invalidTokens.push(tokens[index]);
          }
          Logger.warn(`FCM delivery failed for token prefix ${tokens[index].substring(0, 10)}...: ${resp.error?.message}`);
        }
      });
    } catch (error) {
      Logger.error('Error during FCM multicast execution', error as Error);
      failureCount = tokens.length;
    }

    return {
      successfulCount,
      failureCount,
      invalidTokens,
    };
  }
}
