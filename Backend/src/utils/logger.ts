export class Logger {
  public static sanitize(message: string): string {
    if (!message || typeof message !== 'string') return '';

    return message
      // Mask MongoDB URIs with credentials (e.g. mongodb+srv://user:pass@host)
      .replace(/(mongodb(?:\+srv)?:\/\/)[^:]+:[^@]+@/gi, '$1***:***@')
      // Mask Bearer tokens and raw JWTs
      .replace(/(Bearer\s+)[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*/gi, '$1***')
      .replace(/eyJ[A-Za-z0-9-_=]+\.eyJ[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*/g, '***JWT***')
      // Mask PEM private keys
      .replace(/-----BEGIN (?:RSA )?PRIVATE KEY-----[\s\S]*?-----END (?:RSA )?PRIVATE KEY-----/gi, '***PRIVATE_KEY***')
      // Mask common credential keys in JSON / logs (supporting : and =)
      .replace(/(["']?(?:password|passwordHash|newPassword|currentPassword)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      .replace(/(["']?(?:secret|jwtSecret|accessSecret|refreshSecret|activationCodeSecret)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      .replace(/(["']?(?:privateKey|imagekitPrivateKey|firebasePrivateKey)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      .replace(/(["']?(?:otp|activationCode|rawCode)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2')
      .replace(/(["']?(?:deviceToken|fcmToken|refreshToken|token)["']?\s*[:=]\s*["']?)[^"'\s,;]+(["']?)/gi, '$1***$2');
  }

  static info(message: string, ...args: unknown[]): void {
    if (process.env.NODE_ENV !== 'test') {
      const sanitized = this.sanitize(message);
      console.log(`[INFO] [${new Date().toISOString()}] ${sanitized}`, ...args);
    }
  }

  static warn(message: string, ...args: unknown[]): void {
    const sanitized = this.sanitize(message);
    console.warn(`[WARN] [${new Date().toISOString()}] ${sanitized}`, ...args);
  }

  static error(message: string, error?: unknown): void {
    const sanitized = this.sanitize(message);
    if (error instanceof Error) {
      console.error(`[ERROR] [${new Date().toISOString()}] ${sanitized}: ${this.sanitize(error.message)}`);
      if (process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test') {
        console.error(error.stack);
      }
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
