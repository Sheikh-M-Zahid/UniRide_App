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

const getNotifications = async (userId) => {
  const result = await rideDb.query(
    `SELECT 
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
     ORDER BY created_at DESC`,
    [userId]
  );

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