const ewuAdminDb = require('../config/ewuAdminDb');
const rideDb = require('../config/rideDb');
const { comparePassword } = require('../utils/password');
const { generateToken } = require('../utils/jwt');
const reportService = require('./reportService');
const offerService = require('./offerService');

const adminLogin = async (email, password) => {
  const result = await ewuAdminDb.query(
    `SELECT id, name, email, password_hash, role
     FROM admins
     WHERE email = $1`,
    [email.trim().toLowerCase()]
  );

  if (result.rowCount === 0) {
    throw new Error('Admin account not found.');
  }

  const admin = result.rows[0];
  const matched = await comparePassword(password, admin.password_hash);

  if (!matched) {
    throw new Error('Invalid admin credentials.');
  }

  const token = generateToken({
    adminId: admin.id,
    email: admin.email,
    isAdmin: true,
  });

  return {
    token,
    admin: {
      id: admin.id,
      name: admin.name,
      email: admin.email,
      role: admin.role,
    },
  };
};

const listUsers = async () => {
  const result = await rideDb.query(
    `SELECT user_id, university_email, first_name, last_name, phone,
            activity_status, account_status, due_balance, rating, created_at
     FROM users
     ORDER BY created_at DESC`
  );

  return result.rows;
};

const suspendOrActivateUser = async (userId, account_status) => {
  const result = await rideDb.query(
    `UPDATE users
     SET account_status = $1
     WHERE user_id = $2
     RETURNING user_id, university_email, first_name, last_name, account_status`,
    [account_status, userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User not found.');
  }

  return result.rows[0];
};

module.exports = {
  adminLogin,
  listUsers,
  suspendOrActivateUser,
  listAllReports: reportService.listAllReports,
  markReportSolved: reportService.markReportSolved,
  createOffer: offerService.createOffer,
  listOffers: offerService.listOffers,
};