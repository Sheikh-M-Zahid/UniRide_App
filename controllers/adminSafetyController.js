const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/safetyCheckService');

const getReports = asyncHandler(async (req, res) => {
  const { status = 'all', page = 1, limit = 20 } = req.query;
  const data = await service.getAdminSafetyReports({ status, page: Number(page), limit: Number(limit) });
  return successResponse(res, 'Safety reports fetched.', data);
});

module.exports = { getReports };
