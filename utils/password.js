const bcrypt = require('bcrypt');

const hashPassword = async (plainPassword) => {
  return bcrypt.hash(plainPassword, 10);
};

const comparePassword = async (plainPassword, hash) => {
  return bcrypt.compare(plainPassword, hash);
};

module.exports = {
  hashPassword,
  comparePassword,
};