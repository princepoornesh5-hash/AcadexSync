import * as admin from 'firebase-admin';

// Initialize Firebase Admin globally
admin.initializeApp();

// Export Cloud Functions
export * from './notifications';
export * from './ai';
