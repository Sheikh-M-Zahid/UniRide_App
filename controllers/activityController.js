const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const activityService = require('../services/activityService');

const getMyActivity = asyncHandler(async (req, res) => {
  const sort = req.query.sort || 'new';

  const data = await activityService.getMyActivity(
    req.user.userId,
    sort
  );

  const message =
    data.length > 0
      ? 'Activity fetched successfully'
      : 'No recent activity found';

  return successResponse(res, message, data);
});

module.exports = {
  getMyActivity,
};