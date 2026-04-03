const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/companyChatService');

const getChatList = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;

  const data = await service.getChatList(userId);

  return successResponse(
    res,
    data.length
      ? 'Co Ride chat list fetched successfully'
      : 'No confirmed Co Ride chat yet',
    data
  );
});

const markAsRead = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;
  const { sessionId } = req.params;

  await service.markAsRead(userId, sessionId);

  return successResponse(res, 'Chat marked as read successfully', {});
});

module.exports = {
  getChatList,
  markAsRead,
};