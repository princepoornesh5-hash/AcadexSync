import { OtpPurpose } from '../constants/status';

export interface RenderOtpEmailOptions {
  otp: string;
  purpose: OtpPurpose | string;
  recipientEmail?: string;
  expiryMinutes?: number;
  appName?: string;
}

export interface RenderedEmail {
  subject: string;
  html: string;
  text: string;
}

/**
 * Generates a clean, responsive, ACADEXSYNC-branded transactional email
 * suitable for OTP messages, account activation, and password recovery.
 */
export function renderOtpEmail(options: RenderOtpEmailOptions): RenderedEmail {
  const {
    otp,
    purpose,
    expiryMinutes = 10,
    appName = 'ACADEXSYNC',
  } = options;

  let subject = `${appName} - Verification Code`;
  let title = 'Verification Code';
  let description = 'Use the verification code below to complete your verification in ACADEXSYNC.';

  switch (purpose) {
    case OtpPurpose.ACCOUNT_ACTIVATION:
      subject = `${appName} - Verification Code for Account Activation`;
      title = 'Activate Your Account';
      description =
        'Welcome to ACADEXSYNC. Use the verification code below to verify your email address and activate your institutional account.';
      break;

    case OtpPurpose.PASSWORD_RESET:
      subject = `${appName} - Password Reset Verification Code`;
      title = 'Reset Your Password';
      description =
        'A password reset request was initiated for your ACADEXSYNC account. Use the verification code below to continue.';
      break;

    case OtpPurpose.EMAIL_VERIFICATION:
      subject = `${appName} - Email Verification Code`;
      title = 'Verify Your Email Address';
      description =
        'Use the verification code below to verify your email address on ACADEXSYNC.';
      break;

    case OtpPurpose.LOGIN:
    case 'login':
    case 'LOGIN':
      subject = `${appName} - Login Verification Code`;
      title = 'Login Verification';
      description =
        'A login verification was requested for your ACADEXSYNC account. Use the code below to complete sign-in.';
      break;

    case OtpPurpose.REGISTRATION:
    case 'registration':
    case 'REGISTRATION':
      subject = `${appName} - Registration Verification Code`;
      title = 'Verify Your Email to Register';
      description =
        'Welcome to ACADEXSYNC. Use the verification code below to verify your email address and complete your account registration.';
      break;

    default:
      subject = `${appName} - Verification Code`;
      title = 'Verification Code';
      description =
        'Use the verification code below to complete your request in ACADEXSYNC.';
      break;
  }

  // HTML Template - Responsive, modern card design
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(subject)}</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #f8fafc;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #0f172a;
      -webkit-font-smoothing: antialiased;
    }
    .wrapper {
      width: 100%;
      background-color: #f8fafc;
      padding: 32px 16px;
    }
    .card {
      max-width: 540px;
      margin: 0 auto;
      background: #ffffff;
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.05);
    }
    .header {
      background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
      padding: 28px 32px;
      text-align: center;
    }
    .brand-title {
      margin: 0;
      color: #ffffff;
      font-size: 22px;
      font-weight: 700;
      letter-spacing: 1.5px;
    }
    .brand-subtitle {
      margin: 6px 0 0 0;
      color: #c7d2fe;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .content {
      padding: 32px;
    }
    .greeting-title {
      margin: 0 0 12px 0;
      font-size: 20px;
      font-weight: 600;
      color: #1e293b;
    }
    .description-text {
      margin: 0 0 24px 0;
      font-size: 15px;
      line-height: 1.6;
      color: #475569;
    }
    .otp-container {
      background: #f1f5f9;
      border: 1px solid #cbd5e1;
      border-radius: 8px;
      padding: 20px;
      text-align: center;
      margin: 24px 0;
    }
    .otp-label {
      margin: 0 0 8px 0;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1.2px;
      color: #64748b;
      font-weight: 600;
    }
    .otp-code {
      margin: 0;
      font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, Courier, monospace;
      font-size: 34px;
      font-weight: 700;
      letter-spacing: 8px;
      color: #1e1b4b;
    }
    .expiry-note {
      margin: 12px 0 0 0;
      font-size: 13px;
      color: #64748b;
    }
    .notice-box {
      background: #fefce8;
      border-left: 4px solid #eab308;
      padding: 14px 16px;
      border-radius: 4px;
      margin: 24px 0 0 0;
    }
    .notice-text {
      margin: 0;
      font-size: 13px;
      line-height: 1.5;
      color: #713f12;
    }
    .footer {
      padding: 24px 32px;
      background: #f8fafc;
      border-top: 1px solid #e2e8f0;
      text-align: center;
      font-size: 12px;
      color: #94a3b8;
      line-height: 1.6;
    }
    .footer p {
      margin: 4px 0;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="card">
      <div class="header">
        <h1 class="brand-title">${escapeHtml(appName)}</h1>
        <p class="brand-subtitle">Campus Management Platform</p>
      </div>
      <div class="content">
        <h2 class="greeting-title">${escapeHtml(title)}</h2>
        <p class="description-text">${escapeHtml(description)}</p>
        
        <div class="otp-container">
          <div class="otp-label">Verification Code</div>
          <div class="otp-code">${escapeHtml(otp)}</div>
          <div class="expiry-note">Expires in ${expiryMinutes} minutes • Single-use only</div>
        </div>

        <div class="notice-box">
          <p class="notice-text">
            <strong>Security Notice:</strong> If you did not request this verification code, please ignore this email or contact your campus administrator immediately. Never share this code with anyone. ACADEXSYNC administrators will never ask for your verification code.
          </p>
        </div>
      </div>
      <div class="footer">
        <p><strong>${escapeHtml(appName)}</strong> • Institutional Academic Operations</p>
        <p>This is an automated operational notification. Please do not reply directly to this message.</p>
      </div>
    </div>
  </div>
</body>
</html>`;

  // Plain-Text Version
  const text = `===========================================================
${appName} - ${title}
===========================================================

${description}

YOUR VERIFICATION CODE:
${otp}

• Valid for: ${expiryMinutes} minutes
• Single-use only

SECURITY NOTICE:
If you did not request this verification code, please ignore this
email or contact your campus administrator immediately.
Never share this code with anyone. ACADEXSYNC will never ask for your code.

===========================================================
${appName} • Institutional Academic Operations
This is an automated operational notification. Please do not reply.
===========================================================
`;

  return { subject, html, text };
}

function escapeHtml(unsafe: string): string {
  return unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
