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
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: email,
    subject: 'UniRide Password Recovery OTP',
    text: `Your password recovery OTP is ${otp}`,
  });
};

module.exports = {
  sendPasswordRecoveryOtpEmail,
};

  return sendMail({
    to: email,
    subject,
    text,
    html,
  });
};

module.exports = {
  sendMail,
  sendPasswordRecoveryOtpEmail,
};