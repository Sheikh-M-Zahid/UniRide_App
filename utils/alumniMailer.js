// Alumni contact-request email notification.
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT || 587),
  secure: Number(process.env.SMTP_PORT) === 465,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

exports.sendAlumniRequestEmail = async ({
  toEmail,
  alumniFirstName,
  requesterName,
  requestMessage,
}) => {
  if (!toEmail) return;

  const safeMessage = (requestMessage || '').trim();

  const html = `
  <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; color: #1F2937;">
    <div style="background: linear-gradient(135deg, #14B8A6, #0F766E); padding: 28px 24px; border-radius: 12px 12px 0 0;">
      <h2 style="color: #ffffff; margin: 0; font-size: 20px;">New Connection Request</h2>
    </div>
    <div style="background: #ffffff; border: 1px solid #E5E7EB; border-top: none; border-radius: 0 0 12px 12px; padding: 28px 24px;">
      <p style="font-size: 15px; line-height: 1.6;">Dear ${alumniFirstName || 'Alumni'},</p>

      <p style="font-size: 15px; line-height: 1.6;">
        <strong>${requesterName}</strong> would like to connect with you through UniRide's Alumni network.
      </p>

      ${
        safeMessage
          ? `<div style="background: #F1F5F9; border-left: 3px solid #14B8A6; padding: 14px 16px; border-radius: 8px; margin: 16px 0;">
               <p style="margin: 0; font-size: 14px; font-style: italic; color: #374151;">"${safeMessage}"</p>
             </div>`
          : ''
      }

      <p style="font-size: 15px; line-height: 1.6;">
        Please open the UniRide app to review this request — check your
        <strong>Notifications</strong>, or go to
        <strong>Services → Alumni → Your Profile (top right) → Connection Requests (next to the edit icon)</strong>.
      </p>

      <p style="font-size: 15px; line-height: 1.6; margin-top: 24px;">
        Thank you for being part of our community.
      </p>

      <p style="font-size: 14px; color: #6B7280; font-style: italic; margin-top: 8px;">
        "Building bonds of trust and connection."
      </p>

      <p style="font-size: 15px; margin-top: 20px; color: #0F766E; font-weight: 600;">
        — UniRide Team
      </p>
    </div>
  </div>
  `;

  await transporter.sendMail({
    from: process.env.EMAIL_FROM || `"UniRide" <no-reply@uniride.app>`,
    to: toEmail,
    subject: `${requesterName} wants to connect with you on UniRide`,
    html,
  });
};
