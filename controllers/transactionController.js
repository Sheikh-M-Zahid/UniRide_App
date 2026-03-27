const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const transactionService = require('../services/transactionService');

const createPaymentRecord = asyncHandler(async (req, res) => {
  const data = await transactionService.createPaymentRecord(req.user.userId, req.body);
  return successResponse(res, 'Payment record created successfully.', data, 201);
});

const listMyTransactions = asyncHandler(async (req, res) => {
  const data = await transactionService.listMyTransactions(req.user.userId);
  return successResponse(res, 'Transactions fetched successfully.', data);
});

const fetchDueBalance = asyncHandler(async (req, res) => {
  const data = await transactionService.fetchDueBalance(req.user.userId);
  return successResponse(res, 'Due balance fetched successfully.', data);
});

const walletPaymentStatus = asyncHandler(async (req, res) => {
  const data = await transactionService.walletPaymentStatus(req.user.userId);
  return successResponse(res, 'Wallet payment status fetched successfully.', data);
});

module.exports = {
  createPaymentRecord,
  listMyTransactions,
  fetchDueBalance,
  walletPaymentStatus,
};