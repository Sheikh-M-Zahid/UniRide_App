const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post('/send-otp', validateRequiredFields(['email']), authController.sendOtp);
router.post('/verify-otp', validateRequiredFields(['email', 'otp_code']), authController.verifyOtp);
router.post(
  '/signup',
  validateRequiredFields(['university_email', 'password']),
  authController.signup
);
router.post('/login', validateRequiredFields(['email', 'password']), authController.login);
router.post('/google-login', validateRequiredFields(['email']), authController.googleLogin);
router.post(
  '/reset-password',
  validateRequiredFields(['email', 'otp_code', 'new_password']),
  authController.resetPassword
);
router.post('/check-ewu-user', validateRequiredFields(['email']), authController.checkEwuAllowedUser);
router.post(
  '/send-signup-otp',
  validateRequiredFields(['email']),
  authController.sendSignupOtp
);

router.post(
  '/verify-signup-otp',
  validateRequiredFields(['email', 'otp']),
  authController.verifySignupOtp
);

router.post(
  '/resend-signup-otp',
  validateRequiredFields(['email']),
  authController.resendSignupOtp
);

router.post(
  '/google-signup-check',
  validateRequiredFields(['email']),
  authController.googleSignupCheck
);

router.post(
  '/register',
  validateRequiredFields([
    'signupToken',
    'first_name',
    'last_name',
    'phone',
    'gender',
    'date_of_birth',
    'home_address',
    'password'
  ]),
  authController.register
);

router.post(
  '/reset-password-with-token',
  validateRequiredFields(['resetToken', 'newPassword', 'confirmPassword']),
  authController.resetPassword
);
router.post('/check-admin', validateRequiredFields(['email']), authController.checkAdminStatus);
router.post('/find-account', validateRequiredFields(['email']), authController.findAccount);

router.post(
  '/verify-recovery-otp',
  validateRequiredFields(['email', 'otp']),
  authController.verifyRecoveryOtp
);

router.post(
  '/resend-recovery-otp',
  validateRequiredFields(['email']),
  authController.resendRecoveryOtp
);
router.post(
  '/reset-password-with-token',
  validateRequiredFields(['resetToken', 'newPassword', 'confirmPassword']),
  authController.resetPassword
);
module.exports = router;
