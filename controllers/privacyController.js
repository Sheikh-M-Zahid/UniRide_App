const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const privacyService = require('../services/privacyService');

const getPrivacyData = asyncHandler(async (req, res) => {
  const data = await privacyService.getPrivacyData(req.user.userId);

  return successResponse(res, 'Privacy data fetched successfully.', data);
});

const updateLocationAccess = asyncHandler(async (req, res) => {
  const { locationAccess } = req.body;

  if (!locationAccess) {
    return errorResponse(res, 'locationAccess is required.', 400);
  }

  const data = await privacyService.updateLocationAccess(
    req.user.userId,
    locationAccess
  );

  return successResponse(res, 'Location access updated successfully.', data);
});

const updateProfileVisibility = asyncHandler(async (req, res) => {
  const { profileVisibility } = req.body;

  if (!profileVisibility) {
    return errorResponse(res, 'profileVisibility is required.', 400);
  }

  const data = await privacyService.updateProfileVisibility(
    req.user.userId,
    profileVisibility
  );

  return successResponse(res, 'Profile visibility updated successfully.', data);
});

const updatePhonePrivacy = asyncHandler(async (req, res) => {
  const { phonePrivacy } = req.body;

  if (!phonePrivacy) {
    return errorResponse(res, 'phonePrivacy is required.', 400);
  }

  const data = await privacyService.updatePhonePrivacy(
    req.user.userId,
    phonePrivacy
  );

  return successResponse(res, 'Phone privacy updated successfully.', data);
});

const requestDataDownload = asyncHandler(async (req, res) => {
  const data = await privacyService.requestDataDownload(req.user.userId);

  return successResponse(
    res,
    'Your data download request has been submitted.',
    data
  );
});

module.exports = {
  getPrivacyData,
  updateLocationAccess,
  updateProfileVisibility,
  updatePhonePrivacy,
  requestDataDownload,
};