const { sendMail } = require('./mailService');

// ── Rider accepted করলে Sender কে email ──
const sendRiderAcceptedEmailToSender = async ({
  senderEmail,
  senderName,
  riderName,
  riderPhone,
  itemType,
  pickupLocation,
  dropLocation,
  deliveryFee,
}) => {
  await sendMail({
    to: senderEmail,
    subject: `UniRide: Rider Found for Your ${itemType} Delivery`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #e5e7eb; border-radius: 12px; overflow: hidden;">
        <div style="background: #14B8A6; padding: 24px; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 22px;">UniRide Delivery</h1>
          <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0 0;">Your delivery request has been accepted!</p>
        </div>
        <div style="padding: 28px;">
          <p style="font-size: 16px; color: #1F2937;">Hi <strong>${senderName}</strong>,</p>
          <p style="color: #374151;">Great news! A rider has accepted your delivery request. Here are the details:</p>

          <div style="background: #f0fdf4; border: 1px solid #86efac; border-radius: 8px; padding: 18px; margin: 20px 0;">
            <h3 style="color: #15803d; margin: 0 0 12px 0;">🏍️ Rider Information</h3>
            <p style="margin: 6px 0; color: #1F2937;"><strong>Name:</strong> ${riderName}</p>
            <p style="margin: 6px 0; color: #1F2937;"><strong>Phone:</strong> ${riderPhone}</p>
          </div>

          <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 18px; margin: 20px 0;">
            <h3 style="color: #0f766e; margin: 0 0 12px 0;">📦 Delivery Details</h3>
            <p style="margin: 6px 0; color: #1F2937;"><strong>Item:</strong> ${itemType}</p>
            <p style="margin: 6px 0; color: #1F2937;"><strong>Pickup:</strong> ${pickupLocation}</p>
            <p style="margin: 6px 0; color: #1F2937;"><strong>Destination:</strong> ${dropLocation}</p>
            <p style="margin: 6px 0; color: #1F2937;"><strong>Delivery Fee:</strong> ৳${deliveryFee}</p>
          </div>

          <p style="color: #6b7280; font-size: 14px;">You can track your delivery in the UniRide app. If you need to contact the rider, please call the number above.</p>
          <p style="color: #6b7280; font-size: 14px; margin-top: 20px;">Thank you for using UniRide! 🚀</p>
        </div>
        <div style="background: #f9fafb; padding: 16px; text-align: center; border-top: 1px solid #e5e7eb;">
          <p style="color: #9ca3af; font-size: 12px; margin: 0;">UniRide — East West University Campus Delivery</p>
        </div>
      </div>
    `,
  });
};

// ── Pickup email to Receiver ──
const sendPickupEmail = async ({
  receiverEmail,
  senderName,
  itemType,
  riderName,
  riderPhone,
  pickedUpAt,
  trackingUrl,
}) => {
  const timeStr = pickedUpAt
    ? new Date(pickedUpAt).toLocaleString('en-BD', { timeZone: 'Asia/Dhaka' })
    : 'Just now';

  await sendMail({
    to: receiverEmail,
    subject: `UniRide: Your ${itemType} is On The Way!`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #e5e7eb; border-radius: 12px; overflow: hidden;">
        <div style="background: #14B8A6; padding: 24px; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 22px;">UniRide Delivery</h1>
          <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0 0;">Your item is on the way!</p>
        </div>
        <div style="padding: 28px;">
          <p style="font-size: 16px; color: #1F2937;">Hello,</p>
          <p style="color: #374151;"><strong>${senderName}</strong> sent you a <strong>${itemType}</strong>. The rider has picked it up and is heading your way.</p>

          <div style="background: #eff6ff; border: 1px solid #93c5fd; border-radius: 8px; padding: 18px; margin: 20px 0;">
            <h3 style="color: #1d4ed8; margin: 0 0 12px 0;">🏍️ Rider Details</h3>
            <p style="margin: 6px 0; color: #1F2937;"><strong>Name:</strong> ${riderName}</p>
            <p style="margin: 6px 0; color: #1F2937;"><strong>Phone:</strong> ${riderPhone}</p>
            <p style="margin: 6px 0; color: #1F2937;"><strong>Picked Up At:</strong> ${timeStr}</p>
          </div>

          <p style="color: #6b7280; font-size: 14px;">Please be available to receive your item. You can contact the rider using the number above.</p>
        </div>
        <div style="background: #f9fafb; padding: 16px; text-align: center; border-top: 1px solid #e5e7eb;">
          <p style="color: #9ca3af; font-size: 12px; margin: 0;">UniRide — East West University Campus Delivery</p>
        </div>
      </div>
    `,
  });
};

// ── Delivery completed email to Sender ──
const sendDeliveryCompletedEmailToSender = async ({
  senderEmail,
  senderName,
  receiverName,
  itemType,
}) => {
  await sendMail({
    to: senderEmail,
    subject: `UniRide: Your ${itemType} Has Been Delivered! ✅`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #e5e7eb; border-radius: 12px; overflow: hidden;">
        <div style="background: #16a34a; padding: 24px; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 22px;">✅ Delivery Completed</h1>
          <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0 0;">Your item has been successfully delivered!</p>
        </div>
        <div style="padding: 28px;">
          <p style="font-size: 16px; color: #1F2937;">Hi <strong>${senderName}</strong>,</p>
          <p style="color: #374151;">Your <strong>${itemType}</strong> has been successfully delivered to <strong>${receiverName}</strong>.</p>
          <p style="color: #6b7280; font-size: 14px; margin-top: 16px;">Thank you for using UniRide delivery service. We hope your experience was great!</p>
        </div>
        <div style="background: #f9fafb; padding: 16px; text-align: center; border-top: 1px solid #e5e7eb;">
          <p style="color: #9ca3af; font-size: 12px; margin: 0;">UniRide — East West University Campus Delivery</p>
        </div>
      </div>
    `,
  });
};

// ── Delivery completed email to Receiver ──
const sendDeliveryCompletedEmailToReceiver = async ({
  receiverEmail,
  itemType,
}) => {
  await sendMail({
    to: receiverEmail,
    subject: `UniRide: Your ${itemType} Has Arrived! 📦`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #e5e7eb; border-radius: 12px; overflow: hidden;">
        <div style="background: #16a34a; padding: 24px; text-align: center;">
          <h1 style="color: white; margin: 0; font-size: 22px;">📦 Item Delivered</h1>
          <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0 0;">Your item has arrived!</p>
        </div>
        <div style="padding: 28px;">
          <p style="font-size: 16px; color: #1F2937;">Hello,</p>
          <p style="color: #374151;">Your <strong>${itemType}</strong> has been delivered to you via UniRide.</p>
          <p style="color: #6b7280; font-size: 14px; margin-top: 16px;">If you did not receive this item or have any issues, please contact UniRide support immediately.</p>
        </div>
        <div style="background: #f9fafb; padding: 16px; text-align: center; border-top: 1px solid #e5e7eb;">
          <p style="color: #9ca3af; font-size: 12px; margin: 0;">UniRide — East West University Campus Delivery</p>
        </div>
      </div>
    `,
  });
};

module.exports = {
  sendRiderAcceptedEmailToSender,
  sendPickupEmail,
  sendDeliveryCompletedEmailToSender,
  sendDeliveryCompletedEmailToReceiver,
};
