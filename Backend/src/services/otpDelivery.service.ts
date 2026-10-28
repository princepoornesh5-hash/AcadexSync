import { OtpPurpose, OtpDeliveryMethod } from '../constants/status';
import { Logger } from '../utils/logger';
import { ApiError } from '../utils/apiError';
import { EmailService } from './email.service';

export interface SendOtpOptions {
  destination: string;
  otp: string;
  purpose: OtpPurpose;
  deliveryMethod: OtpDeliveryMethod;
}

export interface OtpDeliveryResult {
  success: boolean;
  messageId?: string;
  error?: string;
  errorCode?: string;
  isProviderRejection?: boolean;
  isTimeout?: boolean;
  isConfigurationError?: boolean;
}

export interface IOtpDeliveryAdapter {
  sendOtp(options: SendOtpOptions): Promise<OtpDeliveryResult | boolean>;
}

/**
 * In-Memory Testing & Development OTP Delivery Adapter
 * Stores the last delivered OTP in-memory for unit/integration testing
 * without logging or exposing secrets in production.
 */
export class DevOtpDeliveryAdapter implements IOtpDeliveryAdapter {
  private lastDelivered: Map<string, string> = new Map();

  async sendOtp(options: SendOtpOptions): Promise<OtpDeliveryResult> {
    this.lastDelivered.set(options.destination, options.otp);
    if (process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test') {
      Logger.info(
        `[DEV OTP DELIVERY] OTP sent to ${options.destination} via ${options.deliveryMethod} for ${options.purpose}`
      );
    }
    return { success: true };
  }

  getLastOtp(destination: string): string | undefined {
    return this.lastDelivered.get(destination);
  }

  clear(): void {
    this.lastDelivered.clear();
  }
}

/**
 * Production Resend Email Delivery Adapter
 */
export class EmailDeliveryAdapter implements IOtpDeliveryAdapter {
  async sendOtp(options: SendOtpOptions): Promise<OtpDeliveryResult> {
    if (!EmailService.isConfigured()) {
      Logger.error('[EMAIL OTP] Delivery failed: Email service is not configured (RESEND_API_KEY is missing).');
      return {
        success: false,
        error: 'Email delivery service is not configured. RESEND_API_KEY is missing.',
        errorCode: 'PROVIDER_NOT_CONFIGURED',
        isConfigurationError: true,
      };
    }

    const result = await EmailService.sendOtpEmail({
      to: options.destination,
      otp: options.otp,
      purpose: options.purpose,
    });

    if (!result.success) {
      return {
        success: false,
        error: result.error,
        errorCode: result.errorCode,
        isProviderRejection: result.isProviderRejection ?? (result.errorCode === 'validation_error' || result.errorCode === 'PROVIDER_SANDBOX_RESTRICTION'),
        isTimeout: result.isTimeout ?? (result.errorCode === 'PROVIDER_TIMEOUT'),
        isConfigurationError: result.errorCode === 'PROVIDER_NOT_CONFIGURED',
      };
    }

    return {
      success: true,
      messageId: result.messageId,
    };
  }
}

/**
 * Production SMS Delivery Adapter placeholder
 */
export class SmsDeliveryAdapter implements IOtpDeliveryAdapter {
  async sendOtp(options: SendOtpOptions): Promise<OtpDeliveryResult> {
    Logger.info(`[SMS OTP] Sending OTP to ${Logger.maskEmail(options.destination)}`);
    // Future integration: Twilio / AWS SNS / MSG91
    return { success: true };
  }
}

export class OtpDeliveryService {
  private static customAdapter: IOtpDeliveryAdapter | null = null;
  private static defaultDevAdapter: DevOtpDeliveryAdapter = new DevOtpDeliveryAdapter();

  static setAdapter(newAdapter: IOtpDeliveryAdapter | null): void {
    this.customAdapter = newAdapter;
  }

  static getAdapter(): IOtpDeliveryAdapter {
    if (this.customAdapter) {
      return this.customAdapter;
    }
    // In test environment, default to DevOtpDeliveryAdapter so existing integration test suites can inspect and clear
    if (process.env.NODE_ENV === 'test') {
      return this.defaultDevAdapter;
    }
    if (EmailService.isConfigured()) {
      return new EmailDeliveryAdapter();
    }
    return this.defaultDevAdapter;
  }

  static isConfigured(deliveryMethod: OtpDeliveryMethod): boolean {
    const adapter = this.getAdapter();
    if (adapter instanceof DevOtpDeliveryAdapter) {
      // In production, placeholder development adapter is strictly rejected
      return process.env.NODE_ENV !== 'production';
    }

    if (adapter instanceof EmailDeliveryAdapter) {
      return EmailService.isConfigured();
    }

    if (process.env.NODE_ENV === 'production' && deliveryMethod === OtpDeliveryMethod.EMAIL) {
      return EmailService.isConfigured();
    }

    return true;
  }

  static assertConfigured(deliveryMethod: OtpDeliveryMethod): void {
    if (!this.isConfigured(deliveryMethod)) {
      Logger.error(
        `[OTP DELIVERY ERROR] Delivery provider for ${deliveryMethod} is not configured.`
      );
      throw ApiError.serviceUnavailable(
        `Contact delivery service for ${deliveryMethod} is not configured in this environment. Please contact your campus administrator.`,
        'DELIVERY_PROVIDER_UNCONFIGURED'
      );
    }
  }

  static async sendOtp(options: SendOtpOptions): Promise<OtpDeliveryResult | boolean> {
    this.assertConfigured(options.deliveryMethod);
    return this.getAdapter().sendOtp(options);
  }
}
