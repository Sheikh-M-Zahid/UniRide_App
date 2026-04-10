const { successResponse, errorResponse } = require('../utils/apiResponse');
const adminPaymentApprovalService = require('../services/adminPaymentApprovalService');

const getPaymentRequests = async (req, res) => {
  try {
    const {
      search = '',
      status = 'all',
      page = 1,
      limit = 20,
    } = req.query;

    const data = await adminPaymentApprovalService.getPaymentRequests({
      search,
      status,
      page: Number(page),
      limit: Number(limit),
    });

    return successResponse(res, 'Payment requests fetched successfully.', data);
  } catch (error) {
    console.error('getPaymentRequests error:', error);
    return errorResponse(res, error.message || 'Failed to fetch payment requests.', 500);
  }
};

const confirmPayment = async (req, res) => {
  try {
    const adminId = req.admin.id;
    const { paymentDbId } = req.params;

    const data = await adminPaymentApprovalService.confirmPayment({
      paymentDbId,
      adminId,
    });

    return successResponse(res, 'Payment confirmed successfully.', data);
  } catch (error) {
    console.error('confirmPayment error:', error);
    return errorResponse(res, error.message || 'Failed to confirm payment.', 400);
  }
};

const declinePayment = async (req, res) => {
  try {
    const adminId = req.admin.id;
    const { paymentDbId } = req.params;

    const data = await adminPaymentApprovalService.declinePayment({
      paymentDbId,
      adminId,
    });

    return successResponse(res, 'Payment declined successfully.', data);
  } catch (error) {
    console.error('declinePayment error:', error);
    return errorResponse(res, error.message || 'Failed to decline payment.', 400);
  }
};

module.exports = {
  getPaymentRequests,
  confirmPayment,
  declinePayment,
};