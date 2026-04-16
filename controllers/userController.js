const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const userService = require('../services/userService');

const getMyProfile = asyncHandler(async (req, res) => {
  const data = await userService.getMyProfile(req.user.userId);
  return successResponse(res, 'Profile fetched successfully.', data);
});

const updateMyProfile = asyncHandler(async (req, res) => {
  await userService.updateMyProfile(req.user.userId, req.body);
  return successResponse(res, 'Profile updated successfully.');
});

const updateProfilePicture = asyncHandler(async (req, res) => {
  const data = await userService.updateProfilePicture(req.user.userId, req.file);
  return successResponse(res, 'Profile picture updated successfully.', data);
});

const getRoleOptions = asyncHandler(async (req, res) => {
  const data = await userService.getRoleOptions(req.user.userId);
  return successResponse(res, 'Role options fetched successfully.', data);
});

module.exports = {
  getMyProfile,
  updateMyProfile,
  updateProfilePicture,
  getRoleOptions,
};