const rideDb = require('../config/rideDb');
const {
  createNotification,
  createBulkNotifications,
} = require('./notificationService');

const getAdminUserIds = async () => {
  const result = await rideDb.query(
    `SELECT DISTINCT user_id
     FROM user_roles
     WHERE role = 'admin'`
  );

  return result.rows.map((row) => row.user_id).filter(Boolean);
};

const notifyAdmins = async ({ title, message, relatedId, isImportant = true }) => {
  const adminUserIds = await getAdminUserIds();

  if (!adminUserIds.length) return [];

  const payloads = adminUserIds.map((adminId) => ({
    userId: adminId,
    title,
    message,
    type: 'adminNotice',
    isImportant,
    targetRole: 'admin',
    relatedId,
  }));

  return createBulkNotifications(payloads);
};

const notifySendItemCreated = async (item) => {
  await createNotification({
    userId: item.sender_id,
    title: 'Send Item Request Submitted',
    message: `Your ${item.item_type} delivery request has been created successfully.`,
    type: 'sendItem',
    isImportant: false,
    targetRole: 'passenger',
    relatedId: item.s_id,
  });

  await notifyAdmins({
    title: 'New Send Item Request',
    message: `A new send item request has been created for ${item.item_type}.`,
    relatedId: item.s_id,
    isImportant: true,
  });
};

const notifySendItemAccepted = async (item) => {
  const payloads = [];

  if (item.sender_id) {
    payloads.push({
      userId: item.sender_id,
      title: 'Rider Accepted Your Item Request',
      message: `${item.rider_name || 'A rider'} accepted your ${item.item_type} delivery request.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: item.s_id,
    });
  }

  if (item.receiver_id) {
    payloads.push({
      userId: item.receiver_id,
      title: 'Incoming Item Delivery',
      message: `A rider accepted an item delivery that will be delivered to you.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: item.s_id,
    });
  }

  if (item.rider_id) {
    payloads.push({
      userId: item.rider_id,
      title: 'Send Item Job Accepted',
      message: `You accepted the ${item.item_type} delivery request successfully.`,
      type: 'sendItem',
      isImportant: false,
      targetRole: 'rider',
      relatedId: item.s_id,
    });
  }

  await createBulkNotifications(payloads);

  await notifyAdmins({
    title: 'Send Item Request Accepted',
    message: `A rider accepted the ${item.item_type} send item request.`,
    relatedId: item.s_id,
    isImportant: false,
  });
};

const notifySendItemPickedUp = async (item) => {
  const payloads = [];

  if (item.sender_id) {
    payloads.push({
      userId: item.sender_id,
      title: 'Item Picked Up',
      message: `Your ${item.item_type} has been picked up by the rider.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: item.s_id,
    });
  }

  if (item.receiver_id) {
    payloads.push({
      userId: item.receiver_id,
      title: 'Item On The Way',
      message: `Your incoming ${item.item_type} is now on the way.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: item.s_id,
    });
  }

  if (item.rider_id) {
    payloads.push({
      userId: item.rider_id,
      title: 'Pickup Confirmed',
      message: `You picked up the ${item.item_type}. Deliver it to the receiver now.`,
      type: 'sendItem',
      isImportant: false,
      targetRole: 'rider',
      relatedId: item.s_id,
    });
  }

  await createBulkNotifications(payloads);

  await notifyAdmins({
    title: 'Send Item Picked Up',
    message: `The ${item.item_type} send item request has been picked up.`,
    relatedId: item.s_id,
    isImportant: false,
  });
};

const notifySendItemDelivered = async (item) => {
  const payloads = [];

  if (item.sender_id) {
    payloads.push({
      userId: item.sender_id,
      title: 'Item Delivered',
      message: `Your ${item.item_type} has been delivered successfully.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: item.s_id,
    });
  }

  if (item.receiver_id) {
    payloads.push({
      userId: item.receiver_id,
      title: 'Item Delivery Completed',
      message: `Your ${item.item_type} delivery has been completed successfully.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: item.s_id,
    });
  }

  if (item.rider_id) {
    payloads.push({
      userId: item.rider_id,
      title: 'Delivery Completed',
      message: `You successfully delivered the ${item.item_type}.`,
      type: 'sendItem',
      isImportant: false,
      targetRole: 'rider',
      relatedId: item.s_id,
    });
  }

  await createBulkNotifications(payloads);

  await notifyAdmins({
    title: 'Send Item Delivered',
    message: `The ${item.item_type} send item request has been delivered.`,
    relatedId: item.s_id,
    isImportant: false,
  });
};

const notifySendItemCancelled = async (item, cancelledByUserId = null) => {
  const payloads = [];

  if (item.sender_id && String(item.sender_id) !== String(cancelledByUserId)) {
    payloads.push({
      userId: item.sender_id,
      title: 'Send Item Cancelled',
      message: `The ${item.item_type} delivery request has been cancelled.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: item.s_id,
    });
  }

  if (item.receiver_id) {
    payloads.push({
      userId: item.receiver_id,
      title: 'Item Delivery Cancelled',
      message: `The ${item.item_type} delivery request for you has been cancelled.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'passenger',
      relatedId: item.s_id,
    });
  }

  if (item.rider_id && String(item.rider_id) !== String(cancelledByUserId)) {
    payloads.push({
      userId: item.rider_id,
      title: 'Send Item Job Cancelled',
      message: `The ${item.item_type} delivery request has been cancelled.`,
      type: 'sendItem',
      isImportant: true,
      targetRole: 'rider',
      relatedId: item.s_id,
    });
  }

  await createBulkNotifications(payloads);

  await notifyAdmins({
    title: 'Send Item Cancelled',
    message: `The ${item.item_type} send item request has been cancelled.`,
    relatedId: item.s_id,
    isImportant: true,
  });
};

module.exports = {
  notifySendItemCreated,
  notifySendItemAccepted,
  notifySendItemPickedUp,
  notifySendItemDelivered,
  notifySendItemCancelled,
};