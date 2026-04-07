const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderBikeService = require('../services/riderBikeService');

const registerBike = async (req, res) => {
  try {
    const userId = req.user.userId;

    const data = await riderBikeService.registerBike({
      userId,
      body: req.body,
      files: req.files,
    });

    return successResponse(res, 'Bike registration submitted successfully.', data);
  } catch (error) {
    console.error('registerBike error:', error);
    return errorResponse(res, error.message, 400);
  }
};

module.exports = {
  registerBike,
};