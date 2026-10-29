import dotenv from 'dotenv';
import path from 'path';
import { z } from 'zod';

// Load .env from backend root (relative to this module) and current working directory
const backendEnvPath = path.resolve(__dirname, '../../.env');
dotenv.config({ path: backendEnvPath });
dotenv.config({ path: path.resolve(process.cwd(), '.env') });
dotenv.config();

export const INSECURE_DEV_SECRETS = new Set([
  'acadex_development_jwt_secret_min_32_chars!',
  'acadex_development_access_token_secret_min_32_chars!',
  'acadex_development_refresh_token_secret_min_32_chars!',
  'acadex_development_reset_token_secret_min_32_chars!',
  'acadex_development_activation_secret_32_chars!',
]);

export function createEnvSchema(isProduction: boolean) {
  return z.object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    PORT: z
      .union([z.string(), z.number()])
      .transform((val) => (typeof val === 'number' ? val : parseInt(val, 10)))
      .pipe(z.number().positive())
      .default('5050'),
    MONGODB_URI: z.string().optional(),
    MONGODB_DATABASE: z.string().default('acadex'),

    // Authentication & Tokens:
    // In development/test mode, fall back to dev secrets for local developer onboarding.
    // In production mode, NO silent fallback is permitted; values must be provided via runtime environment.
    JWT_SECRET: isProduction
      ? z.string().trim().optional()
      : z.string().trim().default('acadex_development_jwt_secret_min_32_chars!'),
    JWT_ACCESS_SECRET: isProduction
      ? z.string().trim().optional()
      : z.string().trim().default('acadex_development_access_token_secret_min_32_chars!'),
    JWT_REFRESH_SECRET: isProduction
      ? z.string().trim().optional()
      : z.string().trim().default('acadex_development_refresh_token_secret_min_32_chars!'),
    JWT_RESET_SECRET: isProduction
      ? z.string().trim().optional()
      : z.string().trim().default('acadex_development_reset_token_secret_min_32_chars!'),
    ACTIVATION_CODE_SECRET: isProduction
      ? z.string().trim().optional()
      : z.string().trim().default('acadex_development_activation_secret_32_chars!'),

    ACCESS_TOKEN_EXPIRES_IN: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('900'), // 15 minutes in seconds

    REFRESH_TOKEN_EXPIRES_IN: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('604800'), // 7 days in seconds

    PASSWORD_RESET_TOKEN_EXPIRES_IN: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('600'), // 10 minutes in seconds

    // Invitation Configuration
    INVITATION_EXPIRES_IN: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('604800'), // 7 days in seconds

    // OTP Configuration
    OTP_EXPIRES_IN: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('300'), // 5 minutes in seconds

    OTP_MAX_ATTEMPTS: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('5'),

    OTP_RESEND_COOLDOWN: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('60'), // 60 seconds

    BCRYPT_SALT_ROUNDS: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('10'),

    // In development/test mode, default to '*' for local tools; in production mode, require explicit origin.
    CORS_ORIGIN: isProduction
      ? z.string().trim().optional()
      : z.string().trim().default('*'),

    // Rate Limiting Configuration
    RATE_LIMIT_WINDOW_MS: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('900000'), // 15 minutes in ms
    RATE_LIMIT_MAX: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('1000'), // 1000 requests per 15 min for general API
    AUTH_RATE_LIMIT_MAX: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('15'), // 15 requests per 5 min for auth endpoints
    UPLOAD_RATE_LIMIT_MAX: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('30'), // 30 requests per 5 min for upload authorization
    REPORT_RATE_LIMIT_MAX: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('60'), // 60 requests per 5 min for report generation
    INVITATION_RATE_LIMIT_MAX: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('30'), // 30 requests per 5 min for invitation management
    DEVICE_TOKEN_RATE_LIMIT_MAX: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('30'), // 30 requests per 5 min for device tokens

    // ImageKit Media & File Storage Configuration
    IMAGEKIT_PUBLIC_KEY: z.string().default('mock_imagekit_public_key'),
    IMAGEKIT_PRIVATE_KEY: z.string().default('mock_imagekit_private_key'),
    IMAGEKIT_URL_ENDPOINT: z.string().default('https://ik.imagekit.io/mock_acadex'),

    NOTES_MAX_FILE_SIZE_MB: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('25'),
    PROFILE_IMAGE_MAX_FILE_SIZE_MB: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('5'),
    SIGNED_URL_EXPIRY_SECONDS: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('300'),

    // Firebase Admin / FCM Configuration
    FIREBASE_PROJECT_ID: z.string().default('acadex-app'),
    FIREBASE_CLIENT_EMAIL: z.string().default('firebase-adminsdk@acadex-app.iam.gserviceaccount.com'),
    FIREBASE_PRIVATE_KEY: z.string().default(''),

    // Google Gemini AI Configuration
    GEMINI_API_KEY: z.string().optional(),
    GEMINI_MODEL: z.string().default('gemini-3.5-flash-lite'),
    AI_RATE_LIMIT_MAX: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('30'),
    AI_TIMEOUT_MS: z
      .string()
      .transform((val) => parseInt(val, 10))
      .pipe(z.number().positive())
      .default('15000'),

    // Resend Transactional Email Delivery Configuration
    RESEND_API_KEY: z.string().optional(),
    RESEND_FROM_EMAIL: z.string().default('onboarding@resend.dev'),
    RESEND_DEV_REDIRECT_EMAIL: z.string().optional(),
    RESEND_TIMEOUT_MS: z
      .union([z.string(), z.number()])
      .transform((val) => (typeof val === 'number' ? val : parseInt(val, 10)))
      .pipe(z.number().positive())
      .default('10000'),
  });
}

