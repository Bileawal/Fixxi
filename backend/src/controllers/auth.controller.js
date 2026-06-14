const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Otp = require('../models/Otp');
const TechnicianProfile = require('../models/TechnicianProfile');
const { sendOtpEmail } = require('../utils/email');
const {
  signToken,
  signOtpToken,
  verifyOtpToken,
  generateOtp,
  fileUrl,
} = require('../utils/helpers');

async function sendCustomerOtp(req, res) {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: 'Email required' });

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const code = generateOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
    await Otp.deleteMany({ email: email.toLowerCase() });
    await Otp.create({ email: email.toLowerCase(), code, expiresAt });

    const result = await sendOtpEmail(email, code);
    if (result.devMode) {
      return res.status(503).json({
        message:
          'Email OTP is not configured. Set SMTP_USER and SMTP_PASS in backend/.env (Gmail App Password).',
      });
    }
    res.json({ message: 'OTP sent to email' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message || 'Failed to send OTP' });
  }
}

async function verifyCustomerOtp(req, res) {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({ message: 'Email and OTP required' });
    }

    const record = await Otp.findOne({ email: email.toLowerCase(), code: otp });
    if (!record || record.expiresAt < new Date()) {
      return res.status(400).json({ message: 'Invalid or expired OTP' });
    }

    record.verified = true;
    await record.save();
    const otpToken = signOtpToken(email.toLowerCase());
    res.json({ otpToken, message: 'OTP verified' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function registerCustomer(req, res) {
  try {
    const { name, phone, address, email, password, otpToken } = req.body;
    if (!name || !phone || !address || !email || !password || !otpToken) {
      return res.status(400).json({ message: 'All fields required' });
    }
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[0-9]/.test(password) || !/[^a-zA-Z0-9]/.test(password)) {
      return res.status(400).json({ message: 'Password must be at least 8 chars long with 1 capital letter, 1 number, and 1 special character' });
    }

    let payload;
    try {
      payload = verifyOtpToken(otpToken);
    } catch {
      return res.status(400).json({ message: 'Invalid OTP token' });
    }
    if (payload.email !== email.toLowerCase()) {
      return res.status(400).json({ message: 'OTP token mismatch' });
    }

    const otpRecord = await Otp.findOne({ email: email.toLowerCase(), verified: true });
    if (!otpRecord) {
      return res.status(400).json({ message: 'Please verify OTP first' });
    }

    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      phone,
      address,
      email: email.toLowerCase(),
      password: hash,
      role: 'customer',
      emailVerified: true,
    });

    await Otp.deleteMany({ email: email.toLowerCase() });
    const token = signToken(user._id, user.role);
    res.status(201).json({ token, user: user.toPublicJSON() });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ message: 'Email already registered' });
    }
    res.status(500).json({ message: err.message });
  }
}

async function registerTechnician(req, res) {
  try {
    const {
      name,
      fatherName,
      address,
      phone,
      email,
      password,
      skills,
      extraSkills,
    } = req.body;

    if (!name || !fatherName || !address || !phone || !email || !password) {
      return res.status(400).json({ message: 'Required fields missing' });
    }
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[0-9]/.test(password) || !/[^a-zA-Z0-9]/.test(password)) {
      return res.status(400).json({ message: 'Password must be at least 8 chars long with 1 capital letter, 1 number, and 1 special character' });
    }

    const front = req.files?.idCardFront?.[0];
    const back = req.files?.idCardBack?.[0];
    if (!front || !back) {
      return res.status(400).json({ message: 'ID card front and back required' });
    }

    let skillsList = [];
    if (skills) {
      try {
        skillsList = typeof skills === 'string' ? JSON.parse(skills) : skills;
      } catch {
        skillsList = Array.isArray(skills) ? skills : [skills];
      }
    }
    if (!Array.isArray(skillsList) || skillsList.length === 0) {
      return res.status(400).json({ message: 'Select at least one skill' });
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      fatherName,
      address,
      phone,
      email: email.toLowerCase(),
      password: hash,
      role: 'technician',
      isAvailable: false,
    });

    await TechnicianProfile.create({
      userId: user._id,
      skills: skillsList,
      extraSkills: extraSkills || '',
      idCardFrontUrl: fileUrl(front.filename),
      idCardBackUrl: fileUrl(back.filename),
      status: 'pending_admin',
    });

    const token = signToken(user._id, user.role);
    const profile = await TechnicianProfile.findOne({ userId: user._id });
    res.status(201).json({
      token,
      user: user.toPublicJSON(),
      technicianProfile: profile.toPublicJSON(),
    });
  } catch (err) {
    console.error(err);
    if (err.code === 11000) {
      return res.status(400).json({ message: 'Email already registered' });
    }
    res.status(500).json({ message: err.message });
  }
}

async function login(req, res) {
  try {
    const { email, password, role } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (role && user.role !== role) {
      return res.status(401).json({ message: `Not a ${role} account` });
    }

    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (user.role !== 'admin' && user.isCurrentlySuspended()) {
      return res.status(403).json({
        message: `Account suspended. ${user.suspensionReason || 'Contact admin.'}`,
      });
    }

    const token = signToken(user._id, user.role);

    // Save FCM token if provided
    if (req.body.fcmToken) {
      user.fcmToken = req.body.fcmToken;
      await user.save();
    }

    const payload = { token, user: user.toPublicJSON() };

    if (user.role === 'technician') {
      const profile = await TechnicianProfile.findOne({ userId: user._id });
      payload.technicianProfile = profile?.toPublicJSON();
    }

    res.json(payload);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getMe(req, res) {
  const payload = { user: req.user.toPublicJSON() };
  if (req.user.role === 'technician') {
    const profile = await TechnicianProfile.findOne({ userId: req.user._id });
    payload.technicianProfile = profile?.toPublicJSON();
  }
  res.json(payload);
}

async function updateFcmToken(req, res) {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ message: 'fcmToken required' });
    await User.findByIdAndUpdate(req.user._id, { fcmToken });
    res.json({ message: 'FCM token updated' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

module.exports = {
  sendCustomerOtp,
  verifyCustomerOtp,
  registerCustomer,
  registerTechnician,
  login,
  getMe,
  updateFcmToken,
};
