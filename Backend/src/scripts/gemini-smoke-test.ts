import { GoogleGenAI } from '@google/genai';
import { env } from '../config/env';

/**
 * ACADEX Gemini AI Integration Smoke Test
 *
 * Verifies that:
 * 1. GEMINI_API_KEY is present and properly loaded in environment.
 * 2. @google/genai client initializes with credentials.
 * 3. Minimal authenticated network roundtrip to Google Gemini API succeeds.
 * 4. Safe error diagnostics are reported without exposing credentials.
 */
async function runSmokeTest(): Promise<void> {
  console.log('====================================================');
  console.log('   ACADEX GEMINI AI INTEGRATION SMOKE TEST');
  console.log('====================================================\n');

  console.log('[1] Checking Environment Configuration:');
  console.log(`    - Configured Model:  ${env.GEMINI_MODEL}`);
  console.log(`    - AI Request Timeout:${env.AI_TIMEOUT_MS}ms`);
  console.log(`    - AI Rate Limit:     ${env.AI_RATE_LIMIT_MAX} req/min`);

  if (!env.GEMINI_API_KEY || env.GEMINI_API_KEY.trim() === '') {
    console.error('\n❌ RESULT: FAILED (Configuration Missing)');
    console.error('----------------------------------------------------');
    console.error('GEMINI_API_KEY is not defined or is empty in Backend/.env.');
    console.error('');
    console.error('Action required:');
    console.error('1. Generate an API key at https://aistudio.google.com/app/apikey');
    console.error('2. Open the file:');
    console.error('   /Users/poornesh/Campus Management Main/Backend/.env');
    console.error('3. Add or update the key:');
    console.error('   GEMINI_API_KEY=your_actual_api_key_here');
    console.error('4. Re-run this smoke test:');
    console.error('   npm run test:gemini-smoke');
    console.error('----------------------------------------------------\n');
    process.exit(1);
  }

  console.log('    - GEMINI_API_KEY:    [CONFIGURED]');
  console.log('\n[2] Initializing @google/genai SDK Client...');

  try {
    const client = new GoogleGenAI({ apiKey: env.GEMINI_API_KEY });
    console.log('    ✓ Client initialized successfully.');

    console.log(
      `\n[3] Dispatching minimal authenticated request to model "${env.GEMINI_MODEL}"...`
    );
    const startTime = Date.now();

    const response = await client.models.generateContent({
      model: env.GEMINI_MODEL,
      contents: 'Respond with exactly: "ACADEX Gemini Live Connection Verified"',
    });

    const duration = Date.now() - startTime;
    const responseText = response.text?.trim() || '';

    console.log(`    ✓ Response received in ${duration}ms!`);
    console.log(`    - Model Output: "${responseText}"`);
    console.log('\n====================================================');
    console.log('✅ RESULT: PASSED - Real Gemini API connectivity verified!');
    console.log('====================================================\n');
    process.exit(0);
  } catch (error: any) {
    console.error('\n❌ RESULT: FAILED (Upstream API Error)');
    console.error('----------------------------------------------------');
    const status = error.status || error.code || 'UNKNOWN';
    console.error(`Status Code: ${status}`);

    const rawMsg = error.message || String(error);
    const safeMsg = env.GEMINI_API_KEY
      ? rawMsg.split(env.GEMINI_API_KEY).join('[REDACTED]')
      : rawMsg;
    if (
      rawMsg.includes('API_KEY_INVALID') ||
      rawMsg.includes('API key not valid') ||
      status === 400
    ) {
      console.error(
        'Reason: The configured GEMINI_API_KEY is invalid or rejected by Google Gemini API.'
      );
      console.error(
        'Please generate a valid key at https://aistudio.google.com/app/apikey and update Backend/.env.'
      );
    } else if (status === 429 || rawMsg.includes('RESOURCE_EXHAUSTED')) {
      console.error('Reason: Rate limit or quota exceeded on this Gemini API key.');
    } else if (status === 404 || rawMsg.includes('not found')) {
      console.error(
        `Reason: Model "${env.GEMINI_MODEL}" was not found or is not supported by your API key.`
      );
      console.error(
        'Try setting GEMINI_MODEL=gemini-3.5-flash-lite in Backend/.env (confirmed available for new API keys).'
      );
    } else {
      console.error(`Reason: ${safeMsg || 'Unknown upstream communication error'}`);
    }
    console.error('----------------------------------------------------\n');
    process.exit(1);
  }
}

runSmokeTest();
