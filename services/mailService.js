const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: process.env.MAIL_HOST,
  port: 587,
  secure: false,
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
  tls: {
    rejectUnauthorized: false,
  },
  requireTLS: true,
  connectionTimeout: 10000,
  greetingTimeout: 10000,
  socketTimeout: 15000,
});

const sendMail = async ({ to, subject, text, html }) => {
  const mailOptions = {
    from: process.env.MAIL_FROM || process.env.MAIL_USER,
    to,
    subject,
    text,
    html,
  };

  return transporter.sendMail(mailOptions);
};

const sendPasswordRecoveryOtpEmail = async (email, otp) => {
  return sendMail({
    to: email,
    subject: 'UniRide Password Recovery OTP',
    text: `Your password recovery OTP is ${otp}`,
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>UniRide Password Recovery</h2>
        <p>Your password recovery OTP is:</p>
        <h1 style="letter-spacing: 4px;">${otp}</h1>
        <p>This OTP will expire soon.</p>
      </div>
    `,
  });
};

const sendSignupOtpEmail = async (email, otpCode) => {
  await transporter.sendMail({
    from: process.env.MAIL_FROM || process.env.EMAIL_USER,
    to: email,
    subject: 'Your UniRide signup OTP',
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>UniRide Email Verification</h2>
        <p>Your OTP for signup is:</p>
        <h1 style="letter-spacing: 4px;">${otpCode}</h1>
        <p>Don't share this code with anyone. This code will expire in 1 minutes.</p>
      </div>
    `,
  });
};

module.exports = {
  sendMail,
  sendPasswordRecoveryOtpEmail,
  sendSignupOtpEmail,
};
