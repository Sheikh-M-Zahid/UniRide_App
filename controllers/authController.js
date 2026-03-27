const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const authService = require('../services/authService');

const sendOtp = asyncHandler(async (req, res) => {
  const data = await authService.sendOtp(req.body.email);
  return successResponse(res, 'OTP sent successfully.', data);
});

const verifyOtp = asyncHandler(async (req, res) => {
  const data = await authService.verifyOtp(req.body.email, req.body.otp_code);
  return successResponse(res, 'OTP verified successfully.', data);
});

const signup = asyncHandler(async (req, res) => {
  const data = await authService.signup(req.body);
  return successResponse(res, 'Signup successful.', data, 201);
});

const login = asyncHandler(async (req, res) => {
  const data = await authService.login(req.body.email, req.body.password);
  return successResponse(res, 'Login successful.', data);
});

const googleLogin = asyncHandler(async (req, res) => {
  const data = await authService.googleLogin(req.body.email);
  return successResponse(res, 'Google login successful.', data);
});

const resetPassword = asyncHandler(async (req, res) => {
  const data = await authService.resetPassword(
    req.body.email,
    req.body.otp_code,
    req.body.new_password
  );

  return successResponse(res, 'Password reset successfully.', data);
});

const checkEwuAllowedUser = asyncHandler(async (req, res) => {
  const data = await authService.checkEwuAllowedUser(req.body.email);
  return successResponse(res, 'EWU email check completed.', data);
});

const checkAdminStatus = asyncHandler(async (req, res) => {
  const data = await authService.checkAdminStatus(req.body.email, req.body.user_id);
  return successResponse(res, 'Admin check completed.', data);
});

const findAccount = asyncHandler(async (req, res) => {
  const data = await authService.findAccount(req.body.email);
  return successResponse(res, 'Account found. OTP sent successfully.', data);
});

const verifyRecoveryOtp = asyncHandler(async (req, res) => {
  const data = await authService.verifyRecoveryOtp(
    req.body.email,
    req.body.otp
  );

  return successResponse(res, 'OTP verified successfully.', data);
});

const resendRecoveryOtp = asyncHandler(async (req, res) => {
  await authService.resendRecoveryOtp(req.body.email);

  return successResponse(
    res,
    'A new OTP has been sent to your university email.'
  );
});

const resetPasswordWithToken = asyncHandler(async (req, res) => {
  await authService.resetPasswordWithToken(
    req.body.resetToken,
    req.body.newPassword,
    req.body.confirmPassword
  );

  return successResponse(res, 'Password reset successfully.');
});

module.exports = {
  sendOtp,
  verifyOtp,
  signup,
  login,
  googleLogin,
  resetPassword,
  checkEwuAllowedUser,
  checkAdminStatus,
  findAccount,
  verifyRecoveryOtp,
  resendRecoveryOtp,
  resetPasswordWithToken,
};