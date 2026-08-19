"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.askAssistant = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const genai_1 = require("@google/genai");
// Initialize the GenAI SDK
// Using an environment variable or fallback to default credentials
const ai = new genai_1.GoogleGenAI({});
exports.askAssistant = functions.https.onCall(async (data, context) => {
    var _a, _b;
    // 1. Authenticate Request
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const uid = context.auth.uid;
    const db = admin.firestore();
    try {
        // 2. Fetch User Context and Tenant
        let collegeId;
        let role;
        // Check custom claims first if available
        if (context.auth.token.collegeId && context.auth.token.role) {
            collegeId = context.auth.token.collegeId;
            role = context.auth.token.role;
        }
        else {
            // Fallback: search across colleges to find the user
            // Note: In production, the client should probably pass collegeId, 
            // but verifying it server-side is more secure.
            const query = data.collegeId ?
                db.collection('colleges').doc(data.collegeId).collection('users').doc(uid) :
                await findUserAcrossColleges(db, uid);
            let userDoc = null;
            if (data.collegeId) {
                userDoc = await query.get();
            }
            else {
                userDoc = (await query);
            }
            if (!userDoc || !userDoc.exists) {
                throw new functions.https.HttpsError('permission-denied', 'User not found in any tenant.');
            }
            collegeId = ((_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.collegeId) || data.collegeId;
            role = (_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.role;
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
    }
    catch (error) {
        console.error("AI Assistant Error:", error);
        // Return a generic error to the client to avoid leaking internals
        throw new functions.https.HttpsError('internal', 'AI Service is temporarily unavailable.');
    }
});
// Helper for multi-tenant lookup if client doesn't pass collegeId
async function findUserAcrossColleges(db, uid) {
    const colleges = await db.collection('colleges').get();
    for (const college of colleges.docs) {
        const user = await college.ref.collection('users').doc(uid).get();
        if (user.exists)
            return user;
    }
    return null;
}
//# sourceMappingURL=ai.js.map