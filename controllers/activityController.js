const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const activityService = require('../services/activityService');

// ================================
// GET MY ACTIVITY
// ================================
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

// ================================
// ACTIVITY DASHBOARD
// ================================
const getActivityDashboard = async (req, res) => {
  try {
    const {
      type = 'all',
      time = 'today',
      page = 1,
      limit = 20,
    } = req.query;

    const data = await activityService.getActivityDashboard({
      userId: req.user.userId,
      type,
      time,
      page: Number(page),
      limit: Number(limit),
    });

    return successResponse(
      res,
      'Activity dashboard fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getActivityDashboard error:', error);

    return errorResponse(
      res,
      error.message || 'Failed to fetch activity dashboard.',
      500
    );
  }
};

// ================================
// EXPORT
// ================================
module.exports = {
  getMyActivity,
  getActivityDashboard,
};