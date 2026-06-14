const jwt = require('jsonwebtoken');

function signToken(userId, role) {
  return jwt.sign({ userId, role }, process.env.JWT_SECRET, { expiresIn: '7d' });
}

function signOtpToken(email) {
  return jwt.sign({ email, purpose: 'otp' }, process.env.JWT_OTP_SECRET || process.env.JWT_SECRET, {
    expiresIn: '15m',
  });
}

function verifyOtpToken(token) {
  return jwt.verify(token, process.env.JWT_OTP_SECRET || process.env.JWT_SECRET);
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function fileUrl(filename) {
  const base = process.env.BASE_URL || 'http://localhost:3000';
  return `${base}/uploads/${filename}`;
}

function haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function checkFee(distanceKm) {
  if (distanceKm <= 4) return 300;
  if (distanceKm <= 8) return 500;
  return 500;
}

module.exports = {
  signToken,
  signOtpToken,
  verifyOtpToken,
  generateOtp,
  fileUrl,
  haversineKm,
  checkFee,
};