export const envSchema = createEnvSchema(process.env.NODE_ENV === 'production');

export type RawEnvConfig = z.infer<typeof envSchema>;

export type EnvConfig = Omit<
  RawEnvConfig,
  'JWT_SECRET' | 'JWT_ACCESS_SECRET' | 'JWT_REFRESH_SECRET' | 'JWT_RESET_SECRET' | 'ACTIVATION_CODE_SECRET' | 'CORS_ORIGIN'
> & {
  JWT_SECRET: string;
  JWT_ACCESS_SECRET: string;
  JWT_REFRESH_SECRET: string;
  JWT_RESET_SECRET: string;
  ACTIVATION_CODE_SECRET: string;
  CORS_ORIGIN: string;
};

/**
 * Validates that mandatory production secrets and secure configurations
 * are strictly present when running in production mode.
 * Fails fast without exposing or logging any secret values.
 */
export function validateProductionConfig(config: Partial<EnvConfig>): void {
  const violations: string[] = [];

  // 1. Mandatory MongoDB URI
  if (!config.MONGODB_URI || config.MONGODB_URI.trim().length === 0) {
    violations.push('MONGODB_URI is required and cannot be empty in production');
  }

  // 2. JWT & Token Secrets must be present, >= 32 chars, not use development defaults, and not contain 'development'
  const secretsToCheck: Array<{ name: keyof EnvConfig; value?: string }> = [
    { name: 'JWT_SECRET', value: config.JWT_SECRET },
    { name: 'JWT_ACCESS_SECRET', value: config.JWT_ACCESS_SECRET },
    { name: 'JWT_REFRESH_SECRET', value: config.JWT_REFRESH_SECRET },
    { name: 'JWT_RESET_SECRET', value: config.JWT_RESET_SECRET },
    { name: 'ACTIVATION_CODE_SECRET', value: config.ACTIVATION_CODE_SECRET },
  ];

  for (const { name, value } of secretsToCheck) {
    if (!value || value.trim().length === 0) {
      violations.push(`${name} is required and cannot be empty in production; inject a unique 32+ character key via Render environment settings`);
    } else if (value.length < 32) {
      violations.push(`${name} must be at least 32 characters in production`);
    } else if (INSECURE_DEV_SECRETS.has(value) || value.toLowerCase().includes('development')) {
      violations.push(`${name} is using an insecure development default; inject a high-entropy production key via secret manager`);
    }
  }

  // Ensure all five production secrets are distinct high-entropy values (prevents cryptographic token reuse)
  const secretValues = secretsToCheck
    .map((s) => s.value)
    .filter((v): v is string => typeof v === 'string' && v.trim().length > 0);
  const uniqueValues = new Set(secretValues);
  if (uniqueValues.size < secretValues.length) {
    violations.push('The five production secrets (JWT_SECRET, JWT_ACCESS_SECRET, JWT_REFRESH_SECRET, JWT_RESET_SECRET, ACTIVATION_CODE_SECRET) must each be unique values');
  }

  // 3. CORS Configuration: Unrestricted wildcard (*) is strictly prohibited in production when credentials are enabled
  if (!config.CORS_ORIGIN || config.CORS_ORIGIN.trim().length === 0) {
    violations.push('CORS_ORIGIN is required and cannot be empty in production when credentialed access is enabled; specify explicit allowed origins (e.g. your deployed Netlify domain)');
  } else if (config.CORS_ORIGIN === '*' || config.CORS_ORIGIN.split(',').map((s) => s.trim()).includes('*')) {
    violations.push('CORS_ORIGIN cannot be "*" (wildcard) in production when credentialed access is enabled; specify explicit allowed origins');
  }

  if (violations.length > 0) {
    console.error('❌ CRITICAL: Production environment security check failed:');
    violations.forEach((v) => console.error(`   - ${v}`));
    throw new Error(`Production environment configuration validation failed: ${violations.join('; ')}`);
  }
}

export function loadEnv(customEnv?: NodeJS.ProcessEnv): EnvConfig {
  const envSource = customEnv || process.env;
  const rawNodeEnv = (envSource.NODE_ENV || '').trim().toLowerCase();
  const isProduction = rawNodeEnv === 'production';
  const schema = createEnvSchema(isProduction);
  const result = schema.safeParse(envSource);
  if (!result.success) {
    console.error('❌ Invalid environment variables:', result.error.format());
    throw new Error('Environment configuration validation failed');
  }

  // Fail fast in production if mandatory secrets or secure CORS configurations are missing
  if (result.data.NODE_ENV === 'production') {
    validateProductionConfig(result.data as Partial<EnvConfig>);
  }

  return result.data as EnvConfig;
}

export const env: EnvConfig = loadEnv();
