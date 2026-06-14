const admin = require('firebase-admin');
const path = require('path');

let initialized = false;

function initFCM() {
  if (initialized) return;
  try {
    const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    initialized = true;
    console.log('[FCM] Firebase Admin initialized');
  } catch (err) {
    console.warn('[FCM] Could not initialize Firebase Admin:', err.message);
  }
}

async function sendPushNotification(fcmToken, title, body) {
  if (!initialized) return;
  if (!fcmToken) return;
  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'fixxi_channel',
        },
      },
    });
  } catch (err) {
    console.warn('[FCM] Push failed:', err.message);
  }
}

module.exports = { initFCM, sendPushNotification };
