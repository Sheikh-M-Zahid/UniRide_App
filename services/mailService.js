const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const sendPasswordRecoveryOtpEmail = async (toEmail, otpCode) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: toEmail,
    subject: 'UniRide Password Recovery OTP',
    html: `
      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>UniRide Password Recovery</h2>
        <p>Your OTP code is:</p>
        <h1 style="letter-spacing: 4px;">${otpCode}</h1>
        <p>This OTP will expire in 10 minutes.</p>
        <p>If you did not request this, please ignore this email.</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};

module.exports = {
  sendPasswordRecoveryOtpEmail,
};