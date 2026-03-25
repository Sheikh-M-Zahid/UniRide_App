const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const userService = require('../services/userService');

const getProfile = asyncHandler(async (req, res) => {
  const data = await userService.getProfile(req.user.userId);
  return successResponse(res, 'Profile fetched successfully.', data);
});

const updateProfile = asyncHandler(async (req, res) => {
  const data = await userService.updateProfile(req.user.userId, req.body);
  return successResponse(res, 'Profile updated successfully.', data);
});

const getRole = asyncHandler(async (req, res) => {
  const data = await userService.getRole(req.user.userId);
  return successResponse(res, 'User role fetched successfully.', data);
});

const getAccountStatus = asyncHandler(async (req, res) => {
  const data = await userService.getAccountStatus(req.user.userId);
  return successResponse(res, 'Account status fetched successfully.', data);
});

const getWalletInfo = asyncHandler(async (req, res) => {
  const data = await userService.getWalletInfo(req.user.userId);
  return successResponse(res, 'Wallet info fetched successfully.', data);
});

const getRoleOptions = asyncHandler(async (req, res) => {
  const data = await userService.getRoleOptions(req.user.userId);
  return successResponse(res, 'Role options fetched successfully.', data);
});

module.exports = {
  getProfile,
  updateProfile,
  getRole,
  getAccountStatus,
  getWalletInfo,
  getRoleOptions,
};