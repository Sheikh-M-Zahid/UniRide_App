const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.MAIL_HOST,
  port: Number(process.env.MAIL_PORT),
  secure: false,
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
});

// Verify connection on startup
transporter.verify((error) => {
  if (error) {
    console.error('Email transporter error:', error.message);
  } else {
    console.log('✅ Email service ready');
  }
});

const sendPickupEmail = async ({ receiverEmail, senderName, itemType, riderName, riderPhone, pickedUpAt, trackingUrl }) => {
  const formattedTime = new Date(pickedUpAt).toLocaleString('en-US', {
    timeZone: 'Asia/Dhaka',
    dateStyle: 'medium',
    timeStyle: 'short',
  });

  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: receiverEmail,
    subject: `📦 Your item is on the way — UniRide Delivery`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 24px; border: 1px solid #e5e7eb; border-radius: 12px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #14B8A6; margin: 0;">UniRide Delivery</h2>
          <p style="color: #6b7280; margin: 4px 0;">Item Pickup Notification</p>
        </div>

        <p style="color: #1f2937; font-size: 15px;">Hello,</p>
        <p style="color: #1f2937; font-size: 15px;">
          <strong>${senderName}</strong> has sent you a <strong>${itemType}</strong>. 
          Your item has been picked up and is now on its way to you.
        </p>

        <div style="background: #f9fafb; border-radius: 10px; padding: 18px; margin: 20px 0;">
          <h3 style="color: #0f766e; margin-top: 0;">Delivery Details</h3>
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 8px 0; color: #6b7280; width: 140px;">Item</td>
              <td style="padding: 8px 0; color: #1f2937; font-weight: 600;">${itemType}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #6b7280;">Sent By</td>
              <td style="padding: 8px 0; color: #1f2937; font-weight: 600;">${senderName}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #6b7280;">Rider Name</td>
              <td style="padding: 8px 0; color: #1f2937; font-weight: 600;">${riderName}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #6b7280;">Rider Phone</td>
              <td style="padding: 8px 0; color: #1f2937; font-weight: 600;">${riderPhone}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #6b7280;">Picked Up At</td>
              <td style="padding: 8px 0; color: #1f2937; font-weight: 600;">${formattedTime}</td>
            </tr>
          </table>
        </div>

        <div style="text-align: center; margin: 24px 0;">
          <a href="${trackingUrl}" 
             style="background: #14B8A6; color: white; padding: 12px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 15px;">
            📍 Track Your Delivery
          </a>
        </div>

        <p style="color: #6b7280; font-size: 13px; text-align: center; margin-top: 24px;">
          If you have any questions, contact the rider directly at <strong>${riderPhone}</strong>.<br/>
          — UniRide Team
        </p>
      </div>
    `,
  });
};

const sendDeliveryCompletedEmailToSender = async ({ senderEmail, senderName, receiverName, itemType }) => {
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: senderEmail,
    subject: `✅ Your item has been delivered — UniRide`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 24px; border: 1px solid #e5e7eb; border-radius: 12px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #14B8A6; margin: 0;">UniRide Delivery</h2>
          <p style="color: #6b7280; margin: 4px 0;">Delivery Completed</p>
        </div>

        <p style="color: #1f2937; font-size: 15px;">Dear <strong>${senderName}</strong>,</p>
        <p style="color: #1f2937; font-size: 15px;">
          Great news! Your <strong>${itemType}</strong> has been successfully delivered to 
          <strong>${receiverName}</strong>.
        </p>

        <div style="background: #f0fdf4; border-left: 4px solid #16a34a; padding: 16px; border-radius: 6px; margin: 20px 0;">
          <p style="color: #15803d; margin: 0; font-weight: 600;">✅ Delivery Successful</p>
          <p style="color: #166534; margin: 6px 0 0 0; font-size: 14px;">
            Your item reached its destination safely.
          </p>
        </div>

        <p style="color: #1f2937; font-size: 15px;">
          Thank you for trusting UniRide for your delivery needs. 
          We are always here to make your deliveries fast, safe, and reliable.
        </p>
        <p style="color: #1f2937; font-size: 15px;">
          We hope to serve you again soon. Stay with <strong>UniRide</strong>! 🚀
        </p>

        <p style="color: #6b7280; font-size: 13px; text-align: center; margin-top: 24px;">
          — UniRide Team | uniride.support@gmail.com
        </p>
      </div>
    `,
  });
};

const sendDeliveryCompletedEmailToReceiver = async ({ receiverEmail, itemType }) => {
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: receiverEmail,
    subject: `📬 Your delivery is complete — UniRide`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 24px; border: 1px solid #e5e7eb; border-radius: 12px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #14B8A6; margin: 0;">UniRide Delivery</h2>
          <p style="color: #6b7280; margin: 4px 0;">Item Received</p>
        </div>

        <p style="color: #1f2937; font-size: 15px;">Hello,</p>
        <p style="color: #1f2937; font-size: 15px;">
          Your <strong>${itemType}</strong> delivery has been completed successfully. 
          We hope everything arrived in perfect condition!
        </p>

        <div style="background: #f0fdf4; border-left: 4px solid #16a34a; padding: 16px; border-radius: 6px; margin: 20px 0;">
          <p style="color: #15803d; margin: 0; font-weight: 600;">✅ Item Delivered Successfully</p>
        </div>

        <p style="color: #1f2937; font-size: 15px;">
          Thank you for being a part of the UniRide community. 
          We look forward to serving you again. Stay with <strong>UniRide</strong>! 🚀
        </p>

        <p style="color: #6b7280; font-size: 13px; text-align: center; margin-top: 24px;">
          — UniRide Team | uniride.support@gmail.com
        </p>
      </div>
    `,
  });
};

module.exports = {
  sendPickupEmail,
  sendDeliveryCompletedEmailToSender,
  sendDeliveryCompletedEmailToReceiver,
};
