const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const authService = require('../services/authService');

/* =========================
   SIGNUP EMAIL VERIFY FLOW
========================= */
const sendSignupOtp = asyncHandler(async (req, res) => {
  try {
    const data = await authService.sendSignupOtp(req.body.email);
    return successResponse(res, 'OTP sent successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const verifySignupOtp = asyncHandler(async (req, res) => {
  try {
    const data = await authService.verifySignupOtp(
      req.body.email,
      req.body.otp
    );
    return successResponse(res, 'OTP verified successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const resendSignupOtp = asyncHandler(async (req, res) => {
  try {
    const data = await authService.resendSignupOtp(req.body.email);
    return successResponse(res, 'A new code has been sent to your email.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const googleSignupCheck = asyncHandler(async (req, res) => {
  try {
    const data = await authService.googleSignupCheck(req.body.email);
    return successResponse(res, 'Google signup check successful.', data);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

const register = asyncHandler(async (req, res) => {
  try {
    const data = await authService.register(req.body);
    return successResponse(res, 'Account created successfully.', data, 201);
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});

/* =========================
   BASIC AUTH
========================= */
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

/* =========================
   PASSWORD RESET FLOW
========================= */
const resetPassword = asyncHandler(async (req, res) => {
  const data = await authService.resetPassword(
    req.body.email,
    req.body.otp_code,
    req.body.new_password
  );

  return successResponse(res, 'Password reset successfully.', data);
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

/* =========================
   CHECK HELPERS
========================= */
const checkEwuAllowedUser = asyncHandler(async (req, res) => {
  const data = await authService.checkEwuAllowedUser(req.body.email);
  return successResponse(res, 'EWU email check completed.', data);
});

const checkAdminStatus = asyncHandler(async (req, res) => {
  const data = await authService.checkAdminStatus(
    req.body.email,
    req.body.user_id
  );
  return successResponse(res, 'Admin check completed.', data);
});

module.exports = {
  sendSignupOtp,
  verifySignupOtp,
  resendSignupOtp,
  googleSignupCheck,
  register,
  sendOtp,
  verifyOtp,
  signup,
  login,
  googleLogin,
  resetPassword,
  findAccount,
  verifyRecoveryOtp,
  resendRecoveryOtp,
  resetPasswordWithToken,
  checkEwuAllowedUser,
  checkAdminStatus,
};