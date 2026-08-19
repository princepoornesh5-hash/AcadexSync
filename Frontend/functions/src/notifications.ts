import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onNotificationCreated = functions.firestore
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
      const tokens: string[] = [];
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
      } else {
        // Fanout logic for section or role
        let query: FirebaseFirestore.Query = db.collection('colleges').doc(collegeId).collection('users');
        
        if (targetType === 'section' && targetId) {
            query = query.where('sectionId', '==', targetId);
        } else if (targetType === 'role' && targetId) {
            query = query.where('role', '==', targetId);
        } else if (targetType === 'college') {
            // Target all in college (might be large, use with caution)
        } else {
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
      } else {
        console.log('No FCM tokens found for target.');
      }
    } catch (error) {
      console.error('Error sending push notification:', error);
    }
  });
