const admin = require('../config/firebase');
const rideDb = require('../config/rideDb');
const { emitNotification } = require('../utils/notificationEmitter');

const mapNotificationRow = (row) => ({
  id: row.notification_id || row.id,
  title: row.title,
  message: row.message,
  type: row.type,
  createdAt: row.created_at || row.createdAt,
  isRead: row.is_read ?? row.isRead,
  isImportant: row.is_important ?? row.isImportant,
  targetRole: row.target_role || row.targetRole,
  relatedId: row.related_id || row.relatedId || null,
});

const getNotifications = async (userId, role = null) => {
  let query = `
    SELECT 
        notification_id,
        title,
        message,
        type,
        created_at,
        is_read,
        is_important,
        target_role,
        related_id
     FROM notifications
     WHERE user_id = $1
  `;
  const params = [userId];

  if (role) {
    query += ` AND (target_role = $2 OR target_role = 'general')`;
    params.push(role);
  }

  query += ` ORDER BY created_at DESC`;

  const result = await rideDb.query(query, params);
  return result.rows.map(mapNotificationRow);
};

const markAsRead = async (userId, id) => {
  await rideDb.query(
    `UPDATE notifications
     SET is_read = TRUE
     WHERE notification_id = $1
       AND user_id = $2`,
    [id, userId]
  );

  // notification_interactions এ shown -> clicked আপডেট (রিওয়ার্ড ট্র্যাকিং এর জন্য)
  try {
    await rideDb.query(
      `UPDATE notification_interactions
       SET action = 'clicked', action_timestamp = CURRENT_TIMESTAMP, reward_value = 1.0
       WHERE user_id = $1 AND notification_id = $2 AND action = 'shown'`,
      [userId, id]
    );
  } catch (err) {
    console.error('notification_interactions clicked log error:', err?.message);
  }
};

const markAllAsRead = async (userId) => {
  await rideDb.query(
    `UPDATE notifications
     SET is_read = TRUE
     WHERE user_id = $1`,
    [userId]
  );
};

const deleteNotification = async (userId, id) => {
  await rideDb.query(
    `DELETE FROM notifications
     WHERE notification_id = $1
       AND user_id = $2`,
    [id, userId]
  );
};

const createNotification = async ({
  userId,
  title,
  message,
  type = 'general',
  isImportant = false,
  targetRole = 'general',
  relatedId = null,
}) => {
  if (!userId || !title || !message) {
    return null;
  }

  const result = await rideDb.query(
    `INSERT INTO notifications (
      user_id,
      title,
      message,
      type,
      is_important,
      target_role,
      related_id
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING 
       notification_id,
       title,
       message,
       type,
       created_at,
       is_read,
       is_important,
       target_role,
       related_id`,
    [userId, title, message, type, isImportant, targetRole, relatedId]
  );

  const notification = mapNotificationRow(result.rows[0]);

  emitNotification(userId, notification);

  // notification_interactions এ "shown" log করা (হালকা ভার্সন, শুধু data collection)
  try {
    await rideDb.query(
      `INSERT INTO notification_interactions (user_id, notification_id, notification_type, action)
       VALUES ($1, $2, $3, 'shown')`,
      [userId, notification.id, type]
    );
  } catch (err) {
    console.error('notification_interactions shown log error:', err?.message);
  }

  // FCM push notification
  try {
    const tokenResult = await rideDb.query(
      `SELECT fcm_token FROM users WHERE user_id = $1`,
      [userId]
    );
    const fcmToken = tokenResult.rows[0]?.fcm_token;

    if (fcmToken) {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: title,
          body: message,
        },
        data: {
          notificationId: String(notification.id),
          type: type,
          relatedId: relatedId ? String(relatedId) : '',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'uniride_channel',
            priority: 'high',
            defaultSound: true,
          },
        },
      });
    }
  } catch (err) {
    console.error('FCM error:', err?.message);
  }

  return notification;
};

const createBulkNotifications = async (notifications = []) => {
  const results = [];

  for (const item of notifications) {
    const created = await createNotification(item);
    if (created) {
      results.push(created);
    }
  }

  return results;
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  createNotification,
  createBulkNotifications,
};
