require('dotenv').config();
const axios = require('axios');

const sendMail = async ({ to, subject, text, html }) => {
  const response = await axios.post(
    'https://api.brevo.com/v3/smtp/email',
    {
      sender: { name: 'UniRide', email: 'uniride.support@gmail.com' },
      to: [{ email: to }],
      subject,
      textContent: text,
      htmlContent: html,
    },
    {
      headers: {
        'api-key': process.env.BREVO_API_KEY,
        'Content-Type': 'application/json',
      },
    }
  );
  return response.data;
};

const sendPasswordRecoveryOtpEmail = async (email, otp) => {
  return sendMail({
    to: email,
    subject: 'UniRide Password Recovery OTP',
    text: `Your password recovery OTP is ${otp}`,
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; background-color: #F9FAFB; padding: 24px;">
        <h2 style="color: #1F2937;">UniRide Password Recovery</h2>
        <p style="color: #6B7280;">Your password recovery OTP is:</p>
        <h1 style="letter-spacing: 8px; color: #14B8A6; font-size: 36px;">${otp}</h1>
        <p style="color: #6B7280;">This OTP will expire soon.</p>
      </div>
    `,
  });
};

const sendSignupOtpEmail = async (email, otpCode) => {
  return sendMail({
    to: email,
    subject: 'Your UniRide signup OTP',
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; background-color: #F9FAFB; padding: 24px;">
        <h2 style="color: #1F2937;">UniRide Email Verification</h2>
        <p style="color: #6B7280;">Your OTP for signup is:</p>
        <h1 style="letter-spacing: 8px; color: #14B8A6; font-size: 36px;">${otpCode}</h1>
        <p style="color: #6B7280;">Don't share this code with anyone. This code will expire in 1 minute.</p>
      </div>
    `,
  });
};

module.exports = {
  sendMail,
  sendPasswordRecoveryOtpEmail,
  sendSignupOtpEmail,
};
