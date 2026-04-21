const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: process.env.MAIL_HOST,
  port: Number(process.env.MAIL_PORT),
  secure: false,
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
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

module.exports = {
  sendMail,
  sendPasswordRecoveryOtpEmail,
};
