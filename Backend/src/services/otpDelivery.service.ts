import { OtpPurpose, OtpDeliveryMethod } from '../constants/status';
import { Logger } from '../utils/logger';

export interface SendOtpOptions {
  destination: string;
  otp: string;
  purpose: OtpPurpose;
  deliveryMethod: OtpDeliveryMethod;
}

export interface IOtpDeliveryAdapter {
  sendOtp(options: SendOtpOptions): Promise<boolean>;
}

/**
 * In-Memory Testing & Development OTP Delivery Adapter
 * Stores the last delivered OTP in-memory for unit/integration testing
 * without logging or exposing secrets in production.
 */
export class DevOtpDeliveryAdapter implements IOtpDeliveryAdapter {
  private lastDelivered: Map<string, string> = new Map();

  async sendOtp(options: SendOtpOptions): Promise<boolean> {
    this.lastDelivered.set(options.destination, options.otp);
    if (process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test') {
      Logger.info(
        `[DEV OTP DELIVERY] OTP sent to ${options.destination} via ${options.deliveryMethod} for ${options.purpose}`
      );
    }
    return true;
  }

  getLastOtp(destination: string): string | undefined {
    return this.lastDelivered.get(destination);
  }

  clear(): void {
    this.lastDelivered.clear();
  }
}

import { EmailService } from './email.service';

/**
 * Production Resend Email Delivery Adapter
 */
export class EmailDeliveryAdapter implements IOtpDeliveryAdapter {
  async sendOtp(options: SendOtpOptions): Promise<boolean> {
    if (!EmailService.isConfigured()) {
      Logger.error('[EMAIL OTP] Delivery failed: Email service is not configured (RESEND_API_KEY is missing).');
      return false;
    }

    const result = await EmailService.sendOtpEmail({
      to: options.destination,
      otp: options.otp,
      purpose: options.purpose,
    });

    return result.success;
  }
}

/**
 * Production SMS Delivery Adapter placeholder
 */
export class SmsDeliveryAdapter implements IOtpDeliveryAdapter {
  async sendOtp(options: SendOtpOptions): Promise<boolean> {
    Logger.info(`[SMS OTP] Sending OTP to ${Logger.maskEmail(options.destination)}`);
    // Future integration: Twilio / AWS SNS / MSG91
    return true;
  }
}

import { ApiError } from '../utils/apiError';

export class OtpDeliveryService {
  private static adapter: IOtpDeliveryAdapter = new DevOtpDeliveryAdapter();

  static setAdapter(newAdapter: IOtpDeliveryAdapter): void {
    this.adapter = newAdapter;
  }

  static getAdapter(): IOtpDeliveryAdapter {
    return this.adapter;
  }

  static isConfigured(deliveryMethod: OtpDeliveryMethod): boolean {
    if (this.adapter instanceof DevOtpDeliveryAdapter) {
      // In production, placeholder development adapter is strictly rejected
      return process.env.NODE_ENV !== 'production';
    }

    if (this.adapter instanceof EmailDeliveryAdapter) {
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
      throw ApiError.internal(
        `Contact delivery service for ${deliveryMethod} is not configured in this environment. Please contact your campus administrator.`
      );
    }
  }

  static async sendOtp(options: SendOtpOptions): Promise<boolean> {
    this.assertConfigured(options.deliveryMethod);
    return this.adapter.sendOtp(options);
  }
}

