const jwt = require('jsonwebtoken');

const generateSignupToken = (email) => {
  return jwt.sign(
    {
      email,
      purpose: 'signup_verification',
    },
    process.env.SIGNUP_TOKEN_SECRET,
    {
      expiresIn: process.env.SIGNUP_TOKEN_EXPIRES_IN || '10m',
    }
  );
};

const verifySignupToken = (token) => {
  return jwt.verify(token, process.env.SIGNUP_TOKEN_SECRET);
};

module.exports = {
  generateSignupToken,
  verifySignupToken,
};