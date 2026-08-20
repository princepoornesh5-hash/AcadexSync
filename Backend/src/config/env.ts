import dotenv from 'dotenv';
import path from 'path';
import { z } from 'zod';

// Load .env from backend root or workspace root
dotenv.config({ path: path.resolve(process.cwd(), '.env') });
dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z
    .string()
    .transform((val) => parseInt(val, 10))
    .pipe(z.number().positive())
    .default('5000'),
  MONGODB_URI: z.string().optional(),
  MONGODB_DATABASE: z.string().default('acadex'),
  
  // Authentication & Tokens
  JWT_SECRET: z.string().default('acadex_development_jwt_secret_min_32_chars!'),
  JWT_ACCESS_SECRET: z.string().default('acadex_development_access_token_secret_min_32_chars!'),
  JWT_REFRESH_SECRET: z.string().default('acadex_development_refresh_token_secret_min_32_chars!'),
  JWT_RESET_SECRET: z.string().default('acadex_development_reset_token_secret_min_32_chars!'),
  ACTIVATION_CODE_SECRET: z.string().default('acadex_development_activation_secret_32_chars!'),
  
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
    .default('600'), // 10 minutes in seconds
    
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
    
  CORS_ORIGIN: z.string().default('*'),

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
});

export type EnvConfig = z.infer<typeof envSchema>;

function loadEnv(): EnvConfig {
  const result = envSchema.safeParse(process.env);
  if (!result.success) {
    console.error('❌ Invalid environment variables:', result.error.format());
    throw new Error('Environment configuration validation failed');
  }
  return result.data;
}

export const env = loadEnv();