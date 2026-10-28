import crypto from 'crypto';
import { env } from '../config/env';
import { JwtPayload } from '../types/auth.types';
import { TokenType } from '../constants/status';
import { AppRole } from '../constants/roles';
import { ApiError } from './apiError';

function base64UrlEncode(str: string): string {
  return Buffer.from(str)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function base64UrlDecode(str: string): string {
  let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4) {
    base64 += '=';
  }
  return Buffer.from(base64, 'base64').toString('utf8');
}

/**
 * Creates a signed JWT token using HMAC SHA-256
 */
export function signJwtToken(
  payload: Omit<JwtPayload, 'iat' | 'exp'>,
  expiresInSeconds = 900,
  secret: string = env.JWT_ACCESS_SECRET
): string {
  const header = {
    alg: 'HS256',
    typ: 'JWT',
  };

  const now = Math.floor(Date.now() / 1000);
  const fullPayload: JwtPayload = {
    ...payload,
    iat: now,
    exp: now + expiresInSeconds,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(fullPayload));

  const signature = crypto
    .createHmac('sha256', secret)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

/**
 * Verifies and decodes a signed JWT token, enforcing tokenType and expiration.
 */
export function verifyJwtToken(
  token: string,
  expectedType?: TokenType,
  secret: string = env.JWT_ACCESS_SECRET
): JwtPayload {
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw ApiError.unauthorized('Invalid token format');
  }

  const [encodedHeader, encodedPayload, signature] = parts;

  // Verify HMAC signature
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  const sigBuffer = Buffer.from(signature);
  const expSigBuffer = Buffer.from(expectedSignature);

  if (
    sigBuffer.length !== expSigBuffer.length ||
    !crypto.timingSafeEqual(sigBuffer, expSigBuffer)
  ) {
    throw ApiError.unauthorized('Invalid token signature');
  }

  let payload: JwtPayload;
  try {
    payload = JSON.parse(base64UrlDecode(encodedPayload)) as JwtPayload;
  } catch {
    throw ApiError.unauthorized('Invalid token payload');
  }

  // Check expiration
  const now = Math.floor(Date.now() / 1000);
  if (payload.exp && payload.exp < now) {
    throw ApiError.unauthorized('Token has expired');
  }

  // Validate token type if specified
  if (expectedType && payload.tokenType !== expectedType) {
    throw ApiError.unauthorized(`Invalid token type. Expected "${expectedType}" token.`);
  }

  return payload;
}

/**
 * Generates an Access Token (short-lived)
 */
export function signAccessToken(
  payload: Omit<JwtPayload, 'iat' | 'exp' | 'tokenType'>,
  expiresInSeconds = env.ACCESS_TOKEN_EXPIRES_IN
): string {
  return signJwtToken(
    {
      ...payload,
      tokenType: TokenType.ACCESS,
    },
    expiresInSeconds,
    env.JWT_ACCESS_SECRET
  );
}

/**
 * Generates a Refresh Token (long-lived)
 */
export function signRefreshToken(
  payload: Omit<JwtPayload, 'iat' | 'exp' | 'tokenType'>,
  expiresInSeconds = env.REFRESH_TOKEN_EXPIRES_IN
): string {
  return signJwtToken(
    {
      ...payload,
      tokenType: TokenType.REFRESH,
    },
    expiresInSeconds,
    env.JWT_REFRESH_SECRET
  );
}

/**
 * Generates a Password Reset Authorization Token (short-lived)
 */
export function signPasswordResetToken(
  payload: Omit<JwtPayload, 'iat' | 'exp' | 'tokenType'>,
  expiresInSeconds = env.PASSWORD_RESET_TOKEN_EXPIRES_IN
): string {
  return signJwtToken(
    {
      ...payload,
      tokenType: TokenType.PASSWORD_RESET,
    },
    expiresInSeconds,
    env.JWT_RESET_SECRET
  );
}

/**
 * Generates an Activation Flow Token (short-lived, 15 minutes)
 * Encapsulates the resolved activation flow state between code validation and OTP verification.
 */
export function signActivationFlowToken(
  payload: {
    flowId: string;
    invitationId: string;
    userId: string;
    collegeId: string;
  },
  expiresInSeconds = 900
): string {
  return signJwtToken(
    {
      userId: payload.userId,
      role: AppRole.STUDENT,
      tokenType: TokenType.ACTIVATION_FLOW,
      invitationId: payload.invitationId,
      flowId: payload.flowId,
      collegeId: payload.collegeId,
      purpose: 'activation_flow',
    },
    expiresInSeconds,
    env.ACTIVATION_CODE_SECRET
  );
}

