const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/notificationService');

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

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
};