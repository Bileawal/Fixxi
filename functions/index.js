const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const nodemailer = require('nodemailer');

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const OTP_EXPIRY_MS = 5 * 60 * 1000;
const MAX_VERIFY_ATTEMPTS = 5;
const RATE_LIMIT_MAX = 3;
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000;
const COLLECTION = 'otp_verifications';

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function generateOtpCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function getSmtpConfig() {
  return {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: Number(process.env.SMTP_PORT || 587),
  };
}

function createTransporter() {
  const { user, pass, host, port } = getSmtpConfig();
  if (!user || !pass) return null;

  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  });
}

function buildOtpEmailHtml(otp) {
  return `
  <!DOCTYPE html>
  <html>
  <head><meta charset="UTF-8"/></head>
  <body style="font-family:Arial,sans-serif;background:#f1f5f9;margin:0;padding:0;">
    <div style="max-width:480px;margin:40px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
      <div style="background:linear-gradient(135deg,#22C55E,#16A34A);padding:32px 24px;text-align:center;">
        <h1 style="color:white;margin:0;font-size:28px;">Fixxi</h1>
        <p style="color:rgba(255,255,255,0.85);margin:6px 0 0;font-size:14px;">Email verification code</p>
      </div>
      <div style="padding:32px 28px;">
        <p style="color:#475569;font-size:15px;line-height:1.6;">Use this code to verify your email:</p>
        <div style="background:#f0fdf4;border:2px solid #bbf7d0;border-radius:14px;padding:24px;text-align:center;margin:24px 0;">
          <div style="font-size:40px;font-weight:800;letter-spacing:10px;color:#15803d;">${otp}</div>
          <small style="display:block;color:#64748b;font-size:12px;margin-top:8px;">Expires in 5 minutes</small>
        </div>
        <p style="color:#475569;font-size:14px;">If you did not request this, ignore this email.</p>
      </div>
    </div>
  </body>
  </html>`;
}

async function sendOtpEmail(email, otp) {
  const transporter = createTransporter();
  const { user } = getSmtpConfig();

  if (!transporter) {
    throw new HttpsError(
      'failed-precondition',
      'Email service is not configured. Set SMTP_USER and SMTP_PASS for Cloud Functions.',
    );
  }

  await transporter.sendMail({
    from: `"Fixxi" <${user}>`,
    to: email,
    subject: 'Fixxi - Your Email Verification Code',
    text: `Your Fixxi verification code is: ${otp}\n\nThis code expires in 5 minutes.`,
    html: buildOtpEmailHtml(otp),
  });
}

function filterRecentTimestamps(timestamps, windowMs) {
  const cutoff = Date.now() - windowMs;
  return timestamps.filter((ts) => {
    const ms = ts instanceof admin.firestore.Timestamp ? ts.toMillis() : Number(ts);
    return ms >= cutoff;
  });
}

exports.sendOtp = onCall({ cors: true }, async (request) => {
  const email = normalizeEmail(request.data?.email);

  if (!email || !isValidEmail(email)) {
    throw new HttpsError('invalid-argument', 'A valid email address is required.');
  }

  const docRef = db.collection(COLLECTION).doc(email);
  const existingSnap = await docRef.get();
  const now = admin.firestore.Timestamp.now();

  let sendHistory = [];
  if (existingSnap.exists) {
    sendHistory = filterRecentTimestamps(
      existingSnap.data().sendHistory || [],
      RATE_LIMIT_WINDOW_MS,
    );
  }

  if (sendHistory.length >= RATE_LIMIT_MAX) {
    throw new HttpsError(
      'resource-exhausted',
      'Too many OTP requests. Maximum 3 codes per 15 minutes. Please try again later.',
    );
  }

  const code = generateOtpCode();
  const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + OTP_EXPIRY_MS);

  sendHistory.push(now);

  await docRef.set({
    code,
    createdAt: now,
    expiresAt,
    verified: false,
    attempts: 0,
    sendHistory,
  });

  try {
    await sendOtpEmail(email, code);
  } catch (err) {
    await docRef.delete();
    console.error('[sendOtp] Email failed:', err);
    throw new HttpsError('internal', 'Failed to send OTP email. Please try again.');
  }

  return {
    success: true,
    message: `OTP sent to ${email}`,
    expiresInSeconds: OTP_EXPIRY_MS / 1000,
  };
});

exports.verifyOtp = onCall({ cors: true }, async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = String(request.data?.code || '').trim();

  if (!email || !isValidEmail(email)) {
    throw new HttpsError('invalid-argument', 'A valid email address is required.');
  }

  if (!/^\d{6}$/.test(code)) {
    throw new HttpsError('invalid-argument', 'OTP must be a 6-digit code.');
  }

  const docRef = db.collection(COLLECTION).doc(email);
  const snap = await docRef.get();

  if (!snap.exists) {
    throw new HttpsError(
      'not-found',
      'No OTP found for this email. Please request a new code.',
    );
  }

  const data = snap.data();
  const attempts = data.attempts || 0;

  if (data.expiresAt.toMillis() < Date.now()) {
    await docRef.delete();
    throw new HttpsError('deadline-exceeded', 'OTP code expired. Please request a new one.');
  }

  if (attempts >= MAX_VERIFY_ATTEMPTS) {
    await docRef.delete();
    throw new HttpsError(
      'resource-exhausted',
      'Too many failed attempts. Please request a new OTP.',
    );
  }

  if (data.code !== code) {
    const newAttempts = attempts + 1;
    if (newAttempts >= MAX_VERIFY_ATTEMPTS) {
      await docRef.delete();
      throw new HttpsError(
        'resource-exhausted',
        'Too many failed attempts. Please request a new OTP.',
      );
    }

    await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
    throw new HttpsError('invalid-argument', 'Wrong OTP code. Please try again.');
  }

  await docRef.update({ verified: true });
  await docRef.delete();

  return {
    success: true,
    message: 'Email verified successfully',
    otpToken: `verified_${email}_${Date.now()}`,
  };
});

exports.sendPush = onCall({ cors: true }, async (request) => {
  const { token, title, body } = request.data;
  if (!token) {
    throw new HttpsError('invalid-argument', 'FCM token is required');
  }
  
  const payload = {
    notification: {
      title: title || 'Fixxi',
      body: body || '',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'fixxi_channel'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    },
    token: token
  };
  
  try {
    await admin.messaging().send(payload);
    return { success: true };
  } catch (err) {
    console.error('[sendPush] Error sending push notification:', err);
    throw new HttpsError('internal', 'Push notification failed');
  }
});
