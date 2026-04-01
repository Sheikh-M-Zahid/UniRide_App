const nodemailer = require('nodemailer');

/* =========================
   MAIL TRANSPORTER
========================= */
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

/* =========================
   PASSWORD RECOVERY OTP
========================= */
const sendPasswordRecoveryOtpEmail = async (toEmail, otpCode) => {
  const mailOptions = {
    from: `"UniRide Support" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: 'UniRide Password Recovery OTP',
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>🔐 UniRide Password Recovery</h2>
        <p>Your OTP code is:</p>
        <h1 style="letter-spacing: 6px; color:#14B8A6;">${otpCode}</h1>
        <p>This OTP will expire in 10 minutes.</p>
        <p>If you did not request this, please ignore this email.</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};

/* =========================
   SIGNUP OTP (IMPORTANT)
========================= */
const sendSignupOtpEmail = async (toEmail, otpCode) => {
  const mailOptions = {
    from: `"UniRide" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: 'UniRide Signup Verification OTP',
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>🚀 Welcome to UniRide</h2>
        <p>Your signup verification OTP is:</p>
        <h1 style="letter-spacing: 6px; color:#14B8A6;">${otpCode}</h1>
        <p>This OTP will expire in 5 minutes.</p>
        <p>Please do not share this code with anyone.</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};

/* =========================
   OPTIONAL TEST FUNCTION
========================= */
const testEmail = async (toEmail) => {
  await transporter.sendMail({
    from: `"UniRide Test" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: 'Test Email',
    text: 'Your email service is working correctly 🚀',
  });
};

module.exports = {
  sendPasswordRecoveryOtpEmail,
  sendSignupOtpEmail,
  testEmail,
};