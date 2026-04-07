const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderProfileService = require('../services/riderProfileService');

const getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const data = await riderProfileService.getProfile({ userId, req });

    return successResponse(res, 'Profile fetched successfully.', data);
  } catch (error) {
    console.error('getProfile error:', error);
    return errorResponse(res, error.message || 'Failed to fetch profile.', 500);
  }
};

const uploadProfileImage = async (req, res) => {
  try {
    const userId = req.user.userId;

    if (!req.file) {
      return errorResponse(res, 'Profile image file is required.', 400);
    }

    const data = await riderProfileService.uploadProfileImage({
      userId,
      file: req.file,
      req,
    });

    return successResponse(res, 'Profile image uploaded successfully.', data);
  } catch (error) {
    console.error('uploadProfileImage error:', error);
    return errorResponse(res, error.message || 'Failed to upload profile image.', 400);
  }
};

module.exports = {
  getProfile,
  uploadProfileImage,
};