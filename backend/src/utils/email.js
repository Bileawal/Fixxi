const nodemailer = require('nodemailer');

function createTransporter() {
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
    return null;
  }
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: Number(process.env.SMTP_PORT) || 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
}

async function sendOtpEmail(email, otp) {
  const transporter = createTransporter();
  const subject = 'Fixxi - Email Verification OTP';
  const text = `Your Fixxi verification code is: ${otp}\n\nValid for 10 minutes.`;

  if (!transporter) {
    console.warn(`[OTP] SMTP not configured — cannot email ${email}`);
    return { devMode: true };
  }

  await transporter.sendMail({
    from: `"Fixxi" <${process.env.SMTP_USER}>`,
    to: email,
    subject,
    text,
    html: `<p>Your Fixxi verification code is:</p><h2>${otp}</h2><p>Valid for 10 minutes.</p>`,
  });
  return { devMode: false };
}

module.exports = { sendOtpEmail };
