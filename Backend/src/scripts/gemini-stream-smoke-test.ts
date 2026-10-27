import { GoogleGenAI } from '@google/genai';
import { env } from '../config/env';

/**
 * ACADEX Gemini AI Streaming Smoke Test
 *
 * Verifies that:
 * 1. GEMINI_API_KEY is loaded in environment.
 * 2. @google/genai client supports generateContentStream.
 * 3. Text chunks stream progressively from upstream API.
 * 4. Measures TTFT (Time to First Token), chunk count, and total duration.
 */
async function runStreamingSmokeTest(): Promise<void> {
  console.log('====================================================');
  console.log('   ACADEX GEMINI AI STREAMING SMOKE TEST');
  console.log('====================================================\n');

  console.log('[1] Checking Environment Configuration:');
  console.log(`    - Configured Model:  ${env.GEMINI_MODEL}`);
  console.log(`    - AI Request Timeout:${env.AI_TIMEOUT_MS}ms`);

  if (!env.GEMINI_API_KEY || env.GEMINI_API_KEY.trim() === '') {
    console.error('\n❌ RESULT: FAILED - GEMINI_API_KEY is not defined in Backend/.env');
    process.exit(1);
  }

  console.log('    - GEMINI_API_KEY:    [CONFIGURED]');

  console.log('\n[2] Initializing @google/genai Client for Streaming...');
  const client = new GoogleGenAI({ apiKey: env.GEMINI_API_KEY });

  try {
    console.log(`[3] Dispatching generateContentStream to model "${env.GEMINI_MODEL}"...`);
    const startTime = Date.now();
    let firstTokenTime: number | null = null;
    let chunkCount = 0;
    let accumulatedText = '';

    const stream = await client.models.generateContentStream({
      model: env.GEMINI_MODEL,
      contents: 'Count from 1 to 5, writing one line per number with a word explaining it (e.g. 1 - One).',
    });

    console.log('    ✓ Stream established. Awaiting incoming chunks...\n');

    for await (const chunk of stream) {
      chunkCount++;
      const now = Date.now();
      if (firstTokenTime === null) {
        firstTokenTime = now - startTime;
        console.log(`    ⚡ [TTFT] First chunk arrived in ${firstTokenTime}ms!`);
      }

      const text = chunk.text || '';
      accumulatedText += text;
      const preview = text.replace(/\n/g, '\\n');
      console.log(`    Chunk #${chunkCount} (+${now - startTime}ms, ${text.length} chars): "${preview}"`);
    }

    const totalDuration = Date.now() - startTime;
    console.log('\n[4] Stream Completed:');
    console.log(`    - Total Duration:    ${totalDuration}ms`);
    console.log(`    - Time to First Token: ${firstTokenTime}ms`);
    console.log(`    - Total Chunks:      ${chunkCount}`);
    console.log(`    - Total Text Length: ${accumulatedText.length} characters`);
    console.log('\n[5] Full Generated Content:');
    console.log('----------------------------------------------------');
    console.log(accumulatedText.trim());
    console.log('----------------------------------------------------');

    if (chunkCount > 1 && accumulatedText.length > 0) {
      console.log('\n====================================================');
      console.log('✅ RESULT: PASSED - Real progressive streaming verified!');
      console.log('====================================================\n');
      process.exit(0);
    } else {
      console.error('\n❌ Warning: Stream received fewer than 2 chunks.');
      process.exit(1);
    }
  } catch (error: any) {
    console.error('\n❌ RESULT: FAILED (Streaming Error)');
    console.error(`Status: ${error.status || error.code || 'UNKNOWN'}`);
    const rawMsg = error.message || String(error);
    const safeMsg = env.GEMINI_API_KEY ? rawMsg.split(env.GEMINI_API_KEY).join('[REDACTED]') : rawMsg;
    console.error(`Message: ${safeMsg}`);
    process.exit(1);
  }
}

runStreamingSmokeTest();
