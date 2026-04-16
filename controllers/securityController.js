const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/securityService');

const getSecuritySummary = asyncHandler(async (req, res) => {
  const data = await service.getSecuritySummary(req.user.userId);

  return successResponse(res, 'Security data fetched successfully.', data);
});

const updateEmergencyContact = asyncHandler(async (req, res) => {
  const { phone } = req.body;

  if (!phone) {
    return errorResponse(res, 'Phone is required.', 400);
  }

  const data = await service.updateEmergencyContact(
    req.user.userId,
    phone
  );

  return successResponse(res, 'Emergency contact updated.', data);
});

const changePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    return errorResponse(res, 'Both passwords required.', 400);
  }

  await service.changePassword(
    req.user.userId,
    currentPassword,
    newPassword
  );

  return successResponse(res, 'Password changed successfully.');
});

module.exports = {
  getSecuritySummary,
  updateEmergencyContact,
  changePassword,
};