export class Logger {
  public static sanitize(message: string): string {
    if (!message || typeof message !== 'string') return '';

    let result = message
      // Mask MongoDB URIs with credentials (e.g. mongodb+srv://user:pass@host)
      .replace(/(mongodb(?:\+srv)?:\/\/)[^:]+:[^@]+@/gi, '$1***:***@')
      // Mask Bearer tokens and raw JWTs
      .replace(/(Bearer\s+)[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*/gi, '$1***')
      .replace(/eyJ[A-Za-z0-9-_=]+\.eyJ[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*/g, '***JWT***')
      // Mask PEM private keys
      .replace(/-----BEGIN (?:RSA )?PRIVATE KEY-----[\s\S]*?-----END (?:RSA )?PRIVATE KEY-----/gi, '***PRIVATE_KEY***')
      // Mask common credential keys in JSON / logs (supporting : and =)
      .replace(/(["']?(?:apiKey|geminiApiKey|GEMINI_API_KEY)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      .replace(/(["']?(?:password|passwordHash|newPassword|currentPassword)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      .replace(/(["']?(?:secret|jwtSecret|accessSecret|refreshSecret|activationCodeSecret)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      .replace(/(["']?(?:privateKey|imagekitPrivateKey|firebasePrivateKey)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      .replace(/(["']?(?:otp|activationCode|rawCode)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      .replace(/(["']?(?:deviceToken|fcmToken|refreshToken|token)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      // Mask Google GenAI / Gemini API keys (AIzaSy...)
      .replace(/AIza[0-9A-Za-z-_]{35}/g, '***API_KEY***');

    if (process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY.trim() !== '') {
      result = result.split(process.env.GEMINI_API_KEY).join('***REDACTED_API_KEY***');
    }

    return result;
  }

  public static sanitizeObject<T>(obj: T): T {
    if (!obj) return obj;
    try {
      const serialized = JSON.stringify(obj);
      return JSON.parse(this.sanitize(serialized));
    } catch {
      return obj;
    }
  }

  static info(message: string, ...args: unknown[]): void {
    if (process.env.NODE_ENV !== 'test') {
      const sanitized = this.sanitize(message);
      const safeArgs = args.map((arg) => (typeof arg === 'object' ? this.sanitizeObject(arg) : typeof arg === 'string' ? this.sanitize(arg) : arg));
      console.log(`[INFO] [${new Date().toISOString()}] ${sanitized}`, ...safeArgs);
    }
  }

  static warn(message: string, ...args: unknown[]): void {
    const sanitized = this.sanitize(message);
    const safeArgs = args.map((arg) => (typeof arg === 'object' ? this.sanitizeObject(arg) : typeof arg === 'string' ? this.sanitize(arg) : arg));
    console.warn(`[WARN] [${new Date().toISOString()}] ${sanitized}`, ...safeArgs);
  }

  static error(message: string, error?: unknown): void {
    const sanitized = this.sanitize(message);
    if (error instanceof Error) {
      console.error(`[ERROR] [${new Date().toISOString()}] ${sanitized}: ${this.sanitize(error.message)}`);
      if (process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test') {
        console.error(this.sanitize(error.stack || ''));
      }
    } else if (typeof error === 'object' && error !== null) {
      console.error(`[ERROR] [${new Date().toISOString()}] ${sanitized}`, this.sanitizeObject(error));
    } else {
      console.error(`[ERROR] [${new Date().toISOString()}] ${sanitized}`, error);
    }
  }

  static debug(message: string, ...args: unknown[]): void {
    if (process.env.NODE_ENV === 'development') {
      const sanitized = this.sanitize(message);
      console.debug(`[DEBUG] [${new Date().toISOString()}] ${sanitized}`, ...args);
    }
  }
}

export const logger = Logger;
