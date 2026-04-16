const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderCarService = require('../services/riderCarService');

const registerCar = async (req, res) => {
  try {
    const userId = req.user.userId;

    const data = await riderCarService.registerCar({
      userId,
      body: req.body,
      files: req.files,
    });

    return successResponse(res, 'Car registration submitted successfully.', data);
  } catch (error) {
    console.error('registerCar error:', error);
    return errorResponse(res, error.message, 400);
  }
};

module.exports = {
  registerCar,
};