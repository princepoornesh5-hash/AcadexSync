import crypto from 'crypto';
import { Otp, IOtp } from '../models/otp.model';
import { OtpPurpose, OtpDeliveryMethod } from '../constants/status';
import { env } from '../config/env';
import { ApiError } from '../utils/apiError';
import { OtpDeliveryService } from './otpDelivery.service';
import mongoose from 'mongoose';

export class OtpService {
  /**
   * Cryptographically secure 6-digit OTP generator
   */
  static generateOtpCode(length = 6): string {
    const min = Math.pow(10, length - 1);
    const max = Math.pow(10, length) - 1;
    return crypto.randomInt(min, max + 1).toString();
  }

  /**
   * Hashes OTP code using SHA-256 with secret salt
   */
  static hashOtpCode(otp: string): string {
    return crypto
      .createHmac('sha256', env.JWT_RESET_SECRET)
      .update(otp)
      .digest('hex');
  }

  /**
   * Constant-time comparison of OTP hashes
   */
  static verifyOtpHash(rawOtp: string, expectedHash: string): boolean {
    const hash = this.hashOtpCode(rawOtp);
    const bufA = Buffer.from(hash, 'hex');
    const bufB = Buffer.from(expectedHash, 'hex');
    if (bufA.length !== bufB.length) return false;
    return crypto.timingSafeEqual(bufA, bufB);
  }

  /**
   * Creates, persists, and delivers a new OTP with rate limiting and cooldown enforcement.
   */
  static async requestOtp(
    userId: mongoose.Types.ObjectId | string,
    purpose: OtpPurpose,
    destination: string,
    deliveryMethod: OtpDeliveryMethod
  ): Promise<{ success: boolean }> {
    const userObjectId = new mongoose.Types.ObjectId(userId);

    // 1. Check resend cooldown
    const latestOtp = await Otp.findOne({
      userId: userObjectId,
      purpose,
    }).sort({ createdAt: -1 });

    if (latestOtp) {
      const secondsSinceCreation = (Date.now() - latestOtp.createdAt.getTime()) / 1000;
      if (secondsSinceCreation < env.OTP_RESEND_COOLDOWN) {
        const waitTime = Math.ceil(env.OTP_RESEND_COOLDOWN - secondsSinceCreation);
        throw ApiError.tooManyRequests(
          `Please wait ${waitTime} seconds before requesting another code.`
        );
      }
    }

    // 2. Generate secure code & hash
    const rawOtp = this.generateOtpCode(6);
    const otpHash = this.hashOtpCode(rawOtp);
    const expiresAt = new Date(Date.now() + env.OTP_EXPIRES_IN * 1000);

    // 3. Persist OTP record
    await Otp.create({
      userId: userObjectId,
      purpose,
      deliveryMethod,
      destination,
      otpHash,
      expiresAt,
      attempts: 0,
      consumedAt: null,
    });

    // 4. Dispatch via delivery adapter
    await OtpDeliveryService.sendOtp({
      destination,
      otp: rawOtp,
      purpose,
      deliveryMethod,
    });

    return { success: true };
  }

  /**
   * Verifies and consumes OTP with expiration, attempt limit, and single-use checks.
   */
  static async verifyAndConsumeOtp(
    userId: mongoose.Types.ObjectId | string,
    purpose: OtpPurpose,
    rawOtp: string
  ): Promise<IOtp> {
    const userObjectId = new mongoose.Types.ObjectId(userId);

    // Find latest OTP for user & purpose
    const otpDoc = await Otp.findOne({
      userId: userObjectId,
      purpose,
    }).sort({ createdAt: -1 });

    if (!otpDoc) {
      throw ApiError.badRequest('No verification code found. Please request a new code.');
    }

    if (otpDoc.isConsumed()) {
      throw ApiError.badRequest('This verification code has already been used. Please request a new code.');
    }

    if (otpDoc.isExpired()) {
      throw ApiError.badRequest('This verification code has expired. Please request a new code.');
    }

    if (otpDoc.attempts >= env.OTP_MAX_ATTEMPTS) {
      throw ApiError.badRequest('Maximum verification attempts exceeded. Please request a new code.');
    }

    // Check code match
    const isValid = this.verifyOtpHash(rawOtp, otpDoc.otpHash);
    if (!isValid) {
      otpDoc.attempts += 1;
      await otpDoc.save();
      const remaining = env.OTP_MAX_ATTEMPTS - otpDoc.attempts;
      if (remaining <= 0) {
        throw ApiError.badRequest('Maximum verification attempts exceeded. Please request a new code.');
      }
      throw ApiError.badRequest(`Invalid verification code. ${remaining} attempt(s) remaining.`);
    }

    // Consume OTP
    otpDoc.consumedAt = new Date();
    await otpDoc.save();

    return otpDoc;
  }
}
