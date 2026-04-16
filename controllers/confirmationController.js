const { successResponse, errorResponse } = require('../utils/apiResponse');
const confirmationService = require('../services/confirmationService');

const getConfirmationStatus = async (req, res) => {
  try {
    const userId = req.user.userId;

    const data = await confirmationService.getConfirmationStatus({ userId });

    return successResponse(res, 'Confirmation status fetched successfully.', data);
  } catch (error) {
    console.error('getConfirmationStatus error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch confirmation status.',
      500
    );
  }
};

const selectMode = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { selectedMode } = req.body;

    const data = await confirmationService.selectMode({
      userId,
      selectedMode,
    });

    return successResponse(res, 'Mode selection processed successfully.', data);
  } catch (error) {
    console.error('selectMode error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to process selected mode.',
      400
    );
  }
};

module.exports = {
  getConfirmationStatus,
  selectMode,
};