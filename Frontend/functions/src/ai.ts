import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { GoogleGenAI } from '@google/genai';

// Initialize the GenAI SDK
// Using an environment variable or fallback to default credentials
const ai = new GoogleGenAI({});

export const askAssistant = functions.https.onCall(async (data, context) => {
  // 1. Authenticate Request
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const uid = context.auth.uid;
  const db = admin.firestore();

  try {
    // 2. Fetch User Context and Tenant
    let collegeId: string | undefined;
    let role: string | undefined;
    
    // Check custom claims first if available
    if (context.auth.token.collegeId && context.auth.token.role) {
      collegeId = context.auth.token.collegeId;
      role = context.auth.token.role;
    } else {
      // Fallback: search across colleges to find the user
      // Note: In production, the client should probably pass collegeId, 
      // but verifying it server-side is more secure.
      const query = data.collegeId ? 
          db.collection('colleges').doc(data.collegeId).collection('users').doc(uid) :
          await findUserAcrossColleges(db, uid);

      let userDoc: admin.firestore.DocumentSnapshot | null = null;
      if (data.collegeId) {
        userDoc = await (query as admin.firestore.DocumentReference).get();
      } else {
        userDoc = (await query) as admin.firestore.DocumentSnapshot | null;
      }

      if (!userDoc || !userDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'User not found in any tenant.');
      }
      collegeId = userDoc.data()?.collegeId || data.collegeId;
      role = userDoc.data()?.role;
    }

    if (!collegeId || !role) {
      throw new functions.https.HttpsError('permission-denied', 'Insufficient user context.');
    }

    // 3. Build Scoped Context based on Role
    const queryStr = data.query || '';
    if (!queryStr) {
      return { answer: "Please ask a question." };
    }

    let scopedContext = `User Role: ${role}\n`;
    
    // Example: Only give Student their own attendance
    if (role === 'Student') {
      const attendanceRef = await db.collection('colleges').doc(collegeId).collection('attendance')
          .where('studentId', '==', uid)
          .limit(10)
          .get();
      const attendanceSummary = attendanceRef.docs.map(d => `${d.data().subjectId}: ${d.data().status}`).join(', ');
      scopedContext += `Recent Attendance: ${attendanceSummary}\n`;
    } 
    // Example: Give Faculty their subjects
    else if (role === 'Faculty') {
      const subjectsRef = await db.collection('colleges').doc(collegeId).collection('subjects')
          .where('facultyId', '==', uid)
          .get();
      const subjectsSummary = subjectsRef.docs.map(d => d.data().name).join(', ');
      scopedContext += `Assigned Subjects: ${subjectsSummary}\n`;
    }

    // Include any client-passed safe context (like current screen context)
    if (data.context && typeof data.context === 'object') {
      scopedContext += `\nCurrent UI Context: ${JSON.stringify(data.context)}`;
    }

    const systemPrompt = `You are the Acadex AI Assistant. You are a helpful AI designed to assist students and faculty in a campus management system. 
You must strictly answer the user's question based ONLY on the provided Context. 
Do not hallucinate data that is not in the Context. If you do not have enough information to answer the question, state: "I don't have enough information to answer that based on your current academic records."

Context:
${scopedContext}
`;

    // 4. Call GenAI Model
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: [
        { role: 'user', parts: [{ text: systemPrompt + "\nUser Question: " + queryStr }] }
      ],
      config: {
        temperature: 0.2, // Low temp for factual responses
      }
    });

    const answer = response.text || "I was unable to generate a response.";

    // 5. Return safe response
    return {
      answer: answer
    };

  } catch (error) {
    console.error("AI Assistant Error:", error);
    // Return a generic error to the client to avoid leaking internals
    throw new functions.https.HttpsError('internal', 'AI Service is temporarily unavailable.');
  }
});

// Helper for multi-tenant lookup if client doesn't pass collegeId
async function findUserAcrossColleges(db: admin.firestore.Firestore, uid: string): Promise<admin.firestore.DocumentSnapshot | null> {
  const colleges = await db.collection('colleges').get();
  for (const college of colleges.docs) {
    const user = await college.ref.collection('users').doc(uid).get();
    if (user.exists) return user;
  }
  return null;
}
