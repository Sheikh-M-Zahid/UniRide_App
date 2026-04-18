const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const profileService = require('../services/profileService');

const getMyProfile = asyncHandler(async (req, res) => {
  try {
    const data = await profileService.getMyProfile(req.user.userId);

    return successResponse(res, 'Profile fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const updateProfileImage = asyncHandler(async (req, res) => {
  try {
    if (!req.file) {
      return errorResponse(res, 'Profile image is required.', 400);
    }

    const data = await profileService.updateProfileImage(
      req.user.userId,
      req.file.path
    );

    return successResponse(res, 'Profile image updated successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

module.exports = {
  getMyProfile,
  updateProfileImage,
};