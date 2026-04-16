const rideDb = require('../config/rideDb');
const { emitNotification } = require('../config/socket');

/* ================= GET ================= */

const getNotifications = async (userId) => {
  const result = await rideDb.query(
    `SELECT 
        notification_id AS id,
        title,
        message,
        type,
        created_at AS "createdAt",
        is_read AS "isRead",
        is_important AS "isImportant",
        target_role AS "targetRole"
     FROM notifications
     WHERE user_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

/* ================= READ ================= */

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

/* ================= DELETE ================= */

const deleteNotification = async (userId, id) => {
  await rideDb.query(
    `DELETE FROM notifications
     WHERE notification_id = $1
       AND user_id = $2`,
    [id, userId]
  );
};

/* ================= CREATE (REUSABLE) ================= */

const createNotification = async ({
  userId,
  title,
  message,
  type,
  isImportant = false,
  targetRole = 'general',
  relatedId = null,
}) => {
  const result = await rideDb.query(
    `INSERT INTO notifications (
      user_id, title, message, type, is_important, target_role, related_id
     )
     VALUES ($1,$2,$3,$4,$5,$6,$7)
     RETURNING *`,
    [userId, title, message, type, isImportant, targetRole, relatedId]
  );

  const notification = result.rows[0];

  // 🔥 REALTIME SEND
  emitNotification(userId, notification);

  return notification;
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  createNotification,
};