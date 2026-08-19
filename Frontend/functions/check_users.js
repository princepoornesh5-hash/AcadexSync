const admin = require('firebase-admin');

try {
  admin.initializeApp();
  console.log('Firebase Admin initialized.');
} catch (e) {
  console.log('Cannot initialize Firebase Admin without credentials in this environment.');
  process.exit(1);
}

async function check() {
  try {
    const listUsers = await admin.auth().listUsers(10);
    console.log('Users in Firebase Auth:', listUsers.users.map(u => u.email));
  } catch (e) {
    console.log('Error checking auth:', e.message);
  }
}
check();
