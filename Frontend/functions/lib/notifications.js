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
exports.onNotificationCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
exports.onNotificationCreated = functions.firestore
    .document('colleges/{collegeId}/notifications/{notificationId}')
    .onCreate(async (snap, context) => {
    const notification = snap.data();
    const collegeId = context.params.collegeId;
    if (!notification) {
        console.error('No notification data found.');
        return;
    }
    const targetType = notification.targetType; // e.g., 'user', 'role', 'section', 'college'
    const targetId = notification.targetId; // e.g., userId, sectionId
    const title = notification.title || 'New Notification';
    const message = notification.message || '';
    const payload = {
        notification: {
            title: title,
            body: message,
        },
        data: {
            notificationId: snap.id,
            collegeId: collegeId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
    };
    try {
        const tokens = [];
        const db = admin.firestore();
        if (targetType === 'user' && targetId) {
            // Fetch tokens for a single user
            const userDoc = await db.collection('colleges').doc(collegeId).collection('users').doc(targetId).get();
            if (userDoc.exists) {
                const userData = userDoc.data();
                if (userData && userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
                    tokens.push(...userData.fcmTokens);
                }
            }
        }
        else {
            // Fanout logic for section or role
            let query = db.collection('colleges').doc(collegeId).collection('users');
            if (targetType === 'section' && targetId) {
                query = query.where('sectionId', '==', targetId);
            }
            else if (targetType === 'role' && targetId) {
                query = query.where('role', '==', targetId);
            }
            else if (targetType === 'college') {
                // Target all in college (might be large, use with caution)
            }
            else {
                console.warn(`Unsupported targetType: ${targetType}`);
                return;
            }
            const querySnapshot = await query.get();
            querySnapshot.forEach(doc => {
                const userData = doc.data();
                if (userData && userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
                    tokens.push(...userData.fcmTokens);
                }
            });
        }
        if (tokens.length > 0) {
            // Send to devices
            const response = await admin.messaging().sendToDevice(tokens, payload);
            console.log(`Successfully sent message to ${response.successCount} devices. Failed: ${response.failureCount}`);
            // Optional: Clean up failed tokens based on response.results
        }
        else {
            console.log('No FCM tokens found for target.');
        }
    }
    catch (error) {
        console.error('Error sending push notification:', error);
    }
});
//# sourceMappingURL=notifications.js.map