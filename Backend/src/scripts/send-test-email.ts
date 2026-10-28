import { env } from '../config/env';
import { EmailService } from '../services/email.service';
import { Logger } from '../utils/logger';

async function main() {
  const recipient = process.argv[2]?.trim();

  console.log('\n===========================================================');
  console.log('  ACADEXSYNC - Resend Email Integration Test Utility');
  console.log('===========================================================\n');

  // 1. Verify recipient was explicitly supplied
  if (!recipient || !recipient.includes('@')) {
    console.error('❌ Error: Recipient email address must be explicitly provided.\n');
    console.log('Usage:');
    console.log('  npm run test:email -- <recipient@example.com>\n');
    console.log('Example:');
    console.log('  npm run test:email -- your-resend-account@gmail.com\n');
    process.exit(1);
  }

  // 2. Verify RESEND_API_KEY is configured
  if (!EmailService.isConfigured()) {
    console.error('❌ Error: RESEND_API_KEY is not configured in Backend/.env\n');
    console.log('To set up Resend email delivery:');
    console.log('  1. Create a free account at https://resend.com');
    console.log('  2. Generate an API key at https://resend.com/api-keys');
    console.log('  3. Add the key to Backend/.env:');
    console.log('     RESEND_API_KEY=re_your_api_key_here');
    console.log('     RESEND_FROM_EMAIL=onboarding@resend.dev\n');
    console.log('Notice:');
    console.log('  On Resend free tier using "onboarding@resend.dev", Resend will ONLY');
    console.log('  deliver emails to the email address registered with your Resend account.');
    console.log('  Production delivery requires a verified custom domain.\n');
    process.exit(1);
  }

  console.log(`📤 Sending test email...`);
  console.log(`   Recipient: ${Logger.maskEmail(recipient)}`);
  console.log(`   Sender:    ${env.RESEND_FROM_EMAIL}`);
  console.log(`   Timeout:   ${env.RESEND_TIMEOUT_MS}ms\n`);

  if (env.RESEND_FROM_EMAIL.includes('onboarding@resend.dev')) {
    console.log('ℹ️  Note: Using test sender "onboarding@resend.dev".');
    console.log('   Delivery will only succeed if the recipient matches your Resend registered email.\n');
  }

  try {
    const result = await EmailService.sendTestEmail(recipient);

    if (result.success) {
      console.log('✅ Success! Test email delivered to Resend API.');
      console.log(`   Message ID: ${result.messageId}`);
      console.log('   Check the recipient inbox (and spam folder) or your Resend dashboard:');
      console.log('   https://resend.com/emails\n');
      process.exit(0);
    } else {
      console.error('❌ Email delivery failed:');
      console.error(`   Error Code: ${result.errorCode || 'UNKNOWN'}`);
      console.error(`   Message:    ${result.error}\n`);
      process.exit(1);
    }
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown exception';
    console.error(`❌ Unexpected failure during test dispatch: ${message}\n`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Fatal error in test script:', err);
  process.exit(1);
});
