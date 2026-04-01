const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/companyChatService');

const getChatList = asyncHandler(async (req, res) => {
  const data = await service.getChatList(req.user.user_id);

  return successResponse(
    res,
    data.length ? 'Chat list fetched successfully' : 'No chats found',
    data
  );
});

module.exports = {
  getChatList,
};