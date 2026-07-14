const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/safetyCheckService');

const respond = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;
  const { checkId } = req.params;
  const { status, message } = req.body;
  const data = await service.respondSafetyCheck(checkId, userId, { status, message });
  return successResponse(res, 'Response recorded.', data);
});

module.exports = { respond };
