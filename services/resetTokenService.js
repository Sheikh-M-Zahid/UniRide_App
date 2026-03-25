const jwt = require('jsonwebtoken');

const generateResetToken = (email) => {
  return jwt.sign(
    {
      email,
      purpose: 'password_reset',
    },
    process.env.RESET_TOKEN_SECRET,
    {
      expiresIn: process.env.RESET_TOKEN_EXPIRES_IN || '10m',
    }
  );
};

const verifyResetToken = (token) => {
  return jwt.verify(token, process.env.RESET_TOKEN_SECRET);
};

module.exports = {
  generateResetToken,
  verifyResetToken,
};
