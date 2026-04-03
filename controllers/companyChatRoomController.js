const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/companyChatRoomService');

const getMessages = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;
  const { sessionId } = req.params;

  const data = await service.getMessages(userId, sessionId);

  return successResponse(res, 'Chat messages fetched successfully', data);
});

const sendMessage = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;
  const { sessionId } = req.params;
  const { message_text } = req.body;

  const io = req.app.get('io');

  const data = await service.sendMessage(
    userId,
    sessionId,
    message_text,
    io
  );

  return successResponse(res, 'Message sent successfully', data);
});

const markAsRead = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;
  const { sessionId } = req.params;

  await service.markAsRead(userId, sessionId);

  return successResponse(res, 'Chat marked as read.');
});

module.exports = {
  getMessages,
  sendMessage,
  markAsRead,
};