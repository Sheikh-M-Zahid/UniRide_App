const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/notificationService');
const rideDb = require('../config/rideDb');

const getNotifications = asyncHandler(async (req, res) => {
  const data = await service.getNotifications(req.user.userId);

  return successResponse(res, 'Notifications fetched', data);
});

const markAsRead = asyncHandler(async (req, res) => {
  await service.markAsRead(req.user.userId, req.params.id);
  return successResponse(res, 'Marked as read');
});

const markAllAsRead = asyncHandler(async (req, res) => {
  await service.markAllAsRead(req.user.userId);
  return successResponse(res, 'All marked as read');
});

const deleteNotification = asyncHandler(async (req, res) => {
  await service.deleteNotification(req.user.userId, req.params.id);
  return successResponse(res, 'Notification deleted');
});

const saveFcmToken = asyncHandler(async (req, res) => {
  const { fcmToken } = req.body;
  const userId = req.user.userId;

  if (!fcmToken) {
    return errorResponse(res, 'fcmToken required', 400);
  }

  await rideDb.query(
    `UPDATE users SET fcm_token = $1 WHERE user_id = $2`,
    [fcmToken, userId]
  );

  return successResponse(res, 'FCM token saved');
});

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  saveFcmToken,
};
