const { successResponse, errorResponse } = require('../utils/apiResponse');
const adminProfileService = require('../services/adminProfileService');

const getAdminProfile = async (req, res) => {
  try {
    const data = await adminProfileService.getAdminProfile({
      adminAuth: req.admin,
      req,
    });

    return successResponse(res, 'Admin profile fetched successfully.', data);
  } catch (error) {
    console.error('getAdminProfile error:', error);
    return errorResponse(res, error.message || 'Failed to fetch admin profile.', 500);
  }
};

const updateAdminProfile = async (req, res) => {
  try {
    const data = await adminProfileService.updateAdminProfile({
      adminAuth: req.admin,
      body: req.body,
      req,
    });

    return successResponse(res, 'Admin profile updated successfully.', data);
  } catch (error) {
    console.error('updateAdminProfile error:', error);
    return errorResponse(res, error.message || 'Failed to update admin profile.', 400);
  }
};

const updateAdminProfileImage = async (req, res) => {
  try {
    if (!req.file) {
      return errorResponse(res, 'Profile image file is required.', 400);
    }

    const data = await adminProfileService.updateAdminProfileImage({
      adminAuth: req.admin,
      file: req.file,
      req,
    });

    return successResponse(res, 'Admin profile image updated successfully.', data);
  } catch (error) {
    console.error('updateAdminProfileImage error:', error);
    return errorResponse(res, error.message || 'Failed to update profile image.', 400);
  }
};

module.exports = {
  getAdminProfile,
  updateAdminProfile,
  updateAdminProfileImage,
};