/**
 * Verifies an Activation Flow Token, ensuring it is valid and has not expired.
 */
export function verifyActivationFlowToken(token: string): JwtPayload {
  const payload = verifyJwtToken(token, TokenType.ACTIVATION_FLOW, env.ACTIVATION_CODE_SECRET);
  if (payload.purpose !== 'activation_flow') {
    throw ApiError.unauthorized('Invalid token purpose. Expected activation flow token.');
  }
  return payload;
}

/**
 * Generates an Activation Completion Authorization Token (short-lived, 10 minutes)
 * Issued exclusively upon successful OTP verification.
 */
export function signActivationCompletionToken(
  payload: {
    tokenId: string;
    invitationId: string;
    userId: string;
    collegeId: string;
    contactMethod: string;
  },
  expiresInSeconds = 600
): string {
  return signJwtToken(
    {
      userId: payload.userId,
      role: AppRole.STUDENT,
      tokenType: TokenType.ACTIVATION_TOKEN,
      invitationId: payload.invitationId,
      tokenId: payload.tokenId,
      collegeId: payload.collegeId,
      contactMethod: payload.contactMethod,
      purpose: 'activation_completion',
    },
    expiresInSeconds,
    env.ACTIVATION_CODE_SECRET
  );
}

/**
 * Verifies an Activation Completion Token, ensuring it is valid and has not expired.
 */
export function verifyActivationCompletionToken(token: string): JwtPayload {
  const payload = verifyJwtToken(token, TokenType.ACTIVATION_TOKEN, env.ACTIVATION_CODE_SECRET);
  if (payload.purpose !== 'activation_completion') {
    throw ApiError.unauthorized('Invalid token purpose. Expected activation completion token.');
  }
  return payload;
}

/**
 * Generates a Registration Authorization Token (short-lived, 10 minutes)
 * Issued upon verifying an email OTP during self-registration.
 */
export function signRegistrationToken(
  payload: { email: string },
  expiresInSeconds = 600
): string {
  return signJwtToken(
    {
      userId: 'unregistered',
      role: AppRole.STUDENT,
      tokenType: TokenType.REGISTRATION,
      email: payload.email,
      purpose: 'registration',
    },
    expiresInSeconds,
    env.JWT_ACCESS_SECRET
  );
}

/**
 * Verifies a Registration Token.
 */
export function verifyRegistrationToken(token: string): { email: string } {
  const payload = verifyJwtToken(token, TokenType.REGISTRATION, env.JWT_ACCESS_SECRET);
  if (payload.tokenType !== TokenType.REGISTRATION || payload.purpose !== 'registration' || !payload.email) {
    throw ApiError.unauthorized('Invalid or expired registration token');
  }
  return { email: payload.email };
}

/**
 * Generates an Email Verification Token for Institutional Activation (short-lived, 10 minutes)
 */
export function signEmailVerificationToken(
  payload: { email: string; purpose?: string; invitationId?: string },
  expiresInSeconds = 600
): string {
  return signJwtToken(
    {
      userId: 'pending_verification',
      role: AppRole.STUDENT,
      tokenType: TokenType.EMAIL_VERIFICATION,
      email: payload.email,
      purpose: payload.purpose || 'email_verification',
      invitationId: payload.invitationId,
    },
    expiresInSeconds,
    env.ACTIVATION_CODE_SECRET
  );
}

/**
 * Verifies an Email Verification Token.
 */
export function verifyEmailVerificationToken(token: string): { email: string; purpose: string; invitationId?: string } {
  const payload = verifyJwtToken(token, TokenType.EMAIL_VERIFICATION, env.ACTIVATION_CODE_SECRET);
  if (payload.tokenType !== TokenType.EMAIL_VERIFICATION || !payload.email) {
    throw ApiError.unauthorized('Invalid or expired email verification token');
  }
  return {
    email: payload.email,
    purpose: payload.purpose || 'email_verification',
    invitationId: payload.invitationId,
  };
}

/**
 * Hashes a token using SHA-256 for persistent session storage (zero plaintext storage).
 */
export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